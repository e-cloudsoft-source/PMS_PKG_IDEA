/**
* ログ出力共通LIB
* 
**/
public with sharing class CommLogUtils {
	private String LOG_TEMPLATE = '[$$_OPERATOR_$$][$$_TIME_$$] [$$_CLASSNAME_$$] [$$_METHODNAME_$$] [$$LOGSTATUS_$$] $$_LOG_$$';
	private String strLog;
	private Boolean isDebug = false;
	private String strLogStatus = 'INFO';
	private List<String>methodNames;
	private Boolean isHaveError = false;
	private String lastErrorContent;
	private String errorContent;

	public CommLogUtils(String className, Boolean pIsDebug) {
		init(className, pIsDebug, false);
	}
	public CommLogUtils(String className, Boolean pIsDebug, Boolean pShowOperator) {
		init(className, pIsDebug, pShowOperator);
	}
	private void init(String className, Boolean pIsDebug, Boolean pShowOperator) {
		isDebug = pIsDebug;
		strLog = '';
		errorContent = '';
		if (!isDebug) return;
		methodNames = new List<String>();		
		LOG_TEMPLATE = LOG_TEMPLATE.replace('$$_CLASSNAME_$$', className);
		if (pShowOperator) LOG_TEMPLATE = LOG_TEMPLATE.replace('$$_OPERATOR_$$', userinfo.getLastName()  + ' ' + userinfo.getFirstName());
		else LOG_TEMPLATE = LOG_TEMPLATE.replace('[$$_OPERATOR_$$]', '');
	}
	
	public void	write_method_start(String pMethodName) {
		methodNames.add(pMethodName);
		strLog += '\n'+LOG_TEMPLATE.replace('$$_TIME_$$', nowTime())
							.replace('$$_METHODNAME_$$', methodNames[methodNames.size()-1])
							.replace('$$LOGSTATUS_$$', strLogStatus)
							.replace('$$_LOG_$$', '*****************START*****************');
	}			
	
	public void write_method_end() {
		// 制限問題回避
		if(methodNames.isEmpty()) return;
		strLog += '\n'+LOG_TEMPLATE.replace('$$_TIME_$$', nowTime())
							.replace('$$_METHODNAME_$$', methodNames[methodNames.size()-1])
							.replace('$$LOGSTATUS_$$', 'INFO')
							.replace('$$_LOG_$$', '*****************END*****************');
		methodNames.remove(methodNames.size()-1);
		
	}
	
	public void write_log(String log) {
		strLog += '\n'+LOG_TEMPLATE.replace('$$_TIME_$$', nowTime())
							.replace('$$_METHODNAME_$$', methodNames[methodNames.size()-1])
							.replace('$$LOGSTATUS_$$', 'INFO')
							.replace('$$_LOG_$$', log);
	}
	public void write_log(String log, String timeStr) {
		strLog += '\n'+LOG_TEMPLATE.replace('$$_TIME_$$', timeStr)
							.replace('$$_METHODNAME_$$', methodNames[methodNames.size()-1])
							.replace('$$LOGSTATUS_$$', 'INFO')
							.replace('$$_LOG_$$', log);
	}
	public void write_error(String log) {
		strLog += '\n'+LOG_TEMPLATE.replace('$$_TIME_$$', nowTime())
							.replace('$$_METHODNAME_$$', methodNames[methodNames.size()-1])
							.replace('$$LOGSTATUS_$$', 'ERROR')
							.replace('$$_LOG_$$', log);
		lastErrorContent = log;
		errorContent += '\n'+log;
		isHaveError = true;
	}
	public void clear() {
		strLog = '';
		isHaveError = false;
	}
	public Boolean isHaveError() {return isHaveError;}
	public String getAllLog () {
		return strLog;
	}
	public String getLastError() {
		return Commutils.nullToBlank(lastErrorContent);
	}
	public string getAllError () {
		return Commutils.nullToBlank(errorContent);
	}
	public static String removeOverLogString(String log) {
		Integer maxLen = 131072;
		return removeOverLogString(log, maxLen);
	}
	// 2017/12/11 LEFT/RIGHT文字列処理パータンを追加 BEGIN
	public static String removeOverLogString(String log, Integer maxLen) {
		return removeOverLogString(log, maxLen, false);
	}
	public static String removeOverLogString(String log, Integer maxLen, Boolean isLeft) {
		if (maxLen == null) maxLen = 131072;
		if (CommUtils.isBLank(log)) return '';
		Integer logLen = log.length();
		//if (logLen > maxLen) return log.mid(logLen-maxLen,maxLen);
		if (logLen > maxLen) {
		    return (isLeft) ? log.left(maxLen) : log.right(maxLen);
		}
		else return log;
	}
	// 2017/12/11 LEFT/RIGHT文字列処理パータンを追加 END
	private String nowTime() {
		return System.now().format('yyyy/MM/dd HH:mm:ss:SSS');
	}
	// 2017/07/26 4）ログ情報はDBに記載する by zy BEGIN
	public enum LogType{POS,WSAPI,EXPO,JR,DISCUSSION,JR1WAY}
	public static void saveLogToDb(String messageJson,LogType logName, List<String> nameLst){
		// 默认设置
    	LogDefine define = new LogDefine();
    	// 定义type字段
    	define.docName = logName.name();
		saveLogToDb(messageJson,define, nameLst);
	}
    public static void saveLogToDb(String messageJson,LogType logName){
    	// 默认设置
    	saveLogToDb(messageJson, logName, 100);
    }
    public static void saveLogToDb(String messageJson,LogType logName, Integer maxFiles){
        // 默认设置
        LogDefine define = new LogDefine();
        // 最大ファイルは【-1】の場合、ログ出力なし
        maxFiles = CommUtils.nullToZero(maxFiles);
        if (maxFiles == -1) return;
        else if (maxFiles > 0) define.MaxFiles = maxFiles;
        // 定义type字段
        define.docName = logName.name();
        saveLogToDb(messageJson,define);
    }
    public static void saveLogToDb(String messageJson,LogDefine define){
    	saveLogToDb(messageJson,define, new List<String>());
    }
    private static void saveLogToDb(String messageJson,LogDefine define, List<String> nameLst ){
    	try {
		 	// 最新のログファイル取得する
			Document doc = getCurDocument(define);
			messageJson = replaceToNull(messageJson,nameLst);
			// ログ保存→DB
			saveLogToDocument(doc,encode(messageJson),define);
    	} catch(exception e) {
    		system.debug(logginglevel.info,'e::::' + e);
    	}
	 }
	private static String replaceToNull(String messageJson,List<String> nameLst){
		for (String name : nameLst) {
			messageJson = CommLogUtils.replace('"' + name + '":"','",', messageJson ,'');
		}
		return messageJson;
	}
    // 最新のログファイル取得する
    private static Document getCurDocument(LogDefine define){
    	// ファイルログ名
		String developerName = 'LogFiles';
		//　ファイル下ドキュメント名
		String documentName = define.docName;
		String selectDocName = documentName + '%';
		// ドキュメント内容制限　１M
		//Decimal maxDocSize = define.MasSize; //document最大制限3M 
		//integer fileCnt = define.MaxFiles;
    	// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id,Name from Folder where DeveloperName = :developerName];
		// ファイル下
        List<Document> existDocs = [select id,BodyLength from Document where FolderId = :fs[0].Id and DeveloperName like :selectDocName  order by LastModifiedDate asc];
        Integer existFiles = existDocs.size();
        Document doc = new Document();
        // 文件名
        doc.name = documentName + fs[0].name + (existFiles + 1) + '.log';
        // 文件ラベルー
        doc.DeveloperName = documentName + (existFiles + 1);
        doc.FolderId = fs[0].Id;
        if(existFiles > 0){
        	//最後ドキュメント内容な字数判断
        	Document curDoc = existDocs[existFiles - 1];
        	// 該当ドキュメント既存情報内容は最大値を超えない場合
        	if(curDoc.BodyLength < define.MasSize){
        		doc = curDoc;
        	} 
        	// 既存内容は最大値を超える場合
        	else {
        	   // 既存ファイルは最大定義値を超える場合
        	   if (existFiles >= define.MaxFiles) {
                    // 一番名のドキュメントを更新を行う
                    doc = existDocs[0];
                    // クリックを行う
                    define.isClearFlg = true;
        	   }
        	}
        }
        return doc;
    }
    // ログ→DB
    private static void saveLogToDocument(Document doc,String curLog,LogDefine define){
    	//if (doc.id != null) doc = [select id ,body from document where id=:doc.id];
    	try{
	    	// 2018/03/07 Security Check BEGIN
	    	List<String> chkFields = new List<String>{'body','folderid','developername','name'};//'id'
	    	Map<String,Schema.SObjectField> m = Schema.SObjectType.Document.fields.getMap();
	    	if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
	    		return;
	    	}
	    	// 2018/03/07 Security Check END
	    	if (doc.id != null) {
	    	    doc = [select id ,body from document where id=:doc.id];
	    		if (define.isClearFlg !=null && define.isClearFlg) doc.body = Blob.valueof(curLog);
	    		// 既存情報＋新ロゴは更新を行う
	    		else {
		    		String content = doc.body.toString();
		    		doc.body = Blob.valueof(content + curLog);
	    		}
	    	} else {
	    		doc.body = Blob.valueof(curLog);
	    	}
	    	if (doc.id != null) update doc;
	    	else insert doc;
    	} catch (exception e){
    		//如果文件名重复，并且无法保存
    		doc.DeveloperName = define.docName + system.now().format('yyyyMMddHHmmssSSS');
    		Database.upsert(doc,false);
    	}
    }
    public static String replace(String bef,String af, String org ,String rep){
    	String content = '';
    	if (!CommUtils.isBlank(bef)) content = org.subStringAfter(bef);
		if(!CommUtils.isBlank(content) && !CommUtils.isBlank(af)) {
			content = content.substringBefore(af);
			org = org.replace(content,'');
		}
		return org;
    }
     //encode加密
    private static String encode(String para) {
    	if (CommUtils.isBlank(para)) return '';
        //return EncodingUtil.urlEncode(para, 'UTF-8');
        return para;
    }
    public class LogDefine {
    	// 文件数制限
        public Integer MaxFiles = 1000;
        // 文件内容大小制限
        public Decimal MasSize = 1024*1024*1.5;
        public String docName;
        public Boolean isClearFlg;
    }
    // 2017/07/26 4）ログ情報はDBに記載する by zy END
}