/**
* バッチ:在庫調整対象情報
* INIT:初期化する
* 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する
* 2015/12/11 在庫調整機能改善：在庫マイナス設定対象外、残室数はNULLの場合、未処理のまま残り、在庫連携対象期間を設定
*            調整不可の室タイプは調整対象外になる
*            バッチ起動後作成の在庫調整情報のみ在庫連携を行う
* 2016/01/20 販売ステータスは２「停止中」の場合、該当室タイプグループは連携対象外する
* 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加
* 2016/02/19 論理連携済のデータ検索条件変更対応
* 2016/05/12 在庫調整日付はデータ取得条件から削除
* 2016/08/18 在庫調整バッチ出力ロゴ場所変更対応
* 2016/10/06 在庫調整対象[仮データ]は抽出対象外
**/
public with sharing class TA_StockAdjustmentBatchExtend implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
	// 検索SOQL
	private final String Query;					
	// 共通定数
	private final String SERVICE_KEY = TA_ServiceCtrl.SERVICE_KEY;
	private static final String STOCK_STATUS_NOSYNC = '未連携';
	private final String STOCK_STATUS_SYNCNG = '連携NG';
	private final String STOCK_STATUS_SYNCOUT = '連携不要';
	private final String STOCK_STATUS_SYNCOK = '連携済';
	private static final String STOCK_STATUS_LOGIC_SYNCOK = '論理連携済';
	
	private final String AGT_TYPE_NET = 'ネット';
	
	private final String COOP_STATUS_STOCKNG = '在庫調整NG';
	private final String COOP_FUNCTION_TYPE_STOCK = '在庫調整';

	private DateTime gScheduleBeginTime;
	// 処理単位のログ記述する
	private CommLogUtils log = new CommLogUtils('TA_StockAdjustmentBatch', true);
	//private final String logManagerId = 'TA_STOCK_LOG_000000000';
	// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
	private boolean isDupFlg = false;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch END
	// 2017/05/25 在庫調整連携方式変更対応 BEGIN
	private boolean isSyncSfStockToTaMode;
	// 2017/05/25 在庫調整連携方式変更対応 END
	// スケジュールからバッチ起動用Method
	public TA_StockAdjustmentBatchExtend(DateTime pScheduleBeginTime) {
		// バッチ起動時間
		gScheduleBeginTime = pScheduleBeginTime;
		// 調整日付は当日以後の日付を連動する
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		Query = 'Select Id,LeadRef__c,TaStatusLst__c,StockChangeDate__c,StockChangeCnt__c,TypeOfRoomRef__c,TypeOfRoomRef__r.RoomTypeCode__c,TypeOfRoomRef__r.ShopInfoRef__r.ShopCode__c,AgtRef__c,AgtRef__r.SalesOfficeCompanyType__c,AgtRef__r.Parent.SalesOfficeCompanyType__c,AgtRef__r.SalesOfficeCompanyCodeTAAPI__c,AgtRef__r.Parent.SalesOfficeCompanyCodeTAAPI__c,CooperationResultRef__c, CooperationResultTaRef__c, CooperationResultTaRef__r.ErrorCount__c, CooperationResultTaRef__r.ErrorContent__c, CooperationResultTaRef__r.MailSendComplete__c,SettingFlg__c,SalesStatus_del__c From StockChangeHisotry__c where TaStatusLst__c in (\''+STOCK_STATUS_NOSYNC+'\',\''+STOCK_STATUS_SYNCNG+'\') and ((CreateSource__c != :SERVICE_KEY And BatchRunTarget__c = null) or  (CreateSource__c = :SERVICE_KEY And BatchRunTarget__c = :SERVICE_KEY)) And StockChangeDate__c >= TODAY And Provisional__c != true ';
		// 2018/12/15 在庫調整と販売状態管理 by zy END
	}
	
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
		isDupFlg = (TA_ServiceConfigHelp.isStockDupStartCheck(BC.getJobId()));
		if (isDupFlg) return Database.getQueryLocator('select id from StockChangeHisotry__c limit 0');
		// 2016/12/14 バッチ重複起動されるチェック　Wgch END
		/*
		log.write_method_start('バッチ処理開始');
		log.write_log('バッチ処理正常に起動された');
		log.write_method_end();
		TA_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		*/
		// 指定期間範囲内
		// 2015/12/11 在庫調整機能改善 BEGIN
		String locatorQuery = Query;
		Date restoreStartDate = null;
		Boolean bIsSyncOnlyNewFlg = true;
		// 2017/05/25 在庫調整連携方式変更対応 BEGIN
		isSyncSfStockToTaMode = true;
		// 2017/05/25 在庫調整連携方式変更対応 END
		try {
			restoreStartDate = TA_ServiceConfigHelp.getCommConfig().restoreStartDate;
			bIsSyncOnlyNewFlg = TA_ServiceConfigHelp.getCommConfig().bIsSyncOnlyNewFlg;
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			isSyncSfStockToTaMode = TA_ServiceConfigHelp.getCommConfig().bIsSf2TaSyncMode;
			// 2017/05/25 在庫調整連携方式変更対応 END
		} catch (Exception e){}
		// 2017/05/25 在庫調整連携方式変更対応 BEGIN 
		// 検索SQLをRESETする
		// 在庫調整日>=TODAY AND 仮データ !=TRUE AND TA連携ステータス IN (連携NG,未連携)
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		if (isSyncSfStockToTaMode) locatorQuery = 'Select Id,LeadRef__c,TaStatusLst__c,StockChangeDate__c,StockChangeCnt__c,TypeOfRoomRef__c,TypeOfRoomRef__r.MaxRooms__c,TypeOfRoomRef__r.RoomTypeCode__c,TypeOfRoomRef__r.ShopInfoRef__r.ShopCode__c,AgtRef__c,AgtRef__r.SalesOfficeCompanyType__c,AgtRef__r.Parent.SalesOfficeCompanyType__c,AgtRef__r.SalesOfficeCompanyCodeTAAPI__c,AgtRef__r.Parent.SalesOfficeCompanyCodeTAAPI__c,CooperationResultRef__c, CooperationResultTaRef__c, CooperationResultTaRef__r.ErrorCount__c, CooperationResultTaRef__r.ErrorContent__c, CooperationResultTaRef__r.MailSendComplete__c,SettingFlg__c,SalesStatus_del__c From StockChangeHisotry__c where TaStatusLst__c in (\''+STOCK_STATUS_NOSYNC+'\',\''+STOCK_STATUS_SYNCNG+'\') And StockChangeDate__c >= TODAY And Provisional__c != true ';
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2017/05/25 在庫調整連携方式変更対応 END
		// 2016/05/12 在庫調整日付はデータ取得条件から削除
		if (restoreStartDate != null) {
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			if (!isSyncSfStockToTaMode)
			// 2017/05/25 在庫調整連携方式変更対応 END
			locatorQuery += ' And DAY_ONLY(convertTimezone(CreatedDate)) >= :restoreStartDate ';
		} else if (bIsSyncOnlyNewFlg) {
			if (gScheduleBeginTime == null) {
				// 処理開始時刻は異常ななくなる場合、時刻は再自動設定を行う
				gScheduleBeginTime = system.now().addMinutes(-15);
			}
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			if (!isSyncSfStockToTaMode)
			// 2017/05/25 在庫調整連携方式変更対応 END
			locatorQuery += ' And CreatedDate >= :gScheduleBeginTime ';
		}
		//Date endTargetDate = Date.today().addDays(TA_ServiceConfigHelp.getCommConfig().syncMaxDays);
		//locatorQuery += ' And StockChangeDate__c <= :endTargetDate  Order By Name ';
		locatorQuery += ' Order By Name ';
//System.debug(loggingLevel.INFO, 'locatorQuery::' + locatorQuery);
//System.debug(loggingLevel.INFO, 'restoreStartDate::' + restoreStartDate);
//System.debug(loggingLevel.INFO, 'gScheduleBeginTime::' + gScheduleBeginTime);
		// 2015/12/11 在庫調整機能改善 END
		// APIへ、部屋タイプの最新定義情報を取得する
		return Database.getQueryLocator(locatorQuery);
	}
	// ***********************************
	// バッチロジック処理開始「バッチサイズは1 前提条件」
	// ***********************************
	public void execute(Database.BatchableContext BC, List<StockChangeHisotry__c> scope){
//System.debug(logginglevel.INFO,'scope:::' + scope );	
		// Batch Size is 1
		if (scope.isEmpty()) return;
		// 処理異常判別用フラグ初期化する
		//isHaveException = false;
		// LOG出力の初期化
		log.clear();
		log.write_method_start('TA_StockAdjustmentBatch_execute');
		
		// 在庫調整情報を取得する
		StockChangeHisotry__c stock = scope[0];
		// 処理ステータスはクリアする
		stock.TaStatusLst__c = null;
		// 該当部屋タイプのプラングループ関連の残室数を取得する[店舗コード情報]
		String shopCode = CommUtils.nullToBlank(stock.TypeOfRoomRef__r.ShopInfoRef__r.ShopCode__c);
		// 該当店舗情報の接続定義はXMLに未定義する場合、処理対象外
		if (!TA_ServiceConfigHelp.isContractShop(shopCode)) {
			// 連携対象外店舗設定されている
			log.write_log('店舗コード['+shopCode+']はXMLに定義されていないため、連携不要対象になる.');
			// 連携結果を更新を行う
			stock.TaStatusLst__c = STOCK_STATUS_SYNCOUT;
			stock.TaProcessLog__c = removeOverLogString(log.getAllLog());
			// 2016/08/26 EDIT BEGIN
			//update stock;
			updateLock(stock);
			// 2016/08/26 EDIT END
			return;
		}
		// 室タイプコードを取得
		Set<String> roomTypeCdSet = new Set<String>();
		String roomTypeCd = CommUtils.nullToBlank(stock.TypeOfRoomRef__r.RoomTypeCode__c);
		roomTypeCdSet.add(roomTypeCd);
		// 調整日付
		Date updateDate = stock.StockChangeDate__c;
		String updateDtStr = DateTime.newInstance(updateDate.year(), updateDate.month(), updateDate.day()).format('yyyy-MM-dd');


		// 該当予約情報はネット販売の部屋タイプの場合

		// 該当部屋タイプの関連のTA室タイプグループリストを取得する
		Boolean isSyncRoomTypeCdFlg = getRoomTypeToTaNetTypeGroupCd(roomTypeCdSet, shopCode);
		// 調整対象なし
		if (!isSyncRoomTypeCdFlg) {
			if (log.isHaveError()) {
				callErroProcess(stock, shopCode);
			} else {
				log.write_log('該当部屋タイプコード['+roomTypeCdSet+']はTA側に定義されていないため、連携対象外になる');
				// 連携結果を更新を行う
				stock.TaStatusLst__c = STOCK_STATUS_SYNCOUT;
			}
			stock.TaProcessLog__c = removeOverLogString(log.getAllLog());
			// 2016/08/26 EDIT BEGIN
			//update stock;
			updateLock(stock);
			// 2016/08/26 EDIT END
			return;
		}
		// グループコードに対して、在庫残室数情報を取得する
		// 指定の室タイプグループ、日付、残室数照会を行う
		callNetStockSearchService(roomTypeCd, updateDtStr, stock, stock.StockChangeCnt__c, shopCode);
		// 該当部屋タイプに対して、正常に完了すると、在庫変更履歴は削除を行う
		// 正常に処理完了の場合、在庫変更履歴は削除を行う
		if (log.isHaveError()) {
			callErroProcess(stock, shopCode);
		} else {
			// ERROR発生する場合、同じエラーを繰り返し問題を発生すると、
			if (CommUtils.isBlank(stock.TaStatusLst__c)) stock.TaStatusLst__c = STOCK_STATUS_SYNCOK;
			// 2016/08/24 既に連携結果NGのデータが存在する場合、該当リンクをそのまま、削除するため
			//stock.CooperationResultRef__c = null;
		}
		stock.TaProcessLog__c = removeOverLogString(log.getAllLog());
		// 2016/08/26 EDIT BEGIN
		//update stock;
		updateLock(stock);
		// 2016/08/26 EDIT END	
		log.write_method_end();
	}

	// SFの部屋タイプからTA側の室タイプグループ情報を取得する
	private Boolean getRoomTypeToTaNetTypeGroupCd(Set<String> sfRoomTypeCode, String shopCd) {
		log.write_method_start('getRoomTypeToTaNetTypeGroupCd');
		log.write_log('P１：'+sfRoomTypeCode);
		log.write_log('P２：'+shopCd);
		
		// 該当部屋タイプコードは連携対象部屋タイプするがどうか
		Boolean iSyncRoomTypeFlg = false;
		// TA API 初期化処理
		// 2016/07/29 ログ出力機能追加 BEGIN
		TA_ServiceCtrl taService = new TA_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		log.write_log('******部屋タイプマスタ検索(ネット販売)API 呼出開始******');
		// 検索を呼出
		TA_RoomTypeInfoItem rep = taService.callRoomTypeMasterSearchService(shopCd);
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******部屋タイプマスタ検索(ネット販売)API 呼出終了******');
			log.write_log('指定の部屋タイプはTA側に存在チェック開始');
			
			for (TA_RoomTypeInfoItem.RoomInfo rmInf : rep.roomList) {
				// 部屋タイプ空白の場合、対象外
				if (CommUtils.isBlank(rmInf.roomTypeCode)) continue;
				log.write_log('TA部屋タイプコード：'+rmInf.roomTypeCode);
				// 部屋タイプはTA側に設定されている場合、連携する
				if (sfRoomTypeCode.contains(rmInf.roomTypeCode)) {
					iSyncRoomTypeFlg = true;
					break;
				}
			}
			log.write_log('指定の部屋タイプはTA側に存在チェック開始終了');
		}
		log.write_method_end();
		
		return iSyncRoomTypeFlg;
	}


	
	// ネット販売,TA側の最新在庫残室数情報を取得する[タイプグループ単位]
	private void callNetStockSearchService (string roomTypeCd, String ajdustDate, StockChangeHisotry__c sfStock, Decimal stockChangeCnt, String shopCode) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'TaStatusLst__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return;
		}
		// 2018/03/07 Security Check END
		log.write_method_start('callNetStockSearchService');
		log.write_log('P１：'+roomTypeCd);
		log.write_log('P2：'+ajdustDate);
		log.write_log('P3：'+sfStock);
		log.write_log('P4：'+stockChangeCnt);
		log.write_log('P5：'+shopCode);
		
		// サビース初期化
		// 2016/07/29 ログ出力機能追加 BEGIN
		TA_ServiceCtrl taService = new TA_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		TA_RoomStockInfoGetItem.RoomStockInfo extractionCondition 
			= new TA_RoomStockInfoGetItem.RoomStockInfo();
		extractionCondition.roomTypeCode = roomTypeCd;	// 部屋タイプコード
		extractionCondition.stockDate = ajdustDate;	// 取得日付
		
		
		log.write_log('******在庫状況照会(ネット販売)API 呼出開始******');
		// 在庫状況照会(ネット販売)API 呼出
		TA_RoomStockInfoGetItem rep = taService.callStockSearchService(shopCode, new list<TA_RoomStockInfoGetItem.RoomStockInfo>{extractionCondition});
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******在庫状況照会(ネット販売)API 呼出終了******');
			
			// 取得のタイプグループの残室数を取得する
			map<string, decimal> stockMap = new map<String, Decimal>();
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
			// 残室数調整可能の室タイプグループが存在する場合：TRUE
			Boolean isCanSyncStockToTlFlg = false;
			// 残室数は未設定の室タイプグループの場合：TRUE
			Boolean remainCountNoSetupFlg = true;
			// 手仕舞いの場合、連携するがどうか
			Boolean salesCloseSync = TA_ServiceConfigHelp.getAppConfig(shopCode).salesCloseSync;
			log.write_log('手仕舞い制御フラグ:'+salesCloseSync);
			// 調整対象数
			Integer groupCnt = 0;
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			Integer sfRemainingCount = 0;
			if (isSyncSfStockToTaMode && !rep.roomStockList.isEmpty()) {
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				//Integer maxRooms = CommUtils.nullToIntZero(sfStock.TypeOfRoomRef__r.MaxRooms__c);
				StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
				Integer maxRooms = helpUtils.getSfMaxRoomOfRoomType(sfStock);
				// 2018/12/15 在庫調整と販売状態管理 by zy END
				Integer usedRooms = getSfStockOfRoomType(sfStock.StockChangeDate__c,sfStock.TypeOfRoomRef__c);
				sfRemainingCount = ((maxRooms - usedRooms) < 0 ) ? 0 : (maxRooms - usedRooms);
			}
			Boolean abortSyncFlg = false;
			// 2017/05/25 在庫調整連携方式変更対応 END
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			boolean settingFlag = sfStock.SettingFlg__c;
			// 2018/12/15 在庫調整と販売状態管理 by zy END
			for (TA_RoomStockInfoGetItem.RoomStockInfo stock : rep.roomStockList) {
				log.write_log('TA側の在庫情報:'+stock);
				// 1：手仕舞い 0：販売
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				if (stock.salesClosed == '1' && !salesCloseSync && !settingFlag) {
				// 2018/12/15 在庫調整と販売状態管理 by zy END
					log.write_log('部屋タイプコード['+stock.roomTypeCode+']は手仕舞いを行うため、販売停止中、連携対象外');
					continue;
				}
				// 調整対応数
				groupCnt++;
				// 2015/12/11 在庫残室数は未設定する場合、該当室タイプの関連
				log.write_log('グループコード['+stock.roomTypeCode+']の残室数(調整前)：'+stock.remainingCount);
		// 2017/05/25 在庫調整連携方式変更対応 BEGIN
				if (isSyncSfStockToTaMode) {
					// 3003:日付の指定が正しくありません:管理期間対象外（１２月以上になる）
					// 3006:指定日付の料金カレンダーが作成されていません
					// 上記２種類の場合、該当TYPEへ連携できない状態ですので、一回未連携のままで処理を行う
					if (stock.errorCode == '3003' || stock.errorCode == '3006') {
						String wkMsg = (stock.errorCode == '3003' ? '管理期間対象外ため' : '指定日付の料金カレンダーが作成されていません');
						log.write_log('部屋タイプコード['+stock.roomTypeCode+']は' + wkMsg + '、連携中止になる。');
						abortSyncFlg = true;
						continue;
					}
				}
				Decimal newRemainingCount = null;
		if (!isSyncSfStockToTaMode) {
		// 2017/05/25 在庫調整連携方式変更対応 END
				// 該当室タイプグループの残室数は未設定の場合、該当未連携のまま残っている、残室数設定まで連携を行う
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				if (!CommUtils.isBLank(stock.remainingCount) && CommUtils.nullToZero(stock.remainingCount) >= 0 && !settingFlag) remainCountNoSetupFlg = false;
				// 2018/12/15 在庫調整と販売状態管理 by zy END
				else continue;
				// 該当室タイプグループの残室数を取得して、今回の変動数を加算して、調整後の残室数を設定する
				// 2017/05/25 在庫調整連携方式変更対応 BEGIN
				//Decimal newRemainingCount = CommUtils.nullToZero(stock.remainingCount)  + stockChangeCnt;
				newRemainingCount = CommUtils.nullToZero(stock.remainingCount)  + stockChangeCnt;
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
                if (sfStock.SettingFlg__c) newRemainingCount = stockChangeCnt;
                // 2018/12/15 在庫調整と販売状態管理 by zy END
				// 2017/05/25 在庫調整連携方式変更対応 BEGIN
				// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
				if (newRemainingCount >= 0) isCanSyncStockToTlFlg = true;
				// 在庫数はマイナスの場合、論理在庫調整として、完了する（TA側へ連携を行わない）
				else continue;
				
				log.write_log('グループコード['+stock.roomTypeCode+']の残室数(調整後)：'+newRemainingCount);
				// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
				// 調整後の残室数は０以下の場合、０のまま設定する[TAのAPIは残室数はマイナスに設定ができません]
				newRemainingCount = newRemainingCount >= 0 ? newRemainingCount : 0;
		// 2017/05/25 在庫調整連携方式変更対応 BEGIN
		} else {
			newRemainingCount = sfRemainingCount;
			log.write_log('グループコード['+stock.roomTypeCode+']の残室数(調整後)：'+newRemainingCount);
		}
		// 2017/05/25 在庫調整連携方式変更対応 END
				// 調整後の残室数は変更なし場合、更新調整を行わない
				if (!CommUtils.isBLank(stock.remainingCount) && CommUtils.nullToZero(stock.remainingCount) == newRemainingCount) {
					// 2017/05/25 在庫調整連携方式変更対応 BEGIN
					log.write_log('残室数['+stock.remainingCount+'](調整前)と残室数['+newRemainingCount+'](調整後)：一致、連携リクエスト発生なし');
					// 2017/05/25 在庫調整連携方式変更対応 END
					continue;
				}
				// 指定日の調整対象室タイプグループの残室数を設定する
				stockMap.put(stock.roomTypeCode, newRemainingCount);
			}
			// 調整対象が存在する場合、詳細処理を行う
			if (groupCnt > 0) {
// 2017/05/25 在庫調整連携方式変更対応 BEGIN
if (!isSyncSfStockToTaMode) {
// 2017/05/25 在庫調整連携方式変更対応 END
				// 該当室タイプは全部残業数初期値は未設定の場合、TA経由で管理しないので、連携対象ステータスは変更なし、残業数設定まで、再連携を行う
				if (remainCountNoSetupFlg) {
					log.write_log('該当部屋タイプ['+roomTypeCd+']関連のTAの室タイプの残室数初期値未設定ため、TAへ連携しない.');
					sfStock.TaStatusLst__c = STOCK_STATUS_SYNCOUT;
					return;
				}
				// 残業数初期値設定ありが、更新後の残室数は全部０以下の場合、TA連携対象外、「ステータス」は「論理連携済」に変更を行う
				if (!isCanSyncStockToTlFlg) {
					log.write_log('該当部屋タイプ['+roomTypeCd+']関連のTAの室タイプの残室数は０以下になるため、TAへ連携しない、論理連携済になる.');
					sfStock.TaStatusLst__c = STOCK_STATUS_LOGIC_SYNCOK;
					return;
				} else {
					// 残室数は０以上の場合、該当部屋タイプの相殺できるの「論理在庫調整済」情報が存在するがどうかチェックする
					// 論理在庫調整情報が存在する場合、該当調整データは連携済に減らす
					// 在庫調整数は＞０の場合、論理在庫調整と相殺更新する
					// 今回の在庫調整対象のステータスは「連携済」
					// [同じ部屋タイプ、同じ調整日付、同じ店舗コード、同じ予約情報を相殺する]
					// 2017/10/09 論理連携済のデータへ相殺条件不正の改修 BEGIN
					/*
					List<StockChangeHisotry__c> existStockHistory = [select Name,AgtRef__c,TaStatusLst__c from StockChangeHisotry__c
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN 
						//where AgtRef__c = :sfStock.AgtRef__c 
						//And LeadRef__c = :sfStock.LeadRef__c
						Where Id != :sfStock.Id 	
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						And StockChangeDate__c = :sfStock.StockChangeDate__c
						And TypeOfRoomRef__c = :sfStock.TypeOfRoomRef__c
						And TaStatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN
						//And Id != :sfStock.Id
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						limit 1];
						*/
                    Id stockId = sfStock.Id;
                    Date stockDate = sfStock.StockChangeDate__c;
                    Id typeOfRoomId = sfStock.TypeOfRoomRef__c;
                    Decimal stockCnt = CommUtils.nullToZero(sfStock.StockChangeCnt__c);
                    String queryStr = 'select Name,AgtRef__c,TaStatusLst__c from StockChangeHisotry__c'+
                       ' Where Id != :stockId'+
                       ' And StockChangeDate__c = :stockDate'+
                       ' And TypeOfRoomRef__c = :typeOfRoomId'+
                       ' And TaStatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK';
                    if (stockCnt > 0) queryStr += ' And StockChangeCnt__c < 0 ';
                    else if (stockCnt < 0) queryStr += ' And StockChangeCnt__c > 0 ';
                    queryStr += ' limit 1 ';
                    List<StockChangeHisotry__c> existStockHistory = DataBase.query(queryStr);
		    // 2017/10/09 論理連携済のデータへ相殺条件不正の改修 END
log.write_log('在庫論理調整対象：'+existStockHistory);
if (!existStockHistory.isEmpty()) {
	log.write_log('sfStock.AgtRef__c：['+sfStock.AgtRef__c+']');
	log.write_log('sfStock.LeadRef__c：['+sfStock.LeadRef__c+']');
	log.write_log('sfStock.StockChangeDate__c：['+sfStock.StockChangeDate__c+']');
	log.write_log('sfStock.TypeOfRoomRef__c：['+sfStock.TypeOfRoomRef__c+']');
	log.write_log('sfStock.Id：['+sfStock.Id+']');
	log.write_log('sfStock.Status：['+STOCK_STATUS_LOGIC_SYNCOK+']');
}
					if (!existStockHistory.isEmpty()) {
						log.write_log('該当部屋タイプ['+roomTypeCd+']関連のTAの室タイプの論理在庫調整対象あるため、TAへ連携しない.[論理在庫調整対象No：('+existStockHistory[0].Name+')]');
						sfStock.TaStatusLst__c = STOCK_STATUS_SYNCOK;
						existStockHistory[0].TaStatusLst__c = STOCK_STATUS_SYNCOK;
						List<StockChangeHisotry__c> updLst = new List<StockChangeHisotry__c>();
						updLst.add(sfStock);
						updLst.add(existStockHistory[0]);
						update updLst;
						return;
					}
				}
// 2017/05/25 在庫調整連携方式変更対応 BEGIN
}
// 2017/05/25 在庫調整連携方式変更対応 END
			} else if (groupCnt == 0 && rep.roomStockList.isEmpty()) {
				log.write_log('TAの室タイプ情報がありません または　調整日付はTA連携可能期間対象外、TAへ連携しない.');
				sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				return;
			}

			// 残室数設定情報が存在する場合、残室数調整を行う
			for (String groupcd : stockMap.keySet()) {
				log.write_log('室タイプグループコード['+groupcd+']在庫調整開始' );
				// 残室数調整を行う
				callNetStockAdjustmentService(groupcd, stockMap.get(groupcd), ajdustDate, shopCode, sfStock);
				log.write_log('室タイプグループコード['+groupcd+']在庫調整終了' );
			}
			// 2017/05/25 在庫調整連携方式変更対応 BEGIN
			if (isSyncSfStockToTaMode && abortSyncFlg) {
				// 連携対象タイプのステータスは未連携のまま設定する
				sfStock.TaStatusLst__c = STOCK_STATUS_NOSYNC;
			}
			// 2017/05/25 在庫調整連携方式変更対応 END
		}
		log.write_method_end();
	}
	// ネット販売：指定日、指定室タイプグループ単位で、残室数調整を行う
	private void callNetStockAdjustmentService(String groupNo, Decimal stockRemainCnt, String ajdustDate, String shopCode, StockChangeHisotry__c sfStock) {
		
		log.write_method_start('callNetStockAdjustmentService');
		log.write_log('P１：'+groupNo);
		log.write_log('P２：'+stockRemainCnt);
		log.write_log('P３：'+ajdustDate);
		log.write_log('P４：'+shopCode);
		
		// サビース初期化
		// 2016/07/29 ログ出力機能追加 BEGIN
		TA_ServiceCtrl taService = new TA_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// REQUEST PARAMETER
		TA_RoomStockInfoUpdItem.RoomStockInfo adjustmentTarget
			= new TA_RoomStockInfoUpdItem.RoomStockInfo();
		adjustmentTarget.roomTypeCode = groupNo;	// ネット室タイプグループコード
		adjustmentTarget.stockDate = ajdustDate;	// 調整日付
		adjustmentTarget.roomStockNum = CommUtils.nullToblank(stockRemainCnt.intValue());	// 残室数
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		// TA->在庫状態不一致
		// 2019/05/23 販売ステータスを設定される場合のみ、連携ステータスを設定する WSQ BEGIN
		//if (sfStock.SettingFlg__c) adjustmentTarget.SalesClosed = sfStock.SalesStatus_del__c == CommConst.STOCK_SET_STOP ? '1' : '0';
		if (sfStock.SettingFlg__c && sfStock.SalesStatus_del__c != null) adjustmentTarget.SalesClosed = sfStock.SalesStatus_del__c == CommConst.STOCK_SET_STOP ? '1' : '0';
		// 2019/05/23 販売ステータスを設定される場合のみ、連携ステータスを設定する WSQ END
		// 2018/12/15 在庫調整と販売状態管理 by zy END
System.debug('adjustmentTarget:'+adjustmentTarget);
		log.write_log('******在庫調整(ネット販売)API 呼出開始******');
		
		// 在庫調整サビースを呼出
		TA_RoomStockInfoUpdItem rep 
			= taService.callStockAdjustmentService( shopCode, new list<TA_RoomStockInfoUpdItem.RoomStockInfo>{adjustmentTarget});
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー個別処理:
			String errCode = rep.commonResponse.failureReason;
			// エラー処理ログを記録する
			log.write_error(errCode+':'+rep.commonResponse.errorDescription);
		} else {
			// 更新エラー部屋リスト
			for (TA_RoomStockInfoUpdItem.RoomInfo errRoom : rep.errorRoomList) {
				// エラー個別処理:
				String errCode = CommUtils.nullToBlank(errRoom.ErrorCode);
				String errMsg  = CommUtils.nullToBlank(errRoom.ErrorMessage);
				// エラー処理ログを記録する
				log.write_error(errCode+':'+errMsg);
			}
			log.write_log('******在庫調整(ネット販売)API 呼出終了******');
		}
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
		if (TA_ServiceConfigHelp.isStockBatchStopCheck()) return;
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		// 作成日は2週間前の在庫変更履歴情報を削除する[連携不要、連携済]
		try {
		//log.clear();
		//log.write_method_start('バッチ処理終了');
		if (TA_ServiceConfigHelp.getCommConfig().bIsDebug) return;
		Date deleteDate = Date.today().addDays(TA_ServiceConfigHelp.getCommConfig().mStockDeleteVal);
		//log.write_log('調整日は['+deleteDate.format()+']前の在庫変更履歴情報を削除');
		// 2016/03/04 ゴミデータの削除条件を変更する BEGIN
		//List<StockChangeHisotry__c> stockChangList = [select id,CooperationResultRef__c from StockChangeHisotry__c where createdDate < :deleteDate];
		List<StockChangeHisotry__c> stockChangList = [select id,CooperationResultRef__c,CooperationResultTaRef__c from StockChangeHisotry__c where StockChangeDate__c < :deleteDate limit 100];
		// 2016/03/04 ゴミデータの削除条件を変更する END
		//log.write_log('削除件数['+stockChangList.size()+']件');
		Set<Id> deleteCoopIdsSet = new Set<Id>();
		for (StockChangeHisotry__c stock : stockChangList) {
			if (stock.CooperationResultRef__c != null) deleteCoopIdsSet.add(stock.CooperationResultRef__c);
			if (stock.CooperationResultTaRef__c != null) deleteCoopIdsSet.add(stock.CooperationResultTaRef__c);
		}
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isDeleteable(StockChangeHisotry__c.getSObjectType()) ||
			!CommSecurityUtils.isDeleteable(CooperationResult__c.getSObjectType())){
				return;
		}
		// 2018/03/07 Security Check END
		if (!stockChangList.isEmpty()) database.delete(stockChangList,false);
		if (!deleteCoopIdsSet.isEmpty()) {
			database.delete([select id from CooperationResult__c where id in :deleteCoopIdsSet], false);
		}
		//log.write_method_end();
		//TA_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (Exception e){}
		// 処理データがまだある場合、次のバッチを起動する
		callNextSchedule();	
	}
	
	// 次のスケジュールを起動する	
	private void callNextSchedule(){
		Integer intervalLength = TA_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
		//log.clear();
		//log.write_method_start('次のスケジュール定義');
		intervalLength = TA_ServiceConfigHelp.getCommConfig().mStockInterval;
		//log.write_log(String.valueOf(intervalLength) + '秒後、次のスケジュールを起動する');
		} catch(Exception e){}
		TA_StockAdjustmentBatch schedule= new TA_StockAdjustmentBatch(gScheduleBeginTime);
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
		String jobName = 'TA_StockAdjustmentBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
		//try {
		//log.write_log('次のスケジュールID:'+jobId);
		//log.write_method_end();
		//TA_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		//} catch (Exception e){}
	}

	// エラー処理
	private void callErroProcess(StockChangeHisotry__c stock, String shopCode) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'ProcessLog__c','MailSendComplete__c','ErrorCount__c','ErrorContent__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return;
		}
		// 2018/03/07 Security Check END
		if (stock.CooperationResultTaRef__c != null) {
			// エラー回数を更新する
			CooperationResult__c updCoop = new  CooperationResult__c(Id = stock.CooperationResultTaRef__c);
			String orgErrMsg =  stock.CooperationResultTaRef__r.ErrorContent__c;	
			String newErrMsg = removeOverErrString(log.getLastError());
			if (orgErrMsg != newErrMsg) {
				updCoop.ErrorCount__c = 1;
				updCoop.ErrorContent__c = newErrMsg;
				updCoop.MailSendComplete__c = false;
			} else {
				updCoop.ErrorCount__c = CommUtils.nullToZero(stock.CooperationResultTaRef__r.ErrorCount__c) + 1;
			}
            // 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
            // 最新のエラーメッセージは既に送信済みの場合
            // 前回送信済みのエラーメッセージと同じ場合、
            if (TA_ServiceConfigHelp.isStockDupErrorMsgCheck(newErrMsg, false)) {
                Boolean orgCoopMailSendFlg = stock.CooperationResultTaRef__r.MailSendComplete__c;
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
			stock.CooperationResultTaRef__c = newCoop.Id;
		}
		// 処理ステータスは未設定の場合、処理NGを設定する
		if (CommUtils.isBlank(stock.TaStatusLst__c)) {
			stock.TaStatusLst__c = STOCK_STATUS_SYNCNG;
		}
	}
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
	**/
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
	}
	/**
	* 同時に同じ在庫調整データを更新回避するため、更新処理関数を追加する
	**/
	private void updateLock(StockChangeHisotry__c updStock) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'TaStatusLst__c','TaProcessLog__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
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
	private Integer getSfStockOfRoomType(Date pStockDate, Id pRoomTypeId) {
		StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
		map<string, Decimal> usdRoomsMap = helpUtils.getStockUsedInfo(new set<Id>{pRoomTypeId},new set<Date>{pStockDate});
		/* #9898 BugFix 在庫利用数取得ロジック改修 WSQ BEGIN */
		//if (usdRoomsMap.isEmpty()) return 0;
		//else return CommUtils.nullToIntZero(usdRoomsMap.values()[0]);
		String key = helpUtils.getRoomStockKey(pRoomTypeId, pStockDate);
		return (usdRoomsMap.containsKey(key) ? CommUtils.nullToIntZero(usdRoomsMap.get(key)) : 0);
		/* #9898 BugFix 在庫利用数取得ロジック改修 WSQ END */
	}
	// 2017/05/25 在庫調整連携方式変更対応 END
}