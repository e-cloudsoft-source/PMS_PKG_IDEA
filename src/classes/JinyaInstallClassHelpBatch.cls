// 2019/09/19 Security Check BY zyz BEGIN
global with sharing class JinyaInstallClassHelpBatch implements Database.Batchable<String>, Schedulable {
// 2019/09/19 Security Check BY zyz END
    global JinyaInstallClassHelpBatch () {}
	public void execute(SchedulableContext SC) {
		JinyaInstallClassHelpBatch batch = new JinyaInstallClassHelpBatch();
		DataBase.executeBatch(batch);
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
    public Iterable<String> start(Database.BatchableContext info){
    	// 2019/09/19 Security Check BY WSQ BEGIN
    	//return [select name,DeveloperName,body from Document where folder.DeveloperName = 'CsvTemplate' and DeveloperName = 'ExpoAreaMst2019'];
    	return ExpoNoAuthHelp.geAreaCsvInfo();
    	// 2019/09/19 Security Check BY WSQ END
    }
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<String> scope){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'name'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.ExpoAreaMst__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// AREAマスタ情報を取得する
		// 2019/09/19 Security Check BY WSQ BEGIN
		//String fileBody = scope[0].body.tostring();
		String fileBody = scope[0];
		// 2019/09/19 Security Check BY WSQ END
		if (CommUtils.isBlank(fileBody)) return;
		
    	// Name/AREAコード/都道府県コード/市区町村名コード/市区町村名（漢字）/所属市
    	String POS_AREACODE_TILTE = 'AREAコード';
    	String POS_STATECODE_TITLE = '都道府県コード';
    	String POS_CITYCODE_TITLE = '団体コード(市区町村コード)';
    	String POS_CITYNAME_TITLE = '市区町村名（漢字）';
    	String POS_CTIYALL_TITLE = '区所属都市';
    	map<String,Integer> fieldPosMap = new map<String, Integer>{
    		POS_AREACODE_TILTE => 0,//地域
    		POS_STATECODE_TITLE => 2,//都道府県
			POS_CITYCODE_TITLE => 1,//市区郡コード
			POS_CITYNAME_TITLE => 5,//市区郡名
			POS_CTIYALL_TITLE => 4//市区郡すべて
    	};
    	
		// CSVファイルをPARSE処理する
		String[] csvLines = fileBody.split('\n');
		if (csvLines.size() < 2) return;

		// 1行目はCSVのタイトルキー
		String headerStr = csvLines[0];
		String[] headerArr = headerStr.split(',');
		for (Integer i = 0; i < headerArr.size(); i++) {
			if (fieldPosMap.containsKey(headerArr[i])) fieldPosMap.put(headerArr[i], i);
		}
		List<ExpoAreaMst__c> mstLst = new List<ExpoAreaMst__c>();
		for (integer i =1; i < csvLines.size(); i++) {
			// 処理対象なし場合
			if (CommUtils.isBlank(csvLines[i])) break;
			String[] csvArr = csvLines[i].split(',');
			ExpoAreaMst__c mst = new ExpoAreaMst__c(
				AreaLst__c = CommUtils.nullToBlank(csvArr[fieldPosMap.get(POS_AREACODE_TILTE)]),
				StateLst__c = CommUtils.nullToBlank(csvArr[fieldPosMap.get(POS_STATECODE_TITLE)]),
				CityCode__c = CommUtils.nullToBlank(csvArr[fieldPosMap.get(POS_CITYCODE_TITLE)]),
				City__c = CommUtils.nullToBlank(csvArr[fieldPosMap.get(POS_CITYNAME_TITLE)]),
				CityAll__c = CommUtils.nullToBlank(csvArr[fieldPosMap.get(POS_CTIYALL_TITLE)])
			);
			// KEYを設定する
			mst.Name = mst.AreaLst__c + '_' + mst.StateLst__c + '_' + mst.CityCode__c;
			mstLst.add(mst);
		}
		if (!mstLst.isEmpty()) {
			database.upsert(mstLst,ExpoAreaMst__c.Name);
		}
	}
	
	public void finish(Database.BatchableContext BC){}
}