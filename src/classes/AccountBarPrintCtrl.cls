public with sharing class AccountBarPrintCtrl {
	private static String defGroupApi = 'nextitemcode__c';
	private static final String RELATION_KEY = '__r.';
	// 画面に表示項目のAPIを定義する、!!!必ず小文字に設定する!!!
	private static Set<String> defAccMasterApiSet = new Set<String>{'id','field3__c','name','field5__c','field7__c','field4__c','gpchange__c'};
	private static Map<String,String> defApiMap = new Map<String,String>{'field3__c' => '130px','field5__c' => '80px;','field7__c' => '80px;','field4__c' => '150px;','gpchange__c' => '150px;'};
	private static Map<String, Schema.DescribeFieldResult> getAllFieldLst{get{ return CommSqlUtils.getAllFieldLst(AccountMaster__c.sObjectType,false,true);}} // 获取AccountMaster__c所有字段信息
	public static String colnumJson{get; private set;}      // 列
	public static String colnumGroupJson{get; private set;} // 分组Field
	public String curPos{get;set;}
	// init class
	public AccountBarPrintCtrl(ApexPages.StandardSetController controller) {
		
	}
	// 初始化页面读取
	public void init(){
		getColnumJson(); // 获取colnumjson
    	getColnumGroupJson(defGroupApi); // 获取groupjson
	}
	@remoteAction
	public static List<Map<String,Object>> getViewInfo() {
		List<String> notInActLst = new List<String>{CommConst.PROD_ACTION_TYPE_NO,CommConst.PROD_ACTION_TYPE_AR,CommConst.PROD_ACTION_TYPE_PY};
    	String queryStr = getQuerySQL();
		queryStr += ' From AccountMaster__c where ActionType__c != :notInActLst and field3__c != null ' ;
		queryStr += ' order by ' + CommConst.PROD_SORT_KEY;
		Map<String,Decimal> prMap = new Map<String,Decimal>();
		for (PrintInfo__c pr : [select id,AccountMasterRef__c,PrintCnt__c from PrintInfo__c]) {
			prMap.put(pr.AccountMasterRef__c,pr.PrintCnt__c);
		}
		List<Map<String,Object>> resultLst = new List<Map<String,Object>>();
		List<AccountMaster__c> accs = DataBase.query(queryStr );
		for (AccountMaster__c acc : accs){
			Map<String,Object> objMap = new Map<String,Object>();
			for(String api : defAccMasterApiSet){
				objMap.put(getObjApiKey(api, false),getValueByApi(acc, api));
			}
			objMap.put('printcnt',CommUtils.nullToIntZero(prMap.get(acc.id)));
			resultLst.add(objMap);
		}
		return resultLst;
		
	}
	private static String getQuerySQL(){
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst;// 获取AccountMaster__c所有字段信息
    	String queryStr = ' Select '; // queryStr
		for(String api : defAccMasterApiSet.clone()){ // 防止地址共存
			if(!modelDeafaultValuesMaps.containsKey(api)) continue; // 去掉无效字段
    		Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(api); // 获取当前字段所以信息
    		if(dr.getType() == Schema.DisplayType.REFERENCE){
    			defAccMasterApiSet.remove(api); // 去掉参照字段
    			api = getObjApiKey(api, true);
    			defAccMasterApiSet.add(api); // 追加参照字段的Nmae
    		}
			queryStr += api + ',';
		}
		queryStr = queryStr.removeEnd(',');
		return queryStr;
	}
	@remoteaction 
	public static String getPrintInfo(String req) {
		ReqJson request = (ReqJson)JSON.deserialize(req,ReqJson.class);
		// 2018/07/26 QRコード印刷対応 by zy BEGIN
		// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
		// String printInfo = CommUtils.nullToBlank(OrderServiceHelp.getPrintInfoByProdId(request.pid,request.ip));
		// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
		String printInfo = CommUtils.nullToBlank(OrderServiceHelp.getPrintInfoByProdId(request.pid,request.ip,request.ptype));
		// 2018/07/26 QRコード印刷対応 by zy END
		return printInfo;
	}
	@remoteaction
	public static OrderServiceHelp.PrintInfo getPrintByIp(String req){
		ReqJson request = (ReqJson)JSON.deserialize(req,ReqJson.class);
		if (!CommUtils.isBlank(request.pos)) return OrderServiceHelp.getPrintByPosName(request.pos);
		if (!CommUtils.isBlank(request.ip)) return OrderServiceHelp.getPrintByIp(request.ip);
		return null;
	}
	@remoteaction 
	public static string savePrintLodToDb(String msg){
		String curLog = system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************会計BARCODE印刷BEGIN********************\n';
		User u = UserUtil.CurrentUser;
		curLog += 'ユーザ：' + u.name + '（' + u.id +'）\n';
		curLog += msg + '\n';
		curLog += system.now().format('yyyy-MM-dd HH:mm:ss SSS') + '*************会計BARCODE印刷END  ********************\n';
		CommLogUtils.saveLogToDb(curLog,CommLogUtils.LogType.POS,new List<String>());
		return '';
	}
	@remoteaction
	public static void savePrintCount(String prodId){
		List<PrintInfo__c> accs = [select id,printCnt__c from PrintInfo__c where AccountMasterRef__c =:prodId];
		if (!accs.isEmpty()) {
			PrintInfo__c acc = accs[0];
			acc.printCnt__c = CommUtils.nullToIntZero(acc.printCnt__c) + 1;
			update acc;
		} else {
			PrintInfo__c pr = new PrintInfo__c(printCnt__c = 1,AccountMasterRef__c = prodId);
			insert pr;
		}
	}
	class ReqJson {
		String pid; // 会計商品ID
		String ip;  // アド
		String pos; // POS
		// 2018/07/26 QRコード印刷対応 by zy BEGIN
		String ptype;//印刷タイプ
		// 2018/07/26 QRコード印刷対応 by zy END
	}
	// 参照字段API转换
	private static String getObjApiKey(String api,Boolean isCtoRFlg){
		String c = '__c';
		String r = '__r.name';
		return isCtoRFlg ? api.replaceAll(c, r) : api.replaceAll(r, c);
	}
	// 获取所有列Info
	private static void getColnumJson(){
		Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMaps = getAllFieldLst; // 获取AccountMaster__c所有字段信息
		
		JSONGenerator gen = JSON.createGenerator(false);
    	gen.writeStartArray();
    	gen.writeStartObject();
    	gen.writeStringField('field', 'checkFun');
    	gen.writeStringField('headerTemplate', '<input type="checkbox" class="allcheck" name="printCheck" onclick="chgAllCheck(this)" />');
    	gen.writeStringField('template', '<input type=\'checkbox\' class=\'checkbox\' id=\'#= id#\' />');
    	gen.writeStringField('width', '40px');
    	gen.writebooleanField('filterable', false);
    	gen.writebooleanField('sortable', false);
    	gen.writebooleanField('menu', false);
    	gen.writeEndObject();
    	for(String api : defAccMasterApiSet){
    		if(!modelDeafaultValuesMaps.containsKey(api) || api == 'id') continue; // 去掉无效字段
    		Schema.DescribeFieldResult dr = modelDeafaultValuesMaps.get(api); // 获取当前字段所以信息
			gen.writeStartObject();
			gen.writeStringField('field', api);
			gen.writeStringField('title', dr.getLabel());
			if (defApiMap.containsKey(api)) gen.writeStringField('width', defApiMap.get(api));
			if (api == 'field3__c') gen.writeStringField('template', '<a target=\'_blank\' href=\'/#= id#\'>#= field3__c#<a>');
    		gen.writeEndObject();
    	}
    	gen.writeEndArray();
    	colnumJson = gen.getAsString(); // 设置获取所有列Info
	}
	// 获取groupjson
	private static void getColnumGroupJson(String groupField){
		JSONGenerator gen = JSON.createGenerator(false);
    	gen.writeStartArray();
    	if(!CommUtils.isBlank(groupField)){
	    	// 関連設定を行う
	    	gen.writeStartObject();
	    	gen.writeStringField('field', groupField);
	    	gen.writeEndObject();
    	}
        gen.writeEndArray();
        colnumGroupJson = gen.getAsString();
	}

    // 参照字段对应
    private static Object getValueByApi(Sobject s ,String field) {
        // 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH BEGIN
        if (s == null) return '';
        // 2017/09/18 カスタマイズ定義のLINKあり項目は自動リンクを付ける対応 WGCH END
        String apiField = field.trim();
        // Jsonにアサインするキー: ssss__r.aaa__r.xxxx -> ssss__r_aaa__r_xxxx
        // 2017/06/06 XMLのAPI定義小文字、大文字区別されない対応 BEGIN
        if (apiField.containsIgnoreCase(RELATION_KEY)) {
            // aaa__r.xxxx
            Integer startPt = apiField.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
            String refFieldNm = apiField.substring(startPt);
            // 一階層のSOBJECT名
            // ssss__r
            String refSobjNm = apiField.substringBefore('.');
            // 二階層のSOBJECT[aaa__r.xxxx]
            if (refFieldNm.containsIgnoreCase(RELATION_KEY)) {
                // 一階層のSOBJECT取得する[ssss__r]
                Sobject refSobj = s.getSObject(refSobjNm);
                if (refSobj == null) {
                    return null;
                }
                // 二階層の参照関係存在する場合、二階層以上は対応しません
                Integer twoStartPt = refFieldNm.indexOfIgnoreCase(RELATION_KEY) + RELATION_KEY.length();
                String twoRefFieldNm = refFieldNm.substring(twoStartPt);
                // Sobject Name [aaa__r]
                String twoRefSobjNm = refFieldNm.substringBefore('.');
                // Two Level Field
                Sobject twoRefSobj = refSobj.getSObject(twoRefSobjNm);
                // JSONに情報を書込する
                if (twoRefSobj == null) return null;
                else {
                    Object val = twoRefSobj.get(twoRefFieldNm);
                    return val;
                }
            } else {
                Sobject refSobj = s.getSObject(refSobjNm);
                if (refSobj == null) return null;
                else {
                    Object val = refSobj.get(refFieldNm);
                    return val;
                }
            }
        } else {
            Object val = s.get(apiField);
            return val;
        }
    }
}