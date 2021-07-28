/*
* AI 
* 指定オブジェクト、指定字段、検索処理
*/
public class QQNAILookupFieldBatch implements Database.Batchable<sObject>, Database.Stateful {
	// オブジェクト名
	private string tableName;
	// 字段名
	private string fieldName;
	// 指定字段値集合
	private Set<string> fieldValues;
	// 実行行列
   	public List<String> excuteFields;
   	public String spcd;
   	public Date startDt;
   	public Date endDt;
   	// 2019/02/15 AI功能改修 by zy BEGIN
   	// 計数開始
   	private integer intRecCnt = 0;
   	private Set<String> exitSet = new Set<String>();
   	// 2019/02/15 AI功能改修 by zy END
	// 初期化
    public QQNAILookupFieldBatch(string pTableName, string pstrField) {
    	tableName = pTableName;
    	fieldName = pstrField;
    	fieldValues = new Set<string>();
    }
    
    public List<sObject> start(Database.BatchableContext BC) {
    	AggregateResult[] groupedResults = [select FieldValue__c value from QQNAILookup__c where 
                                     TableName__c = :tableName AND 
                                     FieldName__c = :fieldName group by FieldValue__c limit 2000];
        exitSet = new Set<String>();
        for (AggregateResult look : groupedResults) {
        	exitSet.add(CommUtils.nullToBlank(look.get('value')));
        }
        // 2019/02/15 AI功能改修 by zy BEGIN
        // 既存計数設定
        LIst<QQNAILookup__c> lookUps = [select TranslatedValue__c,id from QQNAILookup__c where TableName__c = :tableName AND FieldName__c = :fieldName order by TranslatedValue__c desc limit 1];
       	if (!lookUps.isEmpty()) intRecCnt = CommUtils.nullToINtZero(lookUps[0].TranslatedValue__c);
       	// 2019/02/15 AI功能改修 by zy END
        Integer cancelBlank = CommConst.LEAD_ST_CANCEL_FLG;
    	string strQuery = 'select ' + fieldName + ' from ' + tableName + ' where CancelBool__c != :cancelBlank';
    	// if (!values.isEmpty()) strQuery += ' and ' + fieldName + ' != :values';
    	//if (!CommUtils.isBlank(spcd)) strQuery += ' and refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :spcd ';
    	if (startDt != null) strQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt ';
    	if (endDt != null) strQuery += ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDt ';
    	// 2019/02/15 AI功能改修 by zy BEGIN
    	// 指定部屋タイプ処理対象
	    Set<Decimal> rommTypCodeSet = QQNAIConfigurationCreator.getRoomTypeSQL();
	   	if (!rommTypCodeSet.isEmpty()) strQuery += ' and refTypeOfRooms__r.Seq__c in :rommTypCodeSet';
	   	 // 2019/02/15 AI功能改修 by zy END
    	strQuery += ' order by refTypeOfRooms__c,Rroom__c ';
    	return Database.query(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        for(sObject objResult : scope) {
        	// 2019/02/15 AI功能改修 by zy BEGIN
        	// fieldValues.add(string.valueof(objResult.get(fieldName)));
        	String value = CommUtils.nullToBlank(objResult.get(fieldName));
        	if (!exitSet.contains(value)) {
        		fieldValues.add(value);
        		exitSet.add(value);
        	}
        	// 2019/02/15 AI功能改修 by zy END
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    	try {
    		// 2019/09/15 Security Check BY zyz BEGIN
    		List<String> chkFieldsLst = new List<String>{'tablename__c','fieldvalue__c','fieldname__c'};
    		Map<String,Schema.SObjectField> mm = Schema.SObjectType.QQNAILookup__c.fields.getMap();
    		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
    			return ;
    		}
    		// 2019/09/15 Security Check BY zyz END
    		List<QQNAILookup__c> aiLookup = new List<QQNAILookup__c>();
    		// 2019/02/15 AI功能改修 by zy BEGIN
    		//integer intRecCnt = 0;
    		if (intRecCnt != 0) intRecCnt++;
    		// 2019/02/15 AI功能改修 by zy END
    		// AI 検索対象作成
    		for(string fieldValue : fieldValues) {
	    		QQNAILookup__c objAILookup = new QQNAILookup__c();
	    		objAILookup.TableName__c = tableName;
	        	objAILookup.FieldName__c = fieldName;
	        	objAILookup.FieldValue__c = fieldValue;
	        	objAILookup.TranslatedValue__c = intRecCnt++;
	        	aiLookup.add(objAILookup);
    		}
        	
        	if(aiLookup.size() > 0)
        		insert aiLookup;
        	// 自動機能実行行列
        	QQNRoomTrainBatch.nextExcuteBatch(excuteFields,spcd,startDt,endDt); 
        } catch(DMLException ex) {
        	QQNAIDriver.generateErrorLog('Exception while creating AILookup records' + ex.getMessage());
        }
    }
}