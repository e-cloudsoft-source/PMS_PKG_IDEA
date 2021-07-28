global with sharing class AutoCompleteCtrl {
    global static SObject[] findSObjects(string obj, string qry, string addFields, String extFilter) {
    	return findSObjectsExt(obj, qry, addFields, extFilter, '');
    }
    // 2014/02/25 使わないに変更する
    global static SObject[] findSObjectsExtSL(string obj, string qryKey, String extFilter, String showFileds) {
    	return findSObjectsExtSL(obj, qryKey, '', extFilter,showFileds);
    }
    // SOSL検索機能対応
    global static SObject[] findSObjectsExtSL(string obj, string qryKey, string addFields, String extFilter, String showFileds) {
    	return findSObjectsExtSL2(obj, qryKey, addFields, extFilter, showFileds, '',false,'');
    }
    @remoteAction
    global static SObject[] findSObjectsExtSL2(string obj, string qryKey, string addFields, String extFilter, String showFileds, String sortKey, Boolean withContact, String withContactKey) {        
    // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
    	return findSObjectsExtSL3(obj, qryKey, addFields, extFilter, showFileds, sortKey,withContact,withContactKey,false);
    }
    // comdefNoUseパラメータを新規追加、TRUE：共通定義の「客様検索機能の表示項目」設定内容無効化
    @remoteAction
    global static SObject[] findSObjectsExtSL3(string obj, string qryKey, string addFields, String extFilter, String showFileds, String sortKey, Boolean withContact, String withContactKey, Boolean comdefNoUse) {         
    // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        //List<String> fieldList = new List<String>{'id','name'};
        // 画面へ表示項目リスト設定
        //if (!CommUtils.isBlank(addFields)) fieldList = addFields.split(',');
        // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
        String cFields = custFields;
        // お客様から情報検索の場合、カスタマイズ定義項目を再設定する
        // 共通定義あり　AND　お客様情報を設定される　AND　該当お客様検索機能有効が必要場合
        if (!CommUtils.isBlank(cFields) && obj == 'contact' && comdefNoUse != true) showFileds = cFields;
        // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        Set<String> showFieldSet = new Set<String>();
        if (!CommUtils.isBlank(showFileds)) {
		// 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
        	//for (String showField : showFileds.split(',')) {
        	//	showFieldSet.add(showField);
        	for (String f : showFileds.split(',')) {
        		showFieldSet.add(CommUtils.nullToBlank(f).toLowerCase());
        	}
		// 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        }
       // check to see if the object passed is valid
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        // 2019/08/30 版本升级对应检索不到数据bug BY zyz BEGIN
        if (obj == null) return null;
        String ns = CommConst.APPOTION_NAMESPACE;
        if(obj.endsWith('__c') && !obj.startsWith(ns)){
        	obj = ns+obj;
        }
        // 2019/08/30 版本升级对应检索不到数据bug BY zyz END
        Schema.SObjectType sot = gd.get(obj);
        if (sot == null) {
            // Object name not valid
            return null;
        }
        // 2014/03/14 Global検索対応
        //if (qryKey.trim().length() < 2) qryKey = qryKey + '　';//return (new List<Sobject>());
        // create the filter text
        //String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
        //begin building the dynamic soql query
        // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
        //String showFields = 'id,Name';
        String showFields = '';
        showFieldSet.add('id');
        showFieldSet.add('name');
        // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        // if an additional field was passed in add it to the soql
        for (String s : showFieldSet) {
            // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
	    //showFields += ', ' + s;
            showFields += (!CommUtils.isBlank(showFields) ? ', ' : '') + s;
	    // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        }
		// 2014/02/22 検索キーの単語は１単語の場合、Nameだけ探す　スペース入ると、全項目から探す
		String[] keywords = CommUtils.splitSpace(qryKey);
		String fieldsScope = 'ALL FIELDS';
		// 2014/03/14 Global検索対応
		//if (keywords.size() <= 1) fieldsScope = 'NAME FIELDS';
		set<id> contactIds = new set<id>();
		if (withContact) {
			String queryContact = 'FIND \''+String.escapeSingleQuotes(qryKey)+'*\' IN ' + fieldsScope + ' RETURNING Contact(id) ';
			try {
				List<List<sObject>> C = search.query(queryContact);
				List<Contact> cLst = (List<Contact>)C[0];
				for (Contact citem : cLst) {
					contactIds.add(citem.Id);
				}
			} catch (Exception e) {}
		}
		// Search Sql
        String queryStr = 'FIND \''+String.escapeSingleQuotes(qryKey)+'*\' IN ' + fieldsScope + ' RETURNING ' + obj +'(' + showFields;
        if (!CommUtils.isBlank(extFilter)) {
        	queryStr += ' WHERE '+extFilter;
        }
        if (!contactIds.isEmpty()) {
        	if (!CommUtils.isBlank(extFilter)) {
        		queryStr += ' And ';
        	} else {
        		queryStr += ' WHERE ';
        	}
        	queryStr += withContactKey + ' IN :contactIds ';
        }
        if (CommUtils.isBlank(sortKey)) queryStr += ' order by Name ';
        else queryStr += sortKey;
        
		queryStr += ' limit 200 )';
        List<List<sObject>> L = new List<List<sObject>>();
        try {
System.debug(loggingLevel.info,'Componet soql:' + queryStr);
            L = search.query(queryStr);
            List<sobject> s1 = L[0];
            // 関連のお客様情報が存在する場合
            if (s1.isEmpty() && !contactIds.isEmpty()) {
            	// 該当お客様関連情報を検索を行う
            	String againQuery = ' SELECT '+showFields + ' from ' + obj + ' where ' + withContactKey + ' in :contactIds ';
				if (!CommUtils.isBlank(extFilter)) {
        			againQuery += ' And '+extFilter;
        		}
       			if (CommUtils.isBlank(sortKey)) queryStr += ' order by Name ';
        		else queryStr += sortKey;
            	againQuery += ' limit 200 ';
System.debug(loggingLevel.info,'Componet again soql:' + againQuery);
            	list<sobject> againSearch = DataBase.query(againQuery);
            	L[0] = againSearch;
            }
        }
        catch (QueryException e) {
            return null;
        }
        return L[0];
    }
    global static SObject[] findSObjectsExt(string obj, string qry, string addFields, String extFilter, String showFileds) {
    	return findSObjectsExt2(obj, qry, addFields, extFilter, showFileds, '',false,'');
    }
    @RemoteAction
    global static SObject[] findSObjectsExt2(string obj, string qry, string addFields, String extFilter, String showFileds, String sortKey, Boolean withContact, String withContactKey) {
    // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
        return findSObjectsExt3(obj, qry, addFields, extFilter, showFileds, sortKey,withContact,withContactKey,false);
    }
    // comdefNoUseパラメータを新規追加、TRUE：共通定義の「客様検索機能の表示項目」設定内容無効化
    @remoteAction
    global static SObject[] findSObjectsExt3(string obj, string qry, string addFields, String extFilter, String showFileds, String sortKey, Boolean withContact, String withContactKey, Boolean comdefNoUse) {
    // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
        // more than one field can be passed in the addFields parameter
        // split it into an array for later use
        List<String> fieldList;
        
        if (!CommUtils.isBlank(addFields)) fieldList = addFields.split(',');
        Set<String> showFieldSet = new Set<String>(fieldList);
        if (!CommUtils.isBlank(showFileds)) {
        	for (String showField : showFileds.split(',')) {
        		showFieldSet.add(showField);
        	}
        }
       // check to see if the object passed is valid
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        // 2019/08/30 版本升级对应检索不到数据bug BY zyz BEGIN
        if (obj == null) return null;
        String ns = CommConst.APPOTION_NAMESPACE;
        if(obj.endsWith('__c') && !obj.startsWith(ns)){
        	obj = ns+obj;
        }
        // 2019/08/30 版本升级对应检索不到数据bug BY zyz END
        Schema.SObjectType sot = gd.get(obj);
        if (sot == null) {
            // Object name not valid
            return null;
        }
        // create the filter text
		// 2019/03/11 SFの全角「＼」問題回避 WSQ BEGIN
		qry = CommUtils.escStr(qry);
        //String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
        String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
        // 2019/03/11 SFの全角「＼」問題回避 WSQ END
        //begin building the dynamic soql query
        String soql = 'select id, Name';
        // if an additional field was passed in add it to the soql
        if (showFieldSet != null) {
            for (String s : showFieldSet) {
                soql += ', ' + s;
            }
        }
        // add the object and filter by name to the soql
        soql += ' from ' + obj + ' where ( name' + filter;
        // add the filter by additional fields to the soql
        if (fieldList != null) {
            for (String s : fieldList) {
                soql += ' or ' + s + filter;
            }
        }
        soql += ')';
        if (!CommUtils.isBlank(extFilter)) {
        	soql += ' and ' + extFilter;
        }
        
        if (CommUtils.isBlank(sortKey)) soql += ' order by Name limit 20';
        else soql += sortKey + ' limit 20';
        List<sObject> L = new List<sObject>();
        try {
System.debug(loggingLevel.info,'Componet soql:' + soql);
            L = Database.query(soql);
        }
        catch (QueryException e) {
            return null;
        }
        return L;
   }
   public string ns{get{return CommBaseCtrl.getNs();}}
   // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ BEGIN
   // お客様のカスタム項目値
   public static string custFields{get{
        String sfields = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ContactSearchFields__c).toLowerCase();
        if (!CommUtils.isBlank(sfields)) {
            list<string> fields = new list<string>();
            
            Map<String, Schema.DescribeFieldResult> allFields = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false);

            map<String, String> lowKeyToFieldsMap = new map<String, String>();
            for (String key : allFields.keySet()) {
               	lowKeyToFieldsMap.put(key.toLowerCase(),key);
            }
			set<string> filter = new set<String>();
            for (String s : sfields.split(',')) {
            	// 重複処理
            	s = CommUtils.nullToBlank(s);
            	if (filter.contains(s)) continue;
            	filter.add(s);
            	if (s == 'mailingaddress') {
            		String state = 'MailingState';
            		String city = 'MailingCity';
            		String street = 'MailingStreet';
            		if (!filter.contains(state)) fields.add(state);
            		if (!filter.contains(city)) fields.add(city);
            		if (!filter.contains(street)) fields.add(street);
					filter.add(state);
					filter.add(city);
					filter.add(street);
            	} else if (s == 'otheraddress') {
            		String state = 'OtherState';
            		String city = 'OtherCity';
            		String street = 'OtherStreet';
            		if (!filter.contains(state)) fields.add(state);
            		if (!filter.contains(city)) fields.add(city);
            		if (!filter.contains(street)) fields.add(street);
					filter.add(state);
					filter.add(city);
					filter.add(street);
            	} else {
	                //カスタム項目の場合、全方NSを追加する
	                if (lowKeyToFieldsMap.containsKey(s)) {
	                	Schema.DescribeFieldResult f = allFields.get(lowKeyToFieldsMap.get(s));
	                	// Returns true if the field is a custom field, false if it is a standard field, such as Name.
	                    if (f.isCustom()) {
	                        fields.add(CommConst.APPOTION_NAMESPACE + lowKeyToFieldsMap.get(s));
	                    } else {
	                        fields.add(lowKeyToFieldsMap.get(s));
	                    }
	                }
            	}
            }
            return String.join(fields, ',');
        } else {
            return '';
        }
   }}
   private final String uid = CommUtils.getGUID();
   public String getGuid() {return uid;}
   // 2019/05/21 お客様検索機能、表示項目をカスタマイズできるように改善 WSQ END
/**
*2015-11-18 
*テストクラスAutoCompleteCtrlTestに移行する     
	@isTest
	static void testCase1() {
		SObject[] s = AutoCompleteCtrl.findSObjectsExt('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null','StatusLst__c');
		System.assertNotEquals(s, null);
		SObject[] s2 = AutoCompleteCtrl.findSObjects('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertNotEquals(s2, null);
		SObject[] s3 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		System.assertEquals(s3,null);
		SObject[] s4 = AutoCompleteCtrl.findSObjects(null,'22', 'ID__c', null);
		
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null','StatusLst__c');
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');
		AutoCompleteCtrl.findSObjectsExtSL('LeadIndex__c', '22', 'ID__c', null);
		AutoCompleteCtrl.findSObjectsExtSL('A-LeadIndex__c', '22', 'ID__c', 'StatusLst__c != \'キャンセル\' And  ParentLeadIndxRef__c = null');

	}
*/
}