/**
* バッチ:在庫調整対象情報
* INIT:初期化する
* 2018/09/03 JR2way最大連携期間定義できる/部屋タイプ存在チェック機能対応追加
* 2019/04/01 JR2way部屋タイプコードが未定義の場合、連係対象外になる改善対応
* 2019/09/19 リクエスト方式改善対応(1部屋タイプ30日単位リクエスト実施)
**/
public with sharing class JR_StockAdjustmentBatchExtend implements Database.Batchable<StockChangeHisotry__c>, Database.Stateful,Database.AllowsCallouts{
    // 検索SOQL
    //private final String Query;                 
    // 共通定数
    // 在庫変更履歴関連定数
    private static final String SERVICE_KEY = JR_ServiceCtrl.SERVICE_KEY;
    private static final String STOCK_STATUS_NOSYNC = '未連携';
    private static final String STOCK_STATUS_SYNCNG = '連携NG';
    private static final String STOCK_STATUS_SYNCOUT = '連携不要';
    private static final String STOCK_STATUS_SYNCOK = '連携済';
    // 連携結果の関連定数
    private static final String COOP_STATUS_STOCKNG = '在庫調整NG';
    private static final String COOP_FUNCTION_TYPE_STOCK = '在庫調整';
    // 処理単位のログ記述する
    private CommLogUtils log = new CommLogUtils('JR_StockAdjustmentBatch', true);
    // バッチ重複起動されるチェック
    private boolean isDupFlg = false;
    // 今回スケジュール対象部屋タイプIDを格納する
    private List<Id> targetIds;
    // スケジュールからバッチ起動用Method
    public JR_StockAdjustmentBatchExtend() {}
    public JR_StockAdjustmentBatchExtend(List<Id> pTargetIds) {
        targetIds = pTargetIds;
    }
    
    // ***********************************
    // バッチ処理開始
    // ***********************************
    public Iterable<StockChangeHisotry__c>  start(Database.BatchableContext BC){
        // 重複起動されるがどうかチェックする
        isDupFlg = (BI_JR_ServiceConfigHelp.isStockDupStartCheck(BC.getJobId()));
        if (isDupFlg) return (new List<StockChangeHisotry__c>());
        // 対象データがなかった場合
        if (targetIds == null || targetIds.isEmpty()) return (new List<StockChangeHisotry__c>());
        Id targetRoomId =  targetIds[0];
        targetIds.remove(0);
        
        // 最大連携機関を設定する
        Integer stockSyncMaxMonths = BI_JR_ServiceConfigHelp.getCommConfig().stockSyncMaxMonths;
        if (stockSyncMaxMonths <= 0 ) StockSyncMaxMonths = 13;
        Date dtNow = Date.today();
        Date dtMax = Date.newInstance(dtNow.year(), dtNow.month(), 1).addMonths(stockSyncMaxMonths + 1);
        // 連携対象部屋タイプを取得する
        String Query = 'Select id,RoomTypeCode__c,ShopInfoRef__r.ShopCode__c,MaxRooms__c from TypeOfRooms__c where Id = :targetRoomId';
        List<TypeOfRooms__c> targetRoomTypes = DataBase.query(Query);
        if (targetRoomTypes.isEmpty()) return (new List<StockChangeHisotry__c>());
        TypeOfRooms__c roomtype = targetRoomTypes[0];
        // ***********************************************
        // 該当部屋タイプ関連在庫調整連携を行う
        // ***********************************************
        // 指定期間のデータリストを取得、GROUPして、データ状態を集計する
        List<Date> dates = CommUtils.getDaysList(dtNow, dtNow.daysBetween(dtMax));
        // 該当在庫変更履歴、既にDataFix実施済みがどうか
        Boolean isFixedFlg = DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c;
        // 該当日付リスト（文字列）を取得する
        List<String> strDates = new list<String>();
        if (isFixedFlg) {
            for (Date dt : dates) strDates.add(CommUtils.dateToYYYYMMDD(dt));
        }
        // 連携対象ステータス情報を格納する
        set<string> status = new set<string>{STOCK_STATUS_NOSYNC,STOCK_STATUS_SYNCNG};
        // 指定期間の連携データ存在がどうか集計を行う
        // 検索用SQL作成する
        String groupSql = 'select max(name) key, StockChangeDate__c dt, SalesStatus_del__c status from StockChangeHisotry__c ';
        groupSql += 'where TypeOfRoomRef__c = :targetRoomId and JrStatusLst__c in :status ';
        if (isFixedFlg) {
            groupSql += 'and StockChangeDateKey__c in :strDates ';
        } else {
            groupSql += 'and StockChangeDate__c in :dates ';
        }
        groupSql += 'group by StockChangeDate__c, SalesStatus_del__c ';
        groupSql += 'order by StockChangeDate__c, SalesStatus_del__c ';
        // 最終状態を取得する
        AggregateResult[] groupedResults = DataBase.query(groupSql);
        // 該当調整日の最終販売状態と取得のデータのName値
        StockInfo parseStock = new StockInfo(roomtype);
        for (AggregateResult avgRs : groupedResults) {
            parseStock.addObject(avgRs);
        }
        return parseStock.getSyncStockInfLst();
    }
    // ***********************************
    // バッチロジック処理開始「バッチサイズは1 前提条件」
    // 処理詳細、部屋タイプ別、調整日付、販売状態別グループして、最終状態でJRへ同期処理を行う(31日間データ一括リクエスト)
    // ***********************************
    public void execute(Database.BatchableContext BC, List<StockChangeHisotry__c> scope){
        // Batch Size is 31
        if (scope.isEmpty()) return;
        // 処理異常判別用フラグ初期化する
        log.clear();
        log.write_method_start('JR_StockAdjustmentBatch_execute');
        // 2018/12/19 らく通性能改善、リクエストに１秒間隔を追加対応 WSQ BEGIN
/*TODO
        log.write_log('>>> execute start at ' + DateTime.now().format('yyyy/MM/dd hh:mm:ss:SSS'));
        Integer sleepTime = 1100;
        try {
            Integer wksleepTime = BI_JR_ServiceConfigHelp.getCommConfig().sleepTime;
            if (wksleepTime > sleepTime) sleepTime = wksleepTime;
        } catch (Exception e){}
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < sleepTime) {
          //sleep 1s
          finishTime = DateTime.now().getTime();
        }
        log.write_log('>>> execute start at ' + DateTime.now().format('yyyy/MM/dd hh:mm:ss:SSS'));
*/
        // 2018/12/19 らく通性能改善、リクエストに１秒間隔を追加対応 WSQ END

system.debug(loggingLevel.info, 'scope='+scope.size());
system.debug(loggingLevel.info, 'scope[1]='+scope[0].TypeOfRoomRef__r);
system.debug(loggingLevel.info, 'scope[2]='+scope[0].StockChangeDate__c);
system.debug(loggingLevel.info, 'scope[3]='+scope[scope.size()-1].StockChangeDate__c);
//return;
        // 性能改善対応[31間連携データを一括送信を行う]
        TypeOfRooms__c roomtype = scope[0].TypeOfRoomRef__r;
        Date begDt = scope[0].StockChangeDate__c;
        Date endDt = scope[scope.size()-1].StockChangeDate__c;
        // 該当部屋タイプのプラングループ関連の残室数を取得する[店舗コード情報]
        String shopCode = CommUtils.nullToBlank(roomtype.ShopInfoRef__r.ShopCode__c);
        // 部屋タイプコード
        String roomTypeCd = CommUtils.nullToBlank(roomtype.RoomTypeCode__c);
        // ***********************************************
        // 該当店舗情報の接続定義はXMLに未定義する場合、処理対象外
        // ***********************************************
        if (!BI_JR_ServiceConfigHelp.isContractShop(shopCode)) {
            // 連携対象外店舗設定されている
            log.write_log('店舗コード['+shopCode+']はXMLに定義されていないため、連携不要対象になる.');
            // 在庫ステータスを更新する
            updStockByRoomTypeId(roomtype,begDt,endDt,STOCK_STATUS_SYNCOUT);
            return;
        }
        // 該当部屋タイプ情報はらく通側に定義されているがどうか確認する
        // サビース初期化
        JR_ServiceCtrl jrService = new JR_ServiceCtrl(log);
        // ***********************************************
        // らく通側管理している部屋タイプ情報を取得する
        // ***********************************************
        // 部屋タイプリスト対象チェック
        JR_ServiceCtrl.JR_GetRoomTypeReply rep = jrService.calGetRoomType(shopCode);
        // 取得APIがエラーが発生する場合
        if (!rep.commonResponse.isSuccess) {
            // エラー個別処理:
            log.write_log('[部屋マスタ取得 API]実施取得失敗'+rep.commonResponse.errorDescription);
            // 処理中止
            return;
        }
        // 管理している部屋タイプが今回の部屋タイプが含めるがどうか確認する
        Boolean isHaveRoomTypeFlg = false;
        for (JR_ServiceCtrl.JR_RoomTypeItem item : rep.roomTypeList) {
			log.write_log('item:'+item );
            if (item.RoomTypeCode == roomTypeCd) {
                isHaveRoomTypeFlg = true;
                break;
            }
        }
		log.write_log('isHaveRoomTypeFlg:'+isHaveRoomTypeFlg );
        // 部屋タイプ定義対象が存在しない場合
        if (!isHaveRoomTypeFlg) {
            log.write_log('該当部屋タイプコード['+roomTypeCd+']はJR側に定義されていないため、連携対象外になる');
            // 連携結果を更新を行う
            updStockByRoomTypeId(roomtype,begDt,endDt,STOCK_STATUS_SYNCOUT);
            return;
        }
        // ***********************************************
        // 該当部屋タイプ関連在庫調整連携を行う
        // ***********************************************
        // らく通連携を行う
        callNetStockSearchService(roomtype, scope, shopCode);
        log.write_log('>>> execute end at ' + DateTime.now().format('yyyy/MM/dd hh:mm:ss'));
        log.write_method_end();
    }
    // 関連の連携情報データを更新する　
    private void updStockInfo (TypeOfRooms__c pRoomType, List<StockChangeHisotry__c> stockLst) {
        Boolean isFixedFlg = DataFixManagerUtils.getInstance().StockChangeHisotryFixed__c;
        // 該当日付リスト（文字列）を取得する
        List<String> strDates = new list<String>();
        List<Date> dates = new list<date>();
        // map<調整日,Name> 該当日最後更新データ
        //map<date,string> maxNameMap = new map<date, string>();
        map<date,StockChangeHisotry__c> dayStockMap = new map<date,StockChangeHisotry__c>();
        for (StockChangeHisotry__c stock : stockLst)  {
            Date stockDt = stock.StockChangeDate__c;
            if (isFixedFlg) strDates.add(CommUtils.dateToYYYYMMDD(stockDt));
            else dates.add(stockDt);
            // 最大名を取得、格納する
            //maxNameMap.put(stockDt, stock.CreateSource__c);
            dayStockMap.put(stockDt, stock);
        }
        // 連携対象ステータス情報を格納する
        set<string> status = new set<string>{STOCK_STATUS_NOSYNC,STOCK_STATUS_SYNCNG};
        // 指定期間の連携データ存在がどうか集計を行う
        Id roomTypeId = pRoomType.Id;
        // 検索用SQL作成する
        String groupSql = 'select name, StockChangeDate__c, SalesStatus_del__c from StockChangeHisotry__c ';
        groupSql += 'where TypeOfRoomRef__c = :roomTypeId and JrStatusLst__c in :status ';
        if (isFixedFlg) {
            groupSql += 'and StockChangeDateKey__c in :strDates ';
        } else {
            groupSql += 'and StockChangeDate__c in :dates ';
        }
        groupSql += ' order by name limit 10000 ';
        // 関連更新データ一覧を取得して、
        // 該当３１日間最大１万件連携データを更新する（31*150)[日単位１部屋タイプは１５０回在庫変更値まで想定]
        list<StockChangeHisotry__c> updateStockLst = new list<StockChangeHisotry__c>();
        for (StockChangeHisotry__c stock : DataBase.query(groupSql)) {
            StockChangeHisotry__c org = dayStockMap.get(stock.StockChangeDate__c);
            // 最大値超えるデータは更新更新対象外
            if (stock.name > org.CreateSource__c) continue;
            stock.JrStatusLst__c = org.JrStatusLst__c;
            stock.JrProcessLog__c = org.JrProcessLog__c;
            stock.SyncRquestNo__c = org.SyncRquestNo__c;
            updateStockLst.add(stock);
        }
        if (!updateStockLst.isempty()) update updateStockLst;
    }
    // 該当部屋タイプ関連の在庫変更履歴を一括更新する
    private void updStockByRoomTypeId(TypeOfRooms__c rType, Date begDate, Date endDate ,String updStatus) {
        // 既存在庫連携データを一括更新を行う
        set<string> status = new set<string>{STOCK_STATUS_NOSYNC,STOCK_STATUS_SYNCNG};
        string msg = log.getAllLog();
        Id roomtypeId = rType.Id;
        Date begDt = begDate;
        Date endDt = endDate;
        list<StockChangeHisotry__c> stockLst = [select id,JrStatusLst__c from StockChangeHisotry__c where TypeOfRoomRef__c = :roomtypeId and JrStatusLst__c in :status 
                                                and StockChangeDate__c >= :begDt and StockChangeDate__c <= :endDt
                                                order by name limit 10000 ];
        for (StockChangeHisotry__c stock : stockLst) {
            stock.JrStatusLst__c = updStatus;
            stock.JrProcessLog__c = removeOverLogString(msg);
        }
        update stockLst;
    }
    // ネット販売,JR側の最新在庫残室数情報を取得する[タイプグループ単位]
    private void callNetStockSearchService (TypeOfRooms__c pRoomType, List<StockChangeHisotry__c> sfStocks, String shopCode) {

        log.write_method_start('callNetStockSearchService');
        log.write_log('P2：'+pRoomType);
        //log.write_log('P2：'+ajdustDate);
        //log.write_log('P3：'+sfStock);
        log.write_log('P3：'+sfStocks.size());
        //log.write_log('P4：'+stockChangeCnt);
        log.write_log('P4：'+shopCode);
        // 処理対象データが存在しない場合、処理中止
        if (sfStocks.isEmpty()) return;
        // 2018/09/03 JR2way最大連携期間定義できる/部屋タイプ存在チェック機能対応追加 BEGIN
        // 部屋タイプがJR側に定義されているがどうチェックははず、在庫調整の処理結果により、連携結果を設定する
        // 指定期間の最新在庫値を取得する
        Set<Date> stockDates = new Set<Date>();
        for (StockChangeHisotry__c stock : sfStocks) stockDates.add(stock.StockChangeDate__c);
        // 在庫値
        StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
        // 既に利用済み部屋数を取得する
        map<string, Decimal> usdRoomsMap = helpUtils.getStockUsedInfo(new set<Id>{pRoomType.ID},stockDates);
        // 部屋タイプの最大在庫値を取得する
        map<string, Decimal> maxRoomMap = helpUtils.getSfMaxRoomOfRoomType(pRoomType, stockDates);
        // 関連の在庫連携情報
        JR_ServiceCtrl.RoomStockInfo ext = new JR_ServiceCtrl.RoomStockInfo();
        ext.StockNo = System.now().format('yyyyMMddHHmmssSSS')+CommUtils.getRandom(3); //sfStocks[0].Name.split('-')[1];
        ext.RoomTypeCode = CommUtils.nullToBlank(pRoomType.RoomTypeCode__c);
        // 連携対象情報を設定する
        for (StockChangeHisotry__c stock : sfStocks) {
log.write_log('******stock******'+stock);
            // 検索キー
            String key = helpUtils.getRoomStockKey(stock.TypeOfRoomRef__c, stock.StockChangeDate__c);
            // 両方情報存在場合
            decimal maxRooms = maxRoomMap.get(key);
            decimal usedRooms = usdRoomsMap.get(key);
//log.write_log('******key******'+key);
log.write_log('******最大在庫数******'+maxRooms);
log.write_log('******利用部屋数******'+usedRooms);
            if (maxRooms == null) continue;
            // 連携パラメータを設定する
            JR_ServiceCtrl.DayStockInfo dstock = new JR_ServiceCtrl.DayStockInfo();
            dstock.StockDate = dateJr2wayDateStr(stock.StockChangeDate__c);
            // 2018/06/22 在庫マナスーの場合、ログ記録する BEGIN
            //Integer sfRemainingCount = ((maxRooms - usedRooms) < 0 ) ? 0 : (maxRooms - usedRooms);
            dstock.VacantRoomCount = ((CommUtils.nullToIntZero(maxRooms) - CommUtils.nullToIntZero(usedRooms)) < 0 ) ? 0 : (CommUtils.nullToIntZero(maxRooms) - CommUtils.nullToIntZero(usedRooms));
log.write_log('******残室数******'+dstock.VacantRoomCount);
            if (!CommUtils.isBlank(stock.SalesStatus_del__c)) {
                dstock.CloseCategory = (stock.SalesStatus_del__c == CommConst.STOCK_SET_STOP ? '1' : '0');
            }
log.write_log('******dstock******'+dstock);
            // 連携対象情報を設定する
            ext.SettingDateList.add(dstock);
        }

        log.write_log('******在庫調整(ネット販売)API 呼出開始******');
        //log.write_log('******ext******'+ext);
        // 在庫調整サビースを呼出
        JR_ServiceCtrl jrService = new JR_ServiceCtrl(log);
        JR_ServiceCtrl.InventorySettingReply rep = jrService.calInventorySetting(shopCode, ext);
//log.write_log('rep='+rep); 
log.write_log('rep.commonResponse.isSuccess='+rep.commonResponse.isSuccess);
        // 取得APIがエラーが発生する場合
        if (!rep.commonResponse.isSuccess) {
            // 再連携不要、連携対象外と判定する
            map<string,string> syncoutmap = new map<string,string> {
                '003'=>'販売期間が終了しているため、在庫調整 NG。',
                '004'=>'らく通では管理していない部屋タイプのため、在庫調整 NG。',
                '005'=>'在庫調整期間外のため、在庫調整 NG。',
                '007'=>'手仕舞い時間を過ぎているため、在庫調整 NG。'
            };
            // 再連携必要エラー
            map<string,string> waiterrmap = new map<string,string> {
                '001'=>'施設コードの指定誤り。',
                '002'=>'部屋タイプコードの指定誤り。',
                '006'=>'らく通にて在庫の状態が未反映のため、在庫調整 NG。',
                '201'=>'認証エラー。',
                '202'=>'要求 XML フォーマットエラー。',
                '203'=>'DB タイムアウト。',
                '204'=>'部屋タイプもしくは日付の要求数を超過。',
                '205'=>'その他システムエラー。',
                '206'=>'重複した部屋タイプが存在する',
                '207'=>'重複した日付が存在する。',
                '208'=>'室数に数字以外がセットされている。',
                '210'=>'要求量が制限を超過した。',
                '211'=>'要求量が制限を超過した。'
            };
            // 日別エラー情報により、設定を行う
            //List<StockChangeHisotry__c> sfStocks
            map<date,string> resultMap = rep.dataErrMap;
            String msg = log.getAllLog();
            for (StockChangeHisotry__c sfStock : sfStocks) {
                // 該当調整日のエラーの場合
                Date stockdt = sfStock.StockChangeDate__c;
                sfStock.SyncRquestNo__c = ext.StockNo;//リクエストIDを設定する
                if (resultMap.containsKey(stockdt)) {
                    String errcd = resultMap.get(stockdt);
                    // 再連携不要の場合
                    if (syncoutmap.containsKey(errcd)) {
                        sfStock.JrStatusLst__c = STOCK_STATUS_SYNCOUT;
                        sfStock.JrProcessLog__c = removeOverLogString(msg + '\n\n' + errcd + ':'+syncoutmap.get(errcd));
                    } else if (waiterrmap.containsKey(errcd)) {
                        sfStock.JrStatusLst__c = STOCK_STATUS_SYNCNG;
                        sfStock.JrProcessLog__c = removeOverLogString(msg + '\n\n' + errcd + ':'+waiterrmap.get(errcd));                  
                    } else {
                        sfStock.JrStatusLst__c = STOCK_STATUS_SYNCNG;
                        sfStock.JrProcessLog__c = removeOverLogString(msg + '\n\n' +  rep.commonResponse.failureReason);    
                    }
                } else {
                    // 処理OK意味
                    sfStock.JrStatusLst__c = STOCK_STATUS_SYNCOK;
                    sfStock.JrProcessLog__c = removeOverLogString(msg);
                }
            }
        } 
        // 処理OKの場合
        else {
            String msg = removeOverLogString(log.getAllLog());
            for (StockChangeHisotry__c sfStock : sfStocks) {
                // 処理OK意味
                sfStock.JrStatusLst__c = STOCK_STATUS_SYNCOK;
                sfStock.JrProcessLog__c = msg;
                sfStock.SyncRquestNo__c = ext.StockNo;//リクエストIDを設定する
            }
        }
        // 処理結果により、関連の連携対象データを一括更新を行う
        updStockInfo(pRoomType,sfStocks);
        
        log.write_log('******在庫調整(ネット販売)API 呼出終了******');

        log.write_method_end();
    }
        
    // ***********************************
    // バッチ終了処理開始
    // ***********************************
    public void finish(Database.BatchableContext BC){
        // 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
        if (isDupFlg != null && isDupFlg) return;
        // 2016/12/14 バッチ重複起動されるチェック　Wgch END
        // 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch BEGIN
        if (BI_JR_ServiceConfigHelp.isStockBatchStopCheck()) return;
        // 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
        // 作成日は2週間前の在庫変更履歴情報を削除する[連携不要、連携済]
        try {
            if (BI_JR_ServiceConfigHelp.getCommConfig().bIsDebug) return;
            Date deleteDate = Date.today().addDays(BI_JR_ServiceConfigHelp.getCommConfig().mStockDeleteVal);
            //log.write_log('調整日は['+deleteDate.format()+']前の在庫変更履歴情報を削除');
            // 2016/03/04 ゴミデータの削除条件を変更する
            List<StockChangeHisotry__c> stockChangList = [select id,CooperationResultRef__c,CooperationResultJrRef__c from StockChangeHisotry__c where StockChangeDate__c < :deleteDate limit 100];
            Set<Id> deleteCoopIdsSet = new Set<Id>();
            for (StockChangeHisotry__c stock : stockChangList) {
                if (stock.CooperationResultRef__c != null) deleteCoopIdsSet.add(stock.CooperationResultRef__c);
                if (stock.CooperationResultJrRef__c != null) deleteCoopIdsSet.add(stock.CooperationResultJrRef__c);
            }
            // 2018/03/07 Security Check BEGIN
            if (!CommSecurityUtils.isDeleteable(StockChangeHisotry__c.getSObjectType()) ||
                !CommSecurityUtils.isDeleteable(CooperationResult__c.getSObjectType())){
                return;
            }
            // 2018/03/07 Security Check END
            // ゴミデータを削除する
            if (!stockChangList.isEmpty()) database.delete(stockChangList,false);
            if (!deleteCoopIdsSet.isEmpty()) {
                database.delete([select id from CooperationResult__c where id in :deleteCoopIdsSet], false);
            }
//CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.POS,new List<String>());
        } catch (Exception e){
            system.debug(logginglevel.info,e.getmessage());
        }
        // 処理データがまだある場合、次のバッチを起動する
        callNextSchedule(); 
    }
    
    // 次のスケジュールを起動する    
    private void callNextSchedule(){
        // 次部屋処理対象が存在場合、次のバッチを呼び出し
        if (!targetIds.isEmpty()) {
            JR_StockAdjustmentBatchExtend batch = new JR_StockAdjustmentBatchExtend(targetIds);
            Id batchJobId = DataBase.executeBatch(batch,BI_JR_ServiceConfigHelp.SYNC_RANGE_DAYS);
            return;
        }
        // 在庫調整バッチの時間間隔
        Integer intervalLength = BI_JR_ServiceConfigHelp.DEF_MIN_INTERVAL_STOCK;
        try {
            // XML定義の時間間隔情報を取得する
            intervalLength = BI_JR_ServiceConfigHelp.getCommConfig().mStockInterval;
        } catch(Exception e){}
        JR_StockAdjustmentBatch schedule= new JR_StockAdjustmentBatch();
        DateTime nowTime = DateTime.now().addSeconds(intervalLength);
        // 起動ＣＲＯＮを設定する
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = 'JR_StockAdjustmentBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        String jobId = system.schedule(jobName, sch, schedule);
    }
	/*
    // エラー処理
    private void callErroProcess(StockChangeHisotry__c stock, String shopCode) {
        // 2017/02/24 Field Security Check BEGIN
        List<String> chkFieldsLst = new List<String>{'ProcessLog__c','MailSendComplete__c','ErrorCount__c','ErrorContent__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.CooperationResult__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
            return;
        }
        // 2017/02/24 Field Security Check End
        if (stock.CooperationResultJrRef__c != null) {
            // エラー回数を更新する
            CooperationResult__c updCoop = new  CooperationResult__c(Id = stock.CooperationResultJrRef__c);
            String orgErrMsg =  stock.CooperationResultJrRef__r.ErrorContent__c;    
            String newErrMsg = removeOverErrString(log.getLastError());
            if (orgErrMsg != newErrMsg) {
                updCoop.ErrorCount__c = 1;
                updCoop.ErrorContent__c = newErrMsg;
                updCoop.MailSendComplete__c = false;
            } else {
                updCoop.ErrorCount__c = CommUtils.nullToZero(stock.CooperationResultJrRef__r.ErrorCount__c) + 1;
            }
            // 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
            // 最新のエラーメッセージは既に送信済みの場合
            // 前回送信済みのエラーメッセージと同じ場合、
            if (BI_JR_ServiceConfigHelp.isStockDupErrorMsgCheck(newErrMsg, false)) {
                Boolean orgCoopMailSendFlg = stock.CooperationResultJrRef__r.MailSendComplete__c;
                // 未送信の場合
                if (orgCoopMailSendFlg == false) {
                    if (updCoop.ErrorCount__c > 4 ) updCoop.ErrorCount__c = 4;
                }
            }
            // 2017/08/24 同じエラーは重複送信しないように回避対応 END
            updCoop.ProcessLog__c = removeOverLogString(log.getAllLog());
            setSendMailAddress(updCoop);
            update updCoop;
        } else {
            // 新規作成を行う
            CooperationResult__c newCoop = new CooperationResult__c(
                Status__c = COOP_STATUS_STOCKNG,
                ProcessingType__c = SERVICE_KEY,
                FunctionType__c = COOP_FUNCTION_TYPE_STOCK,
                ErrorCount__c = 1,
                ErrorContent__c = removeOverErrString(log.getLastError()),
                MailSendComplete__c = false,
                ManageID__c = SERVICE_KEY + '_' + stock.Id,
                ShopCode__c = shopCode,
                ProcessLog__c =  removeOverLogString(log.getAllLog())
            );
            setSendMailAddress(newCoop);
            upsert newCoop CooperationResult__c.ManageID__c;
            stock.CooperationResultJrRef__c = newCoop.Id;
        }
        // 処理ステータスは未設定の場合、処理NGを設定する
        if (CommUtils.isBlank(stock.JrStatusLst__c)) {
            stock.JrStatusLst__c = STOCK_STATUS_SYNCNG;
        }
    }*/
    /**
    * ログは最大格納値を超えると、最後から格納する
    **/
    private String removeOverLogString(String log) {
        return CommLogUtils.removeOverLogString(log);
    }
    private String removeOverErrString(String err) {
        return CommLogUtils.removeOverLogString(err,255);
    }
    /**
    * メール通知先のアドレス宛を設定する
    **//*
    private void setSendMailAddress(CooperationResult__c coop) {
        // メール送信
        String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
        if (CommUtils.isBlank(mailAdds)) mailAdds=UserInfo.getUserEmail();
        String[] toAddresses = mailAdds.split(',');
        coop.MailSendAddress1__c = toAddresses[0];
        if (toAddresses.size() > 1) coop.MailSendAddress2__c = toAddresses[1];
        if (toAddresses.size() > 2) coop.MailSendAddress3__c = toAddresses[2];
        if (toAddresses.size() > 3) coop.MailSendAddress4__c = toAddresses[3];
        if (toAddresses.size() > 4) coop.MailSendAddress5__c = toAddresses[4];
    }*/
    /**
    * 同時に同じ在庫調整データを更新回避するため、更新処理関数を追加する
    **/
    private void updateLock(StockChangeHisotry__c updStock) {
        // 2017/02/24 Field Security Check BEGIN
        List<String> chkFields = new List<String>{'JrStatusLst__c','JrProcessLog__c'};
        Map<String,Schema.SObjectField> m = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
            return;
        }
        // 在庫変更履歴更新を行う
        list<StockChangeHisotry__c> lockData = [select id from StockChangeHisotry__c where id = :updStock.Id for update];
        if (!lockData.isEmpty()) {
            update updStock;
        }
    }
    // 2017/05/25 在庫調整連携方式変更対応 BEGIN
    /**
    * 該当部屋のSF在庫数はTAへ連携送信を行う
    * 指定日と指定部屋により、残室数情報を取得する
    * SF最大在庫ー（故障部屋数＋有効予約）計算した残室数をTAへ送信する
    * Return: 利用済みの部屋数
    **/
    /* #9898 BugFix 無用なMethodを削除する WSQ BEGIN
    /*
    private Integer getSfStockOfRoomType(Date pStockDate, Id pRoomTypeId) {
        StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
        map<string, Decimal> usdRoomsMap = helpUtils.getStockUsedInfo(new set<Id>{pRoomTypeId},new set<Date>{pStockDate});
        if (usdRoomsMap.isEmpty()) return 0;
        else return CommUtils.nullToIntZero(usdRoomsMap.values()[0]);
    }
    #9898 BugFix 無用なMethodを削除する WSQ END */
    // 2017/05/25 在庫調整連携方式変更対応 END
    // 部屋タイプ別指定日付範囲の在庫調整情報を格納
    class StockInfo {
        // 該当調整日付の最終状態設定ある場合、状態を格納する、ない場合、日付情報のみ格納する
        public StockInfo(TypeOfRooms__c pRoomtype) {
            roomTypeId = pRoomtype.Id;
            roomtype = pRoomtype;
            maxNameMap = new map<Date, String>();
            maxStatusMap = new map<Date, String>();
        }
        public void addObject(AggregateResult s) {
            String key = CommUtils.nullToBlank(s.get('key'));
            Date dt = (Date)s.get('dt');
            String status = CommUtils.nullToBlank(s.get('status'));
            if (!maxNameMap.containsKey(dt)) {
                maxNameMap.put(dt,key);
                maxStatusMap.put(dt,status);
            } else {
                // 同じ日付、ステータス存在場合、更新設定お行う
                String locKey = maxNameMap.get(dt);
                String locStatus = maxStatusMap.get(dt);
                // 既存調整日付が存在場合、該当調整のNAME最大値を取得する
                if (key > locKey) maxNameMap.put(dt, key);
                // 新たステータスが存在場合、該当ステータスを格納する
                if (!CommUtils.isBlank(status)) {
                    // 元のステータスが空白場合、販売ステータスはMAPに格納する
                    if (CommUtils.isBlank(locStatus)) maxStatusMap.put(dt, status);
                    // 元のステータスが存在場合、該当データのNAMEは最新するがどう判断する
                    else if (key > locKey) {
                        maxStatusMap.put(dt, status);
                    }
                }
            }
        }
        // 連携対象在庫調整情報を取得する
        public list<StockChangeHisotry__c> getSyncStockInfLst () {
            list<StockChangeHisotry__c> retLst = new list<StockChangeHisotry__c>();
            list<Date> syncDateLst = new list<Date>(maxNameMap.keyset());
            syncDateLst.sort();
            // 日付リストを作成後、一覧リストを返却する
            for (Date dt : syncDateLst) {
                StockChangeHisotry__c item = new StockChangeHisotry__c(
                    CreateSource__c = maxNameMap.get(dt),//該当日最後のNo、該当番号以後の連携データを更新しない
                    StockChangeDate__c = dt,
                    TypeOfRoomRef__c =roomTypeId,
                    TypeOfRoomRef__r = roomtype,
                    SalesStatus_del__c = CommUtils.nullToBlank(maxStatusMap.get(dt))
                );
                retLst.add(item);
            }
            return retLst;
        }
        // 部屋タイプID
        string roomTypeId;
        TypeOfRooms__c roomtype;
        // 該当日の最大NAME値を格納する
        map<Date,String> maxNameMap;
        // 該当日の販売ステータスを格納する
        map<Date,String> maxStatusMap;
    }
    private String dateJr2wayDateStr(Date dt) {
        if (dt == null) return '';
        return (Datetime.newInstance(dt.year(),dt.month(),dt.day())).format('yyyy-MM-dd');
    } 
}