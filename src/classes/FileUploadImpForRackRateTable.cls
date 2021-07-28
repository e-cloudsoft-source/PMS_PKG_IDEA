public with sharing class FileUploadImpForRackRateTable {

    // CSV HEADER MATCH
    
    private static final String CSV_HD_SHOPNAME = '店舗名';
    private static final String CSV_HD_TIERNAME = 'ラックレート名';
    private static final String CSV_HD_ROOMTYPENAME = '部屋タイプ名';
    private static final String CSV_HD_PEOPLES = '人数';
    private static final String CSV_HD_PRICE = '金額';
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    private static final String CSV_HD_BASEPLAN = 'ベースプラン名';
    private static final String CSV_HD_STATUS = '販売状態';
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
    private static final String CSV_HD_PLAN = 'ベースプラン名';
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
    
    private static final Map<String,Integer> kmp = new Map<String, Integer>{
                                                        CSV_HD_SHOPNAME => 0,
                                                        CSV_HD_TIERNAME => 1,
                                                        CSV_HD_ROOMTYPENAME => 3,
                                                        CSV_HD_PEOPLES => 2,
                                                        CSV_HD_PRICE => 4 
                                                    };
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    // 对应plan的map
    private static final Map<String,Integer> pmp = new Map<String, Integer>{
                                                        CSV_HD_SHOPNAME => 0,
                                                        CSV_HD_TIERNAME => 1,
                                                        CSV_HD_ROOMTYPENAME => 3,
                                                        CSV_HD_BASEPLAN => 2,
                                                        CSV_HD_STATUS => 4 
                                                    };
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
    // 对应planTier的map
    private static final Map<String,Integer> tmp = new Map<String, Integer>{
                                                        CSV_HD_SHOPNAME => 0,
                                                        CSV_HD_TIERNAME => 1,
                                                        CSV_HD_ROOMTYPENAME => 3,
                                                        CSV_HD_PEOPLES => 2,
                                                        CSV_HD_PRICE => 4,
                                                        CSV_HD_PLAN => 5
                                                    };
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
                                                 
    // リアルAGTのレコードタイプID
    //private static final Id REC_TYPEID_REALAGT = [select id,DeveloperName from RecordType where SobjectType = :RealAGT__c.sObjectType.getDescribe().getName() And DeveloperName = 'GenerMstRealAgtRecType'][0].Id;   
    public FileUploadImp filehand{get; private set;}
    public FileUploadImp.UploadResult getResult(){ return filehand.result; }
    
    //
    public String strTemplateId{get; private set;}
    public Id strDocFolderId{get; private set;}
    //public String strCsvDocumentId{get; private set;}
    //public String strCsvFileName{get; private set;}
    public Document lastDoc{get; private set;}
    //public String documentPrefix{get; private set;}
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    public Boolean rackRatePlanFlg{get{ return CommConst.RACKRATE_PLAN_FLG;}set;}
    // タブ順情報格納する
    public Integer tabIndex{get;set;}
    public String strPlanTemplateId{get; private set;}
    public Document lastPlanDoc{get; private set;}
    public static final Integer RACKRATE_TAB = 1;
    public static final Integer RACKRATE_PLAN_TAB = 2;
    public Boolean isTab1{get{return tabIndex == RACKRATE_TAB;}}
    public Boolean isTab2{get{return tabIndex == RACKRATE_PLAN_TAB;}}
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
    public String strBasePlanTempId{get; private set;}
    public Boolean rackRatePlanTierFlg{get{ return CommConst.RACKRATE_BASEPLAN;}set;}
    public static final Integer RACKRATE_PLAN_TIER_TAB = 3;
    public Boolean isTab3{get{return tabIndex == RACKRATE_PLAN_TIER_TAB;}}
    public Document lastBasePlanDoc{get; private set;}
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
    /**
    * クラス初期化
    **/
    //private FileUploadImp filehand;
    public FileUploadImpForRackRateTable() {
		List<Document> sr = [select body, name from Document where DeveloperName = 'RackRateTemplate'];
		strTemplateId = sr[0].Id;
		List<Folder> fs = [select id from Folder where DeveloperName = 'RackRateHistory'];
		strDocFolderId = fs[0].Id;
		// 最終回作成したリアルAGTのCSVファイル
		List<Document> lastNew = [select id,Name,CreatedDate from Document where FolderId = :strDocFolderId and Name like 'ラックレート_%' Order By Name desc limit 1];
		if (!lastNew.isEmpty()) {
			lastDoc = lastNew[0];
		}
		// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
		sr = [select body, name from Document where DeveloperName = 'RackRateBasePlanTemplate'];
		strBasePlanTempId = sr.isEmpty() ? '' : sr[0].Id;
		lastNew = [select id,Name,CreatedDate from Document where FolderId = :strDocFolderId and Name like 'プラン別_ラックレート_%' Order By Name desc limit 1];
		if (!lastNew.isEmpty()) {
			lastBasePlanDoc = lastNew[0];
		}
		if(rackRatePlanTierFlg) tabIndex = RACKRATE_PLAN_TIER_TAB;
		// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
		
		// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
		if(false){
			sr = [select body, name from Document where DeveloperName = 'RackRatePlanTemplate'];
			strPlanTemplateId = sr.isEmpty() ? '' : sr[0].Id;
			// 最終回作成したリアルAGTのCSVファイル
			lastNew = [select id,Name,CreatedDate from Document where FolderId = :strDocFolderId and Name like 'ラックレート(プラン)_%' Order By Name desc limit 1];
			if (!lastNew.isEmpty()) {
				lastPlanDoc = lastNew[0];
			}
			// タブ順情報を格納する
			tabIndex = RACKRATE_TAB;
		}
		// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
		// ファイル処理ハンドル初期化
		filehand = 	new FileUploadImp();
    }
    
    /**
    * CSV内容処理
    **/
    public void processCsvFile() {
    	// 2017/02/23 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','ContentType','type','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/02/23 Field Security Check End by wx
    	//strCsvDocumentId = strCsvFileName = null;
    	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    	tabIndex = RACKRATE_TAB;
    	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
    	// CSV事前処理を行う
    	List<String[]> pCsvfile = fileHand.processCsvFile(1);
    	
		if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
			return;
		}

System.debug(LoggingLevel.INFO, 'processLineData:::' + pCsvfile);
        // 処理結果情報を格納する
        //UploadResult result = new UploadResult();
        // リアルAGT設定情報有効性チェックを行う
        // Set<旅行会社 + "_" + 支店名 + "_" + 部屋タイプ名>
        Map<String, CsvItem> dupKeyChkMap = new Map<String, CsvItem>();
        List<CsvItem> dataList = new List<CsvItem>();
		//　Filed Nums
		Integer fieldNums = kmp.keySet().size();
        // CSV情報関連チェックを行う
        for (Integer i = 0; i < pCsvfile.size(); i++) {
            // CSV設定内容
            String[] line = pCsvfile[i];
            // 行目NO
            Integer csvLineNo = i + 2;
            // 項目数設定個数チェック
            if (line.size() < fieldNums) {
            	filehand.result.addMessage(String.valueOf(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0101);
            	continue;
            }
            String tierVal      = line[kmp.get(CSV_HD_TIERNAME)].trim();
            String shopVal      = line[kmp.get(CSV_HD_SHOPNAME)].trim();
            String roomTypeVal  = line[kmp.get(CSV_HD_ROOMTYPENAME)].trim();
            String peoplesVal   = line[kmp.get(CSV_HD_PEOPLES)].trim();
            String priceVal     = line[kmp.get(CSV_HD_PRICE)].trim();
            
            // 必須項目チェックを行う
            Boolean tierFlg     = filehand.strIsEmpty(tierVal,       csvLineNo, CSV_HD_TIERNAME);
            Boolean roomTypeFlg = filehand.strIsEmpty(roomTypeVal,   csvLineNo, CSV_HD_ROOMTYPENAME);
            Boolean peoplesFlg  = filehand.strIsEmpty(peoplesVal,    csvLineNo, CSV_HD_PEOPLES);
            Boolean priceFlg    = filehand.strIsEmpty(priceVal,      csvLineNo, CSV_HD_PRICE);
            // 必須項目は未入力存在する場合
            if (tierFlg || roomTypeFlg || peoplesFlg || priceFlg) {
                continue;
            }
            // 数値有効性チェック
            peoplesFlg          = filehand.isNumber(peoplesVal,      csvLineNo, CSV_HD_PEOPLES);
            priceFlg            = filehand.isNumber(priceVal,        csvLineNo, CSV_HD_PRICE);
            if (!peoplesFlg || !priceFlg) {
                continue;
            }
            // CSV情報を初期する
            CsvItem item = new CsvItem(line, csvLineNo);
            // ファイルに、キー重複存在チェック用
            String key = item.getSerachKey();
            if (dupKeyChkMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0150);
                continue;
            }
            dupKeyChkMap.put(key,item);
            dataList.add(item);
        }
        // エラーチェックエラーがあり場合
        if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
            return;
        }

        // 旅行会社情報を取得
        Set<String> roomTpNameSet = new Set<String>();
        Set<String> shopNameSet = new Set<String>();
        // CSVの最大日付と最小日付項目設定
        // 旅行会社、支店、部屋タイプ名情報を格納する
        for (CsvItem item : dataList) {
             roomTpNameSet.add(item.roomtypeName);
             shopNameSet.add(item.shopName);
        }
         // 支店関連の部屋タイプ情報を取得する
        List<TypeOfRooms__c> existTypeRooms = [select id, Name, ShopInfoRef__r.Name from TypeOfRooms__c where name in :roomTpNameSet And ShopInfoRef__r.Name in :shopNameSet];
        // Map<支店名_部屋タイプ名, 部屋タイプID>
        Map<String, Id> existRtpMap = new Map<String, Id>();
        for (TypeOfRooms__c tp : existTypeRooms) {
            String key = CommUtils.nullToBlank(tp.ShopInfoRef__r.Name) + '_' + tp.Name;
            existRtpMap.put(key , tp.Id);
        }
        // 料金表情報を格納する
        List<RackRateTable__c> validateLst = new List<RackRateTable__c>();
        // 汎用マスタへ反映を行う
        for (CsvItem item : dataList) {
            boolean okFlg = true;
            //　部屋タイプ存在チェック
            String key = item.shopName + '_' + item.roomtypeName;
            if (!existRtpMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107);
                okFlg = false;
            }
            if (!okFlg) continue;
            // 新規・更新用情報を格納する
            Id roomTypeId = existRtpMap.get(key);
            String serachKey = item.tierName + '_' + roomTypeId + '_' + item.peoples;
            RackRateTable__c newItem = new RackRateTable__c(
            //    RecordTypeId = REC_TYPEID_REALAGT
                SearchKey__c = serachKey
            ,   Tier__c = item.tierName
            ,   RoomTypeRel__c = roomTypeId
            ,   Persons__c = item.peoples
            ,   Price__c = item.price
            );
            validateLst.add(newItem);
        }
        // エラーチェックが存在する場合、処理中止、画面に戻る
		if (filehand.result.isHasErrMsg) { 
            // ファイルクリア処理を行う
            filehand.clear();
            return; 
		}

        try {
            // データは新規・更新を行う
            upsert validateLst RackRateTable__c.SearchKey__c;
            
            DateTime nowDt = System.now();
            String timestamp = nowDt.format('yyyyMMddHHmmssSSS');
            //String timestamp2 = nowDt.format('yyyy/MM/dd HH:mm:ss');
            // 2016/11/25 TIMEZON fix BEGIN by zh
            //String timestamp2 = nowDt.format(CommBaseCtrl.getDateTimeFormat());
            String timestamp2 = nowDt.format();
            // 2016/11/25 TIMEZON fix END by zh
            // CSVファイルをアップロードする
            Document newDoc = new Document(
            	DeveloperName = 'RackRate' + timestamp,
            	//ラックレートアップロード
            	Description = Label.CONST_003_0117+timestamp2,
            	FolderId = strDocFolderId,
            	//ラックレート_
            	Name = Label.CONST_003_0118 + timestamp,
            	ContentType = 'text/csv',
            	type = 'csv',
            	body = filehand.getFileBody()
            );
            insert newDoc;
            lastDoc = newDoc;
        } catch (Exception e) {
            filehand.result.addMessage(Label.ERR_9000 + '(' + e.getmessage() + ')');
        } finally {
            // ファイルクリア処理を行う
            filehand.clear();
        }
        
        if (filehand.result.isHasErrMsg) {
            return;
        } else {
        	// 成功結果は画面に戻って、設定を行う
        	//件
        	filehand.result.addInfoMessage(Label.MSG_9001 + '('+dataList.size()+ Label.CONST_003_0119 +')');
        }
        return;
    }

    public class CsvItem {
        public CsvItem(String[] line, Integer pLineNo) {
            tierName = line[kmp.get(CSV_HD_TIERNAME)].trim();
            shopName = CommUtils.nullToBlank(line[kmp.get(CSV_HD_SHOPNAME)]).trim();
            roomtypeName = line[kmp.get(CSV_HD_ROOMTYPENAME)].trim();
            peoples = CommUtils.nullToBlank(line[kmp.get(CSV_HD_PEOPLES)]).trim();
            price = Decimal.valueOf(line[kmp.get(CSV_HD_PRICE)].trim());
            lineNo = pLineNo;
        }
        public Integer lineNo{get;set;}
        public String tierName{get;set;}
        public String shopName{get;set;}
        public String roomtypeName{get;set;}
        public String peoples{get;set;}
        public Decimal price{get;set;}
        public String getSerachKey() {
        	return (
        			tierName + '_' +
        			shopName + '_' +
        			roomtypeName + '_' +
        			peoples + '_');

        }
    }
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    /**
    * CSV内容処理
    **/
    public void processCsvFilePlan() {
    	// 2017/02/23 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','ContentType','type','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/02/23 Field Security Check End by wx
    	// タブ順情報を格納する
    	tabIndex = RACKRATE_PLAN_TAB;
    	// CSV事前処理を行う
    	List<String[]> pCsvfile = fileHand.processCsvFile(1);
    	
		if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
			return;
		}

        // リアルAGT設定情報有効性チェックを行う
        // Set<旅行会社 + "_" + 支店名 + "_" + 部屋タイプ名>
        Map<String, CsvPlanItem> dupKeyChkMap = new Map<String, CsvPlanItem>();
        List<CsvPlanItem> dataList = new List<CsvPlanItem>();
		//　Filed Nums
		Integer fieldNums = pmp.keySet().size();
        // CSV情報関連チェックを行う
        for (Integer i = 0; i < pCsvfile.size(); i++) {
            // CSV設定内容
            String[] line = pCsvfile[i];
            // 行目NO
            Integer csvLineNo = i + 2;
            // 項目数設定個数チェック
            if (line.size() < fieldNums) {
            	// XXX行目:ファイル内容が不正です。
            	filehand.result.addMessage(String.valueOf(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0101);
            	continue;
            }
            String tierVal      = line[pmp.get(CSV_HD_TIERNAME)].trim();
            String roomTypeVal  = line[pmp.get(CSV_HD_ROOMTYPENAME)].trim();
            String basePlanVal  = line[pmp.get(CSV_HD_BASEPLAN)].trim();
            
            // 必須項目チェックを行う
            Boolean tierFlg     = filehand.strIsEmpty(tierVal,       csvLineNo, CSV_HD_TIERNAME);
            Boolean roomTypeFlg = filehand.strIsEmpty(roomTypeVal,   csvLineNo, CSV_HD_ROOMTYPENAME);
            Boolean basePlanFlg = filehand.strIsEmpty(basePlanVal,   csvLineNo, CSV_HD_BASEPLAN);
            //Boolean statusFlg   = filehand.strIsEmpty(statusVal,     csvLineNo, CSV_HD_STATUS);
            // 必須項目は未入力存在する場合
            if (tierFlg || roomTypeFlg || basePlanFlg) {
                continue;
            }
            // CSV情報を初期する
            CsvPlanItem item = new CsvPlanItem(line, csvLineNo);
            // ファイルに、キー重複存在チェック用
            String key = item.getSerachKey();
            if (dupKeyChkMap.containsKey(key)) {
            	// XXX行目:同一の店舗名+ラックレート名+人数+部屋タイプ名のレコードがファイルに重複存在します。
                filehand.result.addMessage(String.valueof(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0150_1);
                continue;
            }
            
            dupKeyChkMap.put(key,item);
            dataList.add(item);
        }
        // エラーチェックエラーがあり場合
        if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
            return;
        }

        // 旅行会社情報を取得
        Set<String> roomTpNameSet = new Set<String>();
        Set<String> shopNameSet = new Set<String>();
        // plan名检索条件
        set<String> planNameSet = new Set<String>();
        // CSVの最大日付と最小日付項目設定
        // 旅行会社、支店、部屋タイプ名情報を格納する
        for (CsvPlanItem item : dataList) {
             roomTpNameSet.add(item.roomtypeName);
             shopNameSet.add(item.shopName);
             planNameSet.add(item.basePlanName);
        }
         // 支店関連の部屋タイプ情報を取得する
        List<TypeOfRooms__c> existTypeRooms = [select id, Name, ShopInfoRef__r.Name from TypeOfRooms__c where name in :roomTpNameSet And ShopInfoRef__r.Name in :shopNameSet];
        // Map<支店名_部屋タイプ名, 部屋タイプID>
        Map<String, Id> existRtpMap = new Map<String, Id>();
        for (TypeOfRooms__c tp : existTypeRooms) {
            String key = CommUtils.nullToBlank(tp.ShopInfoRef__r.Name) + '_' + tp.Name;
            existRtpMap.put(key , tp.Id);
        }
        
        // baseplan
        List<Plan__c> existPlans = null;
        // 店舗別プランの場合
        if (CommConst.APPOTION_BI_SHOPPLAN_FLG) {
        	existPlans = [select id, Name, ShopInfoRef__r.Name from Plan__c where IsClosed__c != true And BasePlanFlg__c = true And name in :planNameSet and ShopInfoRef__r.Name in :shopNameSet];
        } else {
        	existPlans = [select id, Name, ShopInfoRef__r.Name from Plan__c where IsClosed__c != true And BasePlanFlg__c = true And name in :planNameSet];
        }
        // Map<支店名_プラン名, planId>
        Map<String, Id> existPBMap = new Map<String, Id>();
        for (Plan__c p : existPlans) {
        	String key = CommUtils.nullToBlank(p.ShopInfoRef__r.Name) + '_' + p.Name;
            existPBMap.put(key , p.Id);
        }
        
        // 料金表情報を格納する
        List<RackRateTable__c> validateLst = new List<RackRateTable__c>();
        // 汎用マスタへ反映を行う
        for (CsvPlanItem item : dataList) {
            boolean okFlg = true;
            //　部屋タイプ存在チェック
            String key = item.shopName + '_' + item.roomtypeName;
            if (!existRtpMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107);
                okFlg = false;
            }
            //　PLAN存在チェック
            String planKey = item.shopName + '_' + item.basePlanName;
            if (!existPBMap.containsKey(planKey)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107_1);
                okFlg = false;
            }
            if (!okFlg) continue;
            // 新規・更新用情報を格納する
            Id roomTypeId = existRtpMap.get(key);
            Id basePlanId = existPBMap.get(planKey);
            String serachKey = roomTypeId + '_' + basePlanId + '_' + item.tierName ;
            RackRateTable__c newItem = new RackRateTable__c(
                SearchKey__c = serachKey
            ,   Tier__c = item.tierName
            ,   RoomTypeRel__c = roomTypeId
            ,   BasePlanRef__c = basePlanId
            ,   SalesStatus__c =item.status
            );
            validateLst.add(newItem);
        }
        // エラーチェックが存在する場合、処理中止、画面に戻る
		if (filehand.result.isHasErrMsg) { 
            // ファイルクリア処理を行う
            filehand.clear();
            return; 
		}

        try {
            // データは新規・更新を行う
            upsert validateLst RackRateTable__c.SearchKey__c;
            
            DateTime nowDt = System.now();
            String timestamp = nowDt.format('yyyyMMddHHmmssSSS');
            // 2016/11/25 TIMEZON fix BEGIN by zh
            String timestamp2 = nowDt.format();
            // 2016/11/25 TIMEZON fix END by zh
            // CSVファイルをアップロードする
            Document newDoc = new Document(
            	/* DOTO:插入的document的文件名字需要变更 */
            	DeveloperName = 'RackRatePlan' + timestamp,
            	//ラックレートアップロード
            	Description = Label.CONST_003_0117+timestamp2,
            	FolderId = strDocFolderId,
            	//ラックレート_
            	Name = Label.CONST_003_0118_1 + timestamp,
            	ContentType = 'text/csv',
            	type = 'csv',
            	body = filehand.getFileBody()
            );
            insert newDoc;
            lastPlanDoc = newDoc;
        } catch (Exception e) {
        	// 処理異常が発生しました。詳細はシステム管理者にお問い合わせください。
            filehand.result.addMessage(Label.ERR_9000 + '(' + e.getmessage() + ')');
        } finally {
            // ファイルクリア処理を行う
            filehand.clear();
        }
        
        if (filehand.result.isHasErrMsg) {
            return;
        } else {
        	// 成功結果は画面に戻って、設定を行う
        	//件
        	// 処理が終了しました。 (XX件)
        	filehand.result.addInfoMessage(Label.MSG_9001 + '('+dataList.size()+ Label.CONST_003_0119 +')');
        }
        return;
    }
    // 販売状態が販売中止で設定する場合
    private static final String STATUS_SALE_STOP = '止';
    public class CsvPlanItem {
        public CsvPlanItem(String[] line, Integer pLineNo) {
            tierName = CommUtils.nullToBlank(line[pmp.get(CSV_HD_TIERNAME)]);
            shopName = CommUtils.nullToBlank(line[pmp.get(CSV_HD_SHOPNAME)]).trim();
            roomtypeName = CommUtils.nullToBlank(line[pmp.get(CSV_HD_ROOMTYPENAME)]);
            basePlanName = CommUtils.nullToBlank(line[pmp.get(CSV_HD_BASEPLAN)]);
            status = CommUtils.nullToBlank(line[pmp.get(CSV_HD_STATUS)]) == STATUS_SALE_STOP ? CommConst.STOCK_SET_STOP : CommConst.STOCK_SET_SALE;
            lineNo = pLineNo;
        }
        public Integer lineNo{get;set;}
        public String tierName{get;set;}
        public String shopName{get;set;}
        public String roomtypeName{get;set;}
        public String basePlanName{get;set;}
        public String status{get;set;}
        public String getSerachKey() {
        	return (
        			roomtypeName + '_' +
        			basePlanName + '_' +
        			shopName + '_' +
        			tierName + '_'
        			);
        }
    }
    // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
    /**
    * CSV内容処理
    **/
    public void processCsvFilePlanTier() {
    	// Field Security Check
		List<String> insChkFields = new List<String>{'Description','FolderId','Name','ContentType','type','body','DeveloperName'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Document.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
    	// タブ順情報を格納する
    	tabIndex = RACKRATE_PLAN_TIER_TAB;
    	// CSV事前処理を行う
    	List<String[]> pCsvfile = fileHand.processCsvFile(1);
    	
		if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
			return;
		}

        // リアルAGT設定情報有効性チェックを行う
        // Set<旅行会社 + "_" + 支店名 + "_" + 部屋タイプ名>
        Map<String, CsvPlanTierItem> dupKeyChkMap = new Map<String, CsvPlanTierItem>();
        List<CsvPlanTierItem> dataList = new List<CsvPlanTierItem>();
		//　Filed Nums
		Integer fieldNums = tmp.keySet().size();
        // CSV情報関連チェックを行う
        for (Integer i = 0; i < pCsvfile.size(); i++) {
            // CSV設定内容
            String[] line = pCsvfile[i];
            // 行目NO
            Integer csvLineNo = i + 2;
            // 項目数設定個数チェック
            if (line.size() < fieldNums) {
            	// XXX行目:ファイル内容が不正です。
            	filehand.result.addMessage(String.valueOf(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0101);
            	continue;
            }
            String tierVal      = line[tmp.get(CSV_HD_TIERNAME)].trim();
            String shopVal      = line[tmp.get(CSV_HD_SHOPNAME)].trim();
            String roomTypeVal  = line[tmp.get(CSV_HD_ROOMTYPENAME)].trim();
            String peoplesVal   = line[tmp.get(CSV_HD_PEOPLES)].trim();
            String priceVal     = line[tmp.get(CSV_HD_PRICE)].trim();
            String basePlanVal  = line[tmp.get(CSV_HD_PLAN)].trim();
            
            
            // 必須項目チェックを行う
            Boolean tierFlg     = filehand.strIsEmpty(tierVal,       csvLineNo, CSV_HD_TIERNAME);
            Boolean roomTypeFlg = filehand.strIsEmpty(roomTypeVal,   csvLineNo, CSV_HD_ROOMTYPENAME);
            Boolean basePlanFlg = filehand.strIsEmpty(basePlanVal,   csvLineNo, CSV_HD_PLAN);
            Boolean peoplesFlg  = filehand.strIsEmpty(peoplesVal,    csvLineNo, CSV_HD_PEOPLES);
            Boolean priceFlg    = filehand.strIsEmpty(priceVal,      csvLineNo, CSV_HD_PRICE);
            // 必須項目は未入力存在する場合
            if (tierFlg || roomTypeFlg || peoplesFlg || priceFlg || basePlanFlg) {
                continue;
            }
            // CSV情報を初期する
            CsvPlanTierItem item = new CsvPlanTierItem(line, csvLineNo);
            // ファイルに、キー重複存在チェック用
            String key = item.getSerachKey();
            if (dupKeyChkMap.containsKey(key)) {
            	// TODO:重复checkmessage调整
            	// XXX行目:同一の店舗名+ラックレート名+人数+部屋タイプ名のレコードがファイルに重複存在します。
                filehand.result.addMessage(String.valueof(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0150_1);
                continue;
            }
            
            dupKeyChkMap.put(key,item);
            dataList.add(item);
        }
        // エラーチェックエラーがあり場合
        if (filehand.result.isHasErrMsg) {
            // ファイルクリア処理を行う
            filehand.clear();
            return;
        }

        // 旅行会社情報を取得
        Set<String> roomTpNameSet = new Set<String>();
        Set<String> shopNameSet = new Set<String>();
        // plan名检索条件
        set<String> planNameSet = new Set<String>();
        // CSVの最大日付と最小日付項目設定
        // 旅行会社、支店、部屋タイプ名情報を格納する
        for (CsvPlanTierItem item : dataList) {
             roomTpNameSet.add(item.roomtypeName);
             shopNameSet.add(item.shopName);
             planNameSet.add(item.basePlanName);
        }
         // 支店関連の部屋タイプ情報を取得する
        List<TypeOfRooms__c> existTypeRooms = [select id, Name, ShopInfoRef__r.Name from TypeOfRooms__c where name in :roomTpNameSet And ShopInfoRef__r.Name in :shopNameSet];
        // Map<支店名_部屋タイプ名, 部屋タイプID>
        Map<String, Id> existRtpMap = new Map<String, Id>();
        for (TypeOfRooms__c tp : existTypeRooms) {
            String key = CommUtils.nullToBlank(tp.ShopInfoRef__r.Name) + '_' + tp.Name;
            existRtpMap.put(key , tp.Id);
        }
        
        // baseplan
        List<Plan__c> existPlans = null;
        // 店舗別プランの場合
        if (CommConst.APPOTION_BI_SHOPPLAN_FLG) {
        	existPlans = [select id, Name, ShopInfoRef__r.Name from Plan__c where IsClosed__c != true And BasePlanFlg__c = true And name in :planNameSet and ShopInfoRef__r.Name in :shopNameSet];
        } else {
        	existPlans = [select id, Name, ShopInfoRef__r.Name from Plan__c where IsClosed__c != true And BasePlanFlg__c = true And name in :planNameSet];
        }
        // Map<支店名_プラン名, planId>
        Map<String, Id> existPBMap = new Map<String, Id>();
        for (Plan__c p : existPlans) {
        	String key = CommUtils.nullToBlank(p.ShopInfoRef__r.Name) + '_' + p.Name;
            existPBMap.put(key , p.Id);
        }
        
        // 料金表情報を格納する
        List<RackRateTable__c> validateLst = new List<RackRateTable__c>();
        // 汎用マスタへ反映を行う
        for (CsvPlanTierItem item : dataList) {
            boolean okFlg = true;
            //　部屋タイプ存在チェック
            String key = item.shopName + '_' + item.roomtypeName;
            if (!existRtpMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107);
                okFlg = false;
            }
            //　PLAN存在チェック
            // TODO:数据重复check，需要重新处理
            String planKey = item.shopName + '_' + item.basePlanName;
            if (!existPBMap.containsKey(planKey)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107_1);
                okFlg = false;
            }
            if (!okFlg) continue;
            // 新規・更新用情報を格納する
            Id roomTypeId = existRtpMap.get(key);
            Id basePlanId = existPBMap.get(planKey);
            String serachKey = item.tierName + '_' + roomTypeId + '_' + item.peoples + '_' + basePlanId ;
            RackRateTable__c newItem = new RackRateTable__c(
                SearchKey__c = serachKey
            ,   Tier__c = item.tierName
            ,   RoomTypeRel__c = roomTypeId
            ,   Persons__c = item.peoples
            ,   Price__c = item.price
            ,   BasePlanRef__c = basePlanId
            );
            validateLst.add(newItem);
        }
        // エラーチェックが存在する場合、処理中止、画面に戻る
		if (filehand.result.isHasErrMsg) { 
            // ファイルクリア処理を行う
            filehand.clear();
            return; 
		}

        try {
            // データは新規・更新を行う
            upsert validateLst RackRateTable__c.SearchKey__c;
            
            DateTime nowDt = System.now();
            String timestamp = nowDt.format('yyyyMMddHHmmssSSS');
            String timestamp2 = nowDt.format();
            // CSVファイルをアップロードする
            Document newDoc = new Document(
            	/* DOTO:插入的document的文件名字需要变更 */
            	DeveloperName = 'RackRatePlan' + timestamp,
            	//ラックレートアップロード
            	Description = Label.CONST_003_0117+timestamp2,
            	FolderId = strDocFolderId,
            	//ラックレート_
            	Name = Label.CONST_003_0118_2 + timestamp,
            	ContentType = 'text/csv',
            	type = 'csv',
            	body = filehand.getFileBody()
            );
            insert newDoc;
            lastBasePlanDoc = newDoc;
        } catch (Exception e) {
        	// 処理異常が発生しました。詳細はシステム管理者にお問い合わせください。
            filehand.result.addMessage(Label.ERR_9000 + '(' + e.getmessage() + ')');
        } finally {
            // ファイルクリア処理を行う
            filehand.clear();
        }
        
        if (filehand.result.isHasErrMsg) {
            return;
        } else {
        	// 成功結果は画面に戻って、設定を行う
        	//件
        	// 処理が終了しました。 (XX件)
        	filehand.result.addInfoMessage(Label.MSG_9001 + '('+dataList.size()+ Label.CONST_003_0119 +')');
        }
        return;
    }
    public class CsvPlanTierItem {
        public CsvPlanTierItem(String[] line, Integer pLineNo) {
            tierName = line[tmp.get(CSV_HD_TIERNAME)].trim();
            shopName = CommUtils.nullToBlank(line[tmp.get(CSV_HD_SHOPNAME)]).trim();
            roomtypeName = line[tmp.get(CSV_HD_ROOMTYPENAME)].trim();
            peoples = CommUtils.nullToBlank(line[tmp.get(CSV_HD_PEOPLES)]).trim();
            price = Decimal.valueOf(line[tmp.get(CSV_HD_PRICE)].trim());
            basePlanName = CommUtils.nullToBlank(line[tmp.get(CSV_HD_PLAN)]);
            lineNo = pLineNo;
        }
        public Integer lineNo{get;set;}
        public String tierName{get;set;}
        public String shopName{get;set;}
        public String roomtypeName{get;set;}
        public String peoples{get;set;}
        public Decimal price{get;set;}
        public String basePlanName{get;set;}
        public String getSerachKey() {
        	return (
        			tierName + '_' +
        			shopName + '_' +
        			roomtypeName + '_' +
        			basePlanName + '_' +
        			peoples + '_');
        }
    }
    // 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
}