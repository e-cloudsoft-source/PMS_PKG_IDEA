/**
* マスタ設定情報のアップロード処理クラス
* Ver0.1 リアルAGTのCSV設定ファイルのアップロード
* Ver0.2 リアル先の取得方式対応
**/
public with sharing class FileUploadImpForRealAGT {

    // CSV HEADER MATCH
    private static final String CSV_HD_TRAVEL = '旅行会社名';
    private static final String CSV_HD_SHOPNAME = '店舗名';
    private static final String CSV_HD_ROOMTYPENAME = '部屋タイプ名';
    private static final String CSV_HD_STARTDATE = '開始日付';      // (YYYY/MM/DD)
    private static final String CSV_HD_ENDDATE = '終了日付';            // (YYYY/MM/DD)
    private static final String CSV_HD_ROOMS = '提供数';
    
    private static final Map<String,Integer> kmp = new Map<String, Integer>{
                                                        CSV_HD_TRAVEL => 0,
                                                        CSV_HD_SHOPNAME => 1,
                                                        CSV_HD_ROOMTYPENAME => 2,
                                                        CSV_HD_STARTDATE => 3,
                                                        CSV_HD_ENDDATE => 4,
                                                        CSV_HD_ROOMS => 5 
                                                    };
                                                 
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
    /**
    * クラス初期化
    **/
    //private FileUploadImp filehand;
    public FileUploadImpForRealAGT() {
		List<Document> sr = [select body, name from Document where DeveloperName = 'RealAgtTemplate'];
		strTemplateId = sr[0].Id;
		List<Folder> fs = [select id from Folder where DeveloperName = 'RealAgtHistory'];
		strDocFolderId = fs[0].Id;
		// 最終回作成したリアルAGTのCSVファイル
		List<Document> lastNew = [select id,Name,CreatedDate from Document where FolderId = :strDocFolderId Order By Name desc limit 1];
		if (!lastNew.isEmpty()) {
			lastDoc = lastNew[0];
		}
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
		// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'EndDate__c','StartDate__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.RealAGT__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
    	//strCsvDocumentId = strCsvFileName = null;
    	
    	// CSV事前処理を行う
    	List<String[]> pCsvfile = fileHand.processCsvFile();
    	
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
            String traveVal     = line[kmp.get(CSV_HD_TRAVEL)].trim();
            String shopVal      = line[kmp.get(CSV_HD_SHOPNAME)].trim();
            String roomTypeVal  = line[kmp.get(CSV_HD_ROOMTYPENAME)].trim();
            String startDtVal   = line[kmp.get(CSV_HD_STARTDATE)].trim();
            String endDtVal     = line[kmp.get(CSV_HD_ENDDATE)].trim();
            String roomsVal     = line[kmp.get(CSV_HD_ROOMS)].trim();
            
            // 必須項目チェックを行う
            Boolean travelFlg   = filehand.strIsEmpty(traveVal,      csvLineNo, CSV_HD_TRAVEL);
            Boolean roomTypeFlg = filehand.strIsEmpty(roomTypeVal,   csvLineNo, CSV_HD_ROOMTYPENAME);
            Boolean startFlg    = filehand.strIsEmpty(startDtVal,    csvLineNo, CSV_HD_STARTDATE);
            Boolean enddateFlg  = filehand.strIsEmpty(endDtVal,      csvLineNo, CSV_HD_ENDDATE);
            Boolean roomsFlg    = filehand.strIsEmpty(roomsVal,      csvLineNo, CSV_HD_ROOMS);
            // 必須項目は未入力存在する場合
            if (travelFlg || roomTypeFlg || startFlg || enddateFlg || roomsFlg) {
                continue;
            }
            // 日付有効性チェック
            startFlg            = filehand.isValidate(startDtVal,    csvLineNo, CSV_HD_STARTDATE);
            enddateFlg          = filehand.isValidate(endDtVal,      csvLineNo, CSV_HD_ENDDATE);
            if (!startFlg || !enddateFlg) {
                continue;
            }
            // 2016.08.08 他地域の日付レイアウト対応
            // 期間範囲順チエック
            //if (startDtVal > endDtVal) {
        	Date startDt = CommUtils.stringToDate(startDtVal);
        	Date endDt = CommUtils.stringToDate(endDtVal);
        	if (startDt > endDt) {
            	filehand.result.addMessage(String.valueof(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0108);
            	continue;
            }
            // 数値有効性チェック
            roomsFlg            = filehand.isNumber(roomsVal,        csvLineNo, CSV_HD_ROOMS);
            if (!roomsFlg) {
                continue;
            }
            // ファイルに、キー重複存在チェック用
            String key = line[kmp.get(CSV_HD_TRAVEL)] + '_'
                        +line[kmp.get(CSV_HD_SHOPNAME)] + '_'
                        +line[kmp.get(CSV_HD_ROOMTYPENAME)];
            if (dupKeyChkMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(csvLineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0105);
                continue;
            }
            CsvItem item = new CsvItem(line, csvLineNo);
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
        Set<String> travelNameSet  = new Set<String>();
        Set<String> roomTpNameSet = new Set<String>();
        Set<String> shopNameSet = new Set<String>();
        // CSVの最大日付と最小日付項目設定
        Date minDate = null;
        Date maxDate = null;
        // 旅行会社、支店、部屋タイプ名情報を格納する
        for (CsvItem item : dataList) {
//System.debug(LoggingLevel.INFO, 'CsvItem::::' + item);
             travelNameSet.add(item.travelName);
             roomTpNameSet.add(item.roomtypeName);
             shopNameSet.add(item.shopName);
             
             minDate = (minDate == null ? item.startDate : (minDate > item.startDate ? item.startDate : minDate) );
             maxDate = (maxDate == null ? item.endDate   : (maxDate < item.endDate 	? item.endDate 	  : maxDate) );
        }
         // 支店関連の部屋タイプ情報を取得する
        List<Account> existAccLst = [select id, Name,SalesOfficeCompanyType__c from Account where Name = :travelNameSet And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL];
        List<TypeOfRooms__c> existTypeRooms = [select id, Name, ShopInfoRef__r.Name from TypeOfRooms__c where name in :roomTpNameSet And ShopInfoRef__r.Name in :shopNameSet];
        Map<String, Account> existAccMap = new Map<String, Account>();
        Map<String, Id> existRtpMap = new Map<String, Id>();
        for (Account acc : existAccLst) {
        	if (existAccMap.containsKey(acc.Name)) {
        		// 重複名前の取引先情報が存在
        		Account orgAccount = existAccMap.get(acc.Name);
        		// 新取引先の旅行会社分類を設定されている場合、上書する
        		if (!CommUtils.isBlank(orgAccount.SalesOfficeCompanyType__c) &&
        			CommUtils.isBlank(acc.SalesOfficeCompanyType__c)) {
        				continue;
        		}
        	}
            existAccMap.put(acc.Name, acc);
        }
        for (TypeOfRooms__c tp : existTypeRooms) {
            String key = CommUtils.nullToBlank(tp.ShopInfoRef__r.Name) + '_' + tp.Name;
            existRtpMap.put(key , tp.Id);
        }
        Map<String, List<RealAGT__c>> existAgtMap = new Map<String, List<RealAGT__c>>();
        set<Id> accIdsSet = new Set<Id>();
        for (Account acc : existAccMap.values()) { accIdsSet.add(acc.Id); }
//System.debug(loggingLevel.INFO, 'minDate::' + minDate);
//System.debug(loggingLevel.INFO, 'maxDate::' + maxDate);
        // 期間反映内の既に存在しているリアルAGT設定情報を取得する
        for (RealAGT__c agt : [select id, AccountRef__c, RoomTypeRel__c, AgtMaxRooms__c, StartDate__c, EndDate__c,SearchKey__c
        		from RealAGT__c 
        		where AccountRef__c in :accIdsSet And RoomTypeRel__c in :existRtpMap.values()
        			And (StartDate__c <= :maxDate And EndDate__c >= :minDate) Order By StartDate__c]) {
        	String key = getSearchKey(agt.AccountRef__c, agt.RoomTypeRel__c);
        	if (!existAgtMap.containsKey(key))	existAgtMap.put(key, new List<RealAGT__c>());
        	existAgtMap.get(key).add(agt);
        }
//System.debug(loggingLevel.INFO, 'existAgtMap::' + existAgtMap);
        // リアルAGT情報を格納する
        List<RealAGT__c> validateLst = new List<RealAGT__c>();
        // 汎用マスタへ反映を行う
        for (CsvItem item : dataList) {
            boolean okFlg = true;
            if (!existAccMap.containsKey(item.travelName)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0106);
                okFlg = false;
            }
            String key = item.shopName + '_' + item.roomtypeName;
            if (!existRtpMap.containsKey(key)) {
                filehand.result.addMessage(String.valueof(item.lineNo).leftPad(5) + Label.ERR_0100 + Label.ERR_0107);
                okFlg = false;
            }
            if (!okFlg) continue;
//System.debug(loggingLevel.INFO, 'item::' + item);
            // 新規・更新用情報を格納する
            Id accId = existAccMap.get(item.travelName).Id;
            Id roomTypeId = existRtpMap.get(key);
            String serachKey = getSearchKey(accId, roomTypeId);//accId + '_' + roomTypeId;
            RealAGT__c newItem = new RealAGT__c(
            //    RecordTypeId = REC_TYPEID_REALAGT
                SearchKey__c = serachKey
            ,   AccountRef__c = accId
            ,   RoomTypeRel__c = roomTypeId
            ,   AgtMaxRooms__c = item.rooms
            ,   StartDate__c = item.startDate
            ,   EndDate__c = item.endDate
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
        	List<RealAGT__c> upsertLst = new List<RealAGT__c>();
        	List<RealAGT__c> deleteLst = new List<RealAGT__c>();
        	// 有効なCSVデータ
        	for (RealAGT__c agt : validateLst) {
//System.debug(loggingLevel.INFO, 'agt::::' + agt);
        		upsertLst.add(agt);
        		// 既存の設定情報
        		if (existAgtMap.containsKey(agt.SearchKey__c)) {
        			List<RealAGT__c> subLst = existAgtMap.get(agt.SearchKey__c);
        			//　期間は
        			for (RealAGT__c subAgt : subLst) {
        				// 期間重なる場合
        				if (agt.StartDate__c <= subAgt.EndDate__c && agt.EndDate__c >= subAgt.StartDate__c ) {
//System.debug(loggingLevel.INFO, '-----------[subAgt]--------' + subAgt);
        					//-------A--------B
        					//---A1----B1
        					if (agt.StartDate__c <= subAgt.StartDate__c && agt.EndDate__c >= subAgt.StartDate__c) {
//System.debug(loggingLevel.INFO, '---- STEP1 ----');
        						subAgt.StartDate__c = agt.EndDate__c.addDays(1);
        						if (subAgt.StartDate__c <= subAgt.EndDate__c) {
        							upsertLst.add(subAgt);
        						} else {
        							deleteLst.add(subAgt);
        						}
        					}
        					//-------A--------B
        					//--------A1----B1----
        					else if (agt.StartDate__c >= subAgt.StartDate__c && agt.EndDate__c <= subAgt.EndDate__c) {
//System.debug(loggingLevel.INFO, '---- STEP2 ----');
        						// CLONE
        						RealAGT__c cloneItem = subAgt.clone(false, true);
        						cloneItem.StartDate__c = agt.EndDate__c.addDays(1);
        						// ORG
								subAgt.EndDate__c = agt.StartDate__c.addDays(-1);
								
								if (subAgt.StartDate__c <= subAgt.EndDate__c) {
									upsertLst.add(subAgt);
								} else {
									deleteLst.add(subAgt);
								}
								if (cloneItem.StartDate__c <= cloneItem.EndDate__c) {
									upsertLst.add(cloneItem);
								}
        					}
        					//-------A--------B
        					//-------------A1----B1----
        					else if (agt.StartDate__c >= subAgt.StartDate__c && agt.EndDate__c >= subAgt.EndDate__c) {
//System.debug(loggingLevel.INFO, '---- STEP3 ----');
        						// CLONE
        						//RealAGT__c cloneItem = subAgt.clone(false, true);
        						//cloneItem.StartDate__c = agt.EndDate__c.addDays(1);
        						// ORG
								subAgt.EndDate__c = agt.StartDate__c.addDays(-1);
								if (subAgt.StartDate__c <= subAgt.EndDate__c) {
									upsertLst.add(subAgt);
								} else {
									deleteLst.add(subAgt);
								}
        					}
        				}
        				
        				
        			}
        		}
        	}
            // データは新規・更新を行う
            // 2018/03/07 Security Check BEGIN
            if (!CommSecurityUtils.isDeleteable(RealAGT__c.getSObjectType())) {
            	return;
            }
            // 2018/03/07 Security Check END
            delete deleteLst;
            upsert upsertLst;
            
            DateTime nowDt = System.now();
            String timestamp = nowDt.format('yyyyMMddHHmmssSSS');
            //String timestamp2 = nowDt.format('yyyy/MM/dd HH:mm:ss');
            // 2016/11/25 TIMEZON fix BEGIN by zh
            //String timestamp2 = nowDt.format(CommBaseCtrl.getDateTimeFormat());
            String timestamp2 = nowDt.format();
            // 2016/11/25 TIMEZON fix END by zh
            // CSVファイルをアップロードする
            Document newDoc = new Document(
            	DeveloperName = 'RealAgt' + timestamp,
            	//リアルAGTアップロード
            	Description = Label.CONST_014_0020 +timestamp2,
            	FolderId = strDocFolderId,
            	//リアルAGT_
            	Name = Label.CONST_014_0021 + timestamp,
            	ContentType = 'text/csv',
            	type = 'csv',
            	body = filehand.getFileBody()
            );
            insert newDoc;
            lastDoc = newDoc;
            //strCsvDocumentId = newDoc.Id;
            //strCsvFileName  = newDoc.Name;

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
        	filehand.result.addInfoMessage(Label.MSG_9001 + '('+dataList.size()+ Label.CONST_014_0022 +')');
        }
        return;
    }

	private String getSearchKey(Id accId, Id roomTypeId) {
		return CommUtils.nullToBlank(accId) + '_' + CommUtils.nullToBlank(roomTypeId);
	}

    public class CsvItem {
        public CsvItem(String[] line, Integer pLineNo) {
            travelName = line[kmp.get(CSV_HD_TRAVEL)];
            shopName = CommUtils.nullToBlank(line[kmp.get(CSV_HD_SHOPNAME)]);
            roomtypeName = line[kmp.get(CSV_HD_ROOMTYPENAME)];
            //startDate = Date.parse(line[kmp.get(CSV_HD_STARTDATE)]);
            startDate = CommUtils.stringToDate(line[kmp.get(CSV_HD_STARTDATE)]);
            //endDate = Date.parse(line[kmp.get(CSV_HD_ENDDATE)]);
            endDate = CommUtils.stringToDate(line[kmp.get(CSV_HD_ENDDATE)]);
            rooms = Decimal.valueOf(line[kmp.get(CSV_HD_ROOMS)].trim());
            lineNo = pLineNo;
        }
        public Integer lineNo{get;set;}
        public String travelName{get;set;}
        public String shopName{get;set;}
        public String roomtypeName{get;set;}
        public Date startDate{get;set;}
        public Date endDate{get;set;}
        public Decimal rooms{get;set;}
    }
}