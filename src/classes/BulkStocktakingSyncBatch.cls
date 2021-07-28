/**
* 棚卸し同期バッチ機能対応
**/
public with sharing class BulkStocktakingSyncBatch implements Database.Batchable<Sobject>, Database.Stateful, Schedulable {
	// 店舗コード
	private final String gShopCode;				
	// 処理締日
	private Date gProDate;
	// デファルト店舗関係処理情報
	private ProcessInfo gDefaultProInfo;
	// スケジュールからバッチ起動する
	private Boolean isFromSchedule;		
	// 会計商品リスト取得SQL文
	private static String Query = 'select id,name,ShopInfoRef__r.ShopCode__c from AccountMaster__c where  field3__c != null ';  
	// 月末定数
	private static String Month_Last_Int = '月末';
	private static String DEF_INFO = 'defaultShopCode';
	// 曜日対応定数
	private static Map<String,Integer> yobiMap = new Map<String,integer>{'日' =>7,'月'=>0,'火' =>1 ,'水' => 2,'木' => 3,'金' => 4,'土' =>5};
	// ログ情報格納用
	private String strErrMsg;
	// バッチ執行フラグ
	public boolean isCanExecuteFlag;
	// メール用処理数
	private Integer processInt;
	// メール用成功数
	private Integer totalInt;
	// メール用エラー処理
	private integer errorInt;
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
	// 処理対象
	public Set<String> processIdSet;
	// 差異集合
	public List<String> diffSet;
	// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
	// インスタンス化
	public BulkStocktakingSyncBatch () {
		isFromSchedule=true;
		isCanExecuteFlag = false;
		// メール用処理数
		processInt = 0;
		// メール用成功数
		totalInt = 0;
		// メール用エラー処理
		errorInt = 0;
		// エラーメーセッジ
		strErrMsg = '';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		diffSet = new List<String>();
		processIdSet = new Set<String>();
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
	}
	public BulkStocktakingSyncBatch (String pShopCd, Date pSaleDate,ProcessInfo info) {
		gShopCode = pShopCd;
		gProDate = pSaleDate;
		gDefaultProInfo = info;
		// request　batchチェックなし
		isCanExecuteFlag = true;
		// メール用処理数
		processInt = 0;
		// メール用成功数
		totalInt = 0;
		// メール用エラー処理
		errorInt = 0;
		// エラーメーセッジ
		strErrMsg = '';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		diffSet = new List<String>();
		processIdSet = new Set<String>();
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
	}
	public BulkStocktakingSyncBatch (String pShopCd, Date pSaleDate) {
		gShopCode = pShopCd;
		gProDate = pSaleDate;
		isFromSchedule = false;
		// request　batchチェックなし
		isCanExecuteFlag = true;
		// メール用処理数
		processInt = 0;
		// メール用成功数
		totalInt = 0;
		// メール用エラー処理
		errorInt = 0;
		// エラーメーセッジ
		strErrMsg = '';
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		// 指定店舗、執行日あり
		if (isCanExecuteFlag) {
			if (gDefaultProInfo == null) {
				// 店舗関係処理情報取得
				Map<String,ProcessInfo> processSpcdMap = loadXmlReading(gProDate);
				gDefaultProInfo = getProcessInfoBySpcd(gShopCode,processSpcdMap);
			}
			// バッチ処理設定
			BulkStocktakingSyncBatch batch = new BulkStocktakingSyncBatch(gShopCode,gProDate,gDefaultProInfo);
			batch.isFromSchedule = isFromSchedule;
			DataBase.executeBatch(batch,2000);
		// スーゲッジュ執行の場合
		} else {
			// 店舗関係処理情報取得
			Map<String,ProcessInfo> processSpcdMap = loadXmlReading(gProDate);
			// 会計商品店舗グループ取得
			AggregateResult[] groupedResults = [select ShopInfoRef__r.shopcode__c spcd from accountMaster__c group by ShopInfoRef__r.shopcode__c];
			// 既存会計商品参照店舗コードLOOP
			for (AggregateResult acc : groupedResults) {
				String spcd = CommUtils.nullToBlank(acc.get('spcd'));
				Datetime curDt = System.now();
				// 店舗対応情報設定
				ProcessInfo proInfo = getProcessInfoBySpcd(spcd,processSpcdMap);
				// 執行日あり
				if (proInfo.processFlag) {
					// 執行日→該当日付の２４時
					Datetime nowTime = CommUtils.convertDatetime(curDt.date(),proInfo.excuteTime);
					if (curDt != nowTime) {
						executeSchedule(curDt.date(),nowTime,spcd,proInfo);
					} else {
						// バッチ処理設定
						BulkStocktakingSyncBatch batch = new BulkStocktakingSyncBatch(spcd,curDt.date(), proInfo);
						DataBase.executeBatch(batch,2000);
					}
				}
			}
		}
	} 
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Database.QueryLocator start(Database.BatchableContext BC){
		String orderSQL = ' order by  ShopInfoRef__r.ShopCode__c';
		String whereSQL = '';
		if (gShopCode != null) whereSQL = ' and ShopInfoRef__r.ShopCode__c =:gShopCode';
		// 処理締日未設定の場合
		if (gProDate == null) gProDate = system.today();
		// 該当店舗・デファルト店舗下　フィルター条件あり
		if (gDefaultProInfo != null && !CommUtils.isBlank(gDefaultProInfo.filter)) {
			whereSQL += ' and ' + gDefaultProInfo.filter;
		} else {
			List<String> notInActLst = new List<String>{CommConst.PROD_ACTION_TYPE_NO,CommConst.PROD_ACTION_TYPE_AR,CommConst.PROD_ACTION_TYPE_PY};
			whereSQL += ' and actionType__c not in :notInActLst';
		}
		return Database.getQueryLocator(Query + whereSQL + orderSQL);
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<AccountMaster__c> scope){
		String whereSQL = '';
		// 既存店舗コード集合
		Set<String> exitSpcdSet = new Set<String>();
		// 処理会計商品集合
		Set<Id> processIds = new Set<Id>();
 		// 在庫計算
		for (AccountMaster__c acc : scope) {
			// 設定あり
			processIds.add(acc.id);
		}
		// 該当処理日の会計商品在庫情報取得
		Map<String,ProductStock__c> prodMap = new Map<String,ProductStock__c>();
		// 既存棚卸し在庫対応
		Map<Id,decimal> stockMap = new Map<Id,decimal>();
		try{
			Set<String> inventoryIds = new Set<String>();
			// 棚卸し在庫処理
			List<InventoryInfo__c> ints = [select id,AccountMasterRef__c,StockDate__c,ShelfChkFlag__c,RealQtyOfStock__c from InventoryInfo__c 
													where AccountMasterRef__c in :processIds and StockDate__c <= :gProDate and ShelfChkFlag__c = true];
			// 棚卸し在庫LOOP
			for (InventoryInfo__c inventory : ints) {
				// 該当商品在庫取得
				Decimal cnt = CommUtils.nullToZero(inventory.RealQtyOfStock__c); 
				// 商品在庫数設定
				stockMap.put(inventory.AccountMasterRef__c,cnt);
				// 在庫処理後再処理フラグ設定
				inventory.ShelfChkFlag__c = false;
				// 締日設定
				inventory.BatchDate__c = gProDate;
				// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
				// 処理会計商品
				processIdSet.add(inventory.AccountMasterRef__c);
				// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
			}
			processIds = stockMap.keySet();
			StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
			helpUtils.getProdcutStockById(processIds);
			// 会計商品処理合計
			totalInt += processIds.size();
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
			//Map<String,ProductStockInventoryCtrl.ProdDiff> diffMap = ProductStockInventoryCtrl.diffProductStockCheck(ints);
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
			List<ProductStock__c>  prodStocks = [select id ,InitQtyOfStock__c,ProductRef__c,ProductRef__r.name from ProductStock__c where ProductRef__c in : processIds];
			// 処理会計商品データあり
			for (ProductStock__c stock : prodStocks) {
				// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
				//stock.InitQtyOfStock__c = CommUtils.nullToIntZero(stockMap.get(stock.ProductRef__c));
				Decimal stockInt = CommUtils.nullToZero(stockMap.get(stock.ProductRef__c));
				//if (diffMap.containsKey(stock.ProductRef__c)) 
				diffSet.add(stock.ProductRef__r.name + ' 在庫:' + stockInt);
				stock.InitQtyOfStock__c = stockInt;
				// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
			}
			// 在庫更新
			if (!prodStocks.isEmpty()) update prodStocks;
			// 棚卸し在庫処理
			if (!ints.isEmpty()) update ints;
			// 会計商品在庫処理合計
			processInt += prodStocks.size();
		}catch(Exception e) {
			strErrMsg += '\n' + '：' + e.getMessage();
			errorInt += processIds.size();
		}
	}
	
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 入庫情報と出庫情報の集計対象フラグを更新する
		String strDt = (DateTime.newInstance(gProDate.year(),gProDate.month(),gProDate.day())).format('yyyyMMdd');
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		if (processIdSet != null && !processIdSet.isEmpty()) {
			// 入庫情報
			BulkStocktakingLinkBatch bt1 = new BulkStocktakingLinkBatch(strDt, BulkStocktakingLinkBatch.BATCH_TYPE.INSTOCK);
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
			bt1.processIdSet = processIdSet;
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
			DataBase.executeBatch(bt1, 2000);
			// 出庫情報
			BulkStocktakingLinkBatch bt2 = new BulkStocktakingLinkBatch(strDt, BulkStocktakingLinkBatch.BATCH_TYPE.OUSTOCK);
			// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
			bt2.processIdSet = processIdSet;
			DataBase.executeBatch(bt2, 2000);
		}
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
		if (gDefaultProInfo != null) {
			// 締日メール送信
			if (gDefaultProInfo.processFlag) sendPosImportMail(strErrMsg);
		}
	}
	// 店舗関係処理情報取得
	public static Map<String,ProcessInfo> loadXmlReading(Date processDt){
		// 初期化
		Map<String,ProcessInfo> processSpcdMap = new Map<String,ProcessInfo>();
		try{
			if (processDt == null) processDt = system.today();
			// XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('BatchRequstConfigXml',new String[]{});
			Dom.XmlNode tempNode = targetNode.getChildElement('INVENTORYSYNC',null);
			if (tempNode != null) {
				for (Dom.XmlNode shopNode : tempNode.getChildElements()) {
					if (shopNode != null) {
						// 店舗コード
						Dom.XmlNode shopCodeNode = shopNode.getChildElement('SHOPCODE',null);
						String spcd = '';
						if (shopCodeNode != null) spcd = CommUtils.nullToBlank(shopCodeNode.getText());
						// 情報作成
						ProcessInfo processInfo = new ProcessInfo(processDt,shopNode);
						// デファルト情報作成
						if (processSpcdMap.isEmpty()) processSpcdMap.put(DEF_INFO,processInfo);
						processSpcdMap.put(spcd,ProcessInfo);
					}
				}
			}
		}catch(exception e) {
			system.debug(logginglevel.info,'e:::' + e.getStackTraceString());
		}
		return processSpcdMap;
	}
	// 指定店舗コード対応の情報取得
	public static ProcessInfo getProcessInfoBySpcd(String spcd,Map<String,ProcessInfo> processSpcdMap){
		ProcessInfo info = processSpcdMap.get(spcd);
		if (info == null) info = processSpcdMap.get(DEF_INFO);
		return info;
	}
	// 店舗関係処理情報
	public class ProcessInfo{
		// 前次処理日
		public date prevDate;
		// 次の処理日
		public date nextDate;
		// 日付リスト
		List<Date> dateLst;
		// フィルター条件
		String filter ;
		// 処理日フラグ
		public boolean processFlag;
		// バッチ処理日の指定時刻
		String excuteTime;
		// 初期化
		public ProcessInfo(Date todayDt,Dom.XmlNode shopNode){
			// フィルター条件
			filter = '';
			// 処理日
			dateLst =  new List<Date>();
			// バッチ処理日の指定時刻
			excuteTime = '24:00';
			// 処理日フラグ
			processFlag = false;
			// REPEAT執行タイプ
			String processType = null;
			// 処理年
			Integer year = todayDt.year();
			// 処理月
			Integer month = todayDt.month();
			// 前執行日付
			LIst<Date> prvDtLst = new List<Date>();
			// 後執行日付
			List<Date> nextDtLst = new List<Date>();
			// 現処理日
			Set<String> processDate = new Set<String>();
			// 該当月の最大日数
			Integer maxDays = Date.daysInMonth(year, month);
			// フィルター条件
			Dom.XmlNode filterNode = shopNode.getChildElement('FILTER',null);
			// 指定起動時刻
			Dom.XmlNode batchNode = shopNode.getChildElement('BATCHTIME',null);
			// フィルター条件設定
			if (filterNode != null) filter = CommUtils.nullToBlank(filterNode.getText());
			// 起動時刻設定
			if (batchNode != null) {
				String startime = CommUtils.nullToBlank(batchNode.getText());
				if (!CommUtils.isBlank(startime)) excuteTime = startime;
			}
			// REPEAT情報
			Dom.XmlNode repeatNode = shopNode.getChildElement('REPEATCONF',null);
			if (repeatNode != null) {
				Dom.XmlNode repeatTypeNode = repeatNode.getChildElement('REPEATTYPE',null);
				Dom.XmlNode repeatDetailNode = repeatNode.getChildElement('REPATDETAIL',null);
				if (repeatTypeNode != null) processType = CommUtils.nullToBlank(repeatTypeNode.getText());
				if (repeatDetailNode != null) {
					// 指定処理日
					String value = CommUtils.nullToBlank(repeatDetailNode.getText());
					// 処理日あり
					if (!CommUtils.isBlank(value)) {
						// 処理日リスト
						List<String> values = value.split(',');
						// 処理日LOOP
						for (String dtVal : values) {
							Date dt = null;
							//　年の場合
							if (processType == 'YEAR') {
								Integer monthInt = CommUtils.nullToIntZero(dtVal.subString(0,2));
								Integer day = CommUtils.nullToIntZero(dtVal.subString(2));
								dt = date.newInstance(year, monthInt, day);
							//　月の場合
							} else if (processType == 'MONTH') {
								Integer day =  dtVal == Month_Last_Int ? maxDays : CommUtils.nullTointZero(dtVal);
								dt = date.newInstance(year, month,day);
							//　週の場合
							} else if (processType == 'WEEK') {
								integer weekInt = yobiMap.get(dtVal);
								Date begDt = todayDt.toStartOfWeek();
								dt = begDt.addDays(weekInt);
							}
							// 処理日あり
							if (dt != null) {
								processDate.add(dt.format());
								dateLst.add(dt);
								if (dt < todayDt) prvDtLst.add(dt);
								if (dt > todayDt) nextDtLst.add(dt);
							}
						}
						// 前日リスト
						if (prvDtLst.isEmpty()) {
							List<Date> dts = getDateLst(processType,values,todayDt,true);
							prevDate = dts[dts.size() - 1];
						} else prevDate = prvDtLst[prvDtLst.size() - 1];
						// 後日リスト
						if (nextDtLst.isEmpty()) {
							List<Date> dts = getDateLst(processType,values,todayDt,false);
							nextDate = dts[0];
						} else nextDate = nextDtLst[0];
							
					}
					dateLst.sort();
					processFlag = processDate.contains(todayDt.format());
				}
			}
		}
		// 所在日付期間以外の日付リスト取得
		public List<Date> getDateLst(String processType,List<String> values,Date proceeDt,boolean prevFlag){
			List<Date> dts = new List<Date>();
			Integer year = proceeDt.year();
			Integer month = proceeDt.month();
			Integer maxDays = Date.daysInMonth(year, month);
			for (String dtVal  : values){
				Date dt = null;
				//　年の場合
				if (processType == 'YEAR') {
					Integer monthInt = CommUtils.nullToIntZero(dtVal.subString(0,2));
					Integer day = CommUtils.nullToIntZero(dtVal.subString(2,4));
					if (prevFlag) {
						dt = date.newInstance(year - 1, monthInt, day);
					} else {
						dt = date.newInstance(year + 1, monthInt, day);
					}
				//　月の場合
				} else if (processType == 'MONTH') {
					Integer day =  dtVal == Month_Last_Int ? maxDays : CommUtils.nullTointZero(dtVal);
					if (prevFlag) {
						if (month == 1) dt = date.newInstance(year - 1, 12,day);
						else dt = date.newInstance(year, month - 1,day);
					} else {
						if (month == 12) dt = date.newInstance(year + 1, 1,day);
						else dt = date.newInstance(year, month + 1,day);
					}
				//　週の場合
				} else if (processType == 'WEEK') {
					integer weekInt = yobiMap.get(dtVal);
					Date begDt = proceeDt.toStartOfWeek();
					dt = begDt.addDays(weekInt);
					if (prevFlag) {
						dt = dt.addDays(-7);
					} else {
						dt = dt.addDays(7);
					}
				}
				if (dt != null) dts.add(dt);
			}
			// 日付リスト並べ
			dts.sort();
			return dts;
		}
	}
	/**
	* メール送信機能対応:
	**/
	private void sendPosImportMail(String errMsg) {
		// 連携結果履歴に記録する
		// メール情報を設定する
		//　商品在庫バッチが以下の通リ終了しましたのでお知らせいたします。
		String mailBodyStr = '\n\n' + '商品棚卸データ締め処理が以下の通リ終了しましたのでお知らせいたします。';
		if (gProDate != null) {
			//処理締日:
			mailBodyStr += '\n'+ '締め対象日:' +' ' + (DateTime.newInstance(gProDate.year(),gProDate.month(),gProDate.day()).format('yyyyMMdd'));
		}
		if (!CommUtils.isBlank(gShopCode)) {
			// 関連店舗情報を取得する　
			List<ShopInformation__c> shops = [select id,name from ShopInformation__c where shopCode__c =:gShopCode limit 1 ];
			//店舗:
			if (!shops.isEmpty()) mailBodyStr += '\n'+ Label.CONST_046_0020 +' ' + shops[0].Name;
		}
		mailBodyStr += '\n\n'+ '同期の棚卸データ件数:' + totalInt + '件';
		mailBodyStr += '\n'+ '成功件数:' + processInt + '件';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		if (!diffSet.isEmpty()) {
			mailBodyStr += '\n成功明細：\n';
			for (String diffMsg : diffSet) {
				mailBodyStr += '\n'+ diffMsg;
			}
		}
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
		mailBodyStr += '\n'+ '失敗件数:' + errorInt + '件';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy BEGIN
		mailBodyStr += '\n失敗明細：\n';
		// 2018/12/30 棚卸しバッチ起動できるように改善対応 by zy END
		// エラー情報が存在する場合、エラーメッセージを出力する　
		if (!CommUtils.isBlank(errMsg))  {
			//処理結果：
			mailBodyStr += '\n\n'+ '処理結果:'  + errMsg;
		}
		mailBodyStr += '\n\n' + Label.INF_9001 + '\n';	//  JinyaConnect Enterprise system R&D team.

	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    //POS取込バッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ '商品棚卸データ締め処理バッチ結果の通知');
		mail.setPlainTextBody(mailBodyStr);
		// Chatterへポストする　
		sendMsgToChatter(mail, mailBodyStr);
	   	// テストクラスの場合、実施しない 
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メールアドレス未設定する場合、メール送信しない
		if (CommUtils.isBlank(mailAdds)) return;
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
	   	// 送信できるがどうか、チェックを行う
	   	Boolean canSendMail = true;
	   	try {
	   		Messaging.reserveSingleEmailCapacity(toAddresses.size());
	   	} catch (Exception e){
	   		canSendMail = false;
	   	}
		if(!Test.isRunningTest() && canSendMail)
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	/**
	* ChatterGroup送信機能対応:
	**/
	private void sendMsgToChatter(Messaging.SingleEmailMessage mail, String pMsgBody) {
		// 
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.PosI_ChatterGroupNameType);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
    	if (chatterGroups.isEmpty()) return;

    	String msgBody = mail.getSubject() + '\n\n';
  		msgBody += pMsgBody;
  		
    	List<FeedItem> feedItems = new List<FeedItem>();

    	for (CollaborationGroup cGroup : chatterGroups) {
			
			FeedItem post = new FeedItem();
			post.Type = 'TextPost';
	        post.Body = msgBody;
	        post.ParentId = cGroup.Id;
	        feedItems.add(post);
    	}
    	if (!feedItems.isEmpty()) insert feedItems;
	}
	private void executeSchedule(Date curDt,Datetime nowTime,String spcd,ProcessInfo proInfo){
		// 執行日→該当日付の２４時
		BulkStocktakingSyncBatch schedult = new BulkStocktakingSyncBatch(spcd, curDt, proInfo);
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
		String jobName = 'BulkStocktakingSyncBatch_' + nowTime.format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedult);
	}
}