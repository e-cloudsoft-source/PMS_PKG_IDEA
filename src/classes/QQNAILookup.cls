public class QQNAILookup {
	// 字段鍵と値対象
	public class LookupValue {
		public LookupValue(integer lookupValue) {
			intValue = lookupValue;
		}
		// 序号
		public integer intValue;
		// 平均值
		public double normalizedValue;
	}
	
	private Map<string, Map<string, Map<string, LookupValue>>> aiLookup;
	//　検索内容処理
	public void loadAll() {
		aiLookup = new Map<string, Map<string, Map<string, LookupValue>>>();
		List<QQNAILookup__c> lookupList = [select TableName__c, FieldName__c, FieldValue__c, TranslatedValue__c
										from QQNAILookup__c order by TableName__c, FieldName__c asc];
		constructAILookup(lookupList);
	}
	// 指定オブジェクトと字段内容取得
	public Map<string, LookupValue> loadField(string tableName, string fieldName) {
		if(aiLookup == null)
			aiLookup = new Map<string, Map<string, Map<string, LookupValue>>>();
		
		List<QQNAILookup__c> lookupList = [select TableName__c, FieldName__c, FieldValue__c, TranslatedValue__c
										from QQNAILookup__c where TableName__c = :tableName and FieldName__c = :fieldName];
		constructAILookup(lookupList);
		
		return getFieldValueMap(tableName, fieldName);
	}
	
	public LookupValue translate(string tableName, string fieldName, string fieldValue) {
		// 2019/02/15 AI功能改修 by zy BEGIN
		LookupValue lookUp = new LookupValue(0);
		if (aiLookup.containsKey(tableName) 
				&& aiLookup.get(tableName).containsKey(fieldName)
					&& aiLookup.get(tableName).get(fieldName).containsKey(fieldValue))
						return aiLookup.get(tableName).get(fieldName).get(fieldValue);
		return lookUp;
    	//return aiLookup.get(tableName).get(fieldName).get(fieldValue);
    	// 2019/02/15 AI功能改修 by zy END
    }
    
    public Map<string, LookupValue> getFieldValueMap(string tableName, string fieldName) {
    	if (aiLookup.containsKey(tableName)) return aiLookup.get(tableName).get(fieldName);
    	return new Map<String,LookupValue>();
    }
	// 构造参照情報
	private void constructAILookup(List<QQNAILookup__c> lookupList) {
		Map<string, LookupValue> field;
		string lastTable;
		string lastField;
		
		for(QQNAILookup__c lookup : lookupList) {
			if(lastTable != lookup.TableName__c || lastField != lookup.FieldName__c) {
				//	Avoid querying the maps unnecessarily
				field = getFieldFromTable(getTable(lookup.TableName__c), lookup.FieldName__c);
				lastTable = lookup.TableName__c;
				lastField = lookup.FieldName__c;
			}
			
			field.put(lookup.FieldValue__c, new LookupValue(lookup.TranslatedValue__c.intValue()));
		}
		
		normalizeValues();
	}
	// 设定平均值
	private void normalizeValues() {
		double multiplier;
		for(Map<string, Map<string, LookupValue>> table : aiLookup.values()) {
			for(Map<string, LookupValue> field : table.values()) {
				multiplier = 2.0 / field.size();
				for(LookupValue lookupValue : field.values()) {
					lookupValue.normalizedValue = lookupValue.intValue * multiplier - 1;
				}
			}
		}
	}
	
	private Map<string, Map<string, LookupValue>> getTable(string tableName) {
		Map<string, Map<string, LookupValue>> table = aiLookup.get(tableName);
		if(table == null) {
			table = new Map<string, Map<string, LookupValue>>();
			aiLookup.put(tableName, table);
		}
		
		return table;
	}
	
	private Map<string, LookupValue> getFieldFromTable(Map<string, Map<string, LookupValue>> table, string fieldName) {
		Map<string, LookupValue> field = table.get(fieldName);
		if(field == null) {
			field = new Map<string, LookupValue>();
			table.put(fieldName, field);
		}
		
		return field;
	}
}