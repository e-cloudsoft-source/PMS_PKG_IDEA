public with sharing class K_ScheduleCookingHelper {
    private final String shopCode;              // 店舗コード
    private final Date pQueryDt;                // 指定日
    private final Boolean isEstQueryFlg;        // 見積明細抽出フラグ
    // 定時なスケジール定義ができない
    // バッチリクエストから
    public K_ScheduleCookingHelper(Date queryDt, String pShopCd) {
        shopCode = pShopCd;
        pQueryDt = queryDt;
    }
    // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
	public boolean isEnLanguage = false;
	// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
    // 「ロジック処理用、非可変」見積もり明細情報を取得用ＳＱＬ
    // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
    //private static final String queryLdStr = ' Select ParentBookingItemRef__c, Field3__c, ActionType__c, ProductName__c, Amount__c, UnitPrice__c, NoneAccount__c, OP__c, OP__r.Name, refAccountMaster__c, refAccountMaster__r.Name,refAccountMaster__r.Field3__c,SpTotal__c FROM BookingEstimateItemFgKu__r ';
    // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    private static final String queryLdStr = ' Select ParentBookingItemRef__c, Field3__c, ActionType__c, ProductName__c, Amount__c, UnitPrice__c, NoneAccount__c, OP__c, OP__r.Name, refAccountMaster__c, refAccountMaster__r.Name,refAccountMaster__r.ProductEnName__c,refAccountMaster__r.Field3__c,SpTotal__c,refAccountMaster__r.GPChange__r.Field1__c , refAccountMaster__r.DPChange__r.Field1__c,refAccountMaster__r.OP__r.OPcode1__c,refAccountMaster__r.Field4__r.Field1__c,CookInfo__c FROM BookingEstimateItemFgKu__r ';
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    // 2018/02/07 オーダーエントリー画面の英語対応 by zy END
    // 「ロジック処理用、非可変」集計対象の会計明細情報を統計する
    //private static final String queryTranStr = ' Select Field1__r.Name, Field1__c, Id, Name,Field41__c,ParentTran1Ref__c,Field7__r.OP__c,Field1__r.Relreserve__c,Field7__c,Field7__r.Name,Field7__r.Field3__c,Field7__r.PaymentType__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,Field5__c,Field40__c,Field23__c,Field20__c From Tran1__c ';
    // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    // 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
    private static final String queryTranStr = ' Select Field1__r.Name,Field7__r.ProductEnName__c, Field1__c, Id, Name,Field41__c,ParentTran1Ref__c,Field7__r.OP__c,Field1__r.Relreserve__c,Field7__c,Field7__r.Name,Field7__r.Field3__c,Field7__r.PaymentType__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,Field5__c,Field40__c,Field23__c,Field20__c , Field7__r.GPChange__r.Field1__c , Field7__r.DPChange__r.Field1__c,Field7__r.OP__r.OPcode1__c,Field7__r.Field4__r.Field1__c,CookInfo__c,Field21__c,Field1__r.CreatedDate From Tran1__c ';
    // 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
    // 2017/10/24 多印刷メッセージ放出機能追加 by zy END
    // 「ロジック処理用、非可変」予約情報取得用項目リスト
    // 部屋名、お客様名、予約番号、到着時刻、アレルギー（料理補足）、予約ID
    // 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
    private static final String queryConstLeadStr = 'Name,Rroom__r.Name,Rroom__c, Relcontact__r.Name, No__c, Field4__c, Field354__c, Id, DayNightCal__c, Field278__c, Field298__c ';
    // 2019/09/15 部屋の並び順をSeq#順に by zy END
    /* 部屋リスト情報を格納する */
    private transient List<Room__c> roomList;
    /** 朝食判断用会計ＯＰのID */
    private transient Set<Id> moringFoodOpIdSet = new Set<Id>();
    /** 予約情報を取得用ＳＱＬ */
    private static String queryLeadStr;
    // 処理がどうか判別用情報を格納用リスト
    private static List<String> filterOpList = new List<String>();
    // 朝食の商品コード
    private static final String CONST_OTHER_CD = 'A_';
    private static final String CONST_MON_FOOD_CD = 'Z_ZZZZZZ';
    // チェックイン後の予約データの料理集計は分けるがどうか判別する
    private static final Boolean cookInfoSplitShow = false;
    // 料理集計種別コード取得する
    private static final String cookingSummyCode = '2';
    // 予定表料理項目商品並べ順表示方式
    private static final String cookFieldSortDiv = CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleCookFieldSortDiv__c;
    // 指定日の見積明細情報JSON情報を取得する
    // 2017/10/16 bug fix アレルギー対応　by　zy BEGIN
    public List<OrderServiceHelp.BulkPrintUIInfo> queryEstLead(){
   	// 2017/10/16 bug fix アレルギー対応　by　zy END
        return queryEstLead(null);
    }
    public List<OrderServiceHelp.BulkPrintUIInfo> queryEstLead(OrderServiceHelp.PrintInfo print) {
    	pntInfo = print;
   	// 2017/10/16 bug fix アレルギー対応　by　zy END
        return queryLead(true);
    }
    // 2017/10/16 bug fix アレルギー対応　by　zy BEGIN
    private OrderServiceHelp.PrintInfo pntInfo;
    // 指定日の料理情報JSON情報を取得する
    public List<OrderServiceHelp.BulkPrintUIInfo> queryFoodInfo(OrderServiceHelp.PrintInfo print) {
    	pntInfo = print;
    // 2017/10/16 bug fix アレルギー対応　by　zy END
        return queryLead(false);
    }
    // 2018/08/31 料理進捗機能追加　by zy BEGIN
    public List<ReportRow> queryCookItem(List<Id> leadLst,Map<String,String> prodToPosMap,Set<String> cookProdSet){
    	// 指定の店舗コードで取得、関連の予約情報を出力する
        // 既存固定定義している予約検索のＳＱＬを取得する
        queryLeadStr = queryConstLeadStr;
        // 固定定義されている項目リストを取得する
        String[] constLeadFields = queryLeadStr.deleteWhitespace().split(',');
        // カスタム項目をＳＱＬへ追加する
        for (String field : constLeadFields) {
            String key = field;
        }
	    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
        Set<String> noLeadSet = new Set<String>();
        if (otherLeadFields != null && !otherLeadFields.isEmpty()) {
           Set<String> exitSet = new Set<String>(constLeadFields); 
           for (String filed : otherLeadFields) {
               if (!exitSet.contains(filed)) {
                   exitSet.add(filed);
                   noLeadSet.add(filed);
               }
           }
           queryLeadStr = String.join(new List<String>(exitSet),',');
        }
	// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
        // -------------------------------------
        // 料理集計設定情報を取得する
        // -------------------------------------
        // 料理抽出条件を設定する場合、該当条件でデータ抽出を行う
        String whereStr = CommConst.getKScheduleReportWhere();
        // 朝食キー
        Set<String> moringFoodkeySet = new Set<String>();
        if (!String.isEmpty(whereStr)) {
            String[] whereLst = whereStr.split(',');
            filterOpList.clear();
            for (String key : whereLst) {
                String[] subKey = key.split(':');
                filterOpList.add(subKey[0]);
                // 朝食キーが存在
                if (subKey.size() > 1) moringFoodKeySet.add(subKey[0]);
            }
        }
        // 指定朝食キー対応
        if (!cookProdSet.isEmpty()) {
        	moringFoodkeySet = cookProdSet;
        	filterOpList = new List<String>(cookProdSet);
        }
	    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
        // 会計OP指定
        Set<Decimal> opts = new Set<Decimal>();
	    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	    // 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN	
        Set<Decimal> roomTypeSet = new Set<Decimal>();
        Set<String> roomIdSet = new Set<String>();
        if (otherSettingMap != null && !otherSettingMap.isEmpty()) {
            // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
            if (otherSettingMap.containsKey('ops')) {
                for (String seq : (List<String>)otherSettingMap.get('ops')){
                    opts.add(CommUtils.nullToZero(seq));
                }
            }
            // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
            if (otherSettingMap.containsKey('types')) {
                for (String typeSeq : CommUtils.nullToBlank(otherSettingMap.get('types')).split(',')) {
                    if (!CommUtils.isBlank(typeSeq)) roomTypeSet.add(CommUtils.nullToZero(typeSeq));
                }
            }
            if (otherSettingMap.containsKey('layoutid')) {
                String layoutId = CommUtils.nullToBlank(otherSettingMap.get('layoutid'));
                List<Document> docs = [select id,name,body,Description,CreatedBy.name,CreatedDate,LastModifiedBy.name,LastModifiedDate from Document where id = :layoutId];
                if (!docs.isEmpty()) {
                    String docBody = '{"rooms":' + CommUtils.nullToBlank(docs[0].body.toString()) + '}';
                    Map<String,List<Map<String,String>>> objectMap = (Map<String,List<Map<String,String>>>)JSON.deserializeStrict(docBody,Map<String,List<Map<String,String>>>.class);
                    if (objectMap.containsKey('rooms')) {
                        for (Map<String,Object> objMap : objectMap.get('rooms')) {
                            String roomId = CommUtils.nullToBlank(objMap.get('roomId'));
                            if (Commutils.isBLank(roomId)) continue;
                            if (objMap.containsKey('roomId'))
                                roomIdSet.add(CommUtils.nullToBlank(objMap.get('roomId')));
                        }
                    }
                }
            }
        }
	    // 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END	
        // 朝食のOP類別情報IDを格納する
	    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
        // if (!moringFoodkeySet.isEmpty()) moringFoodOpIdSet = getMoringFoodOpIdSet(moringFoodkeySet);
        if (!opts.isEmpty()) cookOpIdSet = getOpIdSet(opts);
        // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
        // 抽出条件を固定設定する
        // *****************************
        // 指定店舗
        // 当日
        // 取得範囲は１日分
        // アサイン部屋のみ表示
        // 予定表料理集計コード:コード２：項目　「昼と夜」別で料理集計を行う
        // 予定表料理集計表示方式:一箇所に纏めて集計結果を表示する
        String area = shopCode;
        // アサイン部屋のみ表示する
        Boolean bRoomViewFlg = true;
        // データ抽出日
        Date todayDt = (pQueryDt != null ? pQueryDt : Date.today());
        // 週間抽出最大日付
        Integer plusDays = 1;
        Date weekedDt  = todayDt.addDays(plusDays);
        // ******** 予約の検索条件 ********** //
        // 有効な予約データ
        String queryWhere = ' Where CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        // 店舗コードにより、関連チェックを行う　
        //if (!CommUtils.isBlank(shopCode)) queryWhere += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode or Rroom__r.ShopInfoRef__r.ShopCode__c = :shopCode ) ';
        if (!CommUtils.isBlank(shopCode)) queryWhere += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode ';
        // 到着日は当日
        // 到着日は週間の範囲で予約データを取得する
        queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ';
        queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <  :weekedDt ';
        // アサイン部屋
        // 2013/11/04 部屋アサイン以外の有効な予約も料理集計対象になる
        
        // ******** 予約見積もり明細の検索条件 ********** //
        Set<String> actTypeSet = new Set<String>{CommConst.PROD_ACTION_TYPE_AR, CommConst.PROD_ACTION_TYPE_NO, CommConst.PROD_ACTION_TYPE_PY, CommConst.PROD_ACTION_TYPE_SR,CommConst.PROD_ACTION_TYPE_PL};
        // 料理のみの場合、
        // 予約見積もり明細の商品種別は「プラン」以外(プラン明細のBreakDownの見積もり明細も対象外する)
        String queryLdWhere = ' Where ParentBookingItemRef__c = null And ActionType__c NOT IN :actTypeSet ';
        // ******** 会計明細の検索条件 ********** //
        // 会計明細の商品種別「プラン」以外(会計データは集計対象が必要)
        String processType = '00';
        String queryTranWhere = ' Where Field1__r.Field39__c = :processType And ActionType__c NOT IN :actTypeSet ';
        String OrKey = 'OR';
        // 料理のＦｉｌｔｅｒキーリスト
        if (!filterOpList.isEmpty()) {
            queryLdWhere += ' And ( ';
            queryTranWhere += ' And ( ';
            for (String key : filterOpList) {
                queryLdWhere += ' OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
                // 会計明細にOP項目がないため、直接商品のOP情報を使う
                queryTranWhere += ' Field7__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
            }
            // 最後のＯＲを削除する
            queryLdWhere = queryLdWhere.substringBeforeLast(OrKey);
            queryLdWhere += ' ) ';
            
            queryTranWhere = queryTranWhere.substringBeforeLast(OrKey);
            queryTranWhere += ' ) ';
        }
	// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN		
        if (!roomTypeSet.isEmpty()) {
            queryWhere += ' and refTypeOfRooms__r.seq__c = :roomTypeSet';
        }
        if (!roomIdSet.isEmpty()) {
            queryWhere += ' and Rroom__c = :roomIdSet';
        }
	// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END		
        // 予約データを検索を行う、検索結果から、部屋リストにマージする
        // 到着日時刻は早めに順番出力する BEGIN
        queryWhere += ' Order By EntryTime__c ';
        // 到着日時刻は早めに順番出力する END
        String querySubStr = queryLdStr + queryLdWhere + ' Order By RowNo__c NULLS LAST, Name ';
        String queryStr = ' Select '+ queryLeadStr + ',(' + querySubStr + ') From Lead__c ' + queryWhere;
        // 存在の予約情報を取得する[到着日は指定日の有効な予約情報を取得する]
        List<Lead__c> reportLst = DataBase.query(queryStr);
        // 予約明細情報を格納
        List<ReportRow> repLst = new List<ReportRow>();
        // 料理集計情報を格納[Key/合計情報]
        //Map<String, ReportSumRow> prodSumMap = new Map<String, ReportSumRow>();
        // 料理集計情報を格納[Key/合計情報] (チェックイン後)
        //Map<String, ReportSumRow> prodSumMap2 = new Map<String, ReportSumRow>();

        // プランの商品存在する場合、プラン関連の商品一覧を取得する
        Set<Id> noCheckInIdSet = new Set<Id>();
         // すでにチェックイン済みの予約情報を取得する
        Set<Id> checkInedIdSet = new Set<Id>();
        boolean allChkFlag = leadLst.isEmpty();
        // 部屋別に予約情報に格納する
        for (Lead__c lead : reportLst) {
            // すでにチェックイン済みの予約IDリストを取得して、会計明細情報を取得する
            if (!CommUtils.isBlank(lead.field298__c)) {
                // 既にチェックインの予約ID配列格納する
                checkInedIdSet.add(lead.Id);
            } else {
                // 未チェックイン予約ID配列格納する
                noCheckInIdSet.add(lead.Id);
            }
            if (allChkFlag) leadLst.add(lead.Id);
        }
        // 会計明細「プラン」以外の会計明細情報を取得する
        // ***************************************************
        // チェックイン済みの会計の関連会計IDにより、明細情報を取得する[料理のみ]
        queryTranWhere += ' And Field1__r.Relreserve__c in :checkInedIdSet ';
        // 会計明細【プラン以外」の情報を取得する、
        queryStr = queryTranStr + queryTranWhere + ' Order By RowNo__c NULLS LAST, Name ';
//System.debug(LoggingLevel.INFO, 'queryStr:::' + queryStr);
    
        List<Tran1__c> checkInTranLst = new List<Tran1__c>();
        if (!checkInedIdSet.isEmpty()) checkInTranLst = DataBase.query(queryStr);
        // 会計明細から取得する料理情報は見積もり明細方式に転換、設定を行う（統計便利するため）
        // 予約に関連付けるの会計情報を格納する
        Map<Id, AccountAcount__c> leadLinkAccountMap = new Map<Id, AccountAcount__c>();
        // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
        OrderServiceHelp.DeviceFilter deviceFilter = OrderServiceHelp.getDeviceFilter();
        // 2017/10/24 多印刷メッセージ放出機能追加 by zy END
        // ID(予約ID/ List<見積もり明細>)
        Map<Id, List<Tran1__c>> tranCookingMap = new Map<Id, List<Tran1__c>>();
        for (Tran1__c tran : checkInTranLst) {
            Id leadId = tran.Field1__r.Relreserve__c;
            // 予約に関連の会計情報を格納する
            if (!leadLinkAccountMap.containsKey(leadId)) leadLinkAccountMap.put(leadId, tran.Field1__r);
            if (!tranCookingMap.containsKey(leadId)) tranCookingMap.put(leadId, new List<Tran1__c>());
            tranCookingMap.get(leadId).add(tran);
//System.debug(LoggingLevel.INFO, 'tran:::' + tran);
			// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
            prodToPosMap.put(tran.Field7__c,deviceFilter.filter(tran.Field7__r));
        	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
        }
        // ***************************************************
        // Lead__c ->　見積もり明細に含めた商品（プラン）
        Map<Id, List<Id>> leadPlanProdMap = new Map<Id, List<Id>>();
        Map<Id, List<BookingEstimateItem__c>> leadEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();

        // 予約のプラン明細に料理存在の予約を取得する[未チェックイン予約プランとプランBreakDown情報を取得する]
        String planProdType = CommConst.PROD_ACTION_TYPE_PL;
        String planQueryStr = ' select id ,(' + queryLdStr + ' where ActionType__c = :planProdType OR ParentBookingItemRef__c != null order by RowNo__c NULLS LAST) From Lead__c where id in :noCheckInIdSet';
//System.debug(LoggingLevel.INFO,'planQueryStr::::'+planQueryStr);
        List<Lead__c> planLead = Database.query(planQueryStr);
        // BreakDown存在する見積もり明細（プラン）情報を格納する Map<見積もり明細PLAN、見積もり明細PLANのBreakDown情報>
        Map<Id, List<BookingEstimateItem__c>> existBreakDownEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
        // 予約データからプラン含めの見積もり明細データを取得する
        Set<Id> planProdIdSet = new Set<Id>();
        // プランを含めの予約データ
        for (Lead__c l : planLead) {
            // 2013/10/25 該当プランは既にBreakDown明細が存在する場合、該当プランは検索対象外
            // 予約→商品（プラン）関連情報格納
            leadPlanProdMap.put(l.Id, new List<Id>());
            // 予約→見積もり明細リスト情報を格納する
            leadEstItemMap.put(l.Id, new List<BookingEstimateItem__c>());
// system.debug(logginglevel.info,'estItem:::' + l.BookingEstimateItemFgKu__r);
            for (BookingEstimateItem__c estItem : l.BookingEstimateItemFgKu__r) {
                
                // 予約→商品（プラン）のBreakDown見積もり明細情報を格納する
                if (estItem.ParentBookingItemRef__c != null) {
                    Id parentId = estItem.ParentBookingItemRef__c;
                    if (!existBreakDownEstItemMap.containsKey(parentId)) {
                        existBreakDownEstItemMap.put(parentId, new List<BookingEstimateItem__c>());
                    }
                    // 該当プランのBreakDown商品は料理が含めする場合、配列に追加する
                    if (isCookingByWord(estItem.OP__r.Name)) existBreakDownEstItemMap.get(parentId).add(estItem);
                    continue;
                }
                // プラン情報を格納して、関連のプラン明細の商品リストを取得するため     
                // Ｍａｔｃｈ用予約ＩＤ→プラン（会計商品）配列
                leadPlanProdMap.get(l.Id).add(estItem.refAccountMaster__c);
                // 商品（プラン）ＩＤを追加する
                planProdIdSet.add(estItem.refAccountMaster__c);
                // Ｍａｔｃｈ用予約ＩＤ→見積もり明細(プラン OR 普通の見積もり明細)を格納する
                leadEstItemMap.get(l.Id).add(estItem);
                // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
                prodToPosMap.put(estItem.refAccountMaster__c,deviceFilter.filter(estItem.refAccountMaster__r));
            	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
            }
        }
        // プラン明細に格納している[上記プラン定義されている見積もり明細（プラン）のプラン明細定義情報を取得する[プラン明細は料理の前提条件あり]
        String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
        // 料理のＦｉｌｔｅｒキーリスト
        if (!filterOpList.isEmpty()) {
            planDlStr += ' And ( ';
            for (String key : filterOpList) {
                planDlStr += ' AccountMasterRef__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
            }
            // 最後のＯＲを削除する
            planDlStr = planDlStr.substringBeforeLast(OrKey);
            planDlStr += ' ) ';
        }
        List<PlanDetail__c> planDlList = DataBase.query(planDlStr);
        
        // プラン明細に含めている料理情報を格納<会計商品(プラン)ID/該当プランに含めするプラン明細（料理）配列
        Map<Id, List<AccountMaster__c>> cookingProdMap = new Map<Id, List<AccountMaster__c>>();
        for (PlanDetail__c detail : planDlList) {
            // プランに含めた明細商品に、料理対象データが存在する場合
            if (!cookingProdMap.containsKey(detail.PlanProdcut__c)) cookingProdMap.put(detail.PlanProdcut__c, new List<AccountMaster__c>());
            cookingProdMap.get(detail.PlanProdcut__c).add(detail.AccountMasterRef__r);
        }
        // アレルギーの項目設定
       	Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(leadLst,null,false);
        for (Lead__c lead : reportLst) {
            // 基本情報を格納する
            ReportRow orgRep = new ReportRow(lead);
            // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
            orgRep.isEnLanguage = isEnLanguage;
            // 2018/02/07 オーダーエントリー画面の英語対応 by zy END
            if (customMap.containsKey(orgRep.leadId)) {
				Map<String,Object> curMap = customMap.get(lead.id);
        		if (curMap.containsKey('allergie')) orgRep.allergie = CommUtils.nullToBlank(curMap.get('allergie'));
			}
            //orgRep.queryDate =  keyDate;
            // 該当予約に関連付く料理の見積もり明細情報を格納する
            List<BookingEstimateItem__c> estItemList = new List<BookingEstimateItem__c>();
            List<Tran1__c> tranLst = new List<Tran1__c>();
            boolean isCheckInFlag = !noCheckInIdSet.contains(lead.Id) && checkInedIdSet.contains(lead.Id);
            // 料理がない場合、出力対象外
            if (!noCheckInIdSet.contains(lead.Id) && !checkInedIdSet.contains(lead.Id)) continue;
            // 未チェックインの場合、該当予約の料理明細情報を格納する
            if (!isCheckInFlag) {
            	// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
				for (BookingEstimateItem__c item : lead.BookingEstimateItemFgKu__r) {
					 prodToPosMap.put(item.refAccountMaster__c,deviceFilter.filter(item.refAccountMaster__r));
				}
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
                // プラン以外の料理の見積もり明細情報は配列に格納する
                estItemList.addAll(lead.BookingEstimateItemFgKu__r);
            } else {
                // 既にチェックインの場合、会計明細の料理情報を格納する
                if (tranCookingMap.containsKey(lead.Id)) tranLst.addAll(tranCookingMap.get(lead.Id));
                // チェックイン情報に会計情報で設定する
                if (leadLinkAccountMap.containsKey(lead.Id)) {
                    AccountAcount__c relAcc = leadLinkAccountMap.get(lead.Id);
                    orgRep.orderId = relAcc.Id;
                    orgRep.orderNo = relAcc.Name;
                }
            }
            leadLst.add(lead.Id);
            // 該当予約に、プランに料理存在するチェックを行う
            if (leadPlanProdMap.containsKey(lead.Id)) {
                // 関連の料理が存在チェック
                Integer subIdx = 0;
                // プラン明細から料理の商品情報を取得する
                for (Id planId : leadPlanProdMap.get(lead.Id)) {
                    // 見積もり明細（プラン）のID
                    Id planEstItemId = leadEstItemMap.get(lead.Id)[subIdx].Id;
                    // 料理を含めのプラン場合[見積もり明細BreakDown設定により]
                    if (existBreakDownEstItemMap.containsKey(planEstItemId)) {
                        estItemList.addAll(existBreakDownEstItemMap.get(planEstItemId));
                        // 注意：INDEX加算必要
                        subIdx++;
                        continue;
                    }
                    // 料理を含めのプラン場合[プラン明細設定により]
                    if (cookingProdMap.containsKey(planId)) {
                        // 該当プランに含めの料理リストを取得する
                        List<AccountMaster__c> accMstLst = cookingProdMap.get(planId);
                        // 取得する商品情報から、見積り明細明細データを作成する
                        for (AccountMaster__c accMst : accMstLst) {
                            BookingEstimateItem__c newEstItem = new BookingEstimateItem__c(
                                refBooking__c = lead.Id,
                                refAccountMaster__c = accMst.Id,
                                Field3__c = accMst.Field3__c,
                                ProductName__c = accMst.Name,
                                OP__c = accMst.OP__c,
                                Amount__c = leadEstItemMap.get(lead.Id)[subIdx].Amount__c
                            );
                            estItemList.add(newEstItem);
                        }
                    }
                    subIdx++;
                }
            }
            // 明細ソートする
            // 2017/04/27 料理数目变更之后变颜色对应 wgch BEGIN
            // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
            orgRep.addDivideRows(estItemList,tranLst,lead,cookOpIdSet);
            // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
            // 2017/04/27 料理数目变更之后变颜色对应 wgch END
	        // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
            if (!noLeadSet.isEmpty()) {
                Map<String,String> leadOtherMap = new Map<String,String>();
                for (String field : noLeadSet){
                    leadOtherMap.put(field,CommUtils.nullToBlank(lead.get(field)));
                }
                orgRep.leadOtherMap = leadOtherMap;
            }
	    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
            repLst.add(orgRep);
        }
        return repLst;
    }
    // 2018/08/31 料理進捗機能追加　by zy END
    // 料理・見積明細情報を取得する
    private List<OrderServiceHelp.BulkPrintUIInfo> queryLead(Boolean isEstOnlyFlg){
        // -------------------------------------
        // カスタム項目設定情報処理
        // -------------------------------------
        try{
            // 指定の店舗コードで取得、関連の予約情報を出力する
            // 既存固定定義している予約検索のＳＱＬを取得する
            queryLeadStr = queryConstLeadStr;
            // 固定定義されている項目リストを取得する
            String[] constLeadFields = queryLeadStr.deleteWhitespace().split(',');
            // カスタム項目をＳＱＬへ追加する
            for (String field : constLeadFields) {
                String key = field;
            }
            // -------------------------------------
            // 料理集計設定情報を取得する
            // -------------------------------------
            // 料理抽出条件を設定する場合、該当条件でデータ抽出を行う
            String whereStr = CommConst.getKScheduleReportWhere();
            // 明細明細の場合、
            if (isEstOnlyFlg) {
                whereStr = null;
                filterOpList.clear();
            }
            // 朝食キー
            Set<String> moringFoodkeySet = new Set<String>();
            if (!String.isEmpty(whereStr)) {
                String[] whereLst = whereStr.split(',');
                filterOpList.clear();
                for (String key : whereLst) {
                    String[] subKey = key.split(':');
                    filterOpList.add(subKey[0]);
                    // 朝食キーが存在
                    if (subKey.size() > 1) moringFoodKeySet.add(subKey[0]);
                }
            }
            // 朝食のOP類別情報IDを格納する
            if (!moringFoodkeySet.isEmpty()) moringFoodOpIdSet = getMoringFoodOpIdSet(moringFoodkeySet);
            // 抽出条件を固定設定する
            // *****************************
            // 指定店舗
            // 当日
            // 取得範囲は１日分
            // アサイン部屋のみ表示
            // 予定表料理集計コード:コード２：項目　「昼と夜」別で料理集計を行う
            // 予定表料理集計表示方式:一箇所に纏めて集計結果を表示する
            String area = shopCode;
            // アサイン部屋のみ表示する
            Boolean bRoomViewFlg = true;
            // データ抽出日
            Date todayDt = (pQueryDt != null ? pQueryDt : Date.today());
            // 週間抽出最大日付
            Integer plusDays = 1;
            Date weekedDt  = todayDt.addDays(plusDays);
            // ******** 予約の検索条件 ********** //
            // 有効な予約データ
            String queryWhere = ' Where CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
            // 店舗コードにより、関連チェックを行う　
            //if (!CommUtils.isBlank(shopCode)) queryWhere += ' And (refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode or Rroom__r.ShopInfoRef__r.ShopCode__c = :shopCode ) ';
            if (!CommUtils.isBlank(shopCode)) queryWhere += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopCode ';
            // 到着日は当日
            // 到着日は週間の範囲で予約データを取得する
            queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :todayDt ';
            queryWhere += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <  :weekedDt ';
            // アサイン部屋
            // 2013/11/04 部屋アサイン以外の有効な予約も料理集計対象になる
            
            // ******** 予約見積もり明細の検索条件 ********** //
            Set<String> actTypeSet = new Set<String>{CommConst.PROD_ACTION_TYPE_AR, CommConst.PROD_ACTION_TYPE_NO, CommConst.PROD_ACTION_TYPE_PY, CommConst.PROD_ACTION_TYPE_SR};
            // 料理のみの場合、
            if (!isEstOnlyFlg) actTypeSet.add(CommConst.PROD_ACTION_TYPE_PL);
            // 予約見積もり明細の商品種別は「プラン」以外(プラン明細のBreakDownの見積もり明細も対象外する)
            String queryLdWhere = ' Where ParentBookingItemRef__c = null And ActionType__c NOT IN :actTypeSet ';
            // ******** 会計明細の検索条件 ********** //
            // 会計明細の商品種別「プラン」以外(会計データは集計対象が必要)
            String processType = '00';
            String queryTranWhere = ' Where Field1__r.Field39__c = :processType And ActionType__c NOT IN :actTypeSet ';
            // 見積明細の場合、
            if (isEstOnlyFlg) {
                //queryLdWhere   += ' And ParentBookingItemRef__c = null ';
                queryTranWhere += ' And ParentTran1Ref__c = null ';
            }
            String OrKey = 'OR';
            // 料理のＦｉｌｔｅｒキーリスト
            if (!filterOpList.isEmpty()) {
                queryLdWhere += ' And ( ';
                queryTranWhere += ' And ( ';
                for (String key : filterOpList) {
                    queryLdWhere += ' OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
                    // 会計明細にOP項目がないため、直接商品のOP情報を使う
                    queryTranWhere += ' Field7__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
                }
                // 最後のＯＲを削除する
                queryLdWhere = queryLdWhere.substringBeforeLast(OrKey);
                queryLdWhere += ' ) ';
                
                queryTranWhere = queryTranWhere.substringBeforeLast(OrKey);
                queryTranWhere += ' ) ';
            }
            // 予約データを検索を行う、検索結果から、部屋リストにマージする
            // 到着日時刻は早めに順番出力する BEGIN
            queryWhere += ' Order By EntryTime__c ';
            // 到着日時刻は早めに順番出力する END
            String querySubStr = queryLdStr + queryLdWhere + ' Order By RowNo__c NULLS LAST, Name ';
            String queryStr = ' Select '+ queryLeadStr + ',(' + querySubStr + ') From Lead__c ' + queryWhere;
//System.debug(loggingLevel.info, 'isEstOnlyFlg='+isEstOnlyFlg);
System.debug(loggingLevel.info, 'queryStr='+queryStr);
            // 存在の予約情報を取得する[到着日は指定日の有効な予約情報を取得する]
            List<Lead__c> reportLst = DataBase.query(queryStr);
            // 予約明細情報を格納
            List<ReportRow> repLst = new List<ReportRow>();
            // 料理集計情報を格納[Key/合計情報]
            //Map<String, ReportSumRow> prodSumMap = new Map<String, ReportSumRow>();
            // 料理集計情報を格納[Key/合計情報] (チェックイン後)
            //Map<String, ReportSumRow> prodSumMap2 = new Map<String, ReportSumRow>();

            // プランの商品存在する場合、プラン関連の商品一覧を取得する
            Set<Id> noCheckInIdSet = new Set<Id>();
             // すでにチェックイン済みの予約情報を取得する
            Set<Id> checkInedIdSet = new Set<Id>();
            // 部屋別に予約情報に格納する
            for (Lead__c lead : reportLst) {
                // すでにチェックイン済みの予約IDリストを取得して、会計明細情報を取得する
                if (!CommUtils.isBlank(lead.field298__c)) {
                    // 既にチェックインの予約ID配列格納する
                    checkInedIdSet.add(lead.Id);
                } else {
                    // 未チェックイン予約ID配列格納する
                    noCheckInIdSet.add(lead.Id);
                }
            }
            // 会計明細「プラン」以外の会計明細情報を取得する
            // ***************************************************
            // チェックイン済みの会計の関連会計IDにより、明細情報を取得する[料理のみ]
            queryTranWhere += ' And Field1__r.Relreserve__c in :checkInedIdSet ';
            // 会計明細【プラン以外」の情報を取得する、
            queryStr = queryTranStr + queryTranWhere + ' Order By RowNo__c NULLS LAST, Name ';
//System.debug(LoggingLevel.INFO, 'queryStr:::' + queryStr);
    
            List<Tran1__c> checkInTranLst = new List<Tran1__c>();
            if (!checkInedIdSet.isEmpty()) checkInTranLst = DataBase.query(queryStr);
            // 会計明細から取得する料理情報は見積もり明細方式に転換、設定を行う（統計便利するため）
            // 予約に関連付けるの会計情報を格納する
            Map<Id, AccountAcount__c> leadLinkAccountMap = new Map<Id, AccountAcount__c>();
            // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
            OrderServiceHelp.DeviceFilter deviceFilter = OrderServiceHelp.getDeviceFilter();
            Map<String,String> prodToPosMap = new Map<String,String>();
            // 2017/10/24 多印刷メッセージ放出機能追加 by zy END
            // ID(予約ID/ List<見積もり明細>)
            Map<Id, List<BookingEstimateItem__c>> tranCookingMap = new Map<Id, List<BookingEstimateItem__c>>();
            for (Tran1__c tran : checkInTranLst) {
                Id leadId = tran.Field1__r.Relreserve__c;
                // 予約に関連の会計情報を格納する
                if (!leadLinkAccountMap.containsKey(leadId)) leadLinkAccountMap.put(leadId, tran.Field1__r);
                if (!tranCookingMap.containsKey(leadId)) tranCookingMap.put(leadId, new List<BookingEstimateItem__c>());
                tranCookingMap.get(leadId).add(
                     new BookingEstimateItem__c(
                        refBooking__c = leadId,
                        refAccountMaster__c = tran.Field7__c,
                        Field3__c = tran.Field7__r.Field3__c,
                        ProductName__c = tran.Field5__c,
                        OP__c = tran.Field7__r.OP__c,
                        Amount__c = tran.Field40__c,
                        refAccountMaster__r = tran.Field7__r,//商品名 参照関係(会計商品)
                        ActionType__c = CommConst.PROD_ACTION_TYPE_PY,// 商品処理種別
                        PaymentType__c = tran.Field7__r.PaymentType__c,// 支払種別 Field7__r.PaymentType__c, Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c
                        UnitPrice__c = CommUtils.nullToZero(tran.Field20__c),
                        SpTotal__c = CommUtils.nullToZero(tran.Field23__c),
                        TaxRate__c = tran.Field7__r.TaxRateCal__c,// 消費税 Field7__r.TaxRateCal__c
                        ServiceRate__c = tran.Field7__r.ServiceRate__c// サービス料(%) Field7__r.ServiceRate__c
                    )
                );
                // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
                prodToPosMap.put(tran.Field7__c,deviceFilter.filter(tran.Field7__r));
            	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
            }
            // ***************************************************
            // Lead__c ->　見積もり明細に含めた商品（プラン）
            Map<Id, List<Id>> leadPlanProdMap = new Map<Id, List<Id>>();
            Map<Id, List<BookingEstimateItem__c>> leadEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
    
            // 予約のプラン明細に料理存在の予約を取得する[未チェックイン予約プランとプランBreakDown情報を取得する]
            String planProdType = CommConst.PROD_ACTION_TYPE_PL;
            String planQueryStr = ' select id ,(' + queryLdStr + ' where ActionType__c = :planProdType OR ParentBookingItemRef__c != null) From Lead__c where id in :noCheckInIdSet';
//System.debug(LoggingLevel.INFO,'planQueryStr::::'+planQueryStr);
            List<Lead__c> planLead = Database.query(planQueryStr);
            // BreakDown存在する見積もり明細（プラン）情報を格納する Map<見積もり明細PLAN、見積もり明細PLANのBreakDown情報>
            Map<Id, List<BookingEstimateItem__c>> existBreakDownEstItemMap = new Map<Id, List<BookingEstimateItem__c>>();
            
            // 予約データからプラン含めの見積もり明細データを取得する
            Set<Id> planProdIdSet = new Set<Id>();
            // プランを含めの予約データ
            for (Lead__c l : planLead) {
                // 2013/10/25 該当プランは既にBreakDown明細が存在する場合、該当プランは検索対象外
                // 予約→商品（プラン）関連情報格納
                leadPlanProdMap.put(l.Id, new List<Id>());
                // 予約→見積もり明細リスト情報を格納する
                leadEstItemMap.put(l.Id, new List<BookingEstimateItem__c>());
                
                for (BookingEstimateItem__c estItem : l.BookingEstimateItemFgKu__r) {
                    
                    // 予約→商品（プラン）のBreakDown見積もり明細情報を格納する
                    if (estItem.ParentBookingItemRef__c != null) {
                        Id parentId = estItem.ParentBookingItemRef__c;
                        if (!existBreakDownEstItemMap.containsKey(parentId)) {
                            existBreakDownEstItemMap.put(parentId, new List<BookingEstimateItem__c>());
                        }
                        // 該当プランのBreakDown商品は料理が含めする場合、配列に追加する
                        if (isCookingByWord(estItem.OP__r.Name)) existBreakDownEstItemMap.get(parentId).add(estItem);
                        continue;
                    }
                    
                    // プラン情報を格納して、関連のプラン明細の商品リストを取得するため     
                    // Ｍａｔｃｈ用予約ＩＤ→プラン（会計商品）配列
                    leadPlanProdMap.get(l.Id).add(estItem.refAccountMaster__c);
                    // 商品（プラン）ＩＤを追加する
                    planProdIdSet.add(estItem.refAccountMaster__c);
                    // Ｍａｔｃｈ用予約ＩＤ→見積もり明細(プラン OR 普通の見積もり明細)を格納する
                    leadEstItemMap.get(l.Id).add(estItem);
                    // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
                    prodToPosMap.put(estItem.refAccountMaster__c,deviceFilter.filter(estItem.refAccountMaster__r));
                	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
                }
            }
            // プラン明細に格納している[上記プラン定義されている見積もり明細（プラン）のプラン明細定義情報を取得する[プラン明細は料理の前提条件あり]
            String planDlStr = ' Select PlanProdcut__c,AccountMasterRef__c, AccountMasterRef__r.OP__c, AccountMasterRef__r.Field3__c, AccountMasterRef__r.Name from PlanDetail__c where PlanProdcut__c in :planProdIdSet ';
            // 料理のＦｉｌｔｅｒキーリスト
            if (!filterOpList.isEmpty()) {
                planDlStr += ' And ( ';
                for (String key : filterOpList) {
                    planDlStr += ' AccountMasterRef__r.OP__r.Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
                }
                // 最後のＯＲを削除する
                planDlStr = planDlStr.substringBeforeLast(OrKey);
                planDlStr += ' ) ';
            }
            List<PlanDetail__c> planDlList = DataBase.query(planDlStr);
            
            // プラン明細に含めている料理情報を格納<会計商品(プラン)ID/該当プランに含めするプラン明細（料理）配列
            Map<Id, List<AccountMaster__c>> cookingProdMap = new Map<Id, List<AccountMaster__c>>();
            for (PlanDetail__c detail : planDlList) {
                // プランに含めた明細商品に、料理対象データが存在する場合
                if (!cookingProdMap.containsKey(detail.PlanProdcut__c)) cookingProdMap.put(detail.PlanProdcut__c, new List<AccountMaster__c>());
                cookingProdMap.get(detail.PlanProdcut__c).add(detail.AccountMasterRef__r);
            }
			List<Id> leadLst = new List<Id>();
            for (Lead__c lead : reportLst) {
                // 基本情報を格納する
                ReportRow orgRep = new ReportRow(lead);
                // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
                orgRep.isEnLanguage = isEnLanguage;
                // 2018/02/07 オーダーエントリー画面の英語対応 by zy END
                //orgRep.queryDate =  keyDate;
                // 該当予約に関連付く料理の見積もり明細情報を格納する
                List<BookingEstimateItem__c> estItemList = new List<BookingEstimateItem__c>();
                // 料理がない場合、出力対象外
                if (!noCheckInIdSet.contains(lead.Id) && !checkInedIdSet.contains(lead.Id)) continue;
                // 未チェックインの場合、該当予約の料理明細情報を格納する
                if (noCheckInIdSet.contains(lead.Id)) {
                	// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
					for (BookingEstimateItem__c item : lead.BookingEstimateItemFgKu__r) {
						 prodToPosMap.put(item.refAccountMaster__c,deviceFilter.filter(item.refAccountMaster__r));
					}
					// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
                    // プラン以外の料理の見積もり明細情報は配列に格納する
                    estItemList.addAll(lead.BookingEstimateItemFgKu__r);
                } else if (checkInedIdSet.contains(lead.Id)) {
                    // 既にチェックインの場合、会計明細の料理情報を格納する
                    if (tranCookingMap.containsKey(lead.Id)) estItemList.addAll(tranCookingMap.get(lead.Id));
                    // チェックイン情報に会計情報で設定する
                    if (leadLinkAccountMap.containsKey(lead.Id)) {
                        AccountAcount__c relAcc = leadLinkAccountMap.get(lead.Id);
                        orgRep.orderId = relAcc.Id;
                        orgRep.orderNo = relAcc.Name;
                    }
                }
                leadLst.add(lead.Id);
                // 該当予約に、プランに料理存在するチェックを行う
                if (leadPlanProdMap.containsKey(lead.Id)) {
                    // 関連の料理が存在チェック
                    Integer subIdx = 0;
                    // プラン明細から料理の商品情報を取得する
                    for (Id planId : leadPlanProdMap.get(lead.Id)) {
                        // 見積もり明細（プラン）のID
                        Id planEstItemId = leadEstItemMap.get(lead.Id)[subIdx].Id;
                        // 料理を含めのプラン場合[見積もり明細BreakDown設定により]
                        if (existBreakDownEstItemMap.containsKey(planEstItemId)) {
                            estItemList.addAll(existBreakDownEstItemMap.get(planEstItemId));
                            // 注意：INDEX加算必要
                            subIdx++;
                            continue;
                        }
                        // 料理を含めのプラン場合[プラン明細設定により]
                        if (cookingProdMap.containsKey(planId)) {
                            // 該当プランに含めの料理リストを取得する
                            List<AccountMaster__c> accMstLst = cookingProdMap.get(planId);
                            // 取得する商品情報から、見積り明細明細データを作成する
                            for (AccountMaster__c accMst : accMstLst) {
                                BookingEstimateItem__c newEstItem = new BookingEstimateItem__c(
                                    refBooking__c = lead.Id,
                                    refAccountMaster__c = accMst.Id,
                                    Field3__c = accMst.Field3__c,
                                    ProductName__c = accMst.Name,
                                    OP__c = accMst.OP__c,
                                    Amount__c = leadEstItemMap.get(lead.Id)[subIdx].Amount__c
                                );
                                estItemList.add(newEstItem);
                            }
                        }
                        subIdx++;
                    }
                }
                // 明細ソートする
                // 2017/04/27 料理数目变更之后变颜色对应 wgch BEGIN
                orgRep.addAllRows(estItemList,lead);
                // 2017/04/27 料理数目变更之后变颜色对应 wgch END
                repLst.add(orgRep);
            }

            // 明細情報：
            // 注文NO：予約番号・会計番号
            // 注文処：部屋名
            // お客様名：
            // 料理ステータス時刻
            // アレルギー内容
            // 明細リスト
                 // 商品名、数量、金額？
            // 注文URL
            // 出力JSON情報作成する
            //List<ReportRow> repLst = new List<ReportRow>();
            Set<Id> productIdSet = new Set<Id>();
            // 出力順番情報をJSON設定する
            for (ReportRow rep : repLst) {
                // 会席情報を取得する
                //productIdSet.add(rep.)
                for (ReportDetail row : rep.rows) {
                    productIdSet.add(row.productId);
                }
            }
            // 会席のBreakdowns情報を取得する　
            Map<Id, List<FoodDetail__c>> foodDetailMap = new Map<Id, List<FoodDetail__c>>();
            if (!productIdSet.isEmpty()) {
                foodDetailMap = OrderServiceHelp.getKaisakiDetailMap(productIdSet);
            }
            // 2017/10/16 bug fix アレルギー対応　by　zy BEGIN
            boolean headFlag = false;
            if (pntInfo != null) headFlag =  pntInfo.headStanFlag;
            else pntInfo = new OrderServiceHelp.PrintInfo();
            // アレルギーの項目設定
            Map<Id,Map<String,Object>> customMap = OrderServiceHelp.getAllCustomMap(leadLst,null,headFlag);
//system.debug(logginglevel.info,'customMap::::' + customMap);
           // 2017/10/16 bug fix アレルギー対応　by　zy END
            // プリンターのObjectリスト情報を作成する
            List<OrderServiceHelp.BulkPrintUIInfo> rsLst = new List<OrderServiceHelp.BulkPrintUIInfo>();
            // 予約IDの
            String leadPreFix = Lead__c.sObjectType.getDescribe().getKeyPrefix();
//System.debug(LoggingLevel.info, 'foodDetailMap='+foodDetailMap);
            for (ReportRow rep : repLst) {
                if (rep.rows.isEmpty()) continue;
                AccountAcount__c acc = new AccountAcount__c();
                // 印刷情報を取得する
                OrderServiceHelp.BulkPrintUIInfo printInf = new OrderServiceHelp.BulkPrintUIInfo();
                if (rep.orderId.startsWith(leadPreFix)) printInf.leadid = rep.orderId;
                else printInf.accid = rep.orderId;
                printInf.leadname = rep.leadName;
                printInf.contactname = rep.contactName;
                printInf.roomname = rep.roomname;
                 // 添加label行 by zy BEGIN
                printInf.leadstatus = rep.leadStatus;
                printInf.leadstatuslabel = '';
                if (CommUtils.isBlank(printInf.leadstatus)) printInf.leadstatuslabel = '';
                else {
                	String firstLabel = printInf.leadstatus.substringAfter('alt="');
                	firstLabel = firstLabel.substringBefore('"');
                	printInf.leadstatuslabel = firstLabel;
                }
                // 添加label行 by zy END
				Map<String,Object> repMap = rep.toPrintMap();
				if (customMap.containsKey(rep.leadId)) {
					Map<String,Object> curMap = customMap.get(rep.leadId);
	        		for (String paraName : curMap.keySet()) {
	        			repMap.put(paraName,CommUtils.nullToBlank(curMap.get(paraName)));
	        		}
				}
// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
//System.debug(LoggingLevel.info, 'rep.toTrans()='+rep.toTrans());
				//printInf.printInfo = OrderServiceHelp.getPrintObj(new OrderServiceHelp.PrintInfo(), rep.toTrans(), OrderServiceHelp.LayoutType.ORDER, foodDetailMap, acc,repMap);
                OrderServiceHelp.makePrintInfos(printInf,pntInfo, rep.toTrans(), prodToPosMap , acc , repMap , foodDetailMap, OrderServiceHelp.LayoutType.ORDER);
				// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
//System.debug(LoggingLevel.info, 'printInf='+printInf);
                rsLst.add(printInf);
            }
            return rsLst;
        } catch(Exception e){
            return null;
        }
    }
    /**
    * レポート明細情報を格納用
    **/
    public class ReportRow {
        //public Lead__c varlead{get; private set;}
        public ReportRow(Lead__c ps) {
            // 明細情報：
            // 注文NO：予約番号・会計番号
            // 注文処：部屋名
            // お客様名：
            // 料理ステータス時刻
            // アレルギー内容
            // 明細リスト
                 // 商品名、数量、金額？
            // 注文URL
            leadName = CommUtils.nullToBlank(ps.Name);
            // 予約情報を格納する
            orderId = CommUtils.nullToBlank(ps.Id);
            // プリンター情報
            orderNo = CommUtils.nullToBlank(ps.No__c);
            roomname = CommUtils.nullToBlank(ps.Rroom__r.Name);
            contactName = CommUtils.nullToBlank(ps.Relcontact__r.Name);
            orderTime = CommUtils.nullToBlank(ps.Field4__c);
            allergie = CommUtils.nullToBlank(ps.Field354__c);
            // 料理明細情報
            rows = new List<ReportDetail>();
            // 添加label行 by zy BEGIN
            leadStatus = CommUtils.nullToBlank(ps.Field278__c);
            leadId = ps.id;
            // 添加label行 by zy END
            // 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
            roomId = CommUtils.nullToBlank(ps.Rroom__c);
            // 2019/09/15 部屋の並び順をSeq#順に by zy END
        }
        // 予約名
        public String leadName{get;set;}
        // 予約ID/会計ID
        public String orderId{get;set;}
        // 予約No/会計No
        public String orderNo{get;set;}
        public String roomName{get;set;}
        public String contactName{get;set;}
        public String orderTime{get;set;}
        public String allergie{get;set;}
        // 添加label行 by zy BEGIN
        public String leadStatus{get;set;}
        public String leadId;
        // 添加label行 by zy END
	    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
        public Map<String,String> leadOtherMap;
	    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
        // 料理見積り明細情報を格納する
        public List<ReportDetail> rows{get; private set;}
        // 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
        public String roomId;
        // 2019/09/15 部屋の並び順をSeq#順に by zy END
        public List<Tran1__c> toTrans () {
            List<Tran1__c> trans = new List<Tran1__c>();
            for (ReportDetail detail : rows) {
                trans.add(detail.toTran());
            }
            return trans;
        }
        // プリンター印刷用情報マップ
        public Map<String,Object> toPrintMap() {
            Map<String,Object> otherMap = new Map<String, Object>();
            otherMap.put('allergie',allergie);
            otherMap.put('custname',contactName);
            otherMap.put('orderno',orderNo);
            otherMap.put('orderplace',roomName);
            otherMap.put('time',orderTime);
            otherMap.put('orderurl','https://login.salesforce.com/'+orderId);
            return otherMap;
        }
        // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
        public boolean isEnLanguage;
        // 2018/02/07 オーダーエントリー画面の英語対応 by zy END
        // 2018/08/31 料理進捗機能追加　by zy BEGIN
        // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
        public void addDivideRows(List<BookingEstimateItem__c> items,List<Tran1__c> trans,Lead__c lead,Set<Id> opIdSet) {
        // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
            // 商品明細
            // 商品コード　と　単価は同じすると、同じ商品として、マージする
            // 会計商品の名から見積り明細の商品名にコピーする
            if(items != null && !items.isEmpty()){
	            for (BookingEstimateItem__c s : items) {
                    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
                    if (opIdSet != null && !opIdSet.isEmpty() && !opIdSet.contains(s.op__c)) continue;
                    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	                ReportDetail subitem = new ReportDetail(s,isEnLanguage);
	                rows.add(subitem);
	            }
            }
            if(trans != null && !trans.isEmpty()){
	            for (Tran1__c s : trans) {
                    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
                    if (opIdSet != null && !opIdSet.isEmpty() && !opIdSet.contains(s.Field7__r.op__c)) continue;
                    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	                ReportDetail subitem = new ReportDetail(s,isEnLanguage);
	                rows.add(subitem);
	            }
            }
        }
        // 2018/08/31 料理進捗機能追加　by zy END
        // 料理明細は該当予約に情報格納する
        public void addAllRows(List<BookingEstimateItem__c> items,Lead__c lead) {
//System.debug(LoggingLevel.INFO, 'items:::' + items);
            if(items.isEmpty()) return;
            // 商品明細
            // 商品コード　と　単価は同じすると、同じ商品として、マージする
            // 会計商品の名から見積り明細の商品名にコピーする
            Map<String, ReportDetail> sortMap = new Map<String, ReportDetail>();
            for (BookingEstimateItem__c s : items) {
            	// 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
                ReportDetail subitem = new ReportDetail(s,isEnLanguage);
                // 2018/02/07 オーダーエントリー画面の英語対応 by zy END
                // 商品存在場合[2014/03/27 料理項目明細、商品コードで並び順表示する]
                String key = getCookFieldSortField(subitem);
                if (sortMap.containsKey(key)) {
                    ReportDetail curItem = sortMap.get(key);
                    // 数量合計処理
                    curItem.qty = CommUtils.deleteRightZero(
                                                String.valueOf( CommUtils.nullToZero(curItem.qty) + 
                                                                CommUtils.nullToZero(subitem.qty)));
                    curItem.amountPrice = CommUtils.deleteRightZero(
                                                String.valueOf( CommUtils.nullToZero(curItem.amountPrice) + 
                                                                CommUtils.nullToZero(subitem.amountPrice)));                                                        
                } else {
                    sortMap.put(key, subitem);
                }
            }
            // 商品名でSORTする
            List<String> prodCodeLst = new List<String>(sortMap.keySet());
            prodCodeLst.sort();
            // 料理明細データはリストへ追加
            for (String prodNm : prodCodeLst) {
                rows.add(sortMap.get(prodNm));
            }
        }
    }
    /**
    * 朝食キー文字を含めの会計ＯＰのＩＤ
    **/
    private Set<Id> getMoringFoodOpIdSet(Set<String> keySet) {
        String OrKey = 'OR';
        String queryStr = ' Select Id from OP__c where  ';
        queryStr += ' ( ';
        for (String key : keySet) {
            queryStr += ' Name like \'%' + CommUtils.escStr(key) + '%\' ' + OrKey;
        }
        // 最後のＯＲを削除する
        queryStr = queryStr.substringBeforeLast(OrKey);
        queryStr += ' ) ';
        List<OP__c> opLst = Database.query(queryStr);
        Set<Id> opIdSet = new Set<Id>();
        for (OP__c op : opLst) opIdSet.add(op.Id);
        return opIdSet;
    }
    /**
    * 料理がどうか判別Method
    * TRUE:該当商品は料理場合
    **/
    private static Boolean isCookingByWord(String prodName) {
        if (String.isEmpty(prodName)) return false;
        for (String key : filterOpList) {
            if (prodName.contains(key)) return true;
        }
        return false;
    }
    // 料理項目明細表示の並べ順項目情報を取得する
    private static String getCookFieldSortField(ReportDetail subitem) {
        if (cookFieldSortDiv == '1') {
            return subitem.productName;
        } else {
            return subitem.productCode;
        }
    }
    // 予約明細の会計商品明細情報格納
    public class ReportDetail {
        public ReportDetail(BookingEstimateItem__c s,boolean isEnLanguage) {
            // 商品名
            productName = CommUtils.nullToBlank(s.refAccountMaster__r.Name == null ? s.ProductName__c : s.refAccountMaster__r.Name);
            // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
            if (isEnLanguage && !CommUtils.isBlank(s.refAccountMaster__r.ProductEnName__c)) productName = s.refAccountMaster__r.ProductEnName__c;
        	// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
            // 予定表の部屋ごとの料理の数量の小数点00サプレス対応
            qty = CommUtils.deleteRightZero(CommUtils.nullToBlank(s.Amount__c));//数量
            // 商品コード
            productCode = CommUtils.nullToBlank(s.refAccountMaster__r.Field3__c == null ? s.Field3__c : s.refAccountMaster__r.Field3__c);
            // 商品ID
            productId = s.refAccountMaster__c;
            // 合計金額
            amountPrice = CommUtils.nullToBlank(s.SpTotal__c);
            // 2018/08/31 料理進捗機能追加　by zy BEGIN
            cookInfo = s.CookInfo__c;
            objectid = s.id;
            // 2018/08/31 料理進捗機能追加　by zy END
        }
        // 2018/08/31 料理進捗機能追加　by zy BEGIN
        public ReportDetail(Tran1__c s,boolean isEnLanguage) {
            // 商品名
            productName = CommUtils.nullToBlank(s.Field7__r.Name == null ? s.Field5__c : s.Field7__r.Name);
            // 2018/02/07 オーダーエントリー画面の英語対応 by zy BEGIN
            if (isEnLanguage && !CommUtils.isBlank(s.Field7__r.ProductEnName__c)) productName = s.Field7__r.ProductEnName__c;
        	// 2018/02/07 オーダーエントリー画面の英語対応 by zy END
            // 予定表の部屋ごとの料理の数量の小数点00サプレス対応
            qty = CommUtils.deleteRightZero(CommUtils.nullToBlank(s.Field21__c));//数量
            // 商品コード
            //productCode = CommUtils.nullToBlank(s.Field7__r.Field3__c == null ? s.Field3__c : s.Field7__r.Field3__c);
            productCode = CommUtils.nullToBlank(s.Field7__r.Field3__c);
            // 商品ID
            productId = s.Field7__c;
            // 合計金額
            amountPrice = CommUtils.nullToBlank(s.Field23__c);
            cookInfo = s.CookInfo__c;
            objectid = s.id;
            // 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
            accTime = s.Field1__r.CreatedDate.format('HH:mm:ss');
            // 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
        }
        public String cookInfo;
        public String objectid;
        // 2018/08/31 料理進捗機能追加　by zy END
        public String productCode {get; private set;}
        public String productName {get; private set;}
        public String qty {get; private set;}
        public String productId {get; private set;}   // 商品ID
        public String amountPrice{get; private set;}  // 合計金額
        // 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
        public String accTime; // 会計作成時間
        // 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
        public Tran1__c toTran() {
//System.debug(loggingLevel.info, productName + '=' + qty + '=' + amountPrice);
            return new Tran1__c(
                Field5__c = productName,
                Field7__c = productId,
                Field23__c = CommUtils.nullToBlank(amountPrice),
                Field21__c = qty
            );
        }
    }
    /*
    // 合計情報格納
    public class ReportSumRow {
        public ReportSumRow() {
            productSummy = 0;
        }
        public String middayIcon{get;set;}
        public String sortKey{get;set;}
        public String productName{get;set;}
        public Decimal productSummy{get;set;}
    }*/
    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
    public Set<String> otherLeadFields;
    // 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
    // 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN		
    public Map<String,Object> otherSettingMap;
    // 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END		
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN		
    public Set<Id> cookOpIdSet; // 会計商品OP集合
    // 指定OP取得
    private Set<Id> getOpIdSet(Set<Decimal> ops){
        Set<Id> opSet = new Set<Id>();
        List<OP__c> opLst = [select id from op__c where OPcode1__c = :ops];
        if (!opLst.isEmpty()) {
            for (OP__c op : opLst) {
                opSet.add(op.id);
            }
        }
        return opSet;
    }
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
}