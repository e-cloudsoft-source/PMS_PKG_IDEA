public with sharing class FreeeSyncCsvGetBatch implements Database.Batchable<Sobject>, Database.Stateful, Schedulable, Database.AllowsCallouts{
	public final String disName = CommConst.DISNAME;   // 事業所名
	public final String callBack = CommConst.CALLBACK; // 回调函数
	private Date gFromDate;						// 売上計上日FROM
	private Date gToDate;						// 売上計上日TO
	private String gShopCode;					// 店舗コード
	private Boolean isFromSchedule;				// スケジュールからバッチ起動する
	private String batchProcessJobNo;			// バッチ処理のSEQNO
	private String batchFilePrefixKey;
	private List<FreeeSyncCsvPostBatch.ProShopInfo> proShopInfoLst;
	private Map<String, List<FreeeSyncCsvPostBatch.ProDocumentInfo>> proDocInfoMap; // Key: shopcode
	// スケジュール処理场合
	public FreeeSyncCsvGetBatch(){
		isFromSchedule = true;
	}
	// ----------- バッチインスタンス化 --------------
	// スケジュールからバッチ起動
	public FreeeSyncCsvGetBatch(Date beginDate, Date endDate){
		gFromDate = beginDate;
		gToDate = endDate;
		isFromSchedule = true; 
	}
	// Requestバッチロジック処理场合
	public FreeeSyncCsvGetBatch(String pShopCd, Date beginDate, Date endDate){
		gFromDate = beginDate;
		gToDate = endDate;
		gShopCode = pShopCd;
		isFromSchedule = false;// リクエストバッチから起動
	}
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC){
		// SYSTEM.DEBUG(logginglevel.info, 'isFromSchedule:='+isFromSchedule);
		if(isFromSchedule){
			Integer offsetVal = CommConst.OFFSETVAL;// 共通定義値
			Date sysdate = Date.today();
			Date calMonth = sysdate.addMonths(offsetVal);
			// 指定処理月の１日
			gFromDate = Date.newInstance(calMonth.year(),calMonth.month(),1);
			gToDate = gFromDate.addMonths(1).addDays(-1);
			// バッチ起動
			FreeeSyncCsvGetBatch batch = new FreeeSyncCsvGetBatch(gFromDate,gToDate);
			DataBase.executeBatch(batch,1);
		} else{
			/*
			STRING gShopCode = '02';
			DATE gFromDate = DATE.newInstance(2019,12,02);
			DATE gToDate = DATE.newInstance(2019,12,02);
			// Requstバッチ起動
			FreeeSyncCsvGetBatch batch = new FreeeSyncCsvGetBatch(gShopCode,gFromDate,gToDate);
			DataBase.executeBatch(batch,1);
			*/
			// Requstバッチ起動
			FreeeSyncCsvGetBatch batch = new FreeeSyncCsvGetBatch(gShopCode,gFromDate,gToDate);
			DataBase.executeBatch(batch,1);
		}
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public List<Sobject> start(Database.BatchableContext BC){
		// スケジュールから起動する場合、全て店舗を処理する
		List<ShopInformation__c> shops = new List<ShopInformation__c>();
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'isFromSchedule:='+isFromSchedule);
		if (isFromSchedule) {
			shops = [	
					SELECT 
					Id
					, Name
					, ShopCode__c
					, Payee1__c
					, Payee2__c
					From ShopInformation__c order by Seq__c limit 100];
	   		// Dumy Shop Info Create
			if (shops.isEmpty()) shops.add(new ShopInformation__c(ShopCode__c = '01'));
			// 共通定義のにより、店舗取得反映を修正が必要
			Set<String> shopCodeSet = CommConst.SHOPCODESET;
			if(!shopCodeSet.isEmpty()){
				List<ShopInformation__c> nwShops = new List<ShopInformation__c>();
				for(ShopInformation__c sp : shops){
					// 共同定义设定值过滤处理
					if(shopCodeSet.contains(sp.ShopCode__c)) nwShops.add(sp);
				}
				// 过滤后最终重置设置
				shops = nwShops;
			}
		} else {
			shops = [	
					SELECT 
					Id
					, Name
					, ShopCode__c
					, Payee1__c
					, Payee2__c
					From ShopInformation__c Where ShopCode__c =: gShopCode order by Seq__c limit 1];
			if (shops.isEmpty()) shops.add(new ShopInformation__c(ShopCode__c = '01'));
		}
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'shops:='+shops);
		String strBeg = CommUtils.dateToYYYYMMDD(gFromDate);
		String strEnd = CommUtils.dateToYYYYMMDD(gToDate);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'strBeg:='+strBeg);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'strEnd:='+strEnd);
		List<RsvAccount__c> rsvLst = [select id, name from RsvAccount__c where name >= :strBeg and name <= :strEnd  order by name];
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'rsvLst:='+rsvLst);
		List<ShopInformation__c> loopRs = new List<ShopInformation__c>();
		for (ShopInformation__c sp : shops) {
			for (RsvAccount__c rsv : rsvLst) {
				ShopInformation__c wksp = sp.clone(false,true);
				wksp.Payee1__c = rsv.id;
				wksp.Payee2__c = rsv.name;
				loopRs.add(wksp);
			}
		}
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'loopRs:='+loopRs);
		// 不满足条件跳出
		if(CommUtils.isBlank(disName) || CommUtils.isBlank(callBack)){
			loopRs = new List<ShopInformation__c>();
			// 'Freee連携設定: 事業所名(屋号) または 認証プロバイダをURL接尾辞設定が正しくありません。';
		}
		// 数据集合初始化
		proShopInfoLst = new List<FreeeSyncCsvPostBatch.ProShopInfo>();
		proDocInfoMap = new Map<String, List<FreeeSyncCsvPostBatch.ProDocumentInfo>>();
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'loopRs:END:='+loopRs);
		return loopRs;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> shopLst){
		ShopInformation__c sitem = shopLst[0];
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'sitem:='+sitem);
		FreeeSyncCsvPostBatch.ProDocumentInfo pro = new FreeeSyncCsvPostBatch.ProDocumentInfo();
		pro.shopCode = CommUtils.nullToBlank(sitem.ShopCode__c);
	   	pro.shopName = CommUtils.nullToBlank(sitem.name);
	   	pro.startDate = CommUtils.nullToBlank(sitem.Payee2__c);
		// 数据集获取
		FreeeSyncCsvTemplateCtrl ctrl = new FreeeSyncCsvTemplateCtrl(sitem.Payee1__c, pro.shopCode);
		String csvBody = ctrl.generalCsvContent(true);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'ctrl:='+ctrl);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'csvBody:='+csvBody);
		// 前方キー
		batchFilePrefixKey = 'SYNCFREE_';
		batchProcessJobNo = pro.startDate + System.now().format('HHmmss');
		// 添附ファイル名				
		String fileName = batchFilePrefixKey + batchProcessJobNo
						+ ( CommUtils.isBlank(pro.shopCode) ? '' : '_' + pro.shopCode)
						+ '.csv';
						
		Attachment att = new Attachment(name =fileName);
	   	att.body = Blob.valueOf(csvBody);
	   	pro.mailMsg.bodyMsg = ctrl.msgStr;
	   	pro.docmentId = createFileToSyncFloder(att,sitem);
	   	pro.csvAccIdMap = ctrl.csvAccIdMap;
	   	// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'pro:='+pro);
	   	
	   	if(!proDocInfoMap.containsKey(pro.shopCode)){
	   		FreeeSyncCsvPostBatch.ProShopInfo proShop = new FreeeSyncCsvPostBatch.ProShopInfo();
	   		proShop.shopCode = pro.shopCode;
	   		proShop.shopName = pro.shopName;
	   		proShop.startDate = CommUtils.dateToYYYYMMDD(gFromDate);
	   		proShop.endDate = CommUtils.dateToYYYYMMDD(gToDate);
	   		proShopInfoLst.add(proShop);
	   		proDocInfoMap.put(pro.shopCode, new List<FreeeSyncCsvPostBatch.ProDocumentInfo>());
	   	}
	   	proDocInfoMap.get(pro.shopCode).add(pro);
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		FreeeSyncCsvPostBatch batch = new FreeeSyncCsvPostBatch(proShopInfoLst, proDocInfoMap);
		DataBase.executeBatch(batch,1);
	}
	/**
	* フォルダに連携結果を保存する
	**/
	private Id createFileToSyncFloder(Attachment att, ShopInformation__c shop) {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'Description','FolderId','ContentType','type','body','Name'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where DeveloperName = 'SyncFiles'];
		list<Document> newDocs = new list<Document>();
		// CSVファイルをアップロードする
		Document newDoc = new Document(
			DeveloperName = batchFilePrefixKey+ batchProcessJobNo + (CommUtils.isBlank(shop.ShopCode__c) ? '' : '_' + shop.ShopCode__c),
			//連携結果_
			Description = Label.MSG_046_0017 + batchFilePrefixKey + System.now().format('yyyyMMddHHmmss'),
			FolderId = fs[0].Id,
			Name = att.name,
			ContentType = 'text/csv',
			type = 'csv',
			body = att.body
		);
		newDocs.add(newDoc);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'newDocs:='+newDocs);
		if (!newDocs.isEmpty()){
			insert newDocs;
			return newDocs[0].Id;
		}
		return null;
	}
}