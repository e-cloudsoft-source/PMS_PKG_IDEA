/**
* バッチ連携：外から連携する顧客情報を反映する
* らくじゃん連携処理
* 2013/06/20 予約変更ステータスデータ連携する場合、処理対象外にする
* 2013/12/27 旅行会社予約番号設定追加
* 2014/02/18 取込みデータの都道府県の桁数を超える場合、該当項目を空欄のままデータを取り込み
* 2014/08/07 部屋自動割り当て機能追加（１部屋タイプ１部屋のみ、部屋は自動予約にアサインする）
* 2016/10/24 予約人数がゼロの不具合改修
* 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修
* 2016/10/21 TR変更機能改善対応、予約変更の場合、予約名を上書きしない、到着日を変更すると、既に割当される部屋をクリア処理追加、項目値自動設定不具合改修
* 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修
* 2017/02/21 お子様プランの料金PRICE機能追加 
* 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応
* 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応
* 2017/07/20 改善要望：ねっぱんクーポンと、ポイントを別で取込
* 2017/09/01 最大文字数をこえない問題回避対応
* 2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応
* 2018/11/20 小人数取り込み不正の対応
* 2018/12/15 ネット取り込み、予約変更機能改善
* 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応
* 2018/12/30 TRポイント取り込み改善対応
* 2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する
* 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応
* 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する
* 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善
* 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善
* 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加
* 2020/07/30 入湯税の自動入力機能について改善
* 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善
**********************************/
global with sharing class BI_TR_LeadInfoSync {
	// 中継アプリの名
	private static final String APPNAME = 'TR';
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
	// 2014/08/07 部屋自動割り当て
	private static Boolean oneRoomAutoAssingRoomFlg { get{ return CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c; }}
	// 2014/11/20 店舗別プラン設定機能判断フラグ
	private static final Boolean isPlanOfShopFlg = CommConst.APPOTION_BI_SHOPPLAN_FLG;
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
	// ネット取込する場合、XMLタグに、室料合計料金のみが存在場合、N人数に対して、室料/人数で計算できる場合、自動計算して、人数＊単価で明細に反映
    private static boolean presonRateAutoCal = true;
    // 消費税情報
	private static JMST__c taxRateMst;
    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
    static map<id,set<string>> fieldChgHisMap = null;
    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
    /*
    * 外部から予約データ連携機能
    */
    webservice static BI_TR_SyncResult upsertLeadInfo(
            BI_TR_SyncInfo bookingInfo) {
        // 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
        unescapeXmlProcess(bookingInfo);
        // 2017/06/30 XML特殊記号文字UTF-8対応 END
		// 店舗コード
        String accommodationName = bookingInfo.AccommodationName;
        shopCd = BI_TR_ServiceConfigHelp.getCommConfig().shopNameMatchMap.get(accommodationName);
System.debug(LoggingLevel.INFO,'宿泊施設名：['+accommodationName+']:店舗コード:['+shopCd+']');
        // 変更、キャンセルする場合、予約取込するがどうか判断用フラグ:TRUEの場合、取込みを行う
        Boolean ucIsSyncFlg = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).ucactisSync;
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
        if (BI_TR_ServiceConfigHelp.getAppConfig(shopCd).romanToKanaFlag) convertGuestInfo(bookingInfo);
        // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
        // 2015/12/11 予約取込機能改善（変更、キャンセル） BEGIN
        LEAD_CREATE_TIME_DIFF_INT = BI_TR_ServiceConfigHelp.getCommConfig().mLeadTimeLimit;
        //bookingNumber = bookingInfo.SalesOfficeCompanyCode + '_' + bookingInfo.TravelAgencyBookingNumber;
        bookingNumber = BI_TR_ServiceConfigHelp.getkey(bookingInfo.SalesOfficeCompanyCode, bookingInfo.TravelAgencyBookingNumber);
        bookingDataId = APPNAME + '_' + bookingNumber;
        bookingInfo.DataID = bookingNumber;
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
        // 2016/06/20 EDIT END
		// 予約情報を更新を行う
System.debug(logginglevel.INFO,bookingInfo);
        BI_TR_SyncResult rs = new BI_TR_SyncResult();
		// 2016/06/20 EDIT BEGIN
		Savepoint sp = Database.setSavepoint();
	try {
		// 2013/06/20 変更ステータス連携対象外
		if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
            // Data発生源の条件を追加する
            String dataFrom = bookingInfo.DataFrom;
            // 2016/06/20 EDIT BEGIN
            if(CommUtils.isBlank(bookingNumber)){
                rs.result = BI_TR_Result.NG;
                return rs;
            }
System.debug(LoggingLevel.INFO,'------DataID------' + bookingNumber);
            // 2016/06/20 EDIT END
			// 既存の予約インデックス情報を取得する
			// 2015/09/10 作成元情報のFilter条件に追加する BEGIN[And (APPNAME__c = :APPNAME OR APPNAME__c = null]
			//String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID)  + '\' And EventSource__c = :dataFrom And (APPNAME__c = :APPNAME OR APPNAME__c = null ) ';
			//List<LeadIndex__c> rslst = Database.query(pString);
			List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
			if (rslst.isEmpty()) {
				//throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
				// 2013/07/17 仮に、データOKに設定する、overフォルダに移動する TODO:ERRORフォルダに移動対応が必要
				if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD) {
                    // 元の予約インデックスは何も処理を行わない
                    System.debug(LoggingLevel.INFO,'DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータが更新対象外になる');
                    
                } 
                // 次の変更後の新規処理を行う
                else if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
                    System.debug(LoggingLevel.INFO,'DataIDと一致するご予約情報はSalesforceからみつかりません。元のデータがキャンセル対象外になる');
                    // 予約インデックスのみ作成して、XMLを格納する
                    // DataIDが非存在する場合、単に該当XMLはSalesforceにアップロードを行う
                    LeadIndex__c dumyIndex = new LeadIndex__c(ID__c = bookingNumber,EventSource__c = bookingInfo.DataFrom,StatusLst__c = CommConst.LEAD_ST_CANCEL,APPNAME__c = APPNAME);
                    insert dumyIndex;
                    System.debug(LoggingLevel.INFO,'該当キャンセルXMLファイルは下記予約インデックス['+dumyIndex.Id+'にアップロード済');
                    rs.sfdcId = dumyIndex.Id;
                    // キャンセルの場合、新規の予約インデックスデータのみ作成して、XMLを格納する
				rs.result = BI_TR_Result.OK;
				return rs;
                }
				// 2016/06/20 EDIT END
			} else {
				// 変更時刻を設定する
                LeadIndex__c leadIndex = rslst[0];
				if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD){
					leadIndex.TravelAgencyBookingUpdDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0) );
				}
				if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL){
					leadIndex.TravelAgencyBookingDelDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
				}
				// 予約インデックスのデータ種別に更新を行う
                leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
				// 2015/09/10 ADD BEGIN
				leadIndex.APPNAME__c = APPNAME;
				// 2015/09/10 ADD END
				// 変更、キャンセル連動対応の場合、予約インストールのステータスも取消を行う
                if (ucIsSyncFlg && bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
                    leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
                }
                update leadIndex;
                // 変更、キャンセル情報を取込ない制御の場合
                if (!ucIsSyncFlg) {
                    System.debug(LoggingLevel.INFO,'変更、キャンセルするため、予約取込処理対象外になる');
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TR_Result.OK;
                    return rs;
                }      
                // 既存の予約インデックス、予約インデックスSUB,予約情報へ変更、キャンセル処理を行う
                // 既存の予約インデックスと関連の予約インスタントSUB情報を取得する
                Set<Id> subLeadIds = new Set<Id>();
                for(LeadIndex__c subIndex : [select id from LeadIndex__c where ParentLeadIndxRef__c =:leadIndex.id]){
                    subLeadIds.add(subIndex.id);
                }
				// 予約はキャンセルされる場合
                if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
                	// 同じ予約インデックスを所属する予約情報は全部キャンセルを行う
	                orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
                							,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
                							,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                							,RoomUpdFlg__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
	                                from Lead__c 
	                                where (LeadIndexRef__c = :leadIndex.id or LeadIndexSubId__c = :subLeadIds)
	                                And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG ];
	                List<Lead__c> emailUpdLeadLst = filterTRImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
	                for (Lead__c orgLead : emailUpdLeadLst) {
                    	// メール本番設定機能、メール内容を取得、設定を行う
						String emailMsg = mailArea(bookingInfo);
                        orgLead.email__c = CommLogUtils.removeOverLogString(emailMsg + '\n\n\n' + CommUtils.nullToBlank(orgLead.email__c),emailLength);
	                }
                } else if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD) {
	                 // 既存予約変更、キャンセル処理する場合、既存の予約情報を一回キャンセルを更新する
	                orgLeadLst = [  select id, ReservedStatus__c,Comment3__c,RoomGroupNo__c,EntryTime__c,LeadIndexSubId__c,LeadIndexRef__c
                							,email__c,Relcontact__c,Field2__c,EventSource__c,BookingDataID__c,Departure__c,CreatedDate 
                							,Nights__c,PlanSycnFlag__c,LeadIndexRef__r.LeadName__c,Name,refTypeOfRooms__c,Rroom__c
                							,Field348__c
                							// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                							,Field4__c,Field3__c,StayPersons__c,Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c,ChildE__c,ChildF__c,ChildOther__c
                							// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
                							,RoomUpdFlg__c
                							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                							,Field276__c
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
						orgLeadLst = filterTRImportData(orgLeadLst,bookingInfo,leadIndex,subLeadIds);
				        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				        fieldChgHisMap = BI_TR_ServiceConfigHelp.getLeadHisotryInfo(orgLeadLst); 
// ***************************************** DEBUG ********************//
						for (String key : fieldChgHisMap.keyset()) {
							System.debug(LoggingLevel.INFO, '項目変更履歴===========[' + key + ']===========' + key );
							for (String str : fieldChgHisMap.get(key)) {
								System.debug(LoggingLevel.INFO, '項目変更時刻[' + str + ']' );
							}
						}
// ***************************************** DEBUG ********************//
				        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				}
				// アクセス権限制限するため、キャンセル処理する場合、削除から更新に変更する
           		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
           		boolean chgRoomTypeFlag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
           		// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
                for (Lead__c lead : orgLeadLst) {
                    // 2015/10/15 Ver15.71以後、予約変更処理ロジック対応するため、下記設定ロジックを変更する BEGIN
                    String cancelMessage = '<br/>' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS')+' ';
                    if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
                    	//キャンセル対応
                        cancelMessage += Label.CONST_038_0002;
                        lead.EventSource__c = bookingDataId + '_' + DateTime.now().getTime();
                        lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                    } else if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD) {
                    	//予約変更対応
                        cancelMessage += Label.CONST_038_0003;
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
                if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
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
System.debug(LoggingLevel.INFO,'既存予約情報('+orgLeadLst.size()+'件)をキャンセル済');
                    // 処理結果を戻る
                    rs.sfdcId = rslst[0].Id;
                    rs.result = BI_TR_Result.OK;
                    return rs;
                }
				//update rslst[0];
			}
        }
        // 2016/06/02 新規予約情報を重複取り込み回避対応（同じ予約番号が存在すると、新規取り込みなし、XMLのみコピーする） BEGIN
		else if(bookingInfo.dmlAction == BI_TR_DmlAction.INS ){
	        if(CommUtils.isBlank(bookingNumber)){
	            rs.result = BI_TR_Result.NG;
	            return rs;
	        }
	         //TRの中に、同じ予約番号は別々取り込みが存在するため、重複チェックが要らない
	        if (!BI_TR_ServiceConfigHelp.getCommConfig().bIsDebug) {
				List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
				if (!rslst.isEmpty()) {
	                if(bookingInfo.dmlAction == BI_TR_DmlAction.INS){
System.debug(LoggingLevel.INFO,'該当データID[' + bookingNumber + ']SalesforceID[' + rslst[0].Id + ']の予約情報は既に取込済ため、重複取込できません。');
						rs.sfdcId = rslst[0].Id;
						rs.result = BI_TR_Result.OK;
						return rs;
	                }
	    	 	}
			}
		}
	// 2016/06/20 EDIT END	
        //try {
            // 旅行会社情報の新規・更新を行う
            //Account traveCompany = upsertTravelInfo(bookingInfo);
            List<Account> traveCompany = upsertTravelInfo(bookingInfo);
            // 団体代表者の情報は顧客へ登録する
            //Contact pkuser = upsertContact(bookingInfo);
            Contact pkuser = upsertContact(bookingInfo,orgLeadLst.isEmpty() ? null : orgLeadLst[0]);
            // 予約インデックスオブジェクト
            LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo, pkuser, traveCompany);
            // 予約データを作成する　
            //upsertLead(bookingInfo, leadIndex, pkuser, traveCompany);
            upsertLead(bookingInfo, leadIndex, pkuser, traveCompany,shopCd,orgLeadLst);
            // 処理結果設定を行う
            rs.sfdcId = leadIndex.Id;
            rs.result = BI_TR_Result.OK;
        } catch (CommException ex) {
			DataBase.rollback(sp);
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            rs.result = BI_TR_Result.NG;
            rs.message = ex.getMessage();
            //rs.message = ex.getStackTraceString();
        } catch (Exception e) {
        	DataBase.rollback(sp);
            System.debug(LoggingLevel.ERROR, e);
            System.debug(LoggingLevel.ERROR, e.getMessage());
            rs.result = BI_TR_Result.NG;
            rs.message = e.getMessage();
            rs.message = e.getStackTraceString();
        }
        return rs;
	}
	
	// 2016/06/20 EDIT BEGIN
	// 既存予約INDEX情報を取得する
    private static List<LeadIndex__c> getExistLeadIndexByDataId(BI_TR_SyncInfo bookingInfo) {
        	return [select id,EntryDate__c,CreatedDate,TravelAgencyBookingUpdDateTime__c,TravelAgencyBookingDelDateTime__c,LeadName__c from LeadIndex__c 
        			where ID__c = :bookingNumber
        			And EventSource__c = :bookingInfo.DataFrom 
        			And APPNAME__c = :APPNAME
        			And StatusLst__c != :CommConst.LEAD_ST_CANCEL 
        			order by CreatedDate desc limit 1];    	
    }
	// 2016/06/20 EDIT END
	
    /**
    * 予約基本情報
    **/
    private static LeadIndex__c upsertLeadIndex(BI_TR_SyncInfo bookingInfo, Contact pkuser, List<Account> TraveCompany) {
    	System.debug(LoggingLevel.INFO, '-------- 予約基本情報 begin ------');
        //LeadIndex__c leadIndex;
        List<LeadIndex__c> rslst = getExistLeadIndexByDataId(bookingInfo);
        boolean updFlag = bookingInfo.dmlAction == BI_TR_DmlAction.UPD;
        LeadIndex__c leadIndex = new LeadIndex__c(ID__c = bookingNumber);
		if(updFlag && !rslst.isEmpty()){
            leadIndex = rslst[0];
        }
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
        boolean updFlgIsInsert = updFlag && rslst.isEmpty();// 更新　かつ　更新元はなかった場合、該当フラグはTRUE
        // 2016/10/21 TL変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
        // ネット旅行Agency
        // 更新/キャンセル場合:存在チェックを行う
        /*if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
            
            // Data発生源の条件を追加する
            String dataFrom = bookingInfo.DataFrom;
            // 既存の予約インデックス情報を取得する
            String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID)  + '\' And EventSource__c = :dataFrom ';
            List<LeadIndex__c> rslst = Database.query(pString);
            if (rslst.isEmpty()) {
                throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
            }
            leadIndex = rslst[0];
			
			// キャンセルステータスに変更する
			if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) leadIndex.StatusLst__c = CommConst.LEAD_ST_CANCEL;
			
            // 2012/12/24 Upsert Index Info
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? null : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c = defaultCheckoutTimeStr;
            leadIndex.Nights__c = bookingInfo.Nights;
			// 2012/12/23 ADD
			leadIndex.contactRef__c = pkuser.Id; 
			leadIndex.Rooms__c = (bookingInfo.TotalRoomCount == null || bookingInfo.TotalRoomCount == 0) ? 
								bookingInfo.roomAndGuestLst.size() : bookingInfo.TotalRoomCount;
			// 2013/08/16 予約名設定追加
			leadIndex.LeadName__c = bookingInfo.GuestOrGroupNameKanjiName;
			// 2013/09/10 特記事項設定追加
			leadIndex.Comment__c = bookingInfo.SpecialServiceRequest;
			
			update leadIndex;
			
			// 既存のSUBINDEXを削除を行う
			delete [select id from LeadIndex__c where ParentLeadIndxRef__c = :leadIndex.Id];
			
        } else {*/
        if(updFlag || bookingInfo.dmlAction == BI_TR_DmlAction.INS) {
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            BI_TR_MemberInfo member = bookingInfo.member;
            //leadIndex = new LeadIndex__c();
            // 2015/09/10 ADD BEGIN
            leadIndex.APPNAME__c = APPNAME;
            // 2015/09/10 ADD END
			leadIndex.DataClassification__c = bookingInfo.dmlAction.name();
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.TravelLeadNo__c = bookingInfo.TravelAgencyBookingNumber; 
            leadIndex.ID__c = bookingInfo.DataID;
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? (bookingInfo.Nights == 0 ? defaultDayUseCheckInTime : defaultCheckInTimeStr) : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
            // 2014/02/25 補足情報を追加する BEGIN
            if(member != null){
                leadIndex.MemberUserName__c = member.UserName;
                leadIndex.MemberUserKana__c = member.UserKana;
                leadIndex.MemberAddPoint__c = String.valueOf(member.UserGivinPoints);
                leadIndex.MemberUsePoint__c = String.valueOf(member.UserUsePoints);
                leadIndex.MemberUserTel__c = member.UserTel;    // 会員電話番号 
                leadIndex.MemberUserMailAddr__c = member.UserMailAddr;  // 会員Email 
                leadIndex.MemberUserZip__c = member.UserZip;    // 会員郵便番号 
                //leadIndex.MemberUserAddr__c = member.UserAddr;  // 会員住所 
                leadIndex.MemberUserAddr__c = CommUtils.nullToBlank(member.UserAddr).length() > 255 ? member.UserAddr.subString(0,255) : member.UserAddr;
                leadIndex.MemberUserCorp__c = member.UserCorp;  // 会員会社 
                leadIndex.MemberUserDep__c = member.UserDep;    // 会員所属部署 
                leadIndex.MemberUserID__c = member.UserID;  // 会員番号 
            }
            leadIndex.TotalAccommodationCharge__c = String.valueOf(bookingInfo.TotalAccommodationCharge);
            leadIndex.Payment__c = getLocalPaymentInfo(bookingInfo.Payment);
            // 2014/02/25 補足情報を追加する END
            // チェックアウト時間はDefault値設定を行う
			leadIndex.DepartureTime__c = (	bookingInfo.CheckOutTime == null
																	? (bookingInfo.Nights == 0 
                                                                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
																	//	? (DateTime.newInstance(Date.today(), CommUtils.stringToTime(leadIndex.EntryTime__c).addHours(CommConst.DEF_DAYUSE_STAY_HOURS))).format('HH:mm')
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
				
            //leadIndex.Channel__c = TraveCompany.size() > 0 ? TraveCompany[0].Name : null;
            leadIndex.Channel__c = getChanelStr(bookingInfo,TraveCompany);
		
			// 2013/08/16 予約名設定追加
			// 2016/10/21 TR変更機能改善対応[予約変更の場合、予約名を上書きしない対応] BEGIN
            if (updFlgIsInsert || bookingInfo.dmlAction == BI_TR_DmlAction.INS)
            // 2016/10/21 TR変更機能改善対応[予約変更の場合、予約名を上書きしない対応] END
			leadIndex.LeadName__c = CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName) ? bookingInfo.GuestOrGroupNameSingleByte : bookingInfo.GuestOrGroupNameKanjiName;
			// 2014/09/29 仮ユーザーを自動作成する場合
			if (CommUtils.isBlank(leadIndex.LeadName__c)) leadIndex.LeadName__c = CommUtils.nullToBlank(pkuser.lastName) + ' ' + CommUtils.nullToBlank(pkuser.FirstName);
			// 2013/09/10 特記事項設定追加
			// 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
            //leadIndex.Comment__c = bookingInfo.SpecialServiceRequest;
            leadIndex.Comment__c = CommLogUtils.removeOverLogString(bookingInfo.SpecialServiceRequest, indexCommentLength);
            // 2017/09/01 最大文字数をこえない問題回避対応 END
			leadIndex.TravelAgencyBookingInsDateTime__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime !=null?bookingInfo.TravelAgencyBookingTime: Time.newInstance(0,0,0,0));
			upsert leadIndex;
        }
        System.debug(LoggingLevel.INFO, '-------- upsertLeadIndex end ------');
        return leadIndex;
    }
    /**
    * プラン情報を設定する
    **/
    private static Plan__c upsertPlan(BI_TR_SyncInfo bookingInfo, List<Account> TraveCompany) {
		System.debug(LoggingLevel.INFO,'----------------upsertPlan BEGIN---------------');
		// プランのPackageCode/プラン名は両方とも存在する場合、処理対象です
		if (  CommUtils.isBlank(bookingInfo.PackagePlanName) &&
		      CommUtils.isBlank(bookingInfo.PackagePlanCode)) { return null; }
		// 同じプラン名情報を検索する
		Plan__c rsPlan = null;
		List<Plan__c> existPlanLst = null;
		// プラン名が存在する場合とプランコード
		/* 2014/06/06 プラン検索方式変更
		if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
			existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
		}*/
		String packageCode = CommUtils.nullToBlank(bookingInfo.PackagePlanCode);
		//String packageName = CommUtils.nullToBlank(bookingInfo.PackagePlanName);
		String packageName = formatPlanName(bookingInfo.PackagePlanName);
		//if (packageName.length() > 80)	packageName = packageName.subString(0,80);
		
System.debug(LoggingLevel.INFO,'packageCode:' + packageCode);
System.debug(LoggingLevel.INFO,'packageName:' + packageName);
		// 2016/07/01 予約チャネル名の設定内容変更対応
		//String agtId = TraveCompany.Id;
		//String agtId = !TraveCompany.isEmpty() ? TraveCompany[0].Id : null;
		String agtId = TraveCompany.size() > 0 ? TraveCompany[0].Id : null;
		//boolean chanelFromCompany = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).chanelFromCompany;
		//if (!chanelFromCompany && TraveCompany.size() > 1) agtId = TraveCompany[1].Id;
		//String shopCode = bookingInfo.AccommodationCode;
		String shopCode = shopCd;
		// 2016/06/20 EDIT BEGIN
		// パッケージコードが存在する場合、パッケージからSFのプラン変換ルールをチエックする
        if (!CommUtils.isBlank(packageCode)) {
            //String planNo = BI_TR_ServiceConfigHelp.getSfPlanNoByAgtPlanInfo(shopCd,bookingInfo.SalesOfficeCompanyName,packageCode);
            String planNo = BI_TR_ServiceConfigHelp.getSfPlanNoByAgtPlanInfo(shopCd,bookingInfo.SalesOfficeCompanyCode,packageCode);
            // 該当パッケージコードからSF側のプランNOが設定されている場合
            if(planNo != null){
                System.debug(LoggingLevel.INFO,'AGTパッケージコード「'+packageCode+'」からPlanNo「'+planNo+'」に変換済');
                // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
                //List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                List<Plan__c> planLst = [select Id, name,PlanNo__c,ShopInfoRef__c,client__c,Price__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c from Plan__c where IsClosed__c != true and PlanNo__c = :planNo limit 1];
                // 2020/07/30 入湯税の自動入力機能について改善 ZH NED
                if(!planLst.isEmpty()) return planLst[0];
            }
        }
		// 2016/06/20 EDIT END
		// 店舗情報格納する
		Map<String, ShopInformation__c> shopInfoMap = new Map<String, ShopInformation__c>(); 
		/* 2014.11.18 プラン検索ロジック変更、店舗検索機能を追加 */
		// 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
		//String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c from Plan__c ';
		String queryHeader = ' select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,Price__c,BathTaxAccMstRef__c from Plan__c ';
		// 2020/07/30 入湯税の自動入力機能について改善 ZH NED
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
				if (!CommUtils.isBlank(packageCode)) { whereStr += ' Or '; }
				whereStr += ' name = :packageName ';
			}
		}
		whereStr += ')';
		String whereStr2 = '';
		if (!CommUtils.isBlank(agtId)) {
			// AGT情報がXMLに設定されている場合、AGT条件に入れて、検索を行う
			whereStr2 = ' And client__c = :agtId ';
System.debug(loggingLevel.info, 'SQL1::' + queryHeader + whereStr + whereStr2 + queryLimit);
			existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
		}
		if (existPlanLst.isEmpty()) {
			existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
		}
System.debug(loggingLevel.info, 'SQL2::' + queryHeader + whereStr + whereStr2 + queryLimit);
		/*
		if (!CommUtils.isBlank(bookingInfo.PackagePlanCode)) {
			whereStr += ' PackageCode__c = :packageCode ';
		}
		if (!CommUtils.isBlank(bookingInfo.PackagePlanName)) {
			if (!CommUtils.isBlank(bookingInfo.PackagePlanCode)) { whereStr += ' Or '; }
			whereStr += ' name = :packageName ';
		}
		whereStr += ')';
		String whereStr2 = '';
		if (!CommUtils.isBlank(agtId)) {
			whereStr2 = ' And client__c = :agtId ';
		}
		String queryHeader = ' select Id, name from Plan__c ';
		String queryLimit = ' limit 1 ';
		existPlanLst = DataBase.query(queryHeader + whereStr + whereStr2 + queryLimit);
		if (existPlanLst.isEmpty()) {
			existPlanLst = DataBase.query(queryHeader + whereStr + queryLimit);
		}*/

		// Plan非存在する場合：新規作成
		if (existPlanLst == null || existPlanLst.isEmpty()) {
			rsPlan = new Plan__c();
			// 2014/12/12 プラン所属支店情報を設定
			rsPlan.ShopInfoRef__c = shopInfoMap.containsKey(shopCode) ? shopInfoMap.get(shopCode).Id : null;
			//rsPlan.name = bookingInfo.PackagePlanName.length() > 80 ? bookingInfo.PackagePlanName.subString(0,80) : bookingInfo.PackagePlanName;
			rsPlan.name = packageName.length() > 80 ?packageName.subString(0,80) : packageName;
			rsPlan.PackageCode__c = packageCode;
			//rsPlan.client__c = (TraveCompany == null ? null : TraveCompany.Id) ;
			// 2016/07/01 予約チャネル名の設定内容変更対応
			rsPlan.client__c = agtId;
            rsPlan.JmstRef__c = taxRateMst.Id;
            // 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            if(!isPlanOfShopFlg && shopInfoMap.isEmpty()) shopInfoMap = ShopInfoUtil.getShopInfoMap();
            // 设定有效的关联入汤税商品ID
            rsPlan.BathTaxAccMstRef__c = CommLogicProcess.getBathTaxAccMstRef(shopInfoMap.get(shopCode), shopCode);
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
			insert rsPlan;
			// 2016/06/20 EDIT BEGIN
			// 新規作成のプラン情報を再取得する
			// 2020/07/30 入湯税の自動入力機能について改善 ZH BEGIN
            //rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c  from Plan__c where id = :rsPlan.id];
            rsPlan = [select Id, name,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,BathTaxAccMstRef__c  from Plan__c where id = :rsPlan.id];
            // 2020/07/30 入湯税の自動入力機能について改善 ZH END
            // 2016/06/20 EDIT END
		}  else {
			rsPlan = existPlanLst[0];
		}
		System.debug(LoggingLevel.INFO,'----------------upsertPlan END---------------');
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
    	System.debug(LoggingLevel.INFO,'プラン明細取得::::::::::::::::' + queryStr);
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
System.debug(LoggingLevel.INFO,'プラン明細取得件数:' + orgPdList.size());
    	// 2019/09/15 軽減税率機能対応 WGCH BEGIN
    	// gPlanDetailInf.init(orgPdList);
    	gPlanDetailInf.init(orgPdList, plan);
    	// 2019/09/15 軽減税率機能対応 WGCH END
    }
    
	public class PlanDetailInfo {
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
		//, BI_TR_ServiceConfigHelp.BOOKINGCONFIG bookingConfig
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
    private static map<string, AccountMaster__c> childPlanAccMstMap = new map<string, AccountMaster__c>();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    private static map<string, AccountMaster__c> childPlanPriceAccMstMap = new map<string, AccountMaster__c>();
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
    private static map<String,String> childPlanNameConvertMap = new map<String,String>();
    // 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
    // 商品コードー＞プラン
    private static map<string, Plan__c> childPlanPlanMstMap = new map<string, Plan__c>();
    // 商品コードー＞プラン明細
    private static map<string, planDetailInfo> childPlanDetailMap = new map<string, planDetailInfo>();
    // childPlanConfigMap:Rate -> PlanNo
    // 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
    //private static void setChildPlanInfo(map<string, string> childPlanConfigMap) {
    private static void setChildPlanInfo(map<string, string> childPlanConfigMap, map<string, string> ChildPlanPriceConfigMap) {
    	//if (childPlanConfigMap == null || childPlanConfigMap.isEmpty()) return;
    	if (childPlanConfigMap.isEmpty() && ChildPlanPriceConfigMap.isEmpty()) return;
    	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
    	System.debug(LoggingLevel.INFO,'-------setChildPlanInfo  BEGIN-----------');
    	// プラン関連情報を取得する
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
System.debug(LoggingLevel.INFO,'子供プラン会計商品:::::::::::::' + childPlanAccMstMap);
System.debug(LoggingLevel.INFO,'子供プラン詳細::::::::::::::::' + childPlanDetailMap);
    }
    
    // お子様プラン自動設定
	private static void matchChildrenPlan(BookingEstimateItem__c item, Decimal perPaxRate) {
		Decimal childrenPrice = item.UnitPrice__c;
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh BEGIN
		String strChildPrice = CommUtils.deleteRightZero(CommUtils.nullToBlank(childrenPrice));
		// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
		// 2019/01/02 (無料)小人0円が小人プランに紐付できるように改善対応 WSQ BEGIN
		//if (childrenPrice <= 0 || perPaxRate <= 0) return;
		if (perPaxRate <= 0) return;
		// 2019/01/02 (無料)小人0円が小人プランに紐付できるように改善対応 WSQ END
		// パーセント計算する:子供一人料金/大人一人料金
		Decimal calRate = childrenPrice / perPaxRate * 100;
		String strCalRate = CommUtils.deleteRightZero(CommUtils.nullToBlank(calRate));
System.debug(LoggingLevel.INFO,'子供一人料金のパーセント::::::::::::' + strCalRate);
		// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
		String key1 = BI_TR_ServiceConfigHelp.getChildRateMatchKey(strCalRate);
		String key2 = BI_TR_ServiceConfigHelp.getChildPriceMatchKey(strChildPrice);
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
    private static void upsertLead(BI_TR_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, List<Account> TraveCompany, String shopCode,List<Lead__c> oldLeadLst) {
         System.debug(LoggingLevel.INFO, '-------- 予約情報を登録 begin ------');
         /*// 予約キャンセル　と　更新場合:　既存予約データを全部キャンセルする
        if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
            // 既存予約データをキャンセルする
            List<Lead__c> existLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexRef__c = :leadIndex.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
            for (Lead__c lead : existLeadLst) {
                lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                //キャンセル対応(外部インタネットから自動連携)
                lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' '+ Label.CONST_038_0035;
            }
            update existLeadLst;
        }
        // キャンセル場合、処理中止
        if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) return;*/
		
		// 部屋自動割り振り機能
        boolean autoAssingRoomflag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).roomAutoAssignFlag; 
System.debug(LoggingLevel.INFO,'--------autoAssingRoomflag---------' + autoAssingRoomflag);
        // 税区分設定
        // 税区分変換を行う
		Integer taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB;
		// XMLの税区分設定情報を取得,SF側の税区分に変換を行う
		String taxServiceFee = bookingInfo.TaxServiceFee;
System.debug(LoggingLevel.INFO,'--------税区分------------' + taxServiceFee);
		if(taxServiceFee == 'IncludingServiceWithOutTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP4;
		}else if(taxServiceFee == 'IncludingServiceAndTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP2;
		}else if(taxServiceFee == 'WithoutServiceAndTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP3;
		}else if(taxServiceFee == 'WithoutServiceAndIncludingTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP1;
		}
		
	  	String tax = String.valueOf(taxRateKbn);
        Integer taxSericeFee = CommUtils.nullToIntZero(tax);
        // 2019/09/15 軽減税率機能対応 WGCH BEGIN
        taxSericeFeeEnd = taxSericeFee;
        // 2019/09/15 軽減税率機能対応 WGCH END
		// 2016/06/17 取り込みの税サ区分はSFDC側の単価定義区分を参照する対応 BEGIN
        boolean isSFTaxServiceKbn = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).isSFTaxServiceKbn;
        if (isSFTaxServiceKbn) {
            taxSericeFee = CommConst.APPOPTION_UTP_DEF_KB;
System.debug(LoggingLevel.INFO,'税区分はSFDC側の単価定義区分に参照する['+taxSericeFee+']');
        }
        // 2016/06/17 取り込みの税サ区分はSFDC側の単価定義区分を参照する対応 END
	// 消費税情報を取得する   
        taxRateMst = CommLogicProcess.getTaxRateInfo();
        //  プラン情報を取得、作成する
        // プラン情報がNULLの場合、見積明細に直接室料を設定する
        Plan__c curPlan = upsertPlan(bookingInfo, TraveCompany);
        // プラン明細情報を取得する
        setPlanDetailPlusInfo(curPlan);
        System.debug(LoggingLevel.INFO,'プラン情報::' + curPlan);
		String emailMsg = mailArea(bookingInfo);
        // 部屋タイプID情報を取得する
        Set<String> roomTypeCdSet = new Set<String>();
		// 2013/02/26 部屋タイプ名情報を格納する
		Set<String> roomTypeNmSet = new Set<String>();
		
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
            //roomTypeMap.put(roomAndGuest.room.RoomTypeCode);
            // 2013/02/26 部屋タイプ名：部屋ID情報を格納する
			if (!CommUtils.isBlank(roomAndGuest.room.RoomTypeName)) roomTypeNmSet.add(roomAndGuest.room.RoomTypeName);
        }
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
		// 2013/02/26 部屋タイプ名情報を格納する
		Map<String,Id> roomTypeNmMap = new Map<String, Id>();
        
		Map<Id, id> oneTypeToRoomMap = new Map<Id, Id>();
		// 部屋タイプリスト取得する
		// UPDATE 2015/09/15　店舗区分 :新追加 ShopInfoRef__c
        for (TypeOfRooms__c roomType: [select id, RoomTypeName__c, RoomTypeCode__c,(Select Id From TypeRoomRef__r limit 2) from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c = :shopCode and  (RoomTypeCode__c in :roomTypeCdSet Or RoomTypeName__c in :roomTypeNmSet)]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
			// 2013/02/26 部屋タイプ名：部屋ID情報を格納する
			if (!CommUtils.isBlank(roomType.RoomTypeName__c)) roomTypeNmMap.put(roomType.RoomTypeName__c, roomType.Id);
        //}
	        System.debug(LoggingLevel.INFO,'roomTypeMap :: ' + roomTypeMap.keySet());
			System.debug(LoggingLevel.INFO,'roomTypeNmMap :: ' + roomTypeNmMap);
	        // 2015/07/22  部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
	        
	        // 自動割り当てフラグはTRUEのみ、該当関連取得を行う
			if (oneRoomAutoAssingRoomFlg) {
				if (roomType.TypeRoomRef__r != null && roomType.TypeRoomRef__r.size() == 1) {
					oneTypeToRoomMap.put( roomType.Id, roomType.TypeRoomRef__r[0].Id );
	            }
			}
        }
        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
        map<Integer, Room__c> oneRoomCanAssignRoomMap = new map<Integer, Room__c>();
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
        /*
		// 部屋タイプが存在する場合
        if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        }
        */
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
		// 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
		// 部屋タイプにより、自動割り振りできる部屋情報を戻る
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
        //map<Id, List<Room__c>> canAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer, Room__c> canAssignRoomMap = new map<Integer, Room__c>();
        if (autoAssingRoomflag) {
            canAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,autoAssingRoomflag,bookingInfo);
        } 
        // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 BEGIN
		// 部屋タイプが存在する場合
        else if (!oneTypeToRoomMap.isEmpty()) {
        	// 割当できる部屋情報を取得する　
        	oneRoomCanAssignRoomMap = getCanAssignRoom(leadIndex,roomTypeMap,oneRoomAutoAssingRoomFlg,bookingInfo);
        }
		// 2017/01/23 部屋自動割り当て機能、翌日にご予約情報が存在すると、該当日のご予約に部屋自動割り当てできない不具合改修 END
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
        // 親部屋識別要フラグ
        String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
        Integer nights = bookingInfo.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
        // 予約名
        String leadName = leadIndex.LeadName__c;
        // Loop Index
        Integer roomNoIdx = 0;
        // 複数件予約データを作成する
        List<Lead__c> insLeadLst = new List<Lead__c>();
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        //for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
		// 2016/06/20 EDIT BEGIN
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
        	//setChildPlanInfo(BI_TR_ServiceConfigHelp.getChildPlanConvertConfig(shopCd));
        	setChildPlanInfo(BI_TR_ServiceConfigHelp.getChildPlanConvertConfig(shopCd),BI_TR_ServiceConfigHelp.getChildPlanPriceConvertConfig(shopCd));
        	// 2017/02/21 お子様プランの料金PRICE機能追加 by zh END
        	// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ BEGIN
        	// プラン設定情報を取得する
        	childPlanNameConvertMap = BI_TR_ServiceConfigHelp.getChildPlanNameConvertConfig(shopCd);
        	// 2019/07/19 子供プランへの置き換え設定を行わず、入ってきたプラン名を見積明細に反映する WSQ END
        	// 2016/06/10 子供料金プラン取り込み機能対応 END
        }
        // プラン関連の会計商品が非存在する場合、室料商品を取得する
        if (commshitulyouAcc == null) {
            commshitulyouAcc = getShiTuLyouAcc();   // [室料商品定義情報を取得する]
        }
        // 見積明細に登録する会計商品
System.debug(LoggingLevel.INFO,'--------会計商品--------' +commshitulyouAcc);
        // 税区分
        
        Boolean isUpdateFlag = bookingInfo.dmlAction == BI_TR_DmlAction.UPD;
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
	            boolean plannameToEstflag = BI_TR_ServiceConfigHelp.isSfPlanNmToEstProdNm(shopCd);
System.debug(LoggingLevel.INFO,'見積明細名はプラン目に変更::::' + plannameToEstflag);
                if(plannameToEstflag){
                	cloneItem.ProductName__c = curPlan.Name;
                } else {
                	cloneItem.ProductName__c = CommUtils.isBlank(bookingInfo.PackagePlanName)
	                                        ? curPlan.Name
	                                        : formatPlanName(bookingInfo.PackagePlanName);
                }
                // 2017/06/29 AGTパッケージコードと、SF側プランの紐付けを行い取込んだ予約の見積明細の表示名がSF側のプラン名に表示できるように改善対応 by zh END
	            cloneItem.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
	        }
   		}

		if(bookingInfo.TravelAgencyBookingTime == null) bookingInfo.TravelAgencyBookingTime = Time.newInstance(0,0,0,0);
        Map<Integer,List<BookingEstimateItem__c>> roomMaps = new Map<Integer,List<BookingEstimateItem__c>>();
        Map<String,Object> autoSetupfieldMap = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).fieldMap;
        Map<String, Schema.DescribeFieldResult> finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),autoSetupfieldMap.keySet());
        // 料金区分:部屋単価・人員単価
        boolean isRoomRateFlg = bookingInfo.RoomRateOrPersonalRate == 'PersonalRate' ? false : true;
		System.debug(LoggingLevel.INFO,'予約情報新規、変更処理開始');
        // 既存予約情報を格納する
        // map<部屋単位,該当部屋関連の予約情報>
        Map<Integer,List<Lead__c>> groupLeadMap = new Map<Integer,List<Lead__c>>();
        Lead__c beforeLead = null;
        integer roomIndex = 0;
        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
        Boolean isCanModifyPeoples = true;
        Integer orgMaxNights = 0;
        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
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
            // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
            // 最大泊数計算を取得する
            if (orgMaxNights < groupLeadMap.get(roomIndex).size()) orgMaxNights = groupLeadMap.get(roomIndex).size();
            // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
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
        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
        // map<index, 人数変更可否フラグ>
        map<Id,boolean> isCanModifyPeoplesMap = new map<Id, boolean>();
        map<Integer,boolean> unionIsCanModifyPeoplesMap = new map<Integer, boolean>();
        if (fieldChgHisMap != null && !fieldChgHisMap.isEmpty()) {
        	Integer rooms = groupLeadMap.keyset().size();
        	// 集める場合、泊単位で人数変更可否を判断する、分割の場合、部屋、泊目単位（予約単位）で人数変更可否
        	if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
        		// 各泊目の予約情報情報をチェック
        		for(Integer i = 0; i < orgMaxNights; i++) {
        			// 該当泊目の人数変更可否識別フラグ、TRUE：変更可能
        			Boolean wkIsCanModifyPeopleFlg = true;
        			// 該当泊目のすべて部屋の人数変更あり、なし判断する
	        		for(Integer j = 0; j < rooms; j ++){
	        			// 該当部屋が既存データに存在する場合
	                    if(!groupLeadMap.containsKey(j)) continue;
                    	// 該当泊目の部屋に人数変更履歴存在場合
                    	if (wkIsCanModifyPeopleFlg != true) break;
                    	// 該当部屋に既存の予約リスト
                        List<Lead__c> oLeadLst = groupLeadMap.get(j);
                        // 該当泊目に予約情報が非存在場合、次の部屋を処理を行う
                        if (oLeadLst.size() <= i) continue;
                        // 該当部屋の該当泊目の予約のIDを取得する
                        Id wkCheckLeadId = oLeadLst[i].Id;
                        // 該当部屋の該当泊目の予約が変更履歴が存在する場合
                        if (fieldChgHisMap.containsKey(wkCheckLeadId)) {
                        	// 該当予約の変更履歴存在チェック
                        	set<String> locChgfieldSet = fieldChgHisMap.get(wkCheckLeadId);
		                	wkIsCanModifyPeopleFlg = (
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'StayPersons__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Mans__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Femails__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildFA__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Childs__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildC__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildD__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildE__c') &&
		            	       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildF__c') &&
		            	       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildOther__c'));
                        }
	        		}// for(Integer j = 0; j < rooms; j ++){
	        		unionIsCanModifyPeoplesMap.put(i, wkIsCanModifyPeopleFlg);
        		} // for(Integer i = 0; i < orgMaxNights; i++) {
        	}//if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
        	else {
        		for(Integer j = 0; j < rooms; j ++){
        			if(!groupLeadMap.containsKey(j)) continue;
    				// 該当部屋の各泊目の予約
    				List<Lead__c> oLeadLst = groupLeadMap.get(j);
    				integer staysNums = oLeadLst.size();
    				for(Integer i = 0; i < staysNums; i ++){
    					// 該当泊目の人数変更可否識別フラグ、TRUE：変更可能
    					Boolean wkIsCanModifyPeopleFlg = true;
        				// データ取得INDEX
            			Integer idx = j * staysNums + i;
                        Id wkCheckLeadId = oLeadLst[i].Id;
                        // 該当部屋の該当泊目の予約が変更履歴が存在する場合
                        if (fieldChgHisMap.containsKey(wkCheckLeadId)) {
                        	// 該当予約の変更履歴存在チェック
                        	set<String> locChgfieldSet = fieldChgHisMap.get(wkCheckLeadId);
		                	wkIsCanModifyPeopleFlg = (
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'StayPersons__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Mans__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Femails__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildFA__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'Childs__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildC__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildD__c') &&
		                       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildE__c') &&
		            	       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildF__c') &&
		            	       BI_TR_ServiceConfigHelp.isSetupVal(locChgfieldSet,'ChildOther__c'));
                        }
                        // 該当部屋、該当泊目の人数変更可否フラグを格納
                        isCanModifyPeoplesMap.put(wkCheckLeadId, wkIsCanModifyPeopleFlg);
    				}//for(Integer i = 0; i < staysNums; i ++){
        		}//for(Integer j = 0; j < rooms; j ++){
        	}
        }// if (fieldChgHisMap != null && !fieldChgHisMap.isEmpty()) {
        
        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
        Map<String,Id> lastRoomMap = new Map<String,Id>();
        Set<String> userOrgLeadSet = new Set<String>();
        Set<Id> updateOrgLeadIdSet = new Set<Id>();
        // 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
        String chanelStr = getChanelStr(bookingInfo,TraveCompany);
        // 2016/07/10 予約チャネル名の変換機能追加対応 END
		// 総部屋数
        Integer rooms = bookingInfo.roomAndGuestLst.size();
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh BEGIN
        // 支払明細はどの部屋どの泊にリンクすることINDEXを記録する
        Integer payMediaLinkPos = 0;
        if (BI_TR_ServiceConfigHelp.getAppConfig(shopCd).payMeaidToLastDayFlag) payMediaLinkPos = (nights-1);
        // 2019/04/30 取り込み場合、支払いメディアの反映を宿泊の最終日にするの対応 by zh END
        // 既存予約の見積明細を上書きするがどう切り替え用フラグ
        Boolean isClearEstItemsFlag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).modifyEstItemsFlag;
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
		for(Integer j = 0; j < rooms; j ++){
			// 部屋とお客様リスト
            BI_TR_RoomAndGuestInfo roomAndGuest = bookingInfo.roomAndGuestLst[j];
            // １部屋タイプから複数日予約データを作成する
            // 複数日から１日単位に作成する
            Integer staysNums = roomAndGuest.roomRateLst.size();
            //if (staysNums == 0) staysNums = 1;
            // 異常データ個別処理
			if (roomAndGuest.roomRateLst.isEmpty() && nights == 1) {
				staysNums = 1;
				BI_TR_RoomRateInfomation rateInfo = new BI_TR_RoomRateInfomation();
				rateInfo.RoomDate = bookingInfo.CheckInDate;
				roomAndGuest.roomRateLst.add(rateInfo);
			}
            // 日付単位情報
            for(Integer i = 0; i < staysNums; i ++){
            	// データ取得INDEX
                Integer idx = j * staysNums + i;
            
                //　到着日
                Date checkInDate = roomAndGuest.roomRateLst[i].RoomDate;
                // 新規予約データ作成
                Lead__c newLead = new Lead__c();
                // 2016/10/21 TR変更機能改善対応、項目値自動設定不具合改修 BEGIN
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
                    if(describeField.isCreateable()){
                    	// デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                    	//mLogUtils.write_log('更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        //mLogUtils.write_log('項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                // 2016/10/21 TR変更機能改善対応、項目値自動設定不具合改修 END
                // 変更前の予約泊数
                Integer orgLeadNights = null;
                Lead__c orgLead = null;
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
           
                // 既存の予約情報が存在する場合
                boolean isHadLeadId = (orgLead != null);
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                set<string> chgfieldSet = new set<string>();
                if (isHadLeadId) {
                    // 該当予約の変更履歴情報を取得する
                    if (fieldChgHisMap != null && fieldChgHisMap.containsKey(orgLead.Id)) chgfieldSet = fieldChgHisMap.get(orgLead.Id);
                }
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                // お客様情報
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Relcontact__c'))
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                newLead.Relcontact__c = newLead.Relcontact__c == null ? pkuser.id : newLead.Relcontact__c;
                // 2013/07/16 記号機能対応 BEGIN
                // 親部屋マーク標識用の文字は予約名の文字列先頭に付加
                // プラン情報         
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field310__c'))
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END      
                newLead.Field310__c = curPlan == null ? null : curPlan.Id;
                // 予約名情報を格納する
                // 該当部屋該当泊目が予約存在場合
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
                	// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                	// 予約人数変更可否フラグを取得する
                	isCanModifyPeoples = true;
                	if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
                		// 集める場合、１番目部屋の泊目にフラグを取得する
                		if (unionIsCanModifyPeoplesMap.containsKey(i)) isCanModifyPeoples = unionIsCanModifyPeoplesMap.get(i);
                	} else {
                		// 分割の場合、泊目、部屋単位のフラグを取得する
                		if (isCanModifyPeoplesMap.containsKey(orgLead.Id)) isCanModifyPeoples = isCanModifyPeoplesMap.get(orgLead.Id);
                	}
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                } else {
                    newLead.name = (rooms > 1 && j == 0 ? strRoomDelegatePrefix : '');
                    // 2013/07/16 記号機能対応 END
                    // 予約データ名設定を行う
                    if (nights > 1) newLead.name += String.valueOf(nights) + '-' + (i+1) + '泊目 ' + leadName;  //bookingInfo.GuestOrGroupNameKanjiName;
                    else newLead.name += leadName; //bookingInfo.GuestOrGroupNameKanjiName;
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
	                isCanModifyPeoples = true;
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                } 
                // レコードタイプ：宿泊タイプ
                newLead.RecordTypeId = bookingRcTypeId;
                // お客様情報
                newLead.Relcontact__c = pkuser.Id;
                // 予約受付日
                // 2013/06/19 予約受付日の受付時間設定ミス、不具合修正、時間項目を設定する
                newLead.ReservedDate__c = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime );
                // 支払方法
                //newLead.Field315__c = bookingInfo.Payment;
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field315__c'))
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                newLead.Field315__c = getLocalPaymentInfo(bookingInfo.Payment);
                // 交通手段
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field348__c'))
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                newLead.Field348__c = bookingInfo.Transportaion;
                // 予約ステータス[Deafult:確認中]
                //newLead.ReservedStatus__c =
                // First Dayの場合
                if (i == 0) {
                    // チェックイン日
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    //newLead.EntryTime__c = checkInFirstDayDt;
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
					// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
					if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field4__c'))
                	// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
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
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
	                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field4__c'))
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                }
                // 最後日の場合
                if (i == nights - 1) {
                    // チェックアウト日
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                    //newLead.Departure__c = checkOutLastDayDt;
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
	                if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field3__c'))
	                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
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
                    newLead.Departure__c = DateTime.newInstance(checkOutLastDayDt.date(), CommUtils.stringToTime(newLead.Field3__c));
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                } else {
                    // チェックアウト日
                    newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field3__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
					// チェックアウト時間
					newLead.Field3__c = defaultCheckoutTimeStr;
                }
                
				// 2013/06/09 宿泊人数は未設定する場合、自動Default値を設定する
				Integer calRoomPaxCount =  CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount) + 
										   CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount) + 
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count) +
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count) +
										   CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount) +
                                           CommUtils.nullToZero(roomAndGuest.room.RoomChildOtherCount);
				String warningMsg = '';
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                Boolean stayPerponsChgFlg = (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'StayPersons__c'));
                // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				if (roomAndGuest.room.PerRoomPaxCount == null || roomAndGuest.room.PerRoomPaxCount == 0) {
					// XMLの中に、未設定する場合、自動的にSFの初期値で自動設定を行う「非設定する場合、自動設定を行う」
					if (calRoomPaxCount > 0) {
						// 1室利用人数
                        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                        if (stayPerponsChgFlg)
                        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
						newLead.StayPersons__c = calRoomPaxCount;
					} else {
						// 該当ケースする場合、注意事項に自動内容追加を行う
						//サイトコントローラからの予約データのなかに、予約人数がありませんでしたので、デフォルト値(仮の値)を設定させていただきました、つきましては、ご予約者の方へご確認していただきまして、本予約データの予約人数を手動にて変更ください。
                        // 2016/10/26 BEGIN
                        //予約人数がゼロで取り込まれましたので人数を変更してください。
						warningMsg = '<font color="red">'+ Label.MSG_043_0003 +'</font><br/>';
                        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                        if (stayPerponsChgFlg)
                        // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                        // 2016/10/24 予約人数がゼロの不具合改修 BEGIN
						newLead.StayPersons__c = 0;
						// 2016/10/24 予約人数がゼロの不具合改修 END
                        // 2016/10/26 END
					}
				} else {
					// 1室利用人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (stayPerponsChgFlg)
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
					newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
				}
				//if(roomNoIdx == 0){
             		// また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
  	 			    //String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
             		//newLead.name = (bookingInfo.roomAndGuestLst.size() > 1  ? strRoomDelegatePrefix : '') +  newLead.name;

         		// 1室利用人数
                //newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
                 // 大人人員(男性)
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.Mans__c = CommUtils.nullToZero(roomAndGuest.room.RoomPaxMaleCount);
				// 大人人員(女性) 
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.Femails__c = CommUtils.nullToZero(roomAndGuest.room.RoomPaxFemaleCount);
				// 子供A人数
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildFA__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildA70Count);
				// 子供B人数
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.Childs__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildB50Count);
				// 子供C人数
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildC__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildC30Count);
				// 子供D,E,F人数追加(2014/08/11)
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildD__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildDNoneCount);
		 		// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildE__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildE__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildECount);
		 		// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildF__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildF__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildFCount);
				// 2018/11/20 小人数取り込み不正の対応 BEGIN
		 		// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildOther__c'))
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
				newLead.ChildOther__c = CommUtils.nullToZero(roomAndGuest.room.RoomChildOtherCount);
				// 2018/11/20 小人数取り込み不正の対応 END
				// プラン情報
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
				//字段定义写重了、上面有定义
				//newLead.Field310__c = curPlan == null ? null : curPlan.Id;
				// 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
         	   	//newLead.Comment3__c = bookingInfo.OtherServiceInformation;
         	   	//String roomSpecialRequest = CommUtils.isBlank(roomAndGuest.room.RoomSpecialRequest) ? '' : roomAndGuest.room.RoomSpecialRequest + '</br>';
         	    // 特記事項設定
       	       	//newLead.Comment3__c = roomSpecialRequest + warningMsg + (CommUtils.isBlank(roomSpecialRequest) ? '' : '\n') +bookingInfo.SpecialServiceRequest;
           	    // 2013/09/16 料理補足
           	    newLead.Field354__c = bookingInfo.MealCondition;
           	    //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                newLead.BookingDataID__c = bookingDataId;
                // プラン自動展開対象外フラグ設定
                newLead.PlanSycnFlag__c = newLead.PlanSycnFlag__c == null ? true : !newLead.PlanSycnFlag__c;
                // 2016/12/31 特記事項設定 FIX BEGIN by zh
                String roomSpecialRequest = CommUtils.isBlank(roomAndGuest.room.RoomSpecialRequest) ? '' : roomAndGuest.room.RoomSpecialRequest + '</br>';
                // 2016/12/31 特記事項設定 FIX END by zh
                if(isHadLeadId){
                	// 2016/12/31 特記事項設定 FIX BEGIN by zh
                    //String commentMessage = newLead.Comment3__c + '<br/>' + warningMsg + CommUtils.nullToBlank(bookingInfo.OtherServiceInformation);
                    //newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
                    String commentMessage = newLead.Comment3__c + '<br/>' + roomSpecialRequest + warningMsg + (CommUtils.isBlank(roomSpecialRequest) ? '' : '\n') +bookingInfo.SpecialServiceRequest;
	       	       	newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
                    // 2016/12/31 特記事項設定 FIX END by zh
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
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Field2__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                   	if(CommUtils.isBlank(newLead.Field2__c)) newLead.Field2__c = chanelStr;
        			// 2016/07/10 予約チャネル名の変換機能追加対応 END
                    // 2016/01/28 ネットからの取込時に予約チャネルに旅行会社名で設定する END
                }else{
                	 // 2016/12/31 特記事項設定 FIX BEGIN by zh
                     //newLead.Comment3__c = warningMsg + CommUtils.nullToBlank(bookingInfo.OtherServiceInformation);
	       	       	 String commentMessage = roomSpecialRequest + warningMsg + (CommUtils.isBlank(roomSpecialRequest) ? '' : '\n') +bookingInfo.SpecialServiceRequest;
	       	       	 newLead.Comment3__c = CommLogUtils.removeOverLogString(commentMessage,commentLength);
                     // 2016/12/31 特記事項設定 FIX END by zh
                     //newLead.email__c = risaplBasic.TelegramData;
                     // 2017/09/01 最大文字数をこえない問題回避対応 BEGIN
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
                
                // 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
				// 2013/02/26 部屋タイプ名：部屋ID情報を格納する
				if (newLead.refTypeOfRooms__c == null ) newLead.refTypeOfRooms__c = roomTypeNmMap.get(roomAndGuest.room.RoomTypeName);
                // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
                boolean chgRoomTypeFlag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).chgRoomTypeFlag;
                // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                // 部屋タイプを自動されている場合                
                if (newLead.refTypeOfRooms__c != null){
                    if(isHadLeadId){
                    	// 2016/10/21 TR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ BEGIN
							//if(chgdtRoomClearFlag) newLead.Rroom__c = null;
							if(chgdtRoomClearFlag) {
								newLead.Rroom__c = null;
								newLead.Field276__c = false;
							}
							// 2020/10/19 部屋変更不可がTrueでも部屋タイプコードを変更できるように改善 WSQ END
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh END
						}
						// 2016/10/21 TR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
                        // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh BEGIN
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
                                // 既存予約の部屋と部屋タイプ定義不一致の場合、ご予約の部屋タイプは部屋により訂正する
                                if (errRoomToTypeIdMap.containsKey(newLead.Rroom__c)) newLead.refTypeOfRooms__c = errRoomToTypeIdMap.get(newLead.Rroom__c);
                                // 2018/12/30 部屋/部屋タイプ不正の場合、部屋と部屋タイプを再設定の改善対応 WSQ END
                            }
                        }
                        // 2018/12/30 TR予約変更通知の際に、部屋タイプを自動変更できるように改善対応 by zh END
                    }
                	if (newLead.Rroom__c == null) {
                        // 部屋自動割り振り機能
                        if (autoAssingRoomflag) {
                        	// 2015/10/30 故障部屋は自動割当て機能に追加対応 BEGIN
                            // 部屋割当可能の場合
                            if (canAssignRoomMap.containsKey(j)) {
                                newLead.Rroom__c = canAssignRoomMap.get(j).Id;
                                System.debug(LoggingLevel.INFO,'複数部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
                            }
                            // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
                        }
                        // 1部屋自動アサイン機能
                        // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする BEGIN
                        // 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 BEGIN
                        //else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c)) {
                        else if (oneTypeToRoomMap.containsKey(newLead.refTypeOfRooms__c) && oneRoomCanAssignRoomMap.containsKey(j)) {
                    	// 2016/10/26 部屋タイプと部屋が1対1の場合は故障部屋を割当される不具合改修 END
                            newLead.Rroom__c = oneTypeToRoomMap.get(newLead.refTypeOfRooms__c);
                            System.debug(LoggingLevel.INFO,'1VS1部屋自動割り当て部屋 :: ' + newLead.Rroom__c);
//System.debug(LoggingLevel.INFO,'----------------部屋自動割当【ONE　VS　ONE】================='+newLead.Rroom__c);
                        }
                //System.debug(LoggingLevel.INFO,'----------------部屋自動割当【ONE　VS　ONE】================='+newLead.Rroom__c);
                    }
//System.debug(LoggingLevel.INFO,'----------------部屋タイプ5=================');
                        // 部屋タイプが存在　かつ　対応部屋タイプに対して、１部屋のみの場合、該当部屋は自動的に予約にアサインする END
                }
                // 2016/10/21 TR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] BEGIN
				else {
					if(isHadLeadId){
						if (orgLead.EntryTime__c.date() != newLead.EntryTime__c.date()) {
							// 2017/07/06 日程変更しても、既にアサイン済みの部屋情報をクリアする・しない制御できるように対応 by zh BEGIN
							//newLead.Rroom__c = null;
							boolean chgdtRoomClearFlag = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).chgdtRoomClearFlag;
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
				// 2016/10/21 TR変更機能改善対応[到着日を変更すると、既に割当される部屋をクリアする] END
					// 旧予約情報を更新する場合、見積明細は変更対象外
	                // 新規予約のみ、見積明細を作成する
	                if (!isHadLeadId) {
	                    //見積もり明細取得
	                    // 該当泊の明細情報のみ、送付する
	                    Date ciDate = bookingInfo.CheckInDate.adddays(i);
	                    roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan,ciDate));
	                } else {
	                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
	                	Date ciDate = bookingInfo.CheckInDate.adddays(i);
	                	if (isClearEstItemsFlag) roomMaps.put(idx,setEachRoomBookingEstimeteItems(cloneItem,roomAndGuest,taxSericeFee,isRoomRateFlg,curPlan,ciDate));
	                	else
	                	// 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
	                    roomMaps.put(idx, new List<BookingEstimateItem__c>());
	                }
	                // 1番目部屋以外　かつ　集める場合
                if (j > 0 && CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION){
                	// １番名の部屋のX泊の予約情報に人数更新
                    Integer roomIdx = i;
					// 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 BEGIN
                    //insLeadLst[roomIdx].StayPersons__c += CommUtils.nullToZero(newLead.StayPersons__c);
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (stayPerponsChgFlg)
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END   
                    insLeadLst[roomIdx].StayPersons__c = CommUtils.nullToZero(insLeadLst[roomIdx].StayPersons__c) + CommUtils.nullToZero(newLead.StayPersons__c); 
                    // 新規　かつ　WARNメッセージ存在　かつ　次の部屋の人数が存在する場合 かつ　部屋情報が集める場合
                    if (CommUtils.nullToZero(newLead.StayPersons__c) > 0 
                    	&& bookingInfo.dmlAction == BI_TR_DmlAction.INS 
                    	&& CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).contains(Label.MSG_038_0008)) {
                    	insLeadLst[roomIdx].comment3__c = CommUtils.nullToBlank(insLeadLst[roomIdx].comment3__c).replace(Label.MSG_038_0008, '');
                    }
                    // 2016/08/31 不具合修正、親部屋の人数は０の場合、人数正常な合計できない不具合修正 END
                    if (roomMaps.containsKey(idx)) {
						// １番名の部屋の予約の見積明細に、当前の見積明細情報をコピーする
                    	roomMaps.get(roomIdx).addAll(roomMaps.get(idx));
                    	roomMaps.remove(idx);
                    }
                    // 代表部屋以外のデータ
                    newLead.StayPersons__c = 0;
                    // 大人人員(男性)
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Mans__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].Mans__c += CommUtils.nullToZero(newLead.Mans__c); 
                    newLead.Mans__c = 0;
                    // 大人人員(女性)
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Femails__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].Femails__c += CommUtils.nullToZero(newLead.Femails__c); 
                    newLead.Femails__c = 0;
                    // 子供A人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildFA__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildFA__c += CommUtils.nullToZero(newLead.ChildFA__c); 
                    newLead.ChildFA__c = 0;
                    // 子供B人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'Childs__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].Childs__c += CommUtils.nullToZero(newLead.Childs__c); 
                    newLead.Childs__c = 0;
                    // 子供C人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildC__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildC__c += CommUtils.nullToZero(newLead.ChildC__c); 
                    newLead.ChildC__c = 0;
                    // 子供D人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildD__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildD__c += CommUtils.nullToZero(newLead.ChildD__c); 
                    newLead.ChildD__c = 0;
                    // 子供E人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildE__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildE__c += CommUtils.nullToZero(newLead.ChildE__c); 
                    newLead.ChildE__c = 0;
                    // 2018/11/20 小人数取り込み不正の対応 BEGIN
					// 子供F人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildF__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildF__c += CommUtils.nullToZero(newLead.ChildF__c); 
                    newLead.ChildF__c = 0;
					// 子供その他人数
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh BEGIN
                    if (isCanModifyPeoples && BI_TR_ServiceConfigHelp.isSetupVal(chgfieldSet,'ChildOther__c'))
                    // 2018/12/15 ネット取り込み、予約変更機能改善 by zh END
                    insLeadLst[roomIdx].ChildOther__c += CommUtils.nullToZero(newLead.ChildOther__c); 
                    newLead.ChildOther__c = 0;
					// 2018/11/20 小人数取り込み不正の対応 END
                    // プラン情報 <- NULL
                    newLead.Field310__c = null;
                    // コメント
                    newLead.Comment3__c = null;
                }
                // 食事条件
//                newLead.MealCondition__c = bookingInfo.MealCondition;
                // 旅行会社関連参照情報設定
                //newLead.SalesOfficeInfoRef__c = (TraveCompany == null ? null : TraveCompany.Id) ;
                newLead.SalesOfficeInfoRef__c = TraveCompany.size() > 1 ? TraveCompany[1].Id : (TraveCompany.size() > 0 ? TraveCompany[0].Id : null);
				// 2012/12/23  Add
                newLead.RoomGroupNo__c = j;//roomNoIdx;
				// 2013/09/25 ADD 旅行会社名から予約チャネルに設定する
//newLead.Field2__c = (TraveCompany == null ? null : TraveCompany.Name);
                newLead.EventSource__c = APPNAME + '_' + bookingInfo.DataID + '_' + DateTime.now().getTime();
                // 2015/10/30 故障部屋は自動割当て機能に追加対応 END
        // 単価定義区分の設定する
                newLead.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
                // 2016/10/21 TR変更機能改善対応、項目値自動設定不具合改修 BEGIN
                /*
                for(String fieldName : finalFieldMap.keySet()){
                    Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
System.debug(LoggingLevel.INFO,'更新内容[' + fieldName + ']::' + describeField.isCreateable() );
System.debug(LoggingLevel.INFO,'更新内容[' + fieldName + ']::' + newLead.get(fieldName));
                    if(newLead.get(fieldName) == null && describeField.isCreateable()){
                        // デイフォル値を自動設定を行う
                        newLead.put(fieldName,CommUtils.ConvByFielType(autoSetupfieldMap.get(fieldName), describeField.getType()));
                        //System.debug(LoggingLevel.INFO,'更新内容[' + fieldName + ']:1:' + fieldMap.get(fieldName) );
                        System.debug(LoggingLevel.INFO,'項目値自動設定[' + fieldName + ']:1:' + newLead.get(fieldName) );
                    }
                }
                */
                // 2016/10/21 TR変更機能改善対応、項目値自動設定不具合改修 END
				// メール本文
				//newLead.email__c = emailMsg ;
                insLeadLst.add(newLead);
            }
			
			//roomNoIdx++;
        }
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;
  		List<Lead__c> updLeadLst = new List<Lead__c>();
  			// 既存の予約情報対象外のデータはキャンセルする
        for(integer key : groupLeadMap.keySet()){
            List<Lead__c> childLst = groupLeadMap.get(key);
//System.debug(LoggingLevel.INFO,'childLst:::' + childLst);
            if(childLst != null){
                for(integer i = 0 ; i < childLst.size(); i++){
System.debug(LoggingLevel.INFO,'i:::' + i);
                    String setKey = key + '_' + i;
                    if(!userOrgLeadSet.contains(setKey)){
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
        if (!updLeadLst.isEmpty()) update updLeadLst;
  		// 2012/12/22 WSQ ADD
  		// SUBINDEX自動作成
  		if (!insLeadLst.isEmpty()) {
  			// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
	  		//CommLogicProcess logic = new CommLogicProcess();
	  		// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
	  		logic.autoCreateIndexSub(insLeadLst);
	  		
	        upsert insLeadLst;
  		}
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
//System.debug(LoggingLevel.INFO,'delete:before::'+insLeadLst);
        // ご予約のプラン項目から自動作成の見積明細を全部削除する
        delete [select id,name from BookingEstimateItem__c where refBooking__c =:leadIds and ParentBookingItemRef__c = null];
        delete [select id,name from BookingEstimateItem__c where refBooking__c = :leadIds ];
        // 変更の場合、支払情報は更新を行わない
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ BEGIN
        //if (updateOrgLeadIdSet.isEmpty()) {
        if (updateOrgLeadIdSet.isEmpty() || isClearEstItemsFlag) {
        // 2019/11/13 変更通知の場合、見積明細の変更を反映できるように改善 WSQ END
        	// 2016/06/17 取り込みの見積明細の順番は調整対応 BEGIN
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
            // 2016/06/17 取り込みの見積明細の順番は調整対応 END
            //見積もり明細　オプション作成する
            //upsertBookingEstimeteItemsByEach(bookingInfo,insLeadLst[0]);
        }
        System.debug(LoggingLevel.INFO,'sync2wayEstRowNoSetup Start');
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
		System.debug(LoggingLevel.INFO,'sync2wayEstRowNoSetup End');
    }
    
    // 2016/06/20 EDIT BEGIN
	// プラン明細に室料するがどうか判断ロジック
    private static Boolean isRoomRateItem(AccountMaster__c acc) {
        return RackRateUtils.isRoomRateProduct(acc);
    }
	// 2016/07/10 予約チャネル名の変換機能追加対応 BEGIN
	private static string getChanelStr(BI_TR_SyncInfo bookingInfo, list<account> TraveCompany) {
        String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
        String chanelStr = BI_TR_ServiceConfigHelp.getMapAgtToChanelConfig(shopCd).get(agtCode);
		if (CommUtils.isBlank(chanelStr)) chanelStr = (!TraveCompany.isEmpty() ? TraveCompany[0].Name : null);
		return chanelStr;
	}
    // 2016/07/10 予約チャネル名の変換機能追加対応 END
    
    // ポイント、売掛金、カードなど事前支払情報は見積明細に反映を行う
    private static List<BookingEstimateItem__c> upsertPaymentBookingExtimeItem(Lead__c lead,BI_TR_SyncInfo bookingInfo){
        System.debug(LoggingLevel.INFO,'-----------upsertPaymentBookingExtimeItem BEGIN----------------');        
        // 合計宿泊料金(総額)
        Decimal totalPrice = bookingInfo.TotalAccommodationCharge;        
        BI_TR_MemberInfo member = bookingInfo.member;
        BillSimpleHelp help = new BillSimpleHelp(shopCd);
        // ポイント合計金額格納
        Decimal pointAmount = 0;
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        // ポイント支払情報格納する
        List<BookingEstimateItem__c> pointLst = new List<BookingEstimateItem__c>();
    
    	// 2016/06/22  
    	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
		String settlementDiv = CommUtils.nullToBlank(bookingInfo.Payment);
        String agtCode = CommUtils.nullToBlank(bookingInfo.SalesOfficeCompanyCode);
        list<string> equalKeyLst = getEqualsKeyLst(settlementDiv, agtCode);
        map<string, AccountMaster__c> payProductIdMap = new map<String, AccountMaster__c>();
        map<String, BI_TR_ServiceConfigHelp.PAYMENT_CONVERT> paymentConfigMap = BI_TR_ServiceConfigHelp.getPaymentConfig(shopCd);
        // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
        //map<String, BI_TR_ServiceConfigHelp.PAYMENT_CONVERT> pointConfigMap = BI_TR_ServiceConfigHelp.getPointConfig(shopCd);
        map<String, List<BI_TR_ServiceConfigHelp.PAYMENT_CONVERT>> pointConfigMap = BI_TR_ServiceConfigHelp.getPointConfig(shopCd);
        // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
        list<string> productCdlst = new list<string>();
        for (BI_TR_ServiceConfigHelp.PAYMENT_CONVERT parserPay : paymentConfigMap.values()) {
            productCdlst.add(parserPay.payProdCode);
        }
        // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
        //for (BI_TR_ServiceConfigHelp.PAYMENT_CONVERT parserPay : pointConfigMap.values()) {
        //    productCdlst.add(parserPay.payProdCode);
        //}
        // 関連の商品コードを取得、SOQL取得条件作成用
        for (List<BI_TR_ServiceConfigHelp.PAYMENT_CONVERT> parserPays : pointConfigMap.values()) {
            for (BI_TR_ServiceConfigHelp.PAYMENT_CONVERT parserPay : parserPays) {
                productCdlst.add(parserPay.payProdCode);
            }
        }
        // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
        if (!productCdlst.isEmpty()) {
            payProductIdMap = BI_TR_ServiceConfigHelp.getPaymentProductId(productCdlst);
        }
    	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END	
    	// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
    	// ポイントリストが存在する場合
    	// ポイントリスト合計金額格納
    	List<BI_TR_UserUsePointInformation> userUsePointList = member.userUsePointList;
    	// 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
    	boolean xmlProdNameToEstItemNameFlg = BI_TR_ServiceConfigHelp.getInstance().xmlProdNameToEstItem;
    	// 2018/12/30 TRポイント取り込み改善対応 WSQ END
    	if(userUsePointList!= null){
    	    // 総計利用ポイント数
    	    //Decimal usePointAmount = 0;
    	    Boolean isHasKeyMatchFlg = false;
    	    // XMLのポイントリストから関連の商品情報を設定する
    		for (BI_TR_UserUsePointInformation pointsInfo : userUsePointList) {
    			Decimal UserUsePoint = CommUtils.nullToZero(pointsInfo.UserUsePoint);
    			// ポイントは０の場合、処理SKIP
    			if (UserUsePoint <= 0) continue;
    			// ポイント商品名
    			String pointName = CommUtils.nullToBlank(pointsInfo.PointName);
				BookingEstimateItem__c bookingEst = null;
				if(UserUsePoint > 0) {
	                bookingEst = new BookingEstimateItem__c (
	                  refBooking__c = lead.id,
	                  UnitPrice__c = UserUsePoint,
	                  Amount__c = 1
	                );
	                // 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
	                if (xmlProdNameToEstItemNameFlg && !CommUtils.isBlank(pointName)) bookingEst.ProductName__c = (pointName.length() > 80 ? pointName.substring(0,80) : pointName);
	                // 2018/12/30 TRポイント取り込み改善対応 WSQ END
	                pointAmount += UserUsePoint;
	            }
				AccountMaster__c covertAcc = null;
                // 該当ポイントリストの一つ項目の商品情報を取得処理
		        for (String key : equalKeyLst) {
                    if (!pointConfigMap.containsKey(key)) continue;
                    // 指定支払方法とAGTコードで商品コードMATCH処理を行う
                    List<BI_TR_ServiceConfigHelp.PAYMENT_CONVERT> convertInfs = pointConfigMap.get(key);
                    String prodoctCode = '';
                    // 指定払方法とAGTコードに関連定義しているMATCHルール情報
                    for (BI_TR_ServiceConfigHelp.PAYMENT_CONVERT convertInf : convertInfs) {
                        // KEYWORD定義なしの場合、チェック不要、無条件で該当商品で見積明細に反映を行う
                        if (convertInf.filterKeyLst.isEmpty()) {
                            prodoctCode = convertInf.payProdCode;
                            break;
                        } else {
                            // POINTリストの商品名は定義の名と一致すると、該当商品コードを使う
                            for (String keyword : convertInf.filterKeyLst) {
                                if (keyword == pointName) {
                                    prodoctCode = convertInf.payProdCode;
                                    isHasKeyMatchFlg = true;
                                    break;
                                }
                            }
                            if (!CommUtils.isBlank(prodoctCode)) break;
                        }
                    }
                    // 商品コードをMatchされる場合
                    if (!CommUtils.isBlank(prodoctCode)) {
                        covertAcc = payProductIdMap.get(prodoctCode);
                        break;
                    }
		        } // END FOR equalKeyLst
		        // MATCH商品が非存在場合、値引商品で設定を行う
                AccountMaster__c pointAcc = covertAcc != null ? covertAcc : help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
                if (pointAcc != null && bookingEst != null) {
                    bookingEst.refAccountMaster__c = pointAcc.Id;
	                bookingEst.refAccountMaster__r = pointAcc;
	                pointLst.add(bookingEst); 
		        }
            } // END FOR userUsePointList
            // 自動MATCHデータが非存在場合、総計ポイントから再度MATCHする
	    // 2018/12/30 TRポイント取り込み改善対応 WSQ BEGIN
            //if (!isHasKeyMatchFlg) {
            if (!isHasKeyMatchFlg && !xmlProdNameToEstItemNameFlg) {
	    // 2018/12/30 TRポイント取り込み改善対応 WSQ END
                pointAmount = 0;
                pointLst.clear();
            }
            if (!pointLst.isEmpty()) insLst.addAll(pointLst);
    	}
    	// 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
    	// ポイント支払情報が存在する場合
        // basicRateにポイント支払情報が未設定する場合   
        if(member != null && pointLst.isEmpty()){
            Decimal UserUsePoints = CommUtils.nullToZero(member.UserUsePoints);
System.debug(LoggingLevel.INFO,'member.UserUsePoints:'+member.UserUsePoints);
            if(UserUsePoints > 0){
                System.debug(LoggingLevel.INFO,'使用ポイント:' + UserUsePoints);
                pointLst.add(new BookingEstimateItem__c (
                  refBooking__c = lead.id,
                  UnitPrice__c = UserUsePoints,
                  Amount__c = 1
                ));
                pointAmount += UserUsePoints;
            }

System.debug(LoggingLevel.INFO,'pointAmount:'+pointAmount);
			if (pointAmount>0) {
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
	            AccountMaster__c covertAcc = null;
	            for (String key : equalKeyLst) {
	System.debug(LoggingLevel.INFO,'割引MATCH:' + KEY + '=' + pointConfigMap.containsKey(key));
	                if (pointConfigMap.containsKey(key)) {
	                    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh BEGIN
	                    //BI_TR_ServiceConfigHelp.PAYMENT_CONVERT convertInf = pointConfigMap.get(key);
	                    List<BI_TR_ServiceConfigHelp.PAYMENT_CONVERT> convertInfs = pointConfigMap.get(key);
	                    // 処理対象情報を格納する
	                    BI_TR_ServiceConfigHelp.PAYMENT_CONVERT convertInf = null;
	                    // MATCHロジック処理を行う
	                    for (BI_TR_ServiceConfigHelp.PAYMENT_CONVERT wkConvertInf : convertInfs) {
	                        // １番目の定義ルールの商品コードで商品変換処理を行う
	                        if (convertInf == null) convertInf = wkConvertInf;
	                        // KEYWORD未設定の場合、該当ルールで変換処理を行う
	                        if (wkConvertInf.filterKeyLst.isEmpty()) {
	                            convertInf = wkConvertInf;
	                            break;
	                        }
	                    }
	                    // 2017/07/20  改善要望：ねっぱんクーポンと、ポイントを別で取込  by zh END
	                    covertAcc = payProductIdMap.get(convertInf.payProdCode);
	                    break;
	                }
	            }
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
	            // ポイント支払メデイア情報を取得する
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
	            AccountMaster__c pointAcc = covertAcc != null ? covertAcc : help.getMediaLabToAccMstMap().get(help.getPaymentTypeToMediaLabMap().get(CommConst.PROD_PAY_TYPE_DIS_PRICE));
	// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う END
	            if (pointAcc != null) {
	                for (BookingEstimateItem__c est : pointLst) {
	                    est.refAccountMaster__c = pointAcc.Id;
	                    est.refAccountMaster__r = pointAcc;
	                }
	            } //else pointLst.clear();
	            if (!pointLst.isEmpty()) insLst.addAll(pointLst);
	        }
        }
		// 事前決済区分により、支払情報の作成
        if(!CommUtils.isBlank(settlementDiv)){
            Integer SettlementDivCd = null;
            set<string> cardPaymentConvertSet = BI_TR_ServiceConfigHelp.getCardPaymentConvertConfig(shopCd);
            if (cardPaymentConvertSet != null && cardPaymentConvertSet.contains(settlementDiv)) {
                SettlementDivCd = 2;
            }
            set<string> creditPaymentConvertSet = BI_TR_ServiceConfigHelp.getCreditPaymentConvertConfig(shopCd);
            if (creditPaymentConvertSet != null && creditPaymentConvertSet.contains(settlementDiv)) {
                SettlementDivCd = 4;
            }
			// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
            AccountMaster__c commAcc = null;
            for (String key : equalKeyLst) {
System.debug(LoggingLevel.INFO,'事前決済MATCH:' + KEY + '=' + paymentConfigMap.containsKey(key));
                if (paymentConfigMap.containsKey(key)) {
                    BI_TR_ServiceConfigHelp.PAYMENT_CONVERT convertInf = paymentConfigMap.get(key);
                    commAcc = payProductIdMap.get(convertInf.payProdCode);
                    break;
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

            System.debug(LoggingLevel.INFO,'--------事前決済区分------------['+settlementDiv+']' + commAcc);
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
        System.debug(LoggingLevel.INFO,'-----------upsertPaymentBookingExtimeItem END----------------');
        // 割引、支払情報を新規作成する
        return insLst;
    }
// 2016/05/12 事前決済区分と登録の支払商品情報マッピングにより、個別登録を行う BEGIN
    private static list<String> getEqualsKeyLst (String settlementDiv, String agtCode) {
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
    // 
    // 
    private static List<BookingEstimateItem__c> setEachRoomBookingEstimeteItems(   BookingEstimateItem__c item, 
                                                                            BI_TR_RoomAndGuestInfo roomAndGuest,
                                                                            Integer taxSericeFee,
                                                                            Boolean isRoomRateFlg,
                                                                            Plan__c curPlan,
                                                                            Date usedDate){
//System.debug(LoggingLevel.INFO,'-----------setEachRoomBookingEstimeteItems-----------');
//System.debug(LoggingLevel.INFO,'BookingEstimateItem__c:' + item);
//System.debug(LoggingLevel.INFO,'roomAndGuest:' + roomAndGuest);
//System.debug(LoggingLevel.INFO,'taxSericeFee:' + taxSericeFee);
//System.debug(LoggingLevel.INFO,'isRoomRateFlg:' + isRoomRateFlg);
//System.debug(LoggingLevel.INFO,'curPlan:' + curPlan);
//System.debug(LoggingLevel.INFO,'usedDate:' + usedDate);
        List<BI_TR_RoomRateInfomation> roomRateLst = roomAndGuest.roomRateLst;
        List<BookingEstimateItem__c> detailLst = new List<BookingEstimateItem__c>();
        if (item == null) return detailLst;
        // 料金設定情報がありません
        if (roomRateLst.isEmpty()) return detailLst;
        // 人員単価金額で総計利用金額を計算を行う
        BI_TR_RoomsInfo room = roomAndGuest.room;
        // 宿泊者タイプの総人数
        Integer roomPaxCount = CommUtils.nullToZero(room.PerRoomPaxCount) ;       	// 利用人数
        Integer roomPaxMalCount = CommUtils.nullToZero(room.RoomPaxMaleCount) ;       // 男性人数
        Integer roomPaxFemaleCount = CommUtils.nullToZero(room.RoomPaxFemaleCount);   // 女性人数
        Integer roomChildACount = CommUtils.nullToZero(room.RoomChildA70Count);       // 子供A人数
        Integer roomChildBCount = CommUtils.nullToZero(room.RoomChildB50Count);       // 子供B人数
        Integer roomCHildCCount = CommUtils.nullToZero(room.RoomChildC30Count);       // 子供C人数
        Integer roomChildDCount = CommUtils.nullToZero(room.RoomChildDNoneCount);     // 子供D人数
		Integer roomChildECount = CommUtils.nullToZero(room.RoomChildECount);
		Integer roomChildFCount = CommUtils.nullToZero(room.RoomChildFCount);
        Integer roomChildOtherCount = CommUtils.nullToZero(room.RoomChildOtherCount);	// 子供その他人数
            
        Map<String,BookingEstimateItem__c> itemMap = new Map<String,BookingEstimateItem__c>();
        
System.debug(LoggingLevel.INFO,'料金区分:' + (isRoomRateFlg ? '部屋単価' : '人員単価'));
		// 処理対象リストを取得する
		list<BI_TR_RoomRateInfomation> currRoomRateLst = new list<BI_TR_RoomRateInfomation>();
		for(BI_TR_RoomRateInfomation roomRate : roomRateLst){
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
                BI_TR_RoomRateInfomation roomRate = currRoomRateLst[i];
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
System.debug(LoggingLevel.INFO,'1室あたり宿泊料金合計から見積明細に設定:'+roomRate.TotalPerRoomRate);
                	// 見積明細作成
            		BookingEstimateItem__c newItem = getRoomEstimateItem(item, roomRate);
                	// 利用人数あり　かつ　男性　OR　女性　以外の設定人数がない場合、平均値計算を行う
                	if (roomPaxCount == (roomPaxMalCount + roomPaxFemaleCount) && roomPaxCount > 0) {
                		Decimal wkPrice = CommUtils.RoundProcess(roomRate.TotalPerRoomRate / roomPaxCount,CommUtils.getPointLen());
                		Decimal wkAmount = wkPrice * roomPaxCount;
                		if (wkAmount != roomRate.TotalPerRoomRate || !presonRateAutoCal) {
System.debug(LoggingLevel.INFO,'宿泊料金合計 * 1 で設定');
	                		// 1部屋単位に設定する
							newItem.UnitPrice__c = roomRate.TotalPerRoomRate;
	        				newItem.Amount__c = 1;
                		} else {
System.debug(LoggingLevel.INFO,'宿泊料金合計 / 人数 * 人数 で設定');
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
                //2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 BEGIN by zh
                //RoomInformation的大人人数
                Integer paxCount = roomPaxMalCount + roomPaxFemaleCount;
                //RoomInformation的小孩人数
                Integer childCount = roomChildACount + roomChildBCount + roomCHildCCount + roomChildDCount + roomChildECount + RoomChildFCount + roomChildOtherCount;
                //RoomRateDetailInformation的大人人数
                Integer detialPaxCount = 0 ;
                //RoomRateDetailInformation的小孩人数
                Integer detialChildCount = 0 ;
                //没有大人人数、小孩人数、没有detail、bug修正[2018/11/05 ZH]
                if(roomRate.detailInfoLst == null) roomRate.detailInfoLst = new List<BI_TR_RoomRateDetailInfomation>();
                //if(roomRate.detailInfoLst != null){
                // 2018/11/20 小人数取り込み不正の対応 BEGIN
    			Decimal dePaxRate = 0;
                // 2018/11/20 小人数取り込み不正の対応 END
            	for (BI_TR_RoomRateDetailInfomation dinfo: roomRate.detailInfoLst) {
					//统计RoomRateDetailInformation的大人人数
					if(dinfo.RateCategory == 1){
						detialPaxCount += CommUtils.nullToZero(dinfo.RatePaxCount);
						// 2018/11/20 小人数取り込み不正の対応 BEGIN
						dePaxRate = dePaxRate > CommUtils.nullToZero(dinfo.RoomRate) ? dePaxRate : CommUtils.nullToZero(dinfo.RoomRate);
						//dePaxRate = CommUtils.nullToZero(dinfo.RoomRate);
						// 2018/11/20 小人数取り込み不正の対応 END
					//统计RoomRateDetailInformation的小孩人数
					}else{
						detialChildCount += CommUtils.nullToZero(dinfo.RatePaxCount);
					}
				}
                //}
				//判断RoomRateDetailInformation的大人人数==RoomInformation的大人人数
				if(detialPaxCount == paxCount){
					for (BI_TR_RoomRateDetailInfomation dinfo: roomRate.detailInfoLst) {
						//生成RoomRateDetailInformation大人的明细
						if(dinfo.RateCategory == 1){
		                    BookingEstimateItem__c newItem = item.clone(false, true);
		                    newItem.UnitPrice__c = CommUtils.nullToZero(dinfo.RoomRate);
		                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
		                    integer perAddAmount = CommUtils.nullToZero(dinfo.RatePaxCount);
		                    if (itemMap.containsKey(key))
		                        itemMap.get(key).Amount__c += perAddAmount;
		                    else {
		                        newItem.Amount__c = perAddAmount;
		                        itemMap.put(key, newItem);
		                    }
						}
					}
				}else{
				//2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 END by zh
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
                //2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 BEGIN by zh
				}
				//判断RoomRateDetailInformation的小孩人数==RoomInformation的小孩人数
				if(detialChildCount == childCount){
					for (BI_TR_RoomRateDetailInfomation dinfo: roomRate.detailInfoLst) {
						//生成RoomRateDetailInformation小孩的明细
						if(dinfo.RateCategory != 1){
							//integer perAddAmount = 1;
		                    BookingEstimateItem__c newItem = item.clone(false, true);
		                    newItem.UnitPrice__c = CommUtils.nullToZero(dinfo.RoomRate);
		                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
		                    // 2018/11/20 小人数取り込み不正の対応 BEGIN
		                    //matchChildrenPlan(newItem,perPaxRate);
		                    matchChildrenPlan(newItem,dePaxRate);
		                    // 2018/11/20 小人数取り込み不正の対応 END
		                    // 2016/06/10 子供料金プラン取り込み機能対応 END
		                    String key = 'PaxMalCount_' + newItem.UnitPrice__c;
		                    integer perAddAmount = CommUtils.nullToZero(dinfo.RatePaxCount);
		                    if (itemMap.containsKey(key))
		                        itemMap.get(key).Amount__c += perAddAmount;
		                    else {
		                        newItem.Amount__c = perAddAmount;
		                        itemMap.put(key, newItem);
		                    }
						}
					}
				}else{
				//2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 END by zh
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
				if(roomChildECount > 0 && roomRate.PerChildERate != null){
                    integer perAddAmount = 1;
                    BookingEstimateItem__c newItem = item.clone(false,true);
                    newItem.UnitPrice__c = roomRate.PerChildERate;
                    // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
                    matchChildrenPlan(newItem,perPaxRate);
                    // 2016/06/10 子供料金プラン取り込み機能対応 END
                    String key = 'ChildECount_' + newItem.UnitPrice__c;
                    if(lastRateFlag) perAddAmount = roomChildECount;
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
                    if(lastRateFlag) perAddAmount = RoomChildFCount;
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
			//2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 BEGIN by zh
            }
            //2018/07/05 料金詳細情報（RoomRateDetailInformation)取り込みできるように改善対応 END by zh
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
            for(BI_TR_RoomRateInfomation roomRate : currRoomRateLst){
            	/*
                BookingEstimateItem__c newItem = item.clone(false,true);
                newItem.UnitPrice__c = roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : roomRate.PerPaxRate;
System.debug(LoggingLevel.INFO,'newItem.UnitPrice__c：' + newItem.UnitPrice__c); 
                newItem.Amount__c = 1;
                */
                 BookingEstimateItem__c estimateItem = getRoomEstimateItem(item, roomRate);
                 if(estimateItem == null)continue;
                 else detailLst.add(estimateItem);
            }
        }
        // RoomRateの場合、プラン室料自動設定機能を追加する END
        // 単価定義区分変換処理を行う
        for(BookingEstimateItem__c bookingItem : detailLst){
            System.debug(LoggingLevel.INFO,'利用金額「変更前」(区分'+taxSericeFee+')：' + bookingItem.UnitPrice__c);
            // Local変換前の利用金額を格納する
            Decimal orgEstUnitPrice = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            orgEstUnitPriceEnd = orgEstUnitPrice;
            // 2019/09/15 軽減税率機能対応 WGCH END
            /*
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
            System.debug(LoggingLevel.INFO,'利用金額「変更後」(区分'+CommConst.APPOPTION_UTP_DEF_KB+')：' + bookingItem.UnitPrice__c);
            */
            // 2016/06/10 子供料金プラン取り込み機能対応 BEGIN
            // 該当対応の会計商品コードを取得する、該当商品コード
            PlanDetailInfo locPlanDetailInf = gPlanDetailInf;
            Plan__c locCurPlan = curPlan;
            String locProductCode = bookingItem.Field3__c;
            if (childPlanPlanMstMap.containsKey(locProductCode)) {
                locCurPlan = childPlanPlanMstMap.get(locProductCode);
            }
            if (childPlanDetailMap.containsKey(locProductCode)) {
                locPlanDetailInf = childPlanDetailMap.get(locProductCode);
            }
            // 2016/06/10 子供料金プラン取り込み機能対応 END
			// 非課税商品が存在すると、該当非課税商品の金額はXMLの単価から減算する
			Decimal noTaxSumValueBaseSf = locPlanDetailInf.isHavePdData ? locPlanDetailInf.priceNoTaxSumVal : 0;
			Decimal noTaxSumValueBaseXml = 0;
			if (noTaxSumValueBaseSf > 0 ) {
				noTaxSumValueBaseXml = CommUtils.convertPriceByTaxKbn(  noTaxSumValueBaseSf,
                                                                        null,
                                                                        item.refAccountMaster__r.ServiceRate__c, 
                                                                        CommConst.APPOPTION_UTP_DEF_KB,
                                                                        taxSericeFee);
			}
            // 税区分変更をお行う「XMLに指定の税区分→SF側の税区分に変更」
            //bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  orgEstUnitPrice,
            bookingItem.UnitPrice__c = CommUtils.convertPriceByTaxKbn(  orgEstUnitPrice - noTaxSumValueBaseXml,
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
            System.debug(LoggingLevel.INFO,'利用金額「変更後」(区分'+CommConst.APPOPTION_UTP_DEF_KB+')：' + bookingItem.UnitPrice__c);
            // 2019/09/15 軽減税率機能対応 WGCH BEGIN
            Decimal estUnitPriceEnd = bookingItem.UnitPrice__c;
            // 2019/09/15 軽減税率機能対応 WGCH END
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
                    System.debug(LoggingLevel.INFO,'非課税商品あり：金額：' + locPlanDetailInf.priceNoTaxSumVal);
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
                    System.debug(LoggingLevel.INFO,'利用金額はサ込、消費税込計算後金額：' + incTaxSerUnitPrice);
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
                    */ 
                    // プラン元金額から非課税金額を外す
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
                    System.debug(LoggingLevel.INFO,'元のプラン金額は調整後：' + orgPlanPrice);
                    System.debug(LoggingLevel.INFO,'元の利用金額は調整後：' + curnPayPrice);
                }
                // 2019/09/15 軽減税率機能対応 WGCH BEGIN
                else if(isReducedTaxFlg){
                	curnPayPrice = CommUtils.nullToZero(estUnitPriceEnd) - CommUtils.nullToZero(locPlanDetailInf.priceNoTaxSumValEnd);
                	orgPlanPrice = CommUtils.nullToZero(locPlanDetailInf.curnPayPriceEnd);
                }
                // 2019/09/15 軽減税率機能対応 WGCH END
                if (orgPlanPrice != curnPayPrice) bookingItem.PlanDetailSyncInfo__c = getPlanDetailSyncInfo(orgPlanPrice,curnPayPrice,locPlanDetailInf);
				System.debug(LoggingLevel.INFO,'プラン明細個別設定情報 ：' + bookingItem.PlanDetailSyncInfo__c);
            }
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        if(ldInfo != null){
        	detailLst = ProductItemUtils.getNwDetailLst(detailLst, ldInfo);
        }
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        for(BI_TR_RoomRateInfomation roomRate : roomRateLst){
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
            if(roomRate.TotalPerlRoomHotSpringTax > 0 && nyuuTouAcc.id != null && roomRate.TotalPerlRoomHotSpringTax != null){
                Integer roomHotSpringCount = 1;
                Decimal unitPrice = roomRate.TotalPerlRoomHotSpringTax;
                if(nyuuTouAcc.Field5__c != null && nyuuTouAcc.Field5__c != 0 ){
                    decimal resultCount = roomRate.TotalPerlRoomHotSpringTax/nyuuTouAcc.Field5__c;
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
        return detailLst;                                                                        
    }
    
    
    // 室料単位の見積明細情報を設定する
    private static BookingEstimateItem__c getRoomEstimateItem(BookingEstimateItem__c orgItem, BI_TR_RoomRateInfomation roomRate) {
    	if(roomRate.TotalPerRoomRate ==null && roomRate.PerPaxRate ==null) return null;
        BookingEstimateItem__c newItem = orgItem.clone(false,true);
        newItem.UnitPrice__c = roomRate.TotalPerRoomRate != null ? roomRate.TotalPerRoomRate : CommUtils.nullToZero(roomRate.PerPaxRate);
		//if (newItem.UnitPrice__c == null) newItem.UnitPrice__c = 0;
        newItem.Amount__c = 1;
        return newItem;
    }
    
    // プラン関連のプラン明細の単価定義情報の取得する
    // 設定書式：プラン明細ID:単価:会計商品ID:会計商品名;
    private static String getPlanDetailSyncInfo(Decimal orgUnitPrice,Decimal curUnitPrice, PlanDetailInfo planDetailInf){
    	System.debug(LoggingLevel.INFO,'----------getPlanDetailSyncInfo begin---------');
        System.debug(LoggingLevel.INFO,'プラン標準金額[非課税外す]：' + orgUnitPrice);
        System.debug(LoggingLevel.INFO,'今回課税商品金額合計：' + curUnitPrice);
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
        		System.debug(LoggingLevel.INFO,'減算可能金額['+orgUnitPrice+']は減算必要な金額['+curUnitPrice+']により、すくないので、配分なし');
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

 		// 調整必要の差分金額
        Decimal diffUnitSum = diffUnit;
        // 室料明細が存在する場合、室料明細に金額調整を行う
        if (!roomPdList.isEmpty()) {
        	System.debug(LoggingLevel.INFO,'室料明細調整前差分金額：' + diffUnit);
        	diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, roomPdList, diffUnit, false);
        	System.debug(LoggingLevel.INFO,'室料明細調整後差分金額：' + diffUnitSum);
        }
        // 調整不可になる
        
        if (diffUnitSum != 0 ) return CommConst.CONST_PLANITEM_NOEXPAND;
        //&& bookingMode == BI_BOOKING_MODE.STOP
        // 調整可能の明細に優先順位で調整を行う
        /*
        if (diffUnitSum != 0 && !otherPdList.isEmpty()) {
            System.debug(LoggingLevel.INFO,'比率で金額を自動配分前差分金額：' + diffUnitSum);
            // 順次配分
            diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, otherPdList, diffUnitSum, true);
            System.debug(LoggingLevel.INFO,'比率で金額を自動配分後差分金額：' + diffUnitSum);
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
                    System.debug(LoggingLevel.INFO,'順次配分2');
                    // 順次配分
                    diffUnitSum = divisionPlanDetailUnitPrice(orgUnitPrice, otherLst, diffUnitSum, true);
                }
                updEstItems.addAll(otherLst);
            }else{
                return CommConst.CONST_PLANITEM_NOEXPAND;
            }
        }
        System.debug(LoggingLevel.INFO,'first diffUnitSum::' + diffUnitSum);
            
        if(!updEstItems.isEmpty()){
            for(PlanDetail__c detail : updEstItems){
                // 明細自動配分情報を作成する：プラン明細ID:配分金額
                if(detail != null) planDetailSyncInfo += detail.id + ':' + detail.Price__c + ';';
            }
        }*/
        
        System.debug(LoggingLevel.INFO,'プランブレイク差分調整金額:' + diffUnit);
        System.debug(LoggingLevel.INFO,'----------getPlanDetailSyncInfo end---------');
        return planDetailSyncInfo;
    }
    
    // プラン明細に金額調整処理機能
    //
    //
    // autoSplitFlg:残り金額は自動配分するがどうか
    private static Decimal divisionPlanDetailUnitPrice(Decimal orgUnitPrice, List<PlanDetail__c> pdList, Decimal orgDiffUnit, Boolean autoSplitFlg){
        System.debug(LoggingLevel.INFO,'----------divisionPlanDetailUnitPrice begin---------');
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
                System.debug(LoggingLevel.INFO,'--------差分額は減額---------');
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
        System.debug(LoggingLevel.INFO,'----------divisionPlanDetailUnitPrice end---------');
        return diffUnitSum;
    }
    
    /**
    * オプション商品情報は１番目部屋１泊目予約の見積明細に反映を行う
    **/
    // 2017/08/15 option数据根据单价定义区分计算 fix BEGIN
    //private static List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_TR_SyncInfo bookingInfo,Lead__c insLead){
    private static List<BookingEstimateItem__c> upsertBookingEstimeteItemsByEach(BI_TR_SyncInfo bookingInfo,Lead__c insLead, Integer taxSericeFee){
    // 2017/08/15 option数据根据单价定义区分计算 fix END
    	// オプション新規作成明細情報を格納する
        List<BookingEstimateItem__c> newOptList = new List<BookingEstimateItem__c>();
        System.debug(LoggingLevel.INFO,'----------upsertBookingEstimeteItemsByEach BEGIN-----------');
        if(bookingInfo.optionLst == null || bookingInfo.optionLst.isEmpty()) {
            return newOptList;
        }
        // オプション商品が存在する場合
        List<BI_TR_Option> optionLst = bookingInfo.optionLst;
        // オプション商品コード　名を格納する
        //set<String> prodCodeSet = new set<String>();
        set<String> prodNameSet = new set<String>();
        for(BI_TR_Option option : optionLst){
            String productNm = option.Name;
            //String productCode = option.OptionCode;
            //if (!CommUtils.isBlank(productCode)) prodCodeSet.add(productCode);
            //if (!CommUtils.isBlank(productNm)) prodNameSet.add(productCode);
            if (!CommUtils.isBlank(productNm)) prodNameSet.add(productNm);
        }
        // コードと名は全部NULLの場合、処理対象外
        //if(prodCodeSet.isEmpty() && prodNameSet.isEmpty()) return newOptList;
        if(prodNameSet.isEmpty()) return newOptList;
        // コード　OR　名前で既存会計商品から情報を取得する
        //List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Field3__c = :prodCodeSet or Name = :prodNameSet];
        // 2017/08/09 オプション商品検索の場合、非表示商品は対象外になる BEGIN
        //List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Name = :prodNameSet];
        List<AccountMaster__c> accs = [select id,name,Field3__c,jmstRef__r.TaxRate__c,ServiceRate__c from AccountMaster__c where Name = :prodNameSet And ActionType__c != :CommConst.PROD_ACTION_TYPE_NO];
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
        for(BI_TR_Option option : optionLst) {
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
    	System.debug(LoggingLevel.INFO,'----------upsertBookingEstimeteItemsByEach END-----------');
    	return newOptList;
    }
	// 2016/06/20 EDIT END
    
    
	// 顧客リスト情報を変数に格納する
	//private static List<Contact> contactsLst;
    /**
    * 代表者として、取引先責任者作成する
    **/
    //private static Contact upsertContact(BI_TR_SyncInfo bookingInfo) {
    private static Contact upsertContact(BI_TR_SyncInfo bookingInfo, Lead__c firstLead) {
System.debug(LoggingLevel.INFO,'-------- 代表者として、取引先責任者 Begin ------');
		String applicantName = bookingInfo.Member != null ? bookingInfo.Member.UserName : null;     // 申込者
        String applicantPhone = bookingInfo.Member != null ? bookingInfo.Member.UserTel : null;     // 申込者電話
        Contact curContact = null;
        // 宿泊者リスト初期化
        //contactsLst = new List<Contact>();
        // 代表者情報は取得取得処理を行う
        String primaryUsr = bookingInfo.GuestOrGroupNameKanjiName;
        String primaryUsrKana = bookingInfo.GuestOrGroupNameSingleByte;
        // ユーザー情報が未設定する場合、仮ユーザ情報を自動設定を行う
        if (CommUtils.isBlank(primaryUsr) && Commutils.isBlank(primaryUsrKana)) {
            return CommLogicProcess.getOrInsertTempContact();
        } 
System.debug(LoggingLevel.INFO,'primaryUsr=' + primaryUsr);
System.debug(LoggingLevel.INFO,'primaryUsrKana=' + primaryUsrKana);
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
        List < Contact > existCList = null;
        Boolean isChgExistUserFlg = false;
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
        boolean conAlwaysNewFlg = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).contactAlwaysNew;
        // XMLタグがTRUEかつ新規予約の場合、お客様情報は常に新規作成する
        conAlwaysNewFlg = conAlwaysNewFlg && (bookingInfo.dmlAction == BI_TR_DmlAction.INS);
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        if(bookingInfo.dmlAction == BI_TR_DmlAction.UPD && firstLead != null){
        	String contactId = firstLead.Relcontact__c;
        	existCList = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,
        	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN
        	//Phone2__c抽出項目を追加する
        							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone,Phone2__c from Contact where id = :contactId];
        	//2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            if(!existCList.isEmpty()) {
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
	            //return existCList[0];
	            // 該当データは変更通知の既存ユーザーありを識別する
	            isChgExistUserFlg = true;
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END
            }
        }
        // 団体名または代表者氏名 漢字
        Map<String, Contact> contactMap = new Map<String, Contact>();
        // 団体名または代表者氏名(半角)
        Map<String, Contact> kanaNmMap = new Map<String, Contact>();

        // 個々の部屋とお客様リスト
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
        	// お客様情報リスト
            for (BI_TR_GuestInfo guest : roomAndGuest.guestLst) {
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
System.debug(LoggingLevel.INFO,'guest住所解析結果：'+addressLst);
System.debug(LoggingLevel.INFO,'guest住所size：'+addressLst.size());
				// 2016/08/10 取込みデータの都道府県の桁数を超える場合、該当項目を空欄のままデータを取り込み begin
                	if (addressLst.size() == 3) {
                        contactItem.MailingState = addressLst[0].length() > 80 ? addressLst[0].subString(0,80) : addressLst[0];
                        contactItem.MailingCity = addressLst[1].length() > 40 ? addressLst[1].subString(0,40) : addressLst[1];
                        contactItem.MailingStreet = addressLst[2].length() > 255 ? addressLst[2].subString(0,255) : addressLst[2];
                        /*contactItem.MailingState = addressLst[0];
                        contactItem.MailingCity = addressLst[1];
                        contactItem.MailingStreet = addressLst[2];*/
                	} else {
                        contactItem.MailingStreet = addressLst[0].length() > 255 ? addressLst[0].subString(0,255) : addressLst[0];
                        //contactItem.MailingStreet = addressLst[0];
                	}
                // 2016/08/10 取込みデータの都道府県の桁数を超える場合、該当項目を空欄のままデータを取り込み end
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
System.debug(LoggingLevel.INFO,'お客様情報リストから設定情報を取得する:::::'+curContact);
        } else if(bookingInfo.Member.UserName == primaryUsr || bookingInfo.Member.UserKana == primaryUsrKana) {
    		//phoneNumber = bookingInfo.Member.UserTel;
    		BI_TR_MemberInfo member = bookingInfo.Member;
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
System.debug(LoggingLevel.INFO,'member住所解析結果：'+addressLst);
System.debug(LoggingLevel.INFO,'member住所size：'+addressLst.size());
				// 2016/08/10 取込みデータの都道府県の桁数を超える場合、該当項目を空欄のままデータを取り込み begin
	        	if (addressLst.size() == 3) {
                    /*curContact.MailingState = addressLst[0];
                    curContact.MailingCity = addressLst[1];
                    curContact.MailingStreet = addressLst[2];*/
                    curContact.MailingState = addressLst[0].length() > 80 ? addressLst[0].subString(0,80) : addressLst[0];
                    curContact.MailingCity = addressLst[1].length() > 40 ? addressLst[1].subString(0,40) : addressLst[1];
                    curContact.MailingStreet = addressLst[2].length() > 255 ? addressLst[2].subString(0,255) : addressLst[2];
	        	} else {
                    //curContact.MailingStreet = addressLst[0];
                    curContact.MailingStreet = addressLst[0].length() > 255 ? addressLst[0].subString(0,255) : addressLst[0];
	        	}
                // 2016/08/10 取込みデータの都道府県の桁数を超える場合、該当項目を空欄のままデータを取り込み end
	        }   
        }
System.debug(LoggingLevel.INFO,'新規存在の顧客情報:::::'+curContact);
        // お客様情報が存在する場合
        if (curContact != null) {
        	if (curContact.firstName == '_' || curContact.firstName == '!') curContact.firstName = '';
        	// 予約者は宿泊者と同じ人の場合、ZIP番号を設定する
            // POSTNOを設定する
            if (bookingInfo.Member != null) {
	            if(bookingInfo.Member.UserName == primaryUsr || bookingInfo.Member.UserKana == primaryUsrKana) {
	        		// 予約者・会員郵便番号
		       		// 郵便番号值设定不正 fix BEGIN
		       		if(!CommUtils.isBlank(bookingInfo.member.UserZip)){
		       			curContact.MailingPostalCode = bookingInfo.member.UserZip;
		       		}
		       		// 郵便番号值设定不正 fix END
	        	}
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
            curContact.Katakana__c = bookingInfo.GuestOrGroupNameDoubleByte;
        }
        // 2016/05/25 お客様電文番号は[--]の場合、エラー回避
        phoneNumber = CommUtils.convTelphoneNumber(phoneNumber);
System.debug(LoggingLevel.INFO,'phoneNumber::::::' + phoneNumber );
        // 電話番号と
        // 2017/12/14 SOSLキーチェック追加対応 BEGIN
        //if (!CommUtils.isBlank(phoneNumber)) {
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN 
        String kajiname = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameKanjiName);
        String kanaName = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameSingleByte);
        String kanaKana = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameDoubleByte);
        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
		if (!conAlwaysNewFlg) {
		// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
        // 変更通知以外の場合、関連お客様情報を検索する、変更の場合、再度検索が不要
        if (!isChgExistUserFlg) {
        //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
	        if (CommUtils.isValidateSoslKey(phoneNumber)) {
	        // 2017/12/14 SOSLキーチェック追加対応 END
	            String fullName = (curContact.lastName + ' ' + CommUtils.nullToBlank(curContact.firstName)).trim();   
	            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH BEGIN       
	            //String kajiname = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameKanjiName);
	            //String kanaName = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameSingleByte);
	            //String kanaKana = CommUtils.nullToblank(bookingInfo.GuestOrGroupNameDoubleByte);
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
        System.debug(LoggingLevel.INFO,'既存お客様:' + existCList );
		if (existCList != null && !existCList.isEmpty()) {
            existCList[0].ApplicantName__c = applicantName;
            existCList[0].ApplicantPhone__c = applicantPhone;
            //System.debug(LoggingLevel.INFO,'：：：：：：：：：：：：：：：：申込者:::::::::::::::::' );
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
            // お客様情報を更新する
            existCList[0].Phone2__c = curContact.Phone2__c;
            //2019/03/15 既存お客様情報場合、SFの項目値は空白、XMLタグ値が存在する場合、反映処理を改善する ZH END 
            existCList[0] = (new CommLogicProcess()).upsertDuplicateErrorProcess(existCList[0]);
System.debug(LoggingLevel.INFO,'existCList[0]:::::::' + existCList[0] );
            //2016/05/24  お客様重複チェック対応 END
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
            //2016/08/01 日本電話分割 by zy　BEGIN 
            curContact.Phone = CommUtils.isBlank(phoneNumber) ? null : PhoneNumberUtils.splitNumber(phoneNumber,'-');
System.debug(LoggingLevel.INFO,'curContact.Phone:' + curContact.Phone );
            //2016/08/01 日本電話分割 by zy　END
	        // 非存在する場合（あり得ない）
	        //2016/05/24  お客様重複チェック対応 BEGIN
	        //insert curContact;  
	        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
			if (!conAlwaysNewFlg) {
			// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
	        curContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(curContact);
	        // 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ BEGIN
			} else {
					(new CommLogicProcess()).forceUpdate(curContact, null);
			}
			// 2019/09/20 ネットからの取り込みで、お客様をすべて新規で取り込みできるように改善 WSQ END
System.debug(LoggingLevel.INFO,'お客様新規作成::' + curContact.id);
	        // 2016/05/24 お客様重複チェック対応 END
        }     
        return curContact;
    }


    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所は
     */
    private static List<Account> upsertTravelInfo (BI_TR_SyncInfo bookingInfo) {
    	System.debug(LoggingLevel.INFO, '-------- 旅行会社情報 Begin ------');
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
System.debug(LoggingLevel.INFO,'------SalesOfficeCompanyName' + bookingInfo.SalesOfficeCompanyName);
System.debug(LoggingLevel.INFO,'------SalesOfficeCompanyCode' + bookingInfo.SalesOfficeCompanyCode);
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
            List<Account> travelCompanyLst = [select id , name, SalesOfficeCompanyCodeTR__c from Account
				// 2016/06/20 EDIT BEGIN
				//where name = :bookingInfo.SalesOfficeCompanyName 
				//And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL
				//and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
				Where ((SalesOfficeCompanyCodeTR__c = :bookingInfo.SalesOfficeCompanyCode)
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
                    travelCompany.SalesOfficeCompanyCodeTR__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeTRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                    // 2016/06/20 EDIT END
                    insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
				if (CommUtils.isBlank(travelCompany.SalesOfficeCompanyCodeTR__c)) {
					travelCompany.SalesOfficeCompanyCodeTR__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeTRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                    update travelCompany;
            	}
        	}
			System.debug(LoggingLevel.INFO,'旅行会社AGT['+(travelCompanyLst.isEmpty() ? '新規':'既存')+']' + travelCompany);
		}else if(!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName)){
			List<Account> travelCompanyLst = [select id , name, SalesOfficeCompanyCodeTR__c from Account
				Where Name = :bookingInfo.SalesOfficeCompanyName And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL limit 1];
			// 存在なければ、取引先を新規作成する
            if (travelCompanyLst.isEmpty()) {
                    travelCompany = new Account();
                    travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
                    //travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
					// 2016/06/20 EDIT BEGIN
                    //travelCompany.SalesOfficeCompanyCodeTR__c = bookingInfo.SalesOfficeCompanyCode;
                    //travelCompany.SalesOfficeCompanyCodeTRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                    // 2016/06/20 EDIT END
                    insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
				/*if (CommUtils.isBlank(travelCompany.SalesOfficeCompanyCodeTR__c)) {
					travelCompany.SalesOfficeCompanyCodeTR__c = bookingInfo.SalesOfficeCompanyCode;
                    travelCompany.SalesOfficeCompanyCodeTRAPI__c = bookingInfo.SalesOfficeCompanyCode;
                    update travelCompany;
            	}*/
        	}
        	System.debug(LoggingLevel.INFO,'旅行会社AGT['+(travelCompanyLst.isEmpty() ? '新規':'既存')+']' + travelCompany);
		}
		if (travelCompany == null) return new list<Account>();
		
        Account traveOffice = null;
		
        // 旅行会社営業所情報が存在する場合
        if (!CommUtils.isBlank(bookingInfo.RetailerCompanyName) ) {
            // 旅行会社営業所情報をチェックを行う
            String retailerCompany = bookingInfo.RetailerCompanyName;
            List<Account> traveOfficeLst = [select id , name from Account where name = :retailerCompany and AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL And ParentId = :travelCompany.Id limit 1];
            if (traveOfficeLst.isEmpty()) {
                traveOffice = new Account();
                traveOffice.Name = bookingInfo.RetailerCompanyName;
                traveOffice.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
                //traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
                traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
                //traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
                insert traveOffice;
                System.debug(LoggingLevel.INFO,'旅行会社-支店新規作成::' + traveOffice.id);
            } else {
                traveOffice = traveOfficeLst[0];
                System.debug(LoggingLevel.INFO,'旅行会社-支店既存取得::' + traveOffice.id);
            } 
        }
        /*
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
            }
        }*/
        //return (traveOffice == null ? travelCompany: traveOffice);
        List<Account> rsAccountLst = new List<Account>();
        if (travelCompany != null) rsAccountLst.add(travelCompany);
        if (traveOffice != null) rsAccountLst.add(traveOffice);
        return rsAccountLst;
    }
    
        // 2013/12/28
    // メール本文情報を設定する
    private static String mailArea(BI_TR_SyncInfo bookingInfo){
    	system.debug(loggingLevel.INFO,'メール本文作成');
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
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            // お客様情報リスト
            for (BI_TR_GuestInfo guest : roomAndGuest.guestLst) {
            	system.debug(loggingLevel.INFO,'guest' + guest);
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
				//住所:
				guestMsg += '\n'+ Label.CONST_043_0006 +' ';
                    if (!CommUtils.isBlank(guest.GuestPostalCode)) guestMsg += '(〒'+guest.GuestPostalCode+')';
                    guestMsg += guest.GuestStateProvidence;
                }
			// 性別、電話番号、緊急連絡先、
                guestMsg += '\n';
			//性別:
			if (!CommUtils.isBlank(guest.GuestGender)) guestMsg += ' '+ Label.CONST_043_0008 +' ' + guest.GuestGender;
			//電話:
                if (!CommUtils.isBlank(guest.GuestPhoneNumber)) guestMsg += ' '+ Label.CONST_043_0009 +' ' + guest.GuestPhoneNumber;
			//緊急連絡先:
                if (!CommUtils.isBlank(guest.GuestEmergencyPhoneNumber)) guestMsg += ' '+Label.CONST_043_0010 +' ' + guest.GuestEmergencyPhoneNumber;
            }
        }
		// 客室へリクエスト情報を作成する
		String roomRequestMsg = '';
        // XML部屋と料金情報を取得する
        for(BI_TR_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
            // RoomInformation[部屋タイプ定義情報]
            BI_TR_RoomsInfo roomInfo = roomGuestInfo.room;
//System.debug(LoggingLevel.INFO,'部屋設定料金情報を取得する::');            
			if (!CommUtils.isBlank(roomInfo.RoomSpecialRequest)) {
				//に特別リクエスト:
				roomRequestMsg += '\n' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ') + Label.CONST_043_0011 + roomInfo.RoomSpecialRequest;
			}
            // 部屋設定料金情報を取得する
            for(BI_TR_RoomRateInfomation roomRate : roomGuestInfo.roomRateLst){
                roomMsg += '\n';
				//yyyy年MM月dd日
				roomMsg += (DateTime.newInstance(roomRate.RoomDate.year(), roomRate.RoomDate.month(), roomRate.RoomDate.day()).format(Label.CONST_043_0012))  + 
                            ' ' + roomInfo.RoomTypeCode + ( CommUtils.isBlank(roomInfo.RoomTypeName) ? ' ' : ' (' + roomInfo.RoomTypeName +') ') + 
                            '@' + CommUtils.nullToBlank(roomRate.TotalPerRoomRate);
                if(roomInfo.RoomPaxMaleCount > 0 ){
					//大人（男）
					//名
					roomMsg += '\n'+ Label.CONST_043_0013 +' ' + roomInfo.RoomPaxMaleCount + Label.CONST_043_0014;
				}
				if(roomInfo.RoomPaxFemaleCount > 0 ){
					//大人（女）
					//名
					roomMsg += '\n'+ Label.CONST_043_0015 +' ' + roomInfo.RoomPaxFemaleCount + Label.CONST_043_0014;
				}
				// 子供人数
				Integer childCount = CommUtils.nullToZero(roomInfo.RoomChildA70Count) + 
									 CommUtils.nullToZero(roomInfo.RoomChildB50Count) +
									 CommUtils.nullToZero(roomInfo.RoomChildC30Count) + 
									 CommUtils.nullToZero(roomInfo.RoomChildDNoneCount) +
									 CommUtils.nullToZero(roomInfo.RoomChildECount)	+ 
									 CommUtils.nullToZero(roomInfo.RoomChildFCount) +
									 CommUtils.nullToZero(roomInfo.RoomChildOtherCount);
				//子供
				//名
				if(childCount > 0 ) roomMsg += '\n'+ Label.CONST_043_0016 +'  　　　' + childCount + Label.CONST_043_0014;
				
				// 料金明細
				if (roomRate.detailInfoLst != null && roomRate.detailInfoLst.size() > 0) {
					// 料金明細情報
					//料金明細:
					roomMsg += '\n'+ Label.CONST_043_0017;
					for (BI_TR_RoomRateDetailInfomation dinfo : roomRate.detailInfoLst) {
						roomMsg += '\n';
						String rateCateStr = '';
						if (dinfo.RateCategory != null) {
							//大人
							if ( dinfo.RateCategory == 1 ) rateCateStr = ' '+ Label.CONST_043_0018 +' ';
							//子供
							else rateCateStr = ' '+ Label.CONST_043_0016 +' ';
						}
						//一人料金：
						if (dinfo.RoomRate != null)  roomMsg += ' '+ Label.CONST_043_0019 +' ¥' + dinfo.RoomRate;
						//人数：
						if (dinfo.RatePaxCount != null)  roomMsg += ' '+ Label.CONST_043_0020 +' ' + dinfo.RatePaxCount + (CommUtils.isBlank(rateCateStr) ? '' : '('+rateCateStr+')');
						//明細：
						if (!CommUtils.isBlank(dinfo.RateDetailInformation))  roomMsg += ' '+ Label.CONST_043_0021 +' ' + dinfo.RateDetailInformation;
					}
				}
                
            }
        }
		//宿泊料金計:

		roomMsg += '\n\n '+ Label.CONST_043_0022 +' ¥' + bookingInfo.TotalAccommodationCharge + '\n';
        
		//【宿泊者への請求額】 ： \42,000
        if (bookingInfo.member != null ) {
            BI_TR_MemberInfo member = bookingInfo.member;
            roomMsg += '\n';
			if (member.UserGivinPoints != null && member.UserGivinPoints > 0) roomMsg += '\n 【付与ポイント】： ' + member.UserGivinPoints;
			//使用ポイント
			if (member.UserUsePoints != null && member.UserUsePoints > 0) roomMsg += '\n 【'+ Label.CONST_043_0023 +'】： ' + member.UserUsePoints;
			//宿泊者への請求額
			if (member.AmountClaimed != null && member.AmountClaimed > 0) roomMsg += '\n 【'+ Label.CONST_043_0024 +'】： ¥' + member.AmountClaimed;
            System.debug(LoggingLevel.INFO,'使用ポイント::' + member.UserUsePoints);
        	System.debug(LoggingLevel.INFO,'宿泊者への請求額::' + member.AmountClaimed);
        }
		String roomAndGuestMsg = '';
		if (CommUtils.nullToZero(bookingInfo.TotalPaxMaleCount) > 0)
		//(男)
		//名
		roomAndGuestMsg += Label.CONST_043_0025 + CommUtils.nullToZero(bookingInfo.TotalPaxMaleCount) + Label.CONST_043_0014 +' ';
		if (CommUtils.nullToZero(bookingInfo.TotalPaxFemaleCount) > 0)
		//(女)
		//名
		roomAndGuestMsg += Label.CONST_043_0026 + CommUtils.nullToZero(bookingInfo.TotalPaxFemaleCount) + Label.CONST_043_0014;
		Integer childCount = CommUtils.nullToZero(bookingInfo.TotalChildA70Count) + 
							 CommUtils.nullToZero(bookingInfo.TotalChildB50Count) +
							 CommUtils.nullToZero(bookingInfo.TotalChildC30Count) + 
							 CommUtils.nullToZero(bookingInfo.TotalChildDNoneCount) +
							 CommUtils.nullToZero(bookingInfo.TotalChildECount)	+ 
							 CommUtils.nullToZero(bookingInfo.TotalChildFCount) +
							 CommUtils.nullToZero(bookingInfo.TotalChildOtherCount);
		//(子供)
		//名		 
		if(childCount > 0 ) roomAndGuestMsg += Label.CONST_043_0027 + childCount + Label.CONST_043_0014;
		//予約通知：
		mailString +=	Label.CONST_043_0028 +' '+ bookingInfo.SalesOfficeCompanyName;
		//予約番号：
		mailString +=	'\n' + Label.CONST_043_0029 +' ' + bookingInfo.TravelAgencyBookingNumber;
//System.debug(LoggingLevel.INFO,'施設情報::');        
        //-------------------施設情報----------------------
        if(!CommUtils.isBlank(bookingInfo.AccommodationName))
		//様
		mailString +=	' ' + bookingInfo.AccommodationName +Label.CONST_043_0030+ ( CommUtils.isBlank(bookingInfo.AccommodationCode) == true ? '' : '(' + bookingInfo.AccommodationCode + ')' );
        
        mailString +=   '\n';
//System.debug(LoggingLevel.INFO,'宿泊者情報::');
        //-------------------宿泊者情報----------------------
		//宿泊者情報：
        mailString +=   '\n' + '宿泊者情報：';
		/*
		if (!CommUtils.isBlank(bookingInfo.GuestOrGroupNameKanjiName)) {
			mailString += 	'\n' + bookingInfo.GuestOrGroupNameKanjiName
		}*/
        mailString +=   guestMsg;
        
        mailString +=   '\n';
//System.debug(LoggingLevel.INFO,'予約者情報::');
        //-------------------予約者情報----------------------
        if (bookingInfo.member != null ) {
            BI_TR_MemberInfo member = bookingInfo.member;
			//予約者情報：
			mailString += 	'\n' + Label.CONST_043_0032;
            if (!CommUtils.isBlank(member.UserName)) mailString +=  '\n' + member.UserName;
            if (!CommUtils.isBlank(member.UserKana)) mailString +=  '\n' + member.UserKana;
			//会社：
			if (!CommUtils.isBlank(member.UserCorp)) mailString += 	'\n' + Label.CONST_043_0033 +member.UserCorp;
			//会員番号：
			if (!CommUtils.isBlank(member.UserId)) 	mailString += 	'\n' + Label.CONST_043_0034 +member.UserId;
            if (!CommUtils.isBlank(member.UserTel)) mailString +=   '\n' + 'Tel：'+member.UserTel;
            if (!CommUtils.isBlank(member.UserMailAddr)) mailString +=  '\n' + 'Mail：'+member.UserMailAddr;
System.debug(LoggingLevel.INFO,'予約者情報:[MAIL]:'+member.UserMailAddr);
System.debug(LoggingLevel.INFO,'予約者情報:[ADDR]:'+member.UserAddr);
            if (!CommUtils.isBlank(member.UserAddr)) {
                mailString += '\n住所：';
                if (!CommUtils.isBlank(member.UserZip)) mailString += '(〒'+member.UserZip+')';
                mailString += member.UserAddr; 
            }
        }
        //-------------------プラン情報----------------------
        mailString +=   '\n';
		//プラン名：
		mailString += 	'\n' + Label.CONST_043_0035 + bookingInfo.PackagePlanName + '(' + bookingInfo.PackagePlanCode + ')' + '\n';
		Date ciDate = bookingInfo.CheckInDate;
		//yyyy年MM月dd日
		//から
		//泊
		mailString +=	'\n' + (DateTime.newInstance(ciDate.year(), ciDate.month(), ciDate.day())).format(Label.CONST_043_0012) + ' '+ Label.CONST_043_0036 + bookingInfo.Nights + Label.CONST_043_0037;
		// 食事関連
		String mealInfo = '';
		if (!CommUtils.isBlank(bookingInfo.MealCondition)) {
			String meal = bookingInfo.MealCondition;
			if (meal == '他') {
				if (!CommUtils.isBlank(bookingInfo.SpecificMealCondition)) {
					mealInfo =	' ' + bookingInfo.SpecificMealCondition;
				}
			} else mealInfo = meal + ' ' + CommUtils.nullToBlank(bookingInfo.SpecificMealCondition);
			mailString += mealInfo;
 		}
//System.debug(logginglevel.INFO, 'bookingInfo.basic.CheckInTime='+bookingInfo.basic.CheckInTime);
        // 税サ区分       
        if (!CommUtils.isBlank(bookingInfo.TaxServiceFee)) {
			String tax = bookingInfo.TaxServiceFee;
			//サ込税別
			if (tax == 'IncludingServiceWithoutTax') 	mailString +=	' サ込税別';
			//サ込税込
			else if (tax == 'IncludingServiceAndTax')	mailString +=	' サ込税込';
			//サ別税別
			else if (tax == 'WithoutServiceAndTax') 	mailString +=	' サ別税別';
			else if (tax == 'WithoutServiceAndIncludingTax') 	mailString +=	' サ別税込';
		}
		//入込方法：
		mailString += 	'\n' + Label.CONST_043_0042 + CommUtils.nullToBlank(bookingInfo.Transportaion);
        if (bookingInfo.CheckInTime != null)
		//チェックイン時間：
		mailString +=	' '+ Label.CONST_043_0043 + CommUtils.nullToBlank((DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm'));
		//人員総数：
		//人  内訳：
		mailString += 	'\n' + Label.CONST_043_0044 + CommUtils.nullToZero(bookingInfo.GrandTotalPaxCount)  + Label.CONST_043_0045 + roomAndGuestMsg
		//客室総数：
        + 	'\n' + Label.CONST_043_0046 + CommUtils.nullToZero(bookingInfo.TotalRoomCount);
		// OPTION 情報
		if (bookingInfo.optionLst != null && bookingInfo.optionLst.size() > 0) {
			//オブション情報
			mailString += '\n'+ Label.CONST_043_0047 ;
			for (BI_TR_Option opt : bookingInfo.optionLst) {
				mailString += '\n';
				//yyyy年MM月dd日
				mailString += (opt.OptionDate == null ? '' : (DateTime.newInstance(opt.OptionDate.year(), opt.OptionDate.month(), opt.OptionDate.day())).format(Label.CONST_043_0012))
							+ (CommUtils.isBlank(opt.Name) ? '' : ' ' + opt.Name)
							//個数：
							+ (opt.OptionCount == null ? '' : ' '+ Label.CONST_043_0048 + opt.OptionCount)
							//単価：
							+ (opt.OptionRate == null ? '' : ' '+ Label.CONST_043_0049 +  opt.OptionRate);
			}
		}
		// 料金区分
		String payUnitString = '';
        if (!CommUtils.isBlank(bookingInfo.RoomRateOrPersonalRate)) {
			//室単価
			if (bookingInfo.RoomRateOrPersonalRate == 'RoomRate') payUnitString = Label.CONST_043_0050;
			//人員単価
			else if (bookingInfo.RoomRateOrPersonalRate == 'PersonalRate') payUnitString = Label.CONST_043_0051;
        }
        mailString += '\n';
        mailString +=   roomMsg
                   + '\n-------------------------------------------------'
//-------------------ご確認事項----------------------
		//支払い方法：
				   + 	'\n' + Label.CONST_043_0052 +  CommUtils.nullToBlank(bookingInfo.Payment);
	   //料金区分：
		if (!Commutils.isBlank(payUnitString)) mailString += '\n' + Label.CONST_043_0053 + payUnitString;
		//ご確認事項：
		mailString +=	'\n' + '\n'+ Label.CONST_043_0054
		+	'\n' +  mealInfo;
        // 客室へリクエスト情報を作成する
        
		if (!CommUtils.isBlank(roomRequestMsg)) {
			mailString += roomRequestMsg;
		}
        if (!CommUtils.isBlank(bookingInfo.SpecialServiceRequest)) {
            mailString += '\n' + bookingInfo.SpecialServiceRequest;
        }
        /*if(!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficeName)){
            mailString += '\n' + '取扱個所：';
            mailString += '\n' + bookingInfo.salesOffice.SalesOfficeName + '(' + bookingInfo.salesOffice.SalesOfficeCode + ')';
            if (!CommUtils.isBlank(bookingInfo.salesOffice.SalesOfficePhoneNumber)) mailString += '     TEL' + bookingInfo.salesOffice.SalesOfficePhoneNumber;
        }*/
//System.debug(LoggingLevel.INFO,'========>\n  '+mailString);
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
	
	// 2016/06/20 EDIT BEGIN
	private static AccountMaster__c getShiTuLyouAcc(){
        List<AccountMaster__c> shituLyoAccs = ProductItemUtils.getRoomRateProduct(CommConst.APPOPTION_ROOMPRICE_PRODNAME);
        if(shituLyoAccs.isEmpty()) return new AccountMaster__c();
        else return shituLyoAccs[0]; 
    }
    // サビース料商品
    private static AccountMaster__c getServiceAcc(){
        String accountCd = BI_TR_ServiceConfigHelp.getAccountConfig(shopCd).serviceCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    // 入湯税商品
    private static AccountMaster__c getNyuuTouAcc(){
        String accountCd = BI_TR_ServiceConfigHelp.getAccountConfig(shopCd).nyuuTouCd;
        if (CommUtils.isBlank(accountCd)) return new AccountMaster__c();
        List<AccountMaster__c> acc = [select Name,Id,Field5__c,TaxRateCal__c,ServiceRate__c  from AccountMaster__c where Field3__c = :accountCd  limit 1];
        if(acc.isEmpty()) return new AccountMaster__c();
        return acc[0];
    }
    
    // 自動割り振りできる部屋リスト情報を取得する
    // 故障部屋は自動割当て機能に追加対応 BEGIN
      private static map<Integer,Room__c> getCanAssignRoom(LeadIndex__c leadIndex, Map<String,Id> roomTypeMap, boolean autoAssingRoomflag, BI_TR_SyncInfo bookingInfo){
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::getCanAssignRoom----------');            
        map<Id, Id> targetRoomIdTypeMap = new map<Id, Id>();
        map<Id, List<Room__c>> wkCanAssignRoomMap = new map<Id, List<Room__c>>();
        map<Integer,Room__c> resultMap = new map<Integer, Room__c>();
        List<Id> roomTypeIdLst = roomTypeMap.values();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::roomTypeIdLst----------' + roomTypeIdLst);
        String sortField = BI_TR_ServiceConfigHelp.getAppConfig(shopCd).roomSortKey;
System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::sortField----------' + sortField);
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
        Integer nights = bookingInfo.Nights;            // 総宿泊数
        if (nights == 0) nights = 1;
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::nights----------' + nights);
        Integer rooms = bookingInfo.roomAndGuestLst.size();
//System.debug(loggingLevel.INFO,'-------------::::::::::::::::::::::::rooms----------' + rooms);
        // 部屋単位に、宿泊期間内の部屋タイプリスト一覧情報を格納する
        //map<Integer, list<string>> tmpRoomTypeListMap = new map<Integer, list<string>>();
        map<Integer, string> tmpRoomTypeMap = new map<Integer, string>();
        // 宿泊期間情報を格納する、1部屋A：1/1,1/2,1/3日は同じ部屋タイプすると、0,1,2は同じリストを格納する<1, <1/1,1/2,1/3>, 2,<1/1,1/2,1/3>>...
        map<Integer, list<date>> roomTypeDateLinkByIdxMap = new map<Integer, list<date>>();
        BI_TR_RoomAndGuestInfo[] roomAndGuest = bookingInfo.roomAndGuestLst;
        for(Integer j = 0; j < rooms; j ++){
            BI_TR_RoomAndGuestInfo roomAndGuestInfo = roomAndGuest[j];
            // 該当部屋に指定の部屋タイプコード[TAの場合、１部屋１部屋タイプコード方式するため]
            tmpRoomTypeMap.put(j,roomAndGuestInfo.room.RoomTypeCode);
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
            }
        }
        // 自動割当可能の部屋IDを格納する
        set<id> isAutoAssignRoomtSet = new set<Id>();
        for (list<Room__c> canAssRooms : canAssignRoomMap.values()) {
            for (Room__c canAssRoom : canAssRooms) {
                isAutoAssignRoomtSet.add(canAssRoom.id);
            }
        }
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
        return resultMap;
     }
    
    

	
	// 小数桁数はシステム定義により、長い場合、単数処理後の処理値は検証する
	private static Decimal checkIfHadScale(Decimal orgPrice,Decimal taxRate,Decimal serviceRate,Integer kbn){
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
	private static List<Lead__c> filterTRImportData(List<Lead__c> orgLst , BI_TR_SyncInfo bookingInfo,LeadIndex__c leadIndex, Set<Id> pSubLeadIds){
		System.debug(LoggingLevel.INFO,'-----------filterTRImportData begin----------');
		// 予約番号比較用: TL_99999999
//		String dataId = bookingDataId;
//		System.debug(LoggingLevel.INFO,'-----------dataId----------' + dataId);
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
			if(!CommUtils.isBlank(lead.BookingDataID__c) && lead.BookingDataID__c == bookingDataId){
				filterLst.add(lead);
				filterIdSet.add(lead.id);
			}
		}
		
		// 予約番号を登録されている予約情報がない場合
		if(filterLst.isEmpty()){
			for(Lead__c lead : orgLst){
				// 予約インデックスSUBのIDをチェックが必要
				if (!pSubLeadIds.contains(lead.LeadIndexSubId__c)) continue;
				// 予約の発生源情報を登録　かつ　TR経由で作成の予約情報場合
				if(!CommUtils.isBlank(lead.EventSource__c) && lead.EventSource__c.contains(APPNAME)){
					filterLst.add(lead);
					filterIdSet.add(lead.id);
				}
			}
		}
		// 予約情報予約番号登録なし　OR　TR発生源も登録なしの予約情報に対して、
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
					System.debug(LoggingLevel.INFO,'関連更新対象外予約ID='+lead.id);
				}
			}
		}
		System.debug(LoggingLevel.INFO,'-----------filterTRImportData end----------');
		return filterLst;
	}
	// 2016/06/20 EDIT END
	
	// 2016/09/30 EDIT BEGIN
	private static String formatPlanName(String planName) {
		planName = CommUtils.nullToBlank(planName);
		return (planName.length() > 80 ? planName.substring(0,80) : planName);
	}
	// 2016/09/30 EDIT END
	
    global class BI_TR_SyncInfo {
        //情報区分 TransactionType
        webservice String DataFrom;   //送り元区分	
        webservice String DataClassification;  //データ種別
        webservice BI_TR_DmlAction dmlAction;
        webservice String DataID;  //データID		
		webservice Date SystemDate;  //システム日付	
		webservice Time SystimTime;  //システム時刻[廃止、使わない]	
		webservice Time SystemTime;  //システム時刻
		
        // 宿泊施設側情報
        webservice String AccommodationArea;  //宿泊地区名		
		webservice String AccommodationName;  //宿泊施設名		
		webservice String AccommodationCode;  //宿泊施設コード		
		webservice String ChainName;  //チェーンホテル名		
		webservice String AccommodationPersonInCharge;  //宿泊施設担当者名		
		webservice String AccommodationEmail;  //宿泊施設担当者Email		
		webservice String AccommodationPhoneNumber;  //宿泊施設電話番号		
		webservice String AccommodationCPUAddress;  //宿泊施設宛先指定
		
		// 振込銀行情報 BankList	
		webservice List<BI_TR_BankInformation> bankList;
		
        //  旅行会社情報
        webservice String SalesOfficeCompanyCode;  //旅行会社コード		
		webservice String SalesOfficeCompanyName;            //旅行会社名		
		webservice String SalesOfficeName;            //旅行会社営業所名		
		webservice String SalesOfficeCode;            //旅行会社営業所コード		
		webservice String SalesOfficePersonInCharge;            //旅行会社営業所担当者名		
		webservice String SalesOfficeEmail;            //旅行会社営業所担当者Email		
		webservice String SalesOfficePhoneNumber;            //旅行会社営業所電話番号		
		webservice String SalesOfficeFaxNumber;            //旅行会社営業所FAX番号		
		webservice String SalesOfficeStateProvidence;            //旅行会社営業所住所都道府県		
		webservice String SalesOfficeCityName;            //旅行会社営業所住所区市名		
		webservice String SalesOfficeAddressLine;            //旅行会社営業所住所町村名
		webservice String SalesOfficeStreetNumber;            //旅行会社営業所住所番地名		
		webservice String SalesOfficePostalCode;            //旅行会社営業所住所郵便番号		
		webservice String SalesOfficeRegisteredCategory;            //旅行会社登録種別		
		webservice String SalesOfficeLicenseNumber;            //旅行会社登録番号		
		webservice String SalesOfficeRegisteredPrefecture;            //旅行会社登録行政庁		
		webservice String SalesOfficeCPUAddress;            //旅行会社宛先指定		
		webservice String RetailerCompanyName;            //販売代理店会社名		
		webservice String RetailerOfficeName;            //販売代理店営業所名		
		webservice String RetailerOfficeCode;            //販売代理店営業所コード		
		webservice String RetailerPersonInCharge;            //販売代理店担当者名		
		webservice String RetailerEmail;            //販売代理店担当者Email		
		webservice String RetailerPhoneNumber;            //販売代理店電話番号		
		webservice String RetailerStateProvidence;            //販売代理店住所都道府県		
		webservice String RetailerCityName;            //販売代理店住所区市名		
		webservice String RetailerAddressLine;            //販売代理店住所町村名		
		webservice String RetailerStreetNumber;            //販売代理店住所番地名		
		webservice String RetailerPostalCode;            //販売代理店住所郵便番号		
		webservice String RetailerRegisteredCategory;            //販売代理店登録種別		
		webservice String RetailerLicenseNumber;            //販売代理店登録番号		
		webservice String RetailerRegisteredPrefecture;            //販売代理店登録行政庁	
        
        // 基本宿泊情報
        webservice String TravelAgencyBookingNumber;      // 旅行会社予約(管理)番号		
		webservice Date TravelAgencyBookingDate;          //旅行会社予約受付日		
		webservice Time TravelAgencyBookingTime;           //旅行会社受付時間
		webservice String TravelAgencyReportNumber;            //通知番号		
		webservice String AccommodationConfirmationNumber;            //宿泊個所予約番号		
		webservice String GuestOrGroupNameSingleByte;            //団体名または代表者氏名(半角)		
		webservice String GuestOrGroupNameDoubleByte;            //団体名または代表者氏名よみがな(全角)		
		webservice String GuestOrGroupNameKanjiName;            //団体名または代表者氏名 漢字		
		webservice String GroupNameWelcomeBoard;            //団体名(ウェルカムボード用)			
		webservice Date CheckInDate;            //チェックイン日	
		webservice Time CheckInTime;            //チェックイン時間	
		webservice Date CheckOutDate;            //チェックアウト日	
		webservice Time CheckOutTime;            //チェックアウト時間	
		webservice Integer Nights;            //宿泊日数	
        webservice String Transportaion;            //入込方法	
		webservice Integer CoachCount;            //入込バス台数	
		webservice String CoachCompany;            //入込バス会社名	
		webservice Integer TotalRoomCount;            //利用客室合計数		
		webservice Integer GrandTotalPaxCount;            //お客様総合計人数
        // 2013/12/29 ADD BEGIN
        webservice Integer TotalPaxMaleCount;            //大人人員（男性）合計		
		webservice Integer TotalPaxFemaleCount;            //大人人員（女性）合計		
		webservice Integer TotalChildA70Count;            //子供A人数合計		
		webservice Integer TotalChildB50Count;            //子供B人数合計		
		webservice Integer TotalChildC30Count;            //子供C人数合計		
		webservice Integer TotalChildDNoneCount;            //子供D人数合計		
		webservice Integer TotalChildECount;            //子供E人数合計		
		webservice Integer TotalChildFCount;            //子供F人数合計		
		webservice Integer TotalChildOtherCount;            //子供その他人数合計
        webservice String Status;            //予約ステータス	
        // 2013/12/29 ADD END
        webservice Integer TotalTourConductorCount;            //添乗員人数合計		
		webservice Integer TotalCoachDriverCount;            //バスドライバー人数合計		
		webservice Integer TotalGuideCount;            //バスガイド人数合計		
		webservice String TypeOfGroup;            //参加形態	
		webservice String PackageType;            //企画商品区分
        webservice String PackagePlanName;            //企画(パッケージ)名		
		webservice String PackagePlanCode;            //企画(パッケージ)コード	
		webservice String PackagePlanContent;            //企画(パッケージ)内容
        webservice String MealCondition;            //食事条件
        webservice String SpecificMealCondition;            //食事有無情報
        webservice String MealPlace;            //食事個所情報		
		webservice String BanquetRoom;            //宴会場利用		
		webservice String ModificationType;            //変更点区分
        webservice String ModificationPoint;            //変更ポイント説明	
        webservice String CancellationNumber;            //宿泊施設取消番号		
		webservice String PreviousPlace;            //前泊地		
		webservice String PreviousAccommodationName;            //前泊宿泊施設名
        // 電文(予約詳細： 一日ごとの大人子供人数の内訳、料金詳細などを出力する。 予約詳細情報は最初の情報が「ZZ」で始まり「,ZZ」で区切られる。)
        webservice String SpecialServiceRequest;
        // 備考
        webservice String OtherServiceInformation;
        webservice String FollowUpInformation;            //詳細情報有無		
		//webservice String TravelAgencyEmail;            //旅行会社作成の予約情報メール
        
        //オプション情報
		webservice List<BI_TR_Option> optionLst;
        
        // 基本情報 BasicRateInformation
        webservice String RoomRateOrPersonalRate;            //料金区分	       
        webservice String TaxServiceFee;            //税サ区分		
		webservice String Payment;            //支払い方法		
		webservice Integer BareNetRate;            //ネット決済額		
		webservice String CancellationCharge;            //前広取消に対する取消料情報		
		webservice String CreditCardAuthority;            //クレジットカード会社名		
		webservice String CreditCardNumber;            //クレジットカード番号		
		webservice String ExpireDate;            //クレジットカード有効期限		
		webservice String CardHolderName;            //クレジットカード保有者氏名		      
		webservice Integer TotalAccommodationCharge;            //合計宿泊料金(総額)		
		webservice Integer TotalAccommodationConsumptionTax;            //合計宿泊料金消費税		
		webservice Integer TotalAccommodationHotSpringTax;            //合計宿泊料金入湯税		
		webservice Integer TotalAccommodationHotelTax;            //合計宿泊料金ホテル税他		
		webservice Integer TotalAccommodationServiceFee;            //合計宿泊料金サービス料		
		webservice Integer TotalAccommodationBreakfastFee;            //合計朝食料金		
		webservice Integer TotalAccommodationOtherFee;            //合計その他料金		
		webservice Decimal CommissionPercentage;            //手数料率(%)		
		webservice Integer TotalAccommodationCommissionAmount;            //合計手数料総額		
		webservice Integer TotalAccommodationCommissionConsumptionTax;            //合計手数料消費税総額		
		webservice Integer TotalAccommodationChargeAfterCheckIn;            //宿泊当日変更後の宿泊料金(総額)		
		webservice Integer TotalBalanceAfterCheckIn;            //宿泊当日変更後の宿泊料金(差額)		
		webservice Integer TotalAccommodationConsumptionAfterCheckIn;            //宿泊当日変更後の手数料消費税		
		webservice Integer CancellationChargeAfterCheckIn;            //宿泊当日取消に対する取消料情報		
		webservice String MembershipFee;            //定率会費		
		webservice String AdjustmentFee;            //精算調整額		
		
        // クーポン明細 0:N
		webservice List<BI_TR_CouponInformation> couponList;
        // 個々の部屋とお客様情報<1:N>
        webservice List<BI_TR_RoomAndGuestInfo> roomAndGuestLst;
        // Member
        webservice BI_TR_MemberInfo member;
    }
    
    //振込銀行情報
	global class BI_TR_BankInformation {
		webservice String BankName;  //振込銀行名	
		webservice String BankAcountNumber;  //口座番号	
		webservice String BankBranchName;  //振込銀行支店名	
		webservice String BankAccountClassification;  //振込銀行口座種別	
		webservice String BankAccountName;  //口座名		
	}
	
    //オプション情報
    global class BI_TR_Option {
    	webservice Date OptionDate;            //オプション利用年月日	
		webservice String Name;            //オプション名称	
		webservice String NameRequest;            //オプション名備考	
		webservice Integer OptionCount;            //オプション個数	
		webservice Integer OptionRate;            //オプション料金単価
    }
    
    // クーポン明細
	global class BI_TR_CouponInformation {
		webservice String CouponAmount;            //クーポン券面額	
		webservice String CouponType;            //クーポン種類	
		webservice String CouponNumber;            //クーポン番号	
		webservice String CouponIssueDate;            //クーポン発行日			
	}
    
    // １部屋利用情報
    global class BI_TR_RoomAndGuestInfo {
        webservice BI_TR_RoomsInfo room;
        webservice List<BI_TR_RoomRateInfomation> roomRateLst;
        webservice List<BI_TR_GuestInfo> guestLst;
    }
    // 部屋情報
    global class BI_TR_RoomsInfo{
		webservice String RoomTypeCode;            //部屋タイプコード	
		webservice String RoomTypeName;            //部屋タイプ名	
		webservice String RoomCategory;            //部屋カテゴリー	
		webservice String ViewType;            //部屋眺望	
		webservice String SmokingOrNonSmoking;            //喫煙/禁煙	
		webservice Integer PerRoomPaxCount;            //1室利用人数	
		webservice Integer RoomPaxMaleCount;            //大人人員(男性)			
		webservice Integer RoomPaxFemaleCount;            //大人人員(女性)		
		webservice Integer RoomChildA70Count;            //子供A人数		
		webservice Integer RoomChildB50Count;            //子供B人数		
		webservice Integer RoomChildC30Count;            //子供C人数		
		webservice Integer RoomChildDNoneCount;            //子供D人数		
		webservice Integer RoomChildECount;            //子供E人数		
		webservice Integer RoomChildFCount;            //子供F人数		
		webservice Integer RoomChildOtherCount;            //子供その他人数		
        webservice String RoomByRoomStatus;            //部屋毎予約ステイタス				
		webservice String RoomByRoomConfirmationNumber;            //部屋毎予約番号
        webservice String Facilities;             // その他設備：複数存在場合、[,]連結して、設定を行う
        webservice String AssignedRoomNumber;     //部屋割り後客室名/番号
        webservice String RoomSpecialRequest;     // 客室に対する特別リクエスト：複数存在場合、[,]連結して、設定を行う
		webservice String RoomTypeAgent;            //在庫引落し先旅行会社コード	
    }
    // 1部屋の部屋料金情報(1:N){連泊}
    global class BI_TR_RoomRateInfomation {
        webservice Date RoomDate;            //利用年月日		
		webservice Integer PerPaxRate;            //大人一人料金
        webservice Integer PerChildA70Rate;            //子供A一人料金		
		webservice Integer PerChildB50Rate;            //子供B一人料金				
		webservice Integer PerChildC30Rate;            //子供C一人料金		
		webservice Integer PerChildDRate;            //子供D一人料金		
		webservice Integer PerChildERate;            //子供E一人料金		
		webservice Integer PerChildFRate;            //子供F一人料金		
		webservice Integer PerChildOtherRate;            //子供その他一人料金		
		webservice Integer TotalPerRoomRate;            //1室あたり宿泊料金合計	
        webservice Integer TotalPerRoomConsumptionTax;            //1室あたり宿泊料金消費税合計	
        webservice Integer TotalRoomHotSpringTax;		// 廃止、	TotalPerlRoomHotSpringTaxで対応する
		webservice Integer TotalPerlRoomHotSpringTax;            //1室あたり宿泊料金入湯税合計		
		webservice Integer TotalPerRoomHotelTax;            //1室あたり宿泊料金ホテル税他合計	
        webservice Integer TotalPerRoomServiceFee;            //1室あたり宿泊料金サービス料合計		
		webservice Integer TotalPerRoomBreakfastFee;            //1室あたり朝食料金合計		
		webservice Integer TotalPerRoomOtherFee;            //1室あたりその他料金合計		
		webservice Integer TotalPerRoomCommissionAmount;            //1室あたり手数料総額		
		webservice Integer TotalPerRoomCommissionConsumptionTax;            //1室あたり手数料消費税額		
        webservice List<BI_TR_RoomRateDetailInfomation> detailInfoLst;
    }
    
    //料金詳細情報*2
    global class BI_TR_RoomRateDetailInfomation {
    	webservice Integer RateCategory;           //大人子供区分
    	webservice Integer RoomRate;               //一人料金
    	webservice Integer RatePaxCount;           //人数
    	webservice String  RateDetailInformation;  //料金詳細情報
    }
    
    // 顧客情報
    global class BI_TR_GuestInfo {
        webservice String GuestNameSingleByte;            //お客様氏名半角カタカナ英字(姓名)		
		webservice String GuestSurName;            //お客様氏名全角ふりがな(姓)		
		webservice String GuestGivenName;            //お客様氏名全角ふりがな(名)		
		webservice String GuestMiddleName;            //お客様氏名半角英字(ミドルネーム)		
		webservice String GuestNamePrefix;            //お客様肩書き		
		webservice String GuestKanjiName;            //お客様氏名全角漢字(姓名)		
		webservice String GuestGender;            //お客様男女区分		
		webservice Integer GuestAge;            //お客様年齢		
		webservice Date GuestDateOfBirth;            //お客様生年月日		
		webservice String GuestType;            //お客様人員区分		
		webservice String GuestShubetsu;            //お客様種別		
		webservice String GuestPhoneNumber;            //お客様電話番号		
		webservice String GuestEmergencyPhoneNumber;            //お客様緊急連絡先		
		webservice String GuestEmail;            //お客様Email		
		webservice String GuestCountry;            //お客様国籍		
		webservice String GuestStateProvidence;            //お客様住所都道府県		
		webservice String GuestCityName;            //お客様住所区市名		
		webservice String GuestAddressLine;            //お客様住所町村名		
		webservice String GuestStreetNumber;            //お客様住所番地名		
		webservice String GuestPostalCode;            //お客様住所郵便番号		
		webservice String GuestBuildingName;            //お客様住所ビル・部屋名		
		webservice String GuestFFPCarrier;            //お客様FFPキャリア		
		webservice String GuestFFPNumber;            //お客様FFPNo.		
		webservice String GuestCoachNumber;            //お客様バス号車番号		
		webservice String SpecialInformation;            //お客様特記情報	
    }
    
    // 予約者・会員情報
    global class BI_TR_MemberInfo {
    	webservice String UserName;            //予約者・会員名漢字		
		webservice String UserKana;            //予約者・会員名カタカナ		
		webservice String UserTel;            //予約者・会員電話番号		
		webservice String UserMailAddr;            //予約者・会員Email		
		webservice String UserZip;            //予約者・会員郵便番号		
		webservice String UserAddr;            //予約者・会員住所		
		webservice String UserCorp;            //予約者・会員会社		
		webservice String UserDep;            //予約者・会員所属部署		
		webservice String UserID;            //予約者・会員番号		
		webservice String VIPCode;            //VIPコード		
		webservice String PointCompanyName;            //充当先		
		webservice String PointName;            //ポイント名称		
		webservice Integer UserGivinPoints;            //付与ポイント		
		webservice Integer UserUsePoints;            //使用ポイント		
		webservice Integer TotalAccommodationDecleasePoints;            //ポイント割引後の総額		
		webservice Integer TotalAccommodationConsumptaionTax;            //ポイント割引後の総額に対する消費税額		
		webservice Integer AmountClaimed;            //宿泊者請求額		
		webservice String ChargeEquation;            //宿泊料金計算式	
		
		// 使用ポイントリスト  0:N
		webservice List<BI_TR_UserUsePointInformation> userUsePointList;
    }
    
    //使用ポイントリスト情報
	global class BI_TR_UserUsePointInformation {
		webservice String PointName;  //ポイント名称 	
		webservice Integer UserUsePoint;  //ポイント金額 	
		
	}

    global class BI_TR_SyncResult {
        // 処理結果
        webservice BI_TR_Result result;
        webservice Id sfdcId;
        webservice String message;
        webservice Id sfdcJobId;
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    global enum BI_TR_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    global enum BI_TR_DmlAction{INS, UPD, CANCEL}
    // 2017/06/30 XML特殊記号文字UTF-8対応 BEGIN
    static void unescapeXmlProcess(BI_TR_SyncInfo bookingInfo) {
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
    	List<BI_TR_BankInformation> bankLst = bookingInfo.bankList;
        if(bankLst != null){
        	for(BI_TR_BankInformation bank : bankLst){
	            bank.BankName = unescapeXml(bank.BankName);  				
				bank.BankAcountNumber = unescapeXml(bank.BankAcountNumber);				
				bank.BankBranchName	= unescapeXml(bank.BankBranchName);				
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
		bookingInfo.AccommodationConfirmationNumber	= unescapeXml(bookingInfo.AccommodationConfirmationNumber);			
		bookingInfo.GuestOrGroupNameSingleByte = unescapeXml(bookingInfo.GuestOrGroupNameSingleByte);     			
		bookingInfo.GuestOrGroupNameDoubleByte = unescapeXml(bookingInfo.GuestOrGroupNameDoubleByte);     			
		bookingInfo.GuestOrGroupNameKanjiName = unescapeXml(bookingInfo.GuestOrGroupNameKanjiName);      			
		bookingInfo.GroupNameWelcomeBoard = unescapeXml(bookingInfo.GroupNameWelcomeBoard);          			
		bookingInfo.Transportaion = unescapeXml(bookingInfo.Transportaion);    			
		bookingInfo.CoachCompany = unescapeXml(bookingInfo.CoachCompany);     			
		bookingInfo.Status = unescapeXml(bookingInfo.Status);           			
		bookingInfo.TypeOfGroup = unescapeXml(bookingInfo.TypeOfGroup);      			
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
    	//オプション情報
    	List<BI_TR_Option> optionLst = bookingInfo.optionLst;
    	if(optionLst != null){
    		for(BI_TR_Option option : optionLst){
	            option.Name= unescapeXml(option.Name);       
				option.NameRequest= unescapeXml(option.NameRequest);				
        	}
    	}
    	// 基本情報 BasicRateInformation
    	bookingInfo.RoomRateOrPersonalRate= unescapeXml(bookingInfo.RoomRateOrPersonalRate); 				
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
    	List<BI_TR_CouponInformation> couponLst = bookingInfo.couponList;
    	if(couponLst != null){
    		for(BI_TR_CouponInformation coupon : couponLst){
	    		coupon.CouponAmount = unescapeXml(coupon.CouponAmount);   			
				coupon.CouponType = unescapeXml(coupon.CouponType);     			
				coupon.CouponNumber = unescapeXml(coupon.CouponNumber);   			
				coupon.CouponIssueDate	= unescapeXml(coupon.CouponIssueDate);			
    		}
    	}
    	// 個々の部屋とお客様情報<1:N>
		for(BI_TR_RoomAndGuestInfo roomGuestInfo : bookingInfo.roomAndGuestLst){
			// 部屋情報
			BI_TR_RoomsInfo roomInfo = roomGuestInfo.room;
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
			// 1部屋の部屋料金情報(1:N){連泊}
			List<BI_TR_RoomRateInfomation> roomRateLst = roomGuestInfo.roomRateLst;
			if(roomRateLst != null){
				for(BI_TR_RoomRateInfomation roonRate : roomRateLst){
		    		//料金詳細情報*2
		    		List<BI_TR_RoomRateDetailInfomation> roomRateDetailLst = roonRate.detailInfoLst;		
	    			if(roomRateDetailLst != null){
	    				for(BI_TR_RoomRateDetailInfomation roomRateDetail : roomRateDetailLst){
				    		roomRateDetail.RateDetailInformation = unescapeXml(roomRateDetail.RateDetailInformation);   			
				    	}
	    			}
	    		}
			}
    		// 顧客情報
    		List<BI_TR_GuestInfo> guestLst = roomGuestInfo.guestLst;
    		if(guestLst != null){
    			for (BI_TR_GuestInfo guest : guestLst) {
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
    		
		}
        // Member    
        BI_TR_MemberInfo member = bookingInfo.member;    
        if(member != null){
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
			member.PointName  = unescapeXml(member.PointName);       				
			member.ChargeEquation = unescapeXml(member.ChargeEquation);
			List<BI_TR_UserUsePointInformation> userUsePointLst = member.userUsePointList;
			if(userUsePointLst != null){
				for(BI_TR_UserUsePointInformation userUsePoint : userUsePointLst){
					userUsePoint.PointName = unescapeXml(userUsePoint.PointName);
				}  
			}
        }
    }
    static string unescapeXml(String s) {
        if (CommUtils.isBlank(s)) return s;
        return s.unescapeXml();
    }
    // 2017/06/30 XML特殊記号文字UTF-8対応 END
    // 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH BEGIN
	static void convertGuestInfo(BI_TR_SyncInfo bookingInfo) {
        // 宿泊施設側情報
        // 振込銀行情報 BankList
        // 旅行会社情報
        // 基本宿泊情報
        bookingInfo.GuestOrGroupNameKanjiName = CommStringUtils.convertRomanToKana(bookingInfo.GuestOrGroupNameKanjiName, true);
        // オプション情報
        // 基本情報 BasicRateInformation
        // クーポン明細 0:N
        // 個々の部屋とお客様情報<1:N>
        for (BI_TR_RoomAndGuestInfo roomGuestInfo: bookingInfo.roomAndGuestLst) {
            // 部屋情報
            // 1部屋の部屋料金情報(1:N){連泊}
            // 顧客情報
            //BI_TR_GuestInfo guest = roomGuestInfo.guest;
            //if (guest != null) {
                List<BI_TR_GuestInfo> guestInfoLst = roomGuestInfo.guestLst;
                if (guestInfoLst != null) {
                    for (BI_TR_GuestInfo guestInfo: guestInfoLst) {
                        guestInfo.guestKanjiName = CommStringUtils.convertRomanToKana(guestInfo.guestKanjiName, true);
                    }
                }
                //guest.GuestKanjiName = CommStringUtils.convertRomanToKana(guest.GuestKanjiName, true);
            //}
        }
        // Member    
        BI_TR_MemberInfo member = bookingInfo.member;
        if (member != null) {
            member.UserName = CommStringUtils.convertRomanToKana(member.UserName, true);
        }
	}
	// 2019/12/30 ローマ字で入ってきたお客様名をカタカナに変換機能の追加 ZH END
}