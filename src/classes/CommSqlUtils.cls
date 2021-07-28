/*********************************************
* CommSqlUtils　SQL全部自動作成クラス
* 2014/04/04 SQL自動作成の除外機能追加
*********************************************/
public class CommSqlUtils {
	// SQL AUTOGENER FILTER SQL作成除外OBJECTと項目情報を定義する
	// 注意、設定する項目の大文字、小文字は大小区分
	// Filter項目は全部　！！！【小文字】！！！で設定が必要
	private static final Map<String, Set<String>> SQL_FILETER_MAP = new Map<String, Set<String>>{
		// 予約情報の発生源を戻らです
		'Lead__c'=>new Set<String>{'eventsource__c'}
	};
	// 指定オブジェクトのみを取得対象とする
	public static String generateQueryString(String name, String[] plusFields) {
       // sObjectを生成
       sObject newObj = (sObject)Type.forName(name).newInstance();
       // 設定情報を取得
       Schema.DescribeSObjectResult descResult = newObj.getsObjectType().getDescribe();
       // 整形して戻す
       //return 'Select ' + concatSet(descResult.fields.getMap().keySet(), ', ', SQL_FILETER_MAP.get(name)) + ' From ' + name;
	   //return 'Select ' + generateAllFieldsString(name) + ' From ' + name;
	   String plusQueryFields = '';
	   if (plusFields != null) plusQueryFields = ',' + String.join(plusFields, ',');
	   return 'Select ' + generateAllFieldsString(name) + plusQueryFields + ' From ' + name;
	}
	// 
	public static String generateQueryString(String name) {
		return generateQueryString(name, null);
	}
	
	// 2016/04/18 システム項目以外のカスタム項目リスト情報を戻る
	public static Map<String, String> getCustomeFieldLst(String objectNm, Boolean isCanWrite) {
		// sObjectを生成
		sObject newObj = (sObject)Type.forName(objectNm).newInstance();
		return getCustomeFieldLst(newObj.getSObjectType(), isCanWrite);
	}
	public static Map<String, String> getCustomeFieldLst(SObjectType objectType, Boolean isCanWrite) {
		// 設定情報を取得
		Schema.DescribeSObjectResult d = objectType.getDescribe();
		//return descResult.fields.getMap().keySet();
		Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
		// 項目定義情報を初期化する
		Map<String, Schema.DescribeFieldResult> fieldsDescMap = getAllFieldLst(objectType,isCanWrite);
		Map<String, String> customeFieldMap = new Map<String, String>();
		for(String fieldName : fieldsDescMap.keySet()) {
			Schema.DescribeFieldResult sField = fieldsDescMap.get(fieldName);
			if(!sField.isCustom()) continue;
			customeFieldMap.put(fieldName, fieldsDescMap.get(fieldName).getLabel());
		}
		return customeFieldMap;
	}
	// 2016/06/05 編集できる項目一覧を戻る BEGIN
	public static Map<String, Schema.DescribeFieldResult> getAllFieldLst(SObjectType objectType, Boolean isCanWrite) {
		return getAllFieldLst(objectType,isCanWrite,false);
	}
	// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
	public static Map<String, Schema.DescribeFieldResult> getAllFieldLst(SObjectType objectType, Boolean isCanWrite, Boolean isLowerKey) {
		return getAllFieldLst(objectType,isCanWrite,isLowerKey,false);
	}
	public static Map<String, Schema.DescribeFieldResult> getAllFieldLst(SObjectType objectType, Boolean isCanWrite, Boolean isLowerKey,boolean isLocalName) {
	// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
		// 設定情報を取得
		Schema.DescribeSObjectResult d = objectType.getDescribe();
		//return descResult.fields.getMap().keySet();
		Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
		// 戻る値変数を初期化する
		Map<String, Schema.DescribeFieldResult> fieldsDescMap = new map<String, Schema.DescribeFieldResult> ();
		for(String fieldName : fieldsMap.keySet()) {
 			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			if (isCanWrite && !sField.isCreateable()) continue;
			// 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため BEGIN
			String locFieldName = sField.getLocalName();
			if (isLowerKey) locFieldName = locFieldName.toLowerCase();
			if (fieldsDescMap.containsKey(locFieldName)) {
				// 既存のAPIのFULLNAME確認する
				Schema.DescribeFieldResult preField = fieldsDescMap.get(locFieldName);
				// PackageのAPIとLocalのAPI名は一致存在する場合
				String preFullFieldName = preField.getName();
				if (isLowerKey) preFullFieldName = preFullFieldName.toLowerCase();
				// 一致しない場合、既に格納しているAPIはPACKAGEのAPI項目です
				if (preFullFieldName != locFieldName) {
					// PACKAGE項目はFULLNAMEで設定する
					fieldsDescMap.put(preFullFieldName, preField);
					// LOCALのカスタマイズ項目は格納する
					fieldsDescMap.put(locFieldName, sField);
				} 
				// 一致場合、既存のAPIはLOCALのカスタマイズAPI項目です
				else {
					String currFullFieldName = sField.getName();
					// FullNameでPackage項目を格納する
					fieldsDescMap.put(currFullFieldName, sField);
				}
			} else {
				fieldsDescMap.put(locFieldName, sField);
				// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
				if (isLocalName) {
					String preFullFieldName = sField.getName();
					if (isLowerKey) preFullFieldName = preFullFieldName.toLowerCase();
					fieldsDescMap.put(preFullFieldName, sField);
				}
				// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
			}
		}
		return fieldsDescMap;
	}
	// 2016/06/05 編集できる項目一覧を戻る END
   // 全て項目を取得する
   public static String generateAllFieldsString(String objectNm) {
       // sObjectを生成
       sObject newObj = (sObject)Type.forName(objectNm).newInstance();
       // 設定情報を取得
       Schema.DescribeSObjectResult descResult = newObj.getsObjectType().getDescribe();
       // 整形して戻す
       return concatSet(descResult.fields.getMap().keySet(), ', ', SQL_FILETER_MAP.get(objectNm));
   }
   /*
   // 指定オブジェクトと指定された子リレーションも取得対象とする
   public static String generateQueryString(String name, Set<String> childSet) {
       // sObjectを生成
       sObject newObj = (sObject)Type.forName(name).newInstance();
       // 設定情報を取得
       Schema.DescribeSObjectResult descResult = newObj.getsObjectType().getDescribe();
       // 取得用項目Set
       Set<String> targetSet = new Set<String>{concatSet(descResult.fields.getMap().keySet(), ', ')};
       // 子リレーションを取得
       for (Schema.ChildRelationship child : descResult.getChildRelationships()) {
           String rName = child.getRelationshipName();
           // 取得対象ではない場合、次へ
           if (!childSet.contains(rName)) continue;
           // 子リレーションの設定情報を取得
           Schema.DescribeSObjectResult childDesc = child.getChildSObject().getDescribe();
           Set<String> tempSet = getAllFieldsForChild(childDesc);
           targetSet.add('(Select ' + concatSet(tempSet, ', ') + ' From ' + rName + ')');
       }
       // 整形して戻す
       return 'Select ' + concatSet(targetSet, ', ') + ' From ' + name;
   }*/
   // 子リレーションの項目取得
   private static Set<String> getAllFieldsForChild(Schema.DescribeSObjectResult descResult) {
       Set<String> retSet = new Set<String>();
       Map<String, Schema.SObjectField> fieldMap = descResult.fields.getMap();
       for (String api : fieldMap.keySet()) {
           // 子リレーションでBase64は取得対象外
           if (fieldMap.get(api).getDescribe().getType() == Schema.DisplayType.base64) continue;
           retSet.add(api);
       }
       return retSet;
   }
   // 連結
   private static String concatSet(Set<String> strSet, String sep, Set<String> filterSet) {
       String retStr;
       if (filterSet == null) filterSet = new Set<String>();
       for (String str : strSet) {
			str = str.toLowerCase();
			if (str == 'ownerid') continue;		// 所有者情報は非表示する
			if (filterSet.contains(str)) continue;
			retStr = retStr == null ? str : retStr + sep + str;
       }
       return retStr == null ? '' : retStr;
   }
   // SOSL：Escaping special characters & | ! ( ) { } [ ] ^ “ ~ * ? : \ '
   public static String escapeSOSLTerm(String term){
        term = CommUtils.nullToBlank(term).replace('\'', '');
        Pattern reservedPattern = pattern.compile('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]');
        Matcher myMatcher = reservedPattern.matcher(term);
        List<Integer> escapeIndexs = new List<Integer>();
        while(true){
            if(myMatcher.find()){
                escapeIndexs.add(myMatcher.start());
            }else{
                break;
            }
        }
        escapeIndexs.sort();
        for(Integer i = escapeIndexs.size()-1; i>=0; i--){
            Integer escapeIndex = escapeIndexs[i];
            term = term.substring(0, escapeIndex) + '\\\\' + term.substring(escapeIndex);
        }
        return term; 
    }
}