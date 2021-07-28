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
* 2016/10/06 在庫調整対象[仮データ]は抽出対象外
* 2017/10/06 論理連携済のデータへ相殺条件不正の改修（相殺のとき、在庫数値はマイナス・プラスのみ相殺可能）
* 2019/08/12 「SObject row was retrieved via SOQL without querying the requested field: ps__StockChangeHisotry__c.Name」不具合改修
**/
public with sharing class TL_StockAdjustmentBatchExtend implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
	// 検索SOQL
	private final String Query;					
	// 共通定数
	private static final String SERVICE_KEY = TL_ServiceCtrl.SERVICE_KEY;
	private static final String STOCK_STATUS_NOSYNC = '未連携';
	private static final String STOCK_STATUS_SYNCNG = '連携NG';
	private static final String STOCK_STATUS_SYNCOUT = '連携不要';
	private static final String STOCK_STATUS_SYNCOK = '連携済';
	private static final String STOCK_STATUS_LOGIC_SYNCOK = '論理連携済';
	
	private static final String AGT_TYPE_NET = 'ネット';
	
	private static final String COOP_STATUS_STOCKNG = '在庫調整NG';
	private static final String COOP_FUNCTION_TYPE_STOCK = '在庫調整';

	private DateTime gScheduleBeginTime;
	// 処理単位のログ記述する
	private CommLogUtils log = new CommLogUtils('TL_StockAdjustmentBatch', true);
	//private final String logManagerId = 'TL_STOCK_LOG_000000000';
	// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
	private boolean isDupFlg = false;
	// 2016/12/14 バッチ重複起動されるチェック　Wgch END
	// スケジュールからバッチ起動用Method
	public TL_StockAdjustmentBatchExtend(DateTime pScheduleBeginTime) {
		// バッチ起動時間
		gScheduleBeginTime = pScheduleBeginTime;
		// 調整日付は当日以後の日付を連動する
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		Query = 'Select Id,LeadRef__c,StatusLst__c,StockChangeDate__c,StockChangeCnt__c,TypeOfRoomRef__c,TypeOfRoomRef__r.RoomTypeCode__c,TypeOfRoomRef__r.ShopInfoRef__r.ShopCode__c,AgtRef__c,AgtRef__r.SalesOfficeCompanyType__c,AgtRef__r.Parent.SalesOfficeCompanyType__c,AgtRef__r.SalesOfficeCompanyCodeTLAPI__c,AgtRef__r.Parent.SalesOfficeCompanyCodeTLAPI__c,CooperationResultRef__c, CooperationResultRef__r.ErrorCount__c, CooperationResultRef__r.ErrorContent__c, CooperationResultRef__r.MailSendComplete__c,SettingFlg__c,SalesStatus_del__c From StockChangeHisotry__c where StatusLst__c in (\''+STOCK_STATUS_NOSYNC+'\',\''+STOCK_STATUS_SYNCNG+'\') and ((CreateSource__c != :SERVICE_KEY And BatchRunTarget__c = null) or  (CreateSource__c = :SERVICE_KEY And BatchRunTarget__c = :SERVICE_KEY)) And StockChangeDate__c >= TODAY And Provisional__c != true ';
		// 2018/12/15 在庫調整と販売状態管理 by zy END
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		// 2016/12/14 バッチ重複起動されるチェック　Wgch BEGIN
		isDupFlg = (TL_ServiceConfigHelp.isStockDupStartCheck(BC.getJobId()));
		if (isDupFlg) return Database.getQueryLocator('select id from StockChangeHisotry__c limit 0');
		// 2016/12/14 バッチ重複起動されるチェック　Wgch END
		/*
		log.write_method_start('バッチ処理開始');
		log.write_log('バッチ処理正常に起動された');
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		*/
		// 指定期間範囲内
		// 2015/12/11 在庫調整機能改善 BEGIN
		String locatorQuery = Query;
		Date restoreStartDate = null;
		Boolean bIsSyncOnlyNewFlg = true;
		try { 
			restoreStartDate = TL_ServiceConfigHelp.getCommConfig().restoreStartDate;
			bIsSyncOnlyNewFlg = TL_ServiceConfigHelp.getCommConfig().bIsSyncOnlyNewFlg;
		} catch (exception e){}
		// 2016/05/12 在庫調整日付はデータ取得条件から削除
		if (restoreStartDate != null) {
			locatorQuery += ' And DAY_ONLY(convertTimezone(CreatedDate)) >= :restoreStartDate ';
		} else if (bIsSyncOnlyNewFlg) {
			if (gScheduleBeginTime == null) {
				// 処理開始時刻は異常ななくなる場合、時刻は再自動設定を行う
				gScheduleBeginTime = system.now().addMinutes(-15);
			}
			locatorQuery += ' And CreatedDate >= :gScheduleBeginTime ';
		}
		//Date endTargetDate = Date.today().addDays(TL_ServiceConfigHelp.getCommConfig().syncMaxDays);
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
System.debug(logginglevel.INFO,'scope:::' + scope );	
		// Batch Size is 1
		if (scope.isEmpty()) return;
		// 処理異常判別用フラグ初期化する
		//isHaveException = false;
		// LOG出力の初期化
		log.clear();
		log.write_method_start('TL_StockAdjustmentBatch_execute');
		
		// 在庫調整情報を取得する
		StockChangeHisotry__c stock = scope[0];
		// 処理ステータスはクリアする
		stock.StatusLst__c = null;
		// 該当部屋タイプのプラングループ関連の残室数を取得する[店舗コード情報]
		String shopCode = CommUtils.nullToBlank(stock.TypeOfRoomRef__r.ShopInfoRef__r.ShopCode__c);
		// 該当店舗情報の接続定義はXMLに未定義する場合、処理対象外
		if (!TL_ServiceConfigHelp.isContractShop(shopCode)) {
			// 連携対象外店舗設定されている
			log.write_log('店舗コード['+shopCode+']はXMLに定義されていないため、連携不要対象になる.');
			// 連携結果を更新を行う
			stock.StatusLst__c = STOCK_STATUS_SYNCOUT;
			stock.ProcessLog__c = removeOverLogString(log.getAllLog());
			// 2016/08/26 EDIT BEGIN
			//update stock;
			updateLock(stock);
			// 2016/08/26 EDIT END
			return;
		}
		// 室タイプコードを取得
		Set<String> roomTypeCdSet = new Set<String>();
		roomTypeCdSet.add(stock.TypeOfRoomRef__r.RoomTypeCode__c);
		// 調整日付
		Date updateDate = stock.StockChangeDate__c;
		String updateDtStr = DateTime.newInstance(updateDate.year(), updateDate.month(), updateDate.day()).format('yyyyMMdd');
			
		// ネット販売　OR　リアル　判定する
		Boolean isNetStockInfo = false;
		if (stock.AgtRef__c != null) {
			// 親が存在
			if (stock.AgtRef__r.parentId != null) {
				if (CommUtils.isBlank(stock.AgtRef__r.parent.SalesOfficeCompanyType__c) || stock.AgtRef__r.parent.SalesOfficeCompanyType__c == AGT_TYPE_NET) {
					isNetStockInfo = true;
				}
			} else {
				// 子供関連
				if (CommUtils.isBlank(stock.AgtRef__r.SalesOfficeCompanyType__c) || stock.AgtRef__r.SalesOfficeCompanyType__c == AGT_TYPE_NET) {
					isNetStockInfo = true;
				}
			}
		} else {
			isNetStockInfo = true;
		}

		// 該当予約情報はネット販売の部屋タイプの場合
		if (isNetStockInfo) {
			// 該当部屋タイプの関連のTL室タイプグループリストを取得する
			// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 BEGIN
			// 該当部屋タイプはルールに定義されが、マッピングされなかったフラグ情報格納用
			set<string> ruleNoMatchSet = new set<string>();
			//map<String, list<string>> targetmap = getRoomTypeToTLNetTypeGroupCd(roomTypeCdSet, shopCode);
			map<String, list<string>> targetmap = getRoomTypeToTLNetTypeGroupCd(roomTypeCdSet, shopCode, stock.LeadRef__c, ruleNoMatchSet);
			// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 END
			// 調整対象なし
			if (targetmap.isEmpty()) {
				if (log.isHaveError()) {
					callErroProcess(stock, shopCode);
				} else {
				    // 該当部屋タイプはルールに適応しなかった場合
				    if (!ruleNoMatchSet.isEmpty()) {
                        log.write_log('該当部屋タイプコード['+roomTypeCdSet+']はTL側に複数部屋タイプにマッピングしますが、ルールを適応しないため、連携対象外になる');
                        // 連携結果を更新を行う
                        stock.StatusLst__c = STOCK_STATUS_NOSYNC;
				    } else {
						log.write_log('該当部屋タイプコード['+roomTypeCdSet+']はTL側に定義されていないため、連携対象外になる');
						// 連携結果を更新を行う
						stock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				    }
				}
				stock.ProcessLog__c = removeOverLogString(log.getAllLog());
				// 2016/08/26 EDIT BEGIN
				//update stock;
				updateLock(stock);
				// 2016/08/26 EDIT END
				return;
			}
			// グループコードに対して、在庫残室数情報を取得する
			Set<String> tlGroupCdSet = new Set<String>();
			for (List<string> gpCds : targetmap.values()) {
				for(String gpCd : gpCds) tlGroupCdSet.add(gpCd);
			}
			// 指定の室タイプグループ、日付、残室数照会を行う
			callNetStockSearchService(tlGroupCdSet, updateDtStr, stock, stock.StockChangeCnt__c, shopCode);
			// 該当部屋タイプに対して、正常に完了すると、在庫変更履歴は削除を行う
		} 
		// 該当予約情報はリアル会社販売の場合
		else {
			// 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 BEGIN
			Boolean realStockReqSync = TL_ServiceConfigHelp.getAppConfig(shopCode).realStockReqSync;
			if (!realStockReqSync) {
				log.write_log('リアル（旅行会社）在庫更新要求の制御パラメータは['+realStockReqSync+']ので、在庫連携対象外になり]');
				// 連携結果を更新を行う
				stock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				stock.ProcessLog__c = removeOverLogString(log.getAllLog());
				// 2016/08/26 EDIT BEGIN
				//update stock;
				updateLock(stock);
				// 2016/08/26 EDIT END
				return;
			}
			// 2016/01/29 リアル（旅行会社）に対して、在庫更新要求を発行する・しない制御パラメータを追加 END
			// 2015/11/29 AGTコードを取得する
			String agtCode = CommUtils.isBlank(stock.AgtRef__r.SalesOfficeCompanyCodeTLAPI__c) ?
								CommUtils.nullToBlank(stock.AgtRef__r.Parent.SalesOfficeCompanyCodeTLAPI__c) :
								CommUtils.nullToBlank(stock.AgtRef__r.SalesOfficeCompanyCodeTLAPI__c);
			// リアルの場合、販売先コードAPIにより、室タイプ単位に設定を行う
			map<String, list<String>> targetmap = getRoomTypeToTLRealType(roomTypeCdSet, shopCode, agtCode);
			// 調整対象なし
			if (targetmap.isEmpty()) {
				if (log.isHaveError()) {
					callErroProcess(stock, shopCode);
				} else {
					log.write_log('該当部屋タイプコード['+roomTypeCdSet+']はTL側に在庫調整可能の室タイプがないため、連携対象外になる AGTコード:['+agtCode+']');
					// 連携結果を更新を行う
					stock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				}
				stock.ProcessLog__c = removeOverLogString(log.getAllLog());
				// 2016/08/26 EDIT BEGIN
				//update stock;
				updateLock(stock);
				// 2016/08/26 EDIT END
				return;
			}
			// 調整単位キーを取得する、在庫残室数情報を取得する
			Set<String> tlRmtypeCdSet = new Set<String>();
			for (List<string> gpCds : targetmap.values()) {
				for(String gpCd : gpCds) tlRmtypeCdSet.add(gpCd);
			}
			// 指定の販売先室タイプ、日付、残室数照会を行う
			callRealStockSearchService(tlRmtypeCdSet, updateDtStr, stock, stock.StockChangeCnt__c, shopCode);
		}
		// 正常に処理完了の場合、在庫変更履歴は削除を行う
		if (log.isHaveError()) {
			callErroProcess(stock, shopCode);
		} else {
			// ERROR発生する場合、同じエラーを繰り返し問題を発生すると、
			if (CommUtils.isBlank(stock.StatusLst__c)) stock.StatusLst__c = STOCK_STATUS_SYNCOK;
			// 2016/08/24 既に連携結果NGのデータが存在する場合、該当リンクをそのまま、削除するため
			//stock.CooperationResultRef__c = null;
		}
		stock.ProcessLog__c = removeOverLogString(log.getAllLog());
		// 2016/08/26 EDIT BEGIN
		//update stock;
		updateLock(stock);
		// 2016/08/26 EDIT END
		log.write_method_end();
	}

	// SFの部屋タイプからTL側の室タイプグループ情報を取得する
	// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 BEGIN
	//private map<String, list<string>> getRoomTypeToTLNetTypeGroupCd(Set<String> sfRoomTypeCode, String shopCd) {
	private map<String, list<string>> getRoomTypeToTLNetTypeGroupCd(Set<String> sfRoomTypeCode, String shopCd, Id leadId, set<string> ruleNoMatchSet) {
	// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 END
		log.write_method_start('getRoomTypeToTLNetTypeGroupCd');
		log.write_log('P１：'+sfRoomTypeCode);
		log.write_log('P２：'+shopCd);
		
		// ネット、旅行会社へ在庫情報連動を行う
		map<String, list<string>> typeOfGroupCdMap = new map<String, list<string>>();
		// TL API 初期化処理
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// 指定の部屋タイプコードから、API経由で、ネットタイプグループを取得する
		TL_NetRoomTypeMasterSearchService.extractionCondition extractionCondition
			= new TL_NetRoomTypeMasterSearchService.extractionCondition();
		extractionCondition.extractionProcedureCode = '0';	// 全件検索
		
		log.write_log('******部屋タイプマスタ検索(ネット販売)API 呼出開始******');
		// 検索を呼出
		TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse rep 
			= tlService.callNetRoomTypeMasterSearchService(shopCd, extractionCondition);
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******部屋タイプマスタ検索(ネット販売)API 呼出終了******');
			log.write_log('指定の部屋タイプはTL側の室タイプグループをMAPPING開始');
			// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 BEGIN
			Map<String, List<TL_ServiceConfigHelp.StockConvertInfo>> stockConvertMap = CommUtils.isBlank(leadId) ? 
			                                     new Map<String, List<TL_ServiceConfigHelp.StockConvertInfo>>() :
			                                     TL_ServiceConfigHelp.getAppConfig(shopCd).stockConvertMap;

			// 該当SETにSFの該当部屋タイプコードはFILTER関連情報定義あり、なし情報格納
            // TL側へTL室タイプコード対象リスト格納
            set<string> targetTlRmTypeCdSet = new set<string>();
			try {
			    // map<TL側の室タイプ名,TL側の室タイプコード>
			    map<String, String> tlRmTypeNameToTlCodeMap = new map<String, String>();
			    // map<SF側の室タイプコード,TL側の室タイプコード>
			    map<String, List<String>> sfRmTypeCodeToTlCodeMap = new map<String, List<String>>();
			    // TLの室タイプコードと室タイプ名のマッピング定義情報を取得する
		        if (rep.rmTypeList != null) {
		            for (TL_NetRoomTypeMasterSearchService.rmType rg : rep.rmTypeList) {
log.write_log('SF-TL-MAPPING: '+rg.rmTypeCode + '=' + rg.rmTypeName + '=' + rg.tlDataOutPutRmTypeCode);
                        tlRmTypeNameToTlCodeMap.put(rg.rmTypeName, rg.rmTypeCode);
                        String wkSfRmTypeCode = rg.tlDataOutPutRmTypeCode;
                        if (CommUtils.isBlank(wkSfRmTypeCode)) wkSfRmTypeCode = rg.rmTypeCode;
		                if (!CommUtils.isBlank(wkSfRmTypeCode)) {
		                    // SFの部屋タイプコード→Tlの室タイプコードマッピング定義格納
		                    if (!sfRmTypeCodeToTlCodeMap.containsKey(wkSfRmTypeCode)) sfRmTypeCodeToTlCodeMap.put(wkSfRmTypeCode, new List<String>());
		                    sfRmTypeCodeToTlCodeMap.get(wkSfRmTypeCode).add(rg.rmTypeCode);
		                }
		            }
		        }
			    // SFの部屋タイプコードからXML定義のFILTER情報により、現在の予約情報変ルールをマッピングする
				for (String sfRoomTypeCd : sfRoomTypeCode) {
				    // 検索条件により、該当予約の条件区分設定を行う
				    String queryHeader = 'Select id From Lead__c where id = :leadId And ';
				    // SFの部屋タイプはXMLに変換ルールが存在する場合
	                if (stockConvertMap.containsKey(sfRoomTypeCd)) {
	                    // 該当SFの部屋タイプの変換ルールにより、TLの室タイプコードがマッピングされるがどうかフラグ
	                    Boolean isMatchFlg = false;
	                    for (TL_ServiceConfigHelp.StockConvertInfo convertInf : stockConvertMap.get(sfRoomTypeCd)) {
	                        // DB情報検索を行う
	                        String queryStr = queryHeader + convertInf.condition + ' Limit 1';
	                        List<Lead__c> filterLead = DataBase.query(queryStr);
//log.write_log('queryStr:'+queryStr);
	                        // 該当FILTER条件を満足すると、該当SFの部屋タイプと変換後のTLの室タイプコートと施設タイプ名のマッピング定義を格納する
	                        if (!filterLead.isEmpty()) {
	                            // TLの室タイプ名からTLの室タイプコードに変換を行う
	                            String tlRmtypeName = convertInf.tlRmtypeName;
	                            if (tlRmTypeNameToTlCodeMap.containsKey(tlRmtypeName)) {
	                                String tlRmtypeCode = tlRmTypeNameToTlCodeMap.get(tlRmtypeName);
	                                // TL連携対象室タイプコード
	                                targetTlRmTypeCdSet.add(tlRmtypeCode);
	                                isMatchFlg = true;
log.write_log('SF->TL室タイプ名変換あり:'+sfRoomTypeCd+'=>'+convertInf.tlRmtypeName);
	                            }
	                            //break;
	                        }
	                    }
	                    // 変換ルールとあわない場合、該当SFの部屋タイプコードはTL側へ連携対象外になる
	                    if (!isMatchFlg) {
log.write_log('SFの部屋タイプコード:'+sfRoomTypeCd+'=>TLの連携対象室タイプコードが見つかりません。'); 
                            // 2017/12/28 変換ルールを定義しますが、在庫連携予約データは全て定義条件を満たしてないとき、該当予約データは連携まち状態になる、
                            ruleNoMatchSet.add(sfRoomTypeCd);
	                    }
	                } // if (stockConvertMap.containsKey(sfRoomTypeCd)) { 
	                // 該当SFの部屋タイプが変換ルールが未定義場合、既存マッピングルールを設定する
	                else {
	                    if (!sfRmTypeCodeToTlCodeMap.containsKey(sfRoomTypeCd)) continue;
	                    // map<SFの部屋タイプコード,set<TLの室タイプコード>>
//log.write_log('sfRmTypeCodeToTlCodeMap:：：：：：'+sfRmTypeCodeToTlCodeMap);
//log.write_log('sfRoomTypeCd:'+sfRoomTypeCd);
	                    targetTlRmTypeCdSet.addAll(sfRmTypeCodeToTlCodeMap.get(sfRoomTypeCd));
	                }
				}
			} catch (Exception e) {
                log.write_error('SF->TL変換 ERROR='+e.getMessage());
                return typeOfGroupCdMap;
			}
			// 変換がある場合、
//log.write_log('SF->TL連携対象室タイプコード:'+targetTlRmTypeCdSet);
//System.debug(loggingLevel.info, 'SF->TL変換情報:'+convertFilterMap);
			// 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 END
			rep.netRmTypeGroupList = (rep.netRmTypeGroupList == null) 
									? new TL_NetRoomTypeMasterSearchService.netRmTypeGroup[0]		
									: rep.netRmTypeGroupList;

			for (TL_NetRoomTypeMasterSearchService.netRmTypeGroup typeGroup : rep.netRmTypeGroupList) {
				// SF側の部屋タイプコードと関係ないの情報に対して、処理対象外になる
                // 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 BEGIN
				//if (!sfRoomTypeCode.contains(typeGroup.rmTypeCode)) continue;
				if (!targetTlRmTypeCdSet.contains(typeGroup.rmTypeCode)) continue;
                // 2017/08/07 在庫連携、指定条件により、SFの部屋タイプからTLの部屋タイプグループ名を変更できるように改善対応 END
				// 室タイプコートはSF側の部屋タイプコードと一致する場合゙
				if (!typeOfGroupCdMap.containskey(typeGroup.rmTypeCode)) {
					typeOfGroupCdMap.put(typeGroup.rmTypeCode, new list<string>());
				}
				// 室タイプー＞グループコードMAPPING情報を格納する
				typeOfGroupCdMap.get(typeGroup.rmTypeCode).add(typeGroup.netRmTypeGroupCode);
			}
			
			log.write_log('指定の部屋タイプはTL側の室タイプグループをMAPPING終了');
		}

		log.write_method_end();
		
		return typeOfGroupCdMap;
	}

	// SFの部屋タイプからTL側のリアルの販売先室タイプコード
	private map<String, list<String>> getRoomTypeToTLRealType(Set<String> sfRoomTypeCode, String shopCd, String agtCode) {
		
		log.write_method_start('getRoomTypeToTLRealType');
		log.write_log('P１：'+sfRoomTypeCode);
		log.write_log('P２：'+shopCd);
		log.write_log('P３：'+agtCode);
		// ネット、旅行会社へ在庫情報連動を行う
		map<String, list<String>> typeOfRealCodeMap = new map<String, list<String>>();
		// TL API 初期化処理
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		log.write_log('******部屋タイプマスタ検索(旅行会社)API 呼出開始******');
		// リアル
		// 指定店舗の部屋MAPPING情報を取得する
		TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse realRep = 
			tlService.callRealRoomTypeMasterSearchService(shopCd);
		if (!realRep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(realRep.commonResponse.failureReason+':'+realRep.commonResponse.errorDescription);
		} else {
			log.write_log('******部屋タイプマスタ検索(旅行会社)API 呼出終了******');
			log.write_log('指定の部屋タイプはTL側の販売先室タイプをMAPPING開始');
			
			realRep.realAgtRmTypeList = (realRep.realAgtRmTypeList == null) 
									? new TL_RealRoomTypeMasterSearchService.realAgtRmType[0]		
									: realRep.realAgtRmTypeList;
			for (TL_RealRoomTypeMasterSearchService.realAgtRmType agt : realRep.realAgtRmTypeList) {
				// 室タイプコード
				String rmTypeCode = agt.rmTypeCode;
				// 調整対象外の室タイプは処理SKIP
				if (!sfRoomTypeCode.contains(rmTypeCode)) continue;
				// 販売先コードは対象チェックする
				if (agtCode != agt.agtCode) continue;
				// 在庫調整操作可否チエック
				if (!agt.isStockAdjustable) {
					log.write_log('旅行会社室タイプコード['+agt.realAgtRmTypeCode+']在庫調整操作不可.');
					continue;
				}
				// 操作対象格納する
				String key = getRealRmTypeKey(agt.agtCode, agt.realAgtRmTypeCode, agt.frame);
				//RealRmTypeInfo newRealRmType = new RealRmTypeInfo(agtCode, agtRmTypeCode, agtRmTypeFrame);
				if (!typeOfRealCodeMap.containsKey(rmTypeCode)) {
					typeOfRealCodeMap.put(rmTypeCode, new List<String>());
				}
				typeOfRealCodeMap.get(rmTypeCode).add(key);
				log.write_log('調整対象の旅行会社室タイプ：'+key);
			}
			log.write_log('指定の部屋タイプはTL側の販売先室タイプをMAPPING終了');
		}
		
		log.write_method_end();
		
		return typeOfRealCodeMap;
	}

	private String getRealRmTypeKey(String agtCode, String rmTypeCode, String frame) {
		return agtCode + '_' + rmTypeCode + '_' + frame;
	}
	
	// ネット販売,TL側の最新在庫残室数情報を取得する[タイプグループ単位]
	private void callNetStockSearchService (Set<String> tlRoomTypeGpCd, String ajdustDate, StockChangeHisotry__c sfStock, Decimal stockChangeCnt, String shopCode) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'StatusLst__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		log.write_method_start('callNetStockSearchService');
		log.write_log('P１：'+tlRoomTypeGpCd);
		log.write_log('P2：'+ajdustDate);
		log.write_log('P3：'+sfStock);
		log.write_log('P4：'+stockChangeCnt);
		log.write_log('P5：'+shopCode);
		
		// サビース初期化
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// 指定日、指定タイプグループコードで、在庫照会を行う
		TL_NetStockSearchService.extractionCondition extractionCondition
			= new TL_NetStockSearchService.extractionCondition();
		extractionCondition.extractionProcedure = '2';			// 「2」:照会期間で検索、
		extractionCondition.searchDurationFrom = ajdustDate;	// 照会期間FROM
		extractionCondition.searchDurationTo = ajdustDate;		// 照会期間TO
		
		log.write_log('******在庫状況照会(ネット販売)API 呼出開始******');
		// 在庫状況照会(ネット販売)API 呼出
		TL_NetStockSearchService.stockSearchForNetResponse rep 
			= tlService.callNetStockSearchService(shopCode, extractionCondition);
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******在庫状況照会(ネット販売)API 呼出終了******');
			
			rep.netRmTypeGroupAndDailyStockStatusList = (rep.netRmTypeGroupAndDailyStockStatusList == null)
								? new TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus[0] 
								: rep.netRmTypeGroupAndDailyStockStatusList;
			// 取得のタイプグループの残室数を取得する
			map<string, decimal> stockMap = new map<String, Decimal>();
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
			// 残室数調整可能の室タイプグループが存在する場合：TRUE
			Boolean isCanSyncStockToTlFlg = false;
			// 残室数は未設定の室タイプグループの場合：TRUE
			Boolean remainCountNoSetupFlg = true;
			// 調整対象数
			Integer groupCnt = 0;
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			boolean stockSettingFlag = sfStock.SettingFlg__c;
			// 2018/12/15 在庫調整と販売状態管理 by zy END
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
			for (TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus stock : rep.netRmTypeGroupAndDailyStockStatusList) {
				// 調整外ｎ室タイプグループの場合、処理対象外
				if (!tlRoomTypeGpCd.contains(stock.netRmTypeGroupCode)) continue;
				// 2016/01/20 販売ステータスは２「停止中」の場合、該当室タイプグループは連携対象外する BEGIN
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				if (stock.salesStatus == '2' && !stockSettingFlag) {
				// 2018/12/15 在庫調整と販売状態管理 by zy END
					log.write_log('グループコード['+stock.netRmTypeGroupCode+']は販売停止中、連携対象外');
					continue;
				}
				// 2016/01/20 販売ステータスは２「停止中」の場合、該当室タイプグループは連携対象外する END
				// 調整対応数
				groupCnt++;
				// 2015/12/11 在庫残室数は未設定する場合、該当室タイプの関連
				log.write_log('グループコード['+stock.netRmTypeGroupCode+']の残室数(調整前)：'+stock.remainingCount);
				// 該当室タイプグループの残室数は未設定の場合、該当未連携のまま残っている、残室数設定まで連携を行う
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				if (stock.remainingCount != null || stockSettingFlag) remainCountNoSetupFlg = false;
				// 2018/12/15 在庫調整と販売状態管理 by zy END
				else continue;
				// 該当室タイプグループの残室数を取得して、今回の変動数を加算して、調整後の残室数を設定する
				Decimal newRemainingCount = CommUtils.nullToZero(stock.remainingCount)  + stockChangeCnt;
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
                if (sfStock.SettingFlg__c) newRemainingCount = stockChangeCnt;
                // 2018/12/15 在庫調整と販売状態管理 by zy END
				// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
				if (newRemainingCount >= 0) isCanSyncStockToTlFlg = true;
				// 在庫数はマイナスの場合、論理在庫調整として、完了する（TL側へ連携を行わない）
				else continue;
				
				log.write_log('グループコード['+stock.netRmTypeGroupCode+']の残室数(調整後)：'+newRemainingCount);
				// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
				// 調整後の残室数は０以下の場合、０のまま設定する[TLのAPIは残室数はマイナスに設定ができません]
				newRemainingCount = newRemainingCount >= 0 ? newRemainingCount : 0;
				// 調整後の残室数は変更なし場合、更新調整を行わない
				if (CommUtils.nullToZero(stock.remainingCount) == newRemainingCount) continue;
				// 指定日の調整対象室タイプグループの残室数を設定する
				stockMap.put(stock.netRmTypeGroupCode, newRemainingCount);
			}
			// 調整対象が存在する場合、詳細処理を行う
			if (groupCnt > 0) {
				// 該当室タイプは全部残業数初期値は未設定の場合、TL経由で管理しないので、連携対象ステータスは変更なし、残業数設定まで、再連携を行う
				if (remainCountNoSetupFlg) {
					log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLのネット室タイプグループの残室数初期値未設定ため、TLへ連携しない.');
					sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
					return;
				}
				// 残業数初期値設定ありが、更新後の残室数は全部０以下の場合、TL連携対象外、「ステータス」は「論理連携済」に変更を行う
				if (!isCanSyncStockToTlFlg) {
					log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLのネット室タイプグループの残室数は０以下になるため、TLへ連携しない、論理連携済になる.');
					sfStock.StatusLst__c = STOCK_STATUS_LOGIC_SYNCOK;
					return;
				} else {
					// 残室数は０以上の場合、該当部屋タイプの相殺できるの「論理在庫調整済」情報が存在するがどうかチェックする
					// 論理在庫調整情報が存在する場合、該当調整データは連携済に減らす
					// 在庫調整数は＞０の場合、論理在庫調整と相殺更新する
					// 今回の在庫調整対象のステータスは「連携済」
					// [同じ部屋タイプ、同じ調整日付、同じ店舗コード、同じ予約情報を相殺する]
					// 2017/10/09 論理連携済のデータへ相殺条件不正の改修 BEGIN
					/*
					List<StockChangeHisotry__c> existStockHistory = [select Name,AgtRef__c,StatusLst__c from StockChangeHisotry__c
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN 
						//where AgtRef__c = :sfStock.AgtRef__c 
						//And LeadRef__c = :sfStock.LeadRef__c
						Where Id != :sfStock.Id 	
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						And StockChangeDate__c = :sfStock.StockChangeDate__c
						And TypeOfRoomRef__c = :sfStock.TypeOfRoomRef__c
						And StatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN
						//And Id != :sfStock.Id
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						limit 1];
				    */
				    Id stockId = sfStock.Id;
				    Date stockDate = sfStock.StockChangeDate__c;
				    Id typeOfRoomId = sfStock.TypeOfRoomRef__c;
                    Decimal stockCnt = CommUtils.nullToZero(sfStock.StockChangeCnt__c);
					String queryStr = 'select Name,AgtRef__c,StatusLst__c from StockChangeHisotry__c'+
					   ' Where Id != :stockId'+
					   ' And StockChangeDate__c = :stockDate'+
					   ' And TypeOfRoomRef__c = :typeOfRoomId'+
					   ' And StatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK';
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
						log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLのネット室タイプグループの論理在庫調整対象あるため、TLへ連携しない.[論理在庫調整対象No：('+existStockHistory[0].Name+')]');
						sfStock.StatusLst__c = STOCK_STATUS_SYNCOK;
						existStockHistory[0].StatusLst__c = STOCK_STATUS_SYNCOK;
						List<StockChangeHisotry__c> updLst = new List<StockChangeHisotry__c>();
						updLst.add(sfStock);
						updLst.add(existStockHistory[0]);
						update updLst;
						return;
					}
				}
			} else if (groupCnt == 0 && rep.netRmTypeGroupAndDailyStockStatusList.isEmpty()) {
				log.write_log('TLのネット室タイプグループ在庫情報がありません または　調整日付はTL連携可能期間対象外、TLへ連携しない.');
				sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				return;
			}
			/*
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
			// 全てグループは残室数調整できない場合、エラーを戻る
			if (!isCanSyncStockToTlFlg && groupCnt > 0) {
				log.write_error(Label.MSG_038_0001);
				log.write_method_end();
				return;
			}
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
			*/
			// 残室数設定情報が存在する場合、残室数調整を行う
			for (String groupcd : stockMap.keySet()) {
				log.write_log('室タイプグループコード['+groupcd+']在庫調整開始' );
				// 残室数調整を行う
				callNetStockAdjustmentService(groupcd, stockMap.get(groupcd), ajdustDate, shopCode, sfStock);
				log.write_log('室タイプグループコード['+groupcd+']在庫調整終了' );
			}
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
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// REQUEST PARAMETER
		TL_NetStockAdjustmentService.adjustmentTarget adjustmentTarget
			= new TL_NetStockAdjustmentService.adjustmentTarget();
		adjustmentTarget.adjustmentProcedureCode = '1';	// 「1」:ネット室タイプグループコードを指定して調整、
		adjustmentTarget.netRmTypeGroupCode = groupNo;	// ネット室タイプグループコード
		adjustmentTarget.adjustmentDate = ajdustDate;	// 調整日付
		adjustmentTarget.remainingCount = CommUtils.nullToblank(stockRemainCnt.intValue());	// 残室数
		// 残室数は＜０の場合、０で更新を行う「注：元の残室数は０すると、変更なし」
		adjustmentTarget.salesStatus = '3';				// 販売状態
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		// 2019/05/23 販売ステータスを設定される場合のみ、連携ステータスを設定する WSQ BEGIN
		if (sfStock.SettingFlg__c && sfStock.SalesStatus_del__c != null) adjustmentTarget.salesStatus = sfStock.SalesStatus_del__c;
		// 2019/05/23 販売ステータスを設定される場合のみ、連携ステータスを設定する WSQ END
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		log.write_log('******在庫調整(ネット販売)API 呼出開始******');
		
		// 在庫調整サビースを呼出
		TL_NetStockAdjustmentService.stockAdjustmentForNetResponse rep 
			= tlService.callNetStockAdjustmentService( shopCode, adjustmentTarget);
		// 実行結果を戻る
		TL_NetStockAdjustmentService.adjustmentResult res = rep.adjustmentResult;
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー個別処理:
			String errCode = rep.commonResponse.failureReason;
			if (errCode == 'E318' || errCode == 'E319') {
				log.write_log('TL連携ステータスは連携済に設定する:' +STOCK_STATUS_SYNCOK);
				sfStock.StatusLst__c = STOCK_STATUS_SYNCOK;
			}
			// エラー処理ログを記録する
			log.write_error(errCode+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******在庫調整(ネット販売)API 呼出終了******');
		}
		log.write_method_end();
	}

	// 在庫調整(旅行会社)API調整用パラメータ情報を格納する
	private class RealRmTypeInfo {
		public RealRmTypeInfo(string pAgtCode, String pRmTypeCode, String pFrame, String pAdjustmentDate) {
			agtCode = pAgtCode;
			realAgtRmTypeCode = pRmTypeCode;
			frame = pFrame;
			adjustmentDate = pAdjustmentDate;
		}
		public String agtCode{get;set;}					// 旅行会社コード
		public String realAgtRmTypeCode{get;set;}		// 旅行会社室タイプ
		public String frame{get;set;}					// 旅行会社室タイプ枠
		public String adjustmentDate{get;set;}			// 調整日付
	}
	
	// リアル,TL側の最新在庫残室数情報を取得する[タイプグループ単位]
	private void callRealStockSearchService (Set<String> tlRoomTypeGpCd, String ajdustDate, StockChangeHisotry__c sfStock, Decimal stockChangeCnt, String shopCode) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'StatusLst__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.StockChangeHisotry__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		log.write_method_start('callRealStockSearchService');
		log.write_log('P１：'+tlRoomTypeGpCd);
		log.write_log('P２：'+ajdustDate);
		log.write_log('P３：'+stockChangeCnt);
		log.write_log('P４：'+shopCode);
		
		// サビース初期化
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// 指定日、指定タイプグループコードで、在庫照会を行う
		// 旅行会社（リアル）の販売状態(2. 在庫状況照会(ネット販売)API ) 
		TL_RealStockSearchService.extractionCondition realCondition 
			= new TL_RealStockSearchService.extractionCondition();
		realCondition.extractionProcedureCode = '2';					// 「2」:照会期間で検索、
		realCondition.searchDurationFrom = ajdustDate;					// 照会期間FROM
		realCondition.searchDurationTo = ajdustDate;					// 照会期間TO
		
		log.write_log('******在庫状況照会(旅行会社)API 呼出開始******');
		
		// 在庫状況照会(ネット販売)API 呼出
		TL_RealStockSearchService.stockSearchForRealResponse rep 
			= tlService.callRealStockSearchService(shopCode, realCondition);
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			
			log.write_log('******在庫状況照会(旅行会社)API 呼出終了******');
			
			// 正常の場合、取得の情報はメモに格納する
			// map<販売先コート+'_'+旅行会社室タイプコート+'_'+枠 +'_'+調整日付
			map<string, decimal> stockMap = new map<String, Decimal>();
			map<string, RealRmTypeInfo> stockAdjustInfoMap = new map<String, RealRmTypeInfo>();
			// 旅行会社室タイプ
			rep.realAgtRmTypeList = (rep.realAgtRmTypeList == null) 
					? new TL_RealStockSearchService.realAgtRmType[0] 
					: rep.realAgtRmTypeList;
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
			// 残室数調整可能の室タイプグループが存在する場合：TRUE
			Boolean isCanSyncStockToTlFlg = false;
			// 残室数は未設定の室タイプグループの場合：TRUE
			Boolean remainCountNoSetupFlg = true;
			// 在庫調整可否フラグ:TRUE全部調整不可の場合
			Boolean stockCannotChangeFlg = true;
			// 連携対象の室タイプ数
			Integer groupCnt = 0;
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
			// 旅行会社室タイフ
			for (TL_RealStockSearchService.realAgtRmType realAgtStock : rep.realAgtRmTypeList) {
				String filterKey = getRealRmTypeKey(realAgtStock.agtCode, realAgtStock.realAgtRmTypeCode, realAgtStock.frame);
				// 処理対象外販売先の室タイプ
				if (!tlRoomTypeGpCd.contains(filterKey)) continue;
				// 指定の日別在庫状況
				// 日別在庫状況
				realAgtStock.dailyStockStatusList = (realAgtStock.dailyStockStatusList == null) 
						? new TL_RealStockSearchService.dailyStockStatus[0] 
						: realAgtStock.dailyStockStatusList;
				for (TL_RealStockSearchService.dailyStockStatus dayStatus : realAgtStock.dailyStockStatusList) {
					// 調整対象情報あり場合
					groupCnt++;
					log.write_log('AGT['+filterKey+']の在庫調整操作可否(調整前)：'+dayStatus.isStockAdjustable);
					// 在庫調整操作可否:不可能の場合(false)
					if (!dayStatus.isStockAdjustable) continue;
					else stockCannotChangeFlg = false;
					
					log.write_log('AGT['+filterKey+']の残室数(調整前)：'+dayStatus.remainingCount);
					// 該当室タイプグループの残室数は未設定の場合、該当未連携のまま残っている、残室数設定まで連携を行う
					if (dayStatus.remainingCount != null) remainCountNoSetupFlg = false;
					else continue;
					// 該当室タイプグループの残室数を取得して、今回の変動数を加算して、調整後の残室数を設定する
					Decimal newRemainingCount = CommUtils.nullToZero(dayStatus.remainingCount)  + stockChangeCnt;
					// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
					if (newRemainingCount >= 0) isCanSyncStockToTlFlg = true;
					// 在庫数はマイナスの場合、論理在庫調整として、完了する（TL側へ連携を行わない）
					else continue;
					
					log.write_log('AGT['+filterKey+']の残室数(調整後)：'+newRemainingCount);
					// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
					// 調整後の残室数は０以下の場合、０のまま設定する[TLのAPIは残室数はマイナスに設定ができません]
					newRemainingCount = newRemainingCount >= 0 ? newRemainingCount : 0;
					// 調整後の残室数は変更なし場合、更新調整を行わない
					if (CommUtils.nullToZero(dayStatus.remainingCount) == newRemainingCount) continue;
					// 指定日の調整対象室タイプグループの残室数を設定する
					String key = filterKey+'_'+dayStatus.saleDate; 
					stockMap.put(key, newRemainingCount);
					// 調整用情報を格納する	
					stockAdjustInfoMap.put(key, new RealRmTypeInfo(realAgtStock.agtCode, realAgtStock.realAgtRmTypeCode, realAgtStock.frame, dayStatus.saleDate));
				}
			}
			if (groupCnt > 0) {
				// 全ての室タイプは調整不可の状態するため、調整対象外になる
				if (stockCannotChangeFlg) {
					log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLの室タイプは在庫調整操作不可ため、TLへ連携しない.');
					sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
					return;
				}
				// 該当室タイプは全部残業数初期値は未設定の場合、TL経由で管理しないので、連携対象ステータスは変更なし、残業数設定まで、再連携を行う
				if (remainCountNoSetupFlg) {
					log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLの室タイプの残室数初期値未設定ため、TLへ連携しない.');
					sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
					return;
				}
				// 残業数初期値設定ありが、更新後の残室数は全部０以下の場合、TL連携対象外、「ステータス」は「論理連携済」に変更を行う
				if (!isCanSyncStockToTlFlg) {
					log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLの室タイプの残室数は０以下になるため、TLへ連携しない、論理連携済になる.');
					sfStock.StatusLst__c = STOCK_STATUS_LOGIC_SYNCOK;
					return;
				} else {
					// 論理在庫調整情報が存在する場合、該当調整データは連携済に減らす
					// 在庫調整数は＞０の場合、論理在庫調整と相殺更新する
					// 今回の在庫調整対象のステータスは「連携済」
					// [同じ部屋タイプ、同じ調整日付、同じ店舗コード、同じ予約情報を相殺する]
					// 2019/08/12 「SObject row was retrieved via SOQL without querying the requested field: ps__StockChangeHisotry__c.Name」不具合改修 BEGIN
					/*
					//List<StockChangeHisotry__c> existStockHistory = [select AgtRef__c,StatusLst__c from StockChangeHisotry__c 
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN
						//where AgtRef__c = :sfStock.AgtRef__c 
						//And LeadRef__c = :sfStock.LeadRef__c 
						Where Id != :sfStock.Id 	
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						And StockChangeDate__c = :sfStock.StockChangeDate__c
						And TypeOfRoomRef__c = :sfStock.TypeOfRoomRef__c
						And StatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK
						// 2016/02/19 論理連携済のデータ検索条件変更対応 BEGIN
						//And Id != :sfStock.Id
						// 2016/02/19 論理連携済のデータ検索条件変更対応 END
						limit 1];
						*/	
				    Id stockId = sfStock.Id;
				    Date stockDate = sfStock.StockChangeDate__c;
				    Id typeOfRoomId = sfStock.TypeOfRoomRef__c;
                    Decimal stockCnt = CommUtils.nullToZero(sfStock.StockChangeCnt__c);
					String queryStr = 'select Name,AgtRef__c,StatusLst__c from StockChangeHisotry__c'+
					   ' Where Id != :stockId'+
					   ' And StockChangeDate__c = :stockDate'+
					   ' And TypeOfRoomRef__c = :typeOfRoomId'+
					   ' And StatusLst__c = :STOCK_STATUS_LOGIC_SYNCOK';
                    if (stockCnt > 0) queryStr += ' And StockChangeCnt__c < 0 ';
                    else if (stockCnt < 0) queryStr += ' And StockChangeCnt__c > 0 ';
                    queryStr += ' limit 1 ';
                    List<StockChangeHisotry__c> existStockHistory = DataBase.query(queryStr);	
                    // 2019/08/12 「SObject row was retrieved via SOQL without querying the requested field: ps__StockChangeHisotry__c.Name」不具合改修 END				
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
						log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連のTLの室タイプの論理在庫調整対象あるため、TLへ連携しない.[論理在庫調整対象No：('+existStockHistory[0].Name+')]');
						sfStock.StatusLst__c = STOCK_STATUS_SYNCOK;
						existStockHistory[0].StatusLst__c = STOCK_STATUS_SYNCOK;
						List<StockChangeHisotry__c> updLst = new List<StockChangeHisotry__c>();
						updLst.add(sfStock);
						updLst.add(existStockHistory[0]);
						update updLst;
						return;
					}
				}
			} else if (groupCnt == 0 && rep.realAgtRmTypeList.isEmpty()) {
				log.write_log('該当部屋タイプ['+tlRoomTypeGpCd+']関連在庫情報がありません または　調整日付はTL連携可能期間対象外、TLへ連携しない.');
				sfStock.StatusLst__c = STOCK_STATUS_SYNCOUT;
				return;
			}
			/*
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 BEGIN
			// 全てグループは残室数調整できない場合、エラーを戻る
			if (!isCanSyncStockToTlFlg && groupCnt > 0) {
				log.write_error(Label.MSG_038_0001);
				log.write_method_end();
				return;
			}
			// 2015/10/28 残室数は０の場合、エラーは戻る、メールを送信する機能対応 END
			if (stockMap.isEmpty()) {
				log.write_error('該当部屋タイプコード['+tlRoomTypeGpCd+']はTL側に在庫照会情報をみつかりません。');
				return;
			}*/
			for (String key : stockMap.keySet()) {
				callRealStockAdjustmentService(stockAdjustInfoMap.get(key), stockMap.get(key), shopCode);
			}
		}
		log.write_method_end();
	}
	// ネット販売：指定日、指定室タイプグループ単位で、残室数調整を行う
	private void callRealStockAdjustmentService(RealRmTypeInfo adjuestInfo, Decimal stockRemainCnt, String shopCode) {
		
		log.write_method_start('callRealStockAdjustmentService');
		log.write_log('P１：'+adjuestInfo);
		log.write_log('P２：'+stockRemainCnt);
		log.write_log('P３：'+shopCode);
		
		// サビース初期化
		// 2016/07/29 ログ出力機能追加 BEGIN
		TL_ServiceCtrl tlService = new TL_ServiceCtrl(log);
		// 2016/07/29 ログ出力機能追加 END
		// REQUEST PARAMETER
		TL_RealStockAdjustmentService.adjustmentTarget adjustmentTarget
			= new TL_RealStockAdjustmentService.adjustmentTarget();
		adjustmentTarget.agtCode = adjuestInfo.agtCode;						// 販売先コード
		adjustmentTarget.realAgtRmTypeCode = adjuestInfo.realAgtRmTypeCode;	// 旅行会社室タイプコード
		adjustmentTarget.frame = adjuestInfo.frame;						// 枠
		adjustmentTarget.adjustmentDate = adjuestInfo.adjustmentDate;	// 調整日付
		adjustmentTarget.remainingCount = CommUtils.nullToblank(stockRemainCnt.intValue());	// 残室数
		
		log.write_log('******在庫調整(旅行会社)API 呼出開始******');
		// 在庫調整サビースを呼出
		TL_RealStockAdjustmentService.stockAdjustmentForRealResponse rep 
			= tlService.callRealStockAdjustmentService( shopCode, adjustmentTarget);
		// 取得APIがエラーが発生する場合
		if (!rep.commonResponse.isSuccess) {
			// エラー処理ログを記録する
			log.write_error(rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription);
		} else {
			log.write_log('******在庫調整(旅行会社)API 呼出終了******');
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
		if (TL_ServiceConfigHelp.isStockBatchStopCheck()) return;
		// 2016/12/14 該当バッチは処理中止するがどうかチェック　Wgch END
		// 作成日は2週間前の在庫変更履歴情報を削除する[連携不要、連携済]
		try {
		//log.clear();
		//log.write_method_start('バッチ処理終了');
		if (TL_ServiceConfigHelp.getCommConfig().bIsDebug) return;
		Date deleteDate = Date.today().addDays(TL_ServiceConfigHelp.getCommConfig().mStockDeleteVal);
		//log.write_log('調整日は['+deleteDate.format()+']前の在庫変更履歴情報を削除');
		// 2016/03/04 ゴミデータの削除条件を変更する BEGIN
		//List<StockChangeHisotry__c> stockChangList = [select id,CooperationResultRef__c from StockChangeHisotry__c where createdDate < :deleteDate];
		List<StockChangeHisotry__c> stockChangList = [select id,CooperationResultRef__c from StockChangeHisotry__c where StockChangeDate__c < :deleteDate limit 100];
		// 2016/03/04 ゴミデータの削除条件を変更する END
		//log.write_log('削除件数['+stockChangList.size()+']件');
		Set<Id> deleteCoopIdsSet = new Set<Id>();
		for (StockChangeHisotry__c stock : stockChangList) if (stock.CooperationResultRef__c != null) deleteCoopIdsSet.add(stock.CooperationResultRef__c);
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
		//TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (exception e){}
		// 処理データがまだある場合、次のバッチを起動する
		callNextSchedule();	
	}
	
	// 次のスケジュールを起動する	
	private void callNextSchedule(){
		Integer intervalLength = TL_ServiceConfigHelp.DEF_MIN_INTERVAL;
		try {
			intervalLength = TL_ServiceConfigHelp.getCommConfig().mStockInterval;
			/*
			log.clear();
			log.write_method_start('次のスケジュール定義');
			log.write_log(String.valueOf(intervalLength) + '秒後、次のスケジュールを起動する');
			*/
		} catch (Exception e) {}
		// 次のスケジュールを起動する
		TL_StockAdjustmentBatch schedule= new TL_StockAdjustmentBatch(gScheduleBeginTime);
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
		String jobName = 'TL_StockAdjustmentBatch_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
		/*
		try {
		log.write_log('次のスケジュールID:'+jobId);
		log.write_method_end();
		TL_ServiceConfigHelp.writeLogToDb(log.getAllLog(), logManagerId, false);
		} catch (Exception e){}*/
	}

	// エラー処理
	private void callErroProcess(StockChangeHisotry__c stock, String shopCode) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFields = new List<String>{'ProcessLog__c','MailSendComplete__c','ErrorCount__c','ErrorContent__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CooperationResult__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
		}
		// 2018/03/07 Security Check END
		if (stock.CooperationResultRef__c != null) {
			// エラー回数を更新する
			CooperationResult__c updCoop = new  CooperationResult__c(Id = stock.CooperationResultRef__c);
			String orgErrMsg =  stock.CooperationResultRef__r.ErrorContent__c;	
			String newErrMsg = removeOverErrString(log.getLastError());
			if (orgErrMsg != newErrMsg) {
				updCoop.ErrorCount__c = 1;
				updCoop.ErrorContent__c = newErrMsg;
				updCoop.MailSendComplete__c = false;
			} else {
				updCoop.ErrorCount__c = CommUtils.nullToZero(stock.CooperationResultRef__r.ErrorCount__c) + 1;
			}
			// 2017/08/24 同じエラーは重複送信しないように回避対応 BEGIN
			// 最新のエラーメッセージは既に送信済みの場合
			// 前回送信済みのエラーメッセージと同じ場合、
            if (TL_ServiceConfigHelp.isStockDupErrorMsgCheck(newErrMsg, false)) {
                Boolean orgCoopMailSendFlg = stock.CooperationResultRef__r.MailSendComplete__c;
                // 未送信の場合
                if (orgCoopMailSendFlg == false) {
                    if (updCoop.ErrorCount__c > 4) updCoop.ErrorCount__c = 4;
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
				ManageID__c = stock.Id,
				ShopCode__c = shopCode,
				ProcessLog__c =  removeOverLogString(log.getAllLog())
			);
			setSendMailAddress(newCoop);
			upsert newCoop CooperationResult__c.ManageID__c;
			stock.CooperationResultRef__c = newCoop.Id;
		}
		// 処理ステータスは未設定の場合、処理NGを設定する
		if (CommUtils.isBlank(stock.StatusLst__c)) {
			stock.StatusLst__c = STOCK_STATUS_SYNCNG;
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
		List<String> chkFields = new List<String>{'StatusLst__c','ProcessLog__c'};
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
}