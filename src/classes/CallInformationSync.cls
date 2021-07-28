/*
 * @Author: persistent systems ltd.
 * @Date: 4th December 2013 
 * @Description: This class is used as a werbservice to pass call information from Java relay app to Salesfore
 * 2015/10/08 CarNo Search Function add
 * 2016/04/13 CarNo Find SOSL Bug Fix
 * 2016/10/25 自動車ナンバーのポップアップと電話のポップアップをユーザー毎にするかしないかの設定を分離対応
 */
 
global with sharing class CallInformationSync {
 

	// 2015/10/08 CarNo Search Function add BEGIN
    public static final String CarNoKey = 'CAR';
	public static final String PhoneKey = 'PHONE';
	// 2015/10/08 CarNo Search Function add END
    /**
    * This method is called from java relay app
    * @callInfo: CallInformation instance which contains call info data
    * @return: CallInformationSyncResult instance which contains call info id and isSuccess flag,
    *           if there is any error then isSuccess is false and errorMessage contains error.
    */
    webservice static CallInformationSyncResult createCallInformation(CallInformation callInfo) {
        try{
            System.debug(loggingLevel.INFO,'callInfo: '+callInfo);
            CommDefine__c commDef = CommDefine__c.getInstance();
            
            Integer maxDBRecords = 10;
            
            if(commDef != null && commDef.maxrecords_DB__c != null){
                maxDBRecords = Integer.valueOf(commDef.maxrecords_DB__c);
            }
            // 2017/06/06 PUSHTOPICの自動作成機能対応 BEGIN
            JinyaInstallClass.setupCtiStramingTopic(true);
            // 2017/06/06 PUSHTOPICの自動作成機能対応 END
            
            /**
            * Get All the Call Information record order by call_time__c in ascending order, so that we get old call info first
            */
            List<Call_Information__c>  callInformationList = [Select Id from Call_Information__c order by Call_Time__c asc, LastmodifiedDate asc, Id asc LIMIT :Limits.getLimitQueryRows()];
            
            Call_Information__c cInfo = new Call_Information__c();
            
            deleteOldCallRecords(maxDBRecords,callInformationList);
            
            system.debug('After delete numbers of record in call List: '+callInformationList.size());
            
            /**
            * If number of call info records has reached maxDBRecords then use old call info record and update it
            * else insert it
            */
            if(callInformationList.size() == maxDBRecords){
                cInfo = callInformationList[0];
                cInfo.isRSNP__c = false;
                cInfo.isDCD1__c = false;
                cInfo.Call_Time__c = null;
                cInfo.Contact__c = null;
                cInfo.Account__c = null;
        		cInfo.RSN_Code__c = '';
                cInfo.No_of_Matching_Customers__c = 0;
                // 2015/10/08 CarNo Search Function add BEGIN
                cInfo.CarModel__c = null;
                cInfo.CallType__c = PhoneKey;
                cInfo.CarColor__c = null;
                cInfo.ImgHex64Info__c = null;
	    		// 2015/10/08 CarNo Search Function add END
	    		// 2016/10/18 音通知複数回回避修正 BEGIN
	    		cInfo.MessageUUID__c = CommUtils.getGUID();
	    		// 2016/10/18 音通知複数回回避修正 END
            }
            cInfo.IsCustomerUpdated__c = false;
            cInfo.SNO__c = callInfo.sno;
            cInfo.Nam__c= callInfo.nam;
            cInfo.LNO__c = callInfo.lno;
            if(callInfo.rsnp != null){
                cInfo.isRSNP__c = callInfo.rsnp;
                cInfo.RSN_Code__c = callInfo.rsnCode;
            }
            if(callInfo.dcd1 != null){
                cInfo.isDCD1__c = callInfo.dcd1;
            }

            // 2015/10/08 CarNo Search Function add BEGIN
            String[] searchGp = CommUtils.nullToBlank(cInfo.SNO__c).split('&');
            String notype = '';
            // CARのNOが存在する場合
            if (searchGp.size() > 0 && searchGp[0].equalsIgnoreCase(CarNoKey)) {
                cInfo.CallType__c = CarNoKey;
                if (searchGp.size() > 1) {
                	cInfo.SNO__c = searchGp[1];
                } else cInfo.SNO__c = 'unknown';
                if (searchGp.size() > 2) {
                	// 車種
                    cInfo.CarModel__c = searchGp[2];
                }
                if (searchGp.size() > 3) {
                	// 色
                    cInfo.CarColor__c = searchGp[3];
                }
                if (searchGp.size() > 4) {
                    // Icon
                    cInfo.ImgHex64Info__c  = searchGp[4];
                }
                notype = CarNoKey;
            }
             // 2015/10/08 CarNo Search Function add END

            /**
            * Create Call Time in users timezone who has called this web service
            */
            if(callInfo.cdt != null && callInfo.ctm != null && callInfo.cdt != '' && callInfo.ctm != ''){
                if(callInfo.cdt.length() == 8 && callInfo.ctm.length() == 6){
                    cInfo.Call_Time__c = DateTime.newInstance(
                                                            Integer.valueOf(callInfo.cdt.substring(0, 4)),      // Year
                                                            Integer.valueof(callInfo.cdt.substring(4, 6)),      // Month
                                                            Integer.valueOf(callInfo.cdt.substring(6, 8)),      // Day 
                                                            Integer.valueOf(callInfo.ctm.substring(0, 2)),      // Hour
                                                            Integer.valueOf(callInfo.ctm.substring(2, 4)),      // Minutes
                                                            Integer.valueOf(callInfo.ctm.substring(4, 6)));     // Seconds
                                                            }
            }
            cInfo.DT0__c = callInfo.dt0;
            cInfo.DT1__c = callInfo.dt1;
            cInfo.DT4__c = callInfo.dt4;
            /* 2014/11/20 DNO番号追加 */
            cInfo.DNO__c = callInfo.dno;
            /**
            * If its not isRSNP then searchContact if isDCD1 is false i.e. Type 1 else searchAccount i.e. Type 2
            */
            if(cInfo.SNO__c != null){
                if(!cInfo.isRSNP__c){
                    if(!cInfo.isDCD1__c){
                        List<Contact> contactList = searchContact(cInfo.SNO__c, notype);
                        if(contactList != null && contactList.size() > 0){
                            cInfo.Contact__c = contactList[0].Id;
                            cInfo.Account__c = contactList[0].AccountId;
                            // 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
                            if(noType == CarNoKey) {
                            	String messageLabel = searchLead(contactList[0].Id);
                            	cInfo.DT4__c = (CommUtils.isblank(messageLabel) ? '' :messageLabel);
                            }
                            // 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
                            cInfo.No_of_Matching_Customers__c = contactList.size();
                        }
                    }
                    else{
                        List<Account> accountList = searchAccount(cInfo.SNo__c, notype);
                        if(accountList != null && accountList.size() > 0){
                            cInfo.Account__c = accountList[0].Id;
                            cInfo.No_of_Matching_Customers__c = accountList.size();
                        }
                    }
                }
            }
            system.debug('cInfo: '+cInfo);
            upsert cInfo;

            if(commDef.ResContRef__c == null || commDef.ResContRef__c == '' || commDef.ResAccRef__c == null || commDef.ResAccRef__c =='' || commDef.ResPhoneRef__c == null || commDef.ResPhoneRef__c == '' || CommUtils.isBlank(commDef.ResCarNoRef__c)){
            	List<CommDefine__c> existComDefList = [select id, name, ResContRef__c,ResAccRef__c, ResPhoneRef__c,CTICarAPIName__c,ResCarNoRef__c from CommDefine__c LIMIT 1];
            	if(existComDefList.size() != null && existComDefList.size() >0){
            		CommDefine__c updObj = existComDefList[0];
					System.debug(loggingLevel.INFO, ' before update :: ' +updObj);
					Map<String, String> resRefMap = getResRefDetails(updObj);
            		//if(CommUtils.isBlank(updObj.ResContRef__c)){
            		if(String.isEmpty(updObj.ResContRef__c)){
            			updObj.ResContRef__c = (resRefMap.get('contRef')!= null)? resRefMap.get('contRef') : '';
            		}
            		//if(CommUtils.isBlank(updObj.ResAccRef__c)){
            		if(String.isEmpty(updObj.ResAccRef__c)){
            			updObj.ResAccRef__c = (resRefMap.get('accRef') !=null)? resRefMap.get('accRef'):'';
            		}
					//if(CommUtils.isBlank(updObj.ResPhoneRef__c)){
					if(String.isEmpty(updObj.ResPhoneRef__c)){
            			updObj.ResPhoneRef__c = (resRefMap.get('phoneRef')!=null)? resRefMap.get('phoneRef'):'';
            		}
					update updObj;
					System.debug(loggingLevel.INFO, ' after update :: ' +updObj); 
            	}
			}
			
			/**
            * Return call info id with isSuccess as true
            */
            return new CallInformationSyncResult(cInfo.id);
        }
        catch(Exception ex){
            /**
            * If there is an exception then return errorMessage with isSuccess as false
            */
            return new CallInformationSyncResult(ex.getMessage());
        }
    }
    
    
    /* This method will return Contact Lookup, Account Lookup and Phone number field ids from Reservation object.*/
    public static Map<String, String> getResRefDetails(CommDefine__c comDef){
    		Map<String, String> resRefMap = new Map<String, String> ();
    	try{
    		
    		List<RecordType> bookingRecTypeList = [Select id , name From RecordType where DeveloperName = 'BookingRecType'];
    		 
    		// Map<String, Schema.RecordTypeInfo> recTypeMap =  Lead__c.SObjectType.getDescribe().getRecordTypeInfosByName();
    		 if(bookingRecTypeList!=null  && bookingRecTypeList.size() >0){
					String recTypeId = bookingRecTypeList[0].id;
					 	
					//Get the field describe values for Contact lookup from reservation object.
			    	Schema.DescribeFieldResult contactDesc = Schema.sObjectType.Lead__c.fields.Relcontact__c;
			    	Schema.DescribeFieldResult accDesc = Schema.sObjectType.Lead__c.fields.refAccount__c;
			    	Schema.DescribeFieldResult phoneDesc = Schema.sObjectType.Lead__c.fields.ContactPhone__c;
					
					// 2015/10/08 CarNo Search Function add BEGIN
					Schema.DescribeFieldResult carNoDesc = null;
					if (!CommUtils.isBlank(comDef.CTICarAPIName__c)) {
						Map<String, Schema.SObjectField> objectFields = Schema.sObjectType.Contact.fields.getMap();
						String carApiName = CommUtils.nullToBlank(comDef.CTICarAPIName__c);
						if (objectFields.containsKey(carApiName)) {
							carNoDesc = objectFields.get(carApiName).getDescribe();
						}
					}
					// 2015/10/08 CarNo Search Function add END
					
				    ///Get the page reference for Lead__c object
					PageReference p = new PageReference('/' + Lead__c.SObjectType.getDescribe().getKeyPrefix() + '/e?nooverride=1&RecordType='+recTypeId);
					System.debug('P:: '+p);
					String html = p.getContent().toString();
					System.debug('html :: '+html );
					Map<String, String> labelToId = new Map<String, String>();
					// 2016/09/22 SalesforceのVersionUpにより、項目HTMLのIDの検索機能不具合改修 BEGIN
					//Matcher m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(.*?)</label>').matcher(html);
					Matcher m = Pattern.compile('<label for="(.*?)">(<span class="assistiveText">\\*</span>)?(.*?)</label>').matcher(html);
					// 2016/09/22 SalesforceのVersionUpにより、項目HTMLのIDの検索機能不具合改修 END
					while (m.find()) {
					   String label = m.group(3);
					    String id = m.group(1);
					    labelToId.put(label, id);
					}
					
					resRefMap.put('contRef', labelToId.get(contactDesc.getLabel()));
					resRefMap.put('accRef', labelToId.get(accDesc.getLabel()));
					resRefMap.put('phoneRef', labelToId.get(phoneDesc.getLabel()));
					// 2015/10/08 CarNo Search Function add BEGIN
					if (carNoDesc != null) {
						p = new PageReference('/003/e');
						String conHtml = p.getContent().toString();
						Map<String, String> conlabelToId = new Map<String, String>();
						// 2016/09/22 SalesforceのVersionUpにより、項目HTMLのIDの検索機能不具合改修 BEGIN
						//m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?('+carNoDesc.getLabel()+')</label>').matcher(conHtml);
						m = Pattern.compile('<label for="(.*?)">(<span class="assistiveText">\\*</span>)?('+carNoDesc.getLabel()+')</label>').matcher(conHtml);
						// 2016/09/22 SalesforceのVersionUpにより、項目HTMLのIDの検索機能不具合改修 END
						while (m.find()) {
							String label = m.group(3);
							String id = m.group(1);
							conlabelToId.put(label, id);
						}
						comDef.ResCarNoRef__c = conlabelToId.get(carNoDesc.getLabel());
					} else {
						comDef.ResCarNoRef__c = null;
					}
					// 2015/10/08 CarNo Search Function add END
					System.debug('resRefMap:: '+resRefMap);
    		 }
    	}catch(Exception e){
    		System.debug('Error occured while getting Contact reference from lead__c object '+e);
    	}
    	return resRefMap;
    	
    }
    // 2016/04/14 CarNo Find SOSL Bug Fix BEGIN
    @TestVisible private static Boolean isContains(String src, String key) {
    	// 複数車情報は項目に格納する場合、一回改行分割する
    	if (!src.contains(key)) return false;
    	String[] srcLines = src.split('\n');
    	//該当文字列から同じキーワードを検索して、
    	for (String s : srcLines) {
			Integer ps = s.indexOfIgnoreCase(key);
			if (ps < 0) continue;
			String midStr = s.substring(ps);
			// CTIの車Noは登録されると、
			//String rs = midStr.substringBefore(' ');
			String rs = CommUtils.nullToBlank(midStr.substringBefore(' '));
			if (rs == key) return true;
			else {
				String nextSrc = midStr.substring(rs.length());
				if (nextSrc.contains(key)) return isContains(nextSrc, key);
			}
    	}
    	return false;
    }
    // 2016/04/14 CarNo Find SOSL Bug Fix END
    /**
    * Search Contacts with matching phoneNumber and order by lastModified
    * Contact which is latest modified is attached with the call information
    */
    static List<Contact> searchContact(String phoneNumber, String noType){
        system.debug('phoneNumber: '+phoneNumber);
        String searchString = phoneNumber;
		// 2015/10/08 CarNo Search Function add BEGIN
        List<List<Sobject>> searchResults = null;
        if (noType == CarNoKey) {
        	// 2016/04/13 CarNo Find SOSL Bug Fix BEGIN
        	CommDefine__c commDef = CommDefine__c.getInstance();
            //searchResults = [FIND :searchString  IN ALL FIELDS RETURNING Contact (Name,Account.Name,AccountId,Id  ORDER BY LastModifiedDate DESC)];
        	String queryStr = 'FIND :searchString  IN ALL FIELDS RETURNING Contact (Name,Account.Name,AccountId,Id,'+ commDef.CTICarAPIName__c + ' ORDER BY LastModifiedDate DESC)';
        	// 2017/12/16 「CTICarAPIName__c」未定義問題回避 BEGIN
        	if (!CommUtils.isBlank(commDef.CTICarAPIName__c)) {
        	   searchResults = search.query(queryStr);
        	} else {
        	    searchResults = new List<List<Sobject>>();
        	    searchResults.add(new List<Contact>());
        	}
        	// 2017/12/16 「CTICarAPIName__c」未定義問題回避 END
        	// 戻る結果項目に、車情報は含めて確認する
        	List<Contact> contactList = (List<Contact>)searchResults[0];
        	List<Contact> resContactList = new List<Contact>();
        	for (Contact con : contactList) {
        		String carinfo = CommUtils.nullToBlank(con.get(commDef.CTICarAPIName__c));
        		//if (carInfo.contains(searchString)) {
                if (isContains(carinfo, searchString)) {
        			resContactList.add(con);
        		}
        	}
        	return resContactList;
        	// 2016/04/13 CarNo Find SOSL Bug Fix END
        }
        // 2015/10/08 CarNo Search Function add END
        else {
        	// 2016/09/17 取引先の電話番号からお客様とご予約情報を検索できる機能対応 BEGIN
            //searchResults = [FIND :searchString  IN Phone FIELDS RETURNING Contact (Name,Account.Name,AccountId,Id  ORDER BY LastModifiedDate DESC)];
            // お客様、取引先様は同時に電話番号項目情報を検索する
            searchResults = [FIND :searchString  IN Phone FIELDS RETURNING Contact (Name,Account.Name,AccountId,Id  ORDER BY LastModifiedDate DESC), Account(Name,Id ORDER BY LastModifiedDate DESC)];
            if (searchResults[0].isEmpty() && !searchResults[1].isEmpty()) {
            	// 取引先IDを取得する
            	Account acc = (Account)searchResults[1][0];
            	// 取引先からお客様情報を検索を行う
            	List<Contact> clst = [select name,account.Name,accountId,id from contact where AccountId = :acc.Id Order by LastModifiedDate DESC];
            	if (!clst.isEmpty()) {
            		searchResults[0] = clst;
            	} else {
            		// 取引先のみ、情報をCTI画面に表示を行う
            		Contact c = new Contact(
            			AccountId = acc.Id,
            			Account = acc
            		);
            		searchResults[0] = new list<sobject>{c};
            	}
            }
            // 2016/09/17 取引先の電話番号からお客様とご予約情報を検索できる機能対応 END
        }

        List<Contact> contactList = (List<Contact>)searchResults[0];
        if(!contactList.isEmpty()){
            return contactList;
        }
        return null;
    }
    // 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz BEGIN
    static String searchLead(Id contactId){
    	// RECAIUS機能統合
    	Date nowDt = Date.today();
    	Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		String apiStr ='';
		String labelStr = Label.MSG_045_0002_1;
		set<String> apiset = CommLogicProcess.parseFieldByLable(labelStr);
		if (apiset.isEmpty()) return '';
		set<String> wkapiset = new set<String>();
		for (String wkapi : apiset){
			String lowerApi = wkapi.toLowerCase();
			if(lowerApi == 'relcontact__r.name') { if (!wkapiset.contains('relcontact__r.katakana__c')) wkapiset.add('relcontact__r.katakana__c');}
			wkapiset.add(lowerApi);
		}
		for (String api : wkapiset){ apiStr += (CommUtils.isBlank(apiStr) ? '' : ',') + api;}
		// 检索予约数据
		String leadQuery = 'select '+ apiStr +' from Lead__c where  Relcontact__c =: contactId And CancelBool__c != :cancelFlg And DAY_ONLY(convertTimezone(EntryTime__c)) >= :nowDt  Order By EntryTime__c asc limit 1';
		List<Lead__c> leadlst = null;
		try{
			leadlst = Database.query(leadQuery);
		} catch(Exception e){return '';}
		if(leadlst.isEmpty()){ return '';}
	    for (String Str : apiset){
	    	String fieldVal = CommUtils.nullToBlank(CommUtils.getFielValue(leadlst[0],Str));
	    	if(Str.toLowerCase() == 'relcontact__r.name'){
	    		String fieldkana = CommUtils.nullToBlank(CommUtils.getFielValue(leadlst[0],'relcontact__r.katakana__c'));
	    		if(!CommUtils.isBlank(fieldkana)) fieldVal = fieldkana;
	    	}
	    	labelStr = labelStr.Replace('{@' +Str+'}' ,fieldVal);
	    }
		return labelStr;
    }
    // 2017/12/07 車ナンバーの通知メッセージは自由にカスタマイズできるように改善対応 zyz END
    /**
    * Search Accounts with matching phoneNumber and order by lastModified
    * Account which is latest modified is attached with the call information
    */
    static List<Account> searchAccount(String phoneNumber, String noType){
        system.debug('phoneNumber: '+phoneNumber);
        String searchString = phoneNumber;
		// 2015/10/08 CarNo Search Function add BEGIN
        List<List<Sobject>> searchResults = null;
        if (noType == CarNoKey) {
        	// 2016/04/13 CarNo Find SOSL Bug Fix BEGIN
        	CommDefine__c commDef = CommDefine__c.getInstance();
            //searchResults = [FIND :searchString  IN ALL FIELDS RETURNING Account (Name, Id  ORDER BY LastModifiedDate DESC)];
            String queryStr = 'FIND :searchString  IN ALL FIELDS RETURNING Account (Name, Id, '+ commDef.CTICarAPIName__c  +' ORDER BY LastModifiedDate DESC)';
        	// 2017/12/16 「CTICarAPIName__c」未定義問題回避 BEGIN
            if (!CommUtils.isBlank(commDef.CTICarAPIName__c)) {
                searchResults = search.query(queryStr);
            } else {
                searchResults = new List<List<Sobject>>();
                searchResults.add(new List<Account>());
            }
        	// 2017/12/16 「CTICarAPIName__c」未定義問題回避 END
        	// 戻る結果項目に、車情報は含めて確認する
        	List<Account> accountList = (List<Account>)searchResults[0];
        	List<Account> resAccountList = new List<Account>();
        	for (Account acc : accountList) {
        		String carinfo = CommUtils.nullToBlank(acc.get(commDef.CTICarAPIName__c));
			//if (carinfo.contains(searchString)) {
        		if (isContains(carinfo, searchString)) {
        			resAccountList.add(acc);
        		}
        	}
        	return resAccountList;
        	// 2016/04/13 CarNo Find SOSL Bug Fix END
        }
        // 2015/10/08 CarNo Search Function add END
        else {
            searchResults = [FIND :searchString  IN Phone FIELDS RETURNING Account (Name, Id  ORDER BY LastModifiedDate DESC)];
        }

        List<Account> accountList = (List<Account>)searchResults[0];
        if(!accountList.isEmpty()){
            return accountList;
        }
        return null;
    }
    
    /**
    * If user has lowered the maxRecords_DB value then delete the remaining records from call information object 
    * to make records in object same as maxRecords_DB value
    */
    private static void deleteOldCallRecords(Integer maxDBRecords, List<Call_Information__c> callInformationList){
        List<Call_Information__c> toDeleteCall = new List<Call_Information__c>();
        Integer numberOfRecordsToBeDeleted = callInformationList.size() - maxDBRecords;
        system.debug('Number of Calls to be Deleted: '+numberOfRecordsToBeDeleted);
        if(callInformationList.size() > maxDBRecords){
            for(Integer i = 0; i < numberOfRecordsToBeDeleted; i++){
                toDeleteCall.add(callInformationList[i]);
            }
            for(Integer i = numberOfRecordsToBeDeleted - 1; i >= 0; i--){
                callInformationList.remove(i);
            }
            delete toDeleteCall;
        }
    }
    
    /**
    * This wrapper is used to send information to the web service in Salesforce
    */
    global class CallInformation{
        webservice String sno{get;set;}
        webservice string nam{get;set;}
        webservice String lno{get;set;}
        webservice String ctm{get;set;}
        webservice String cdt{get;set;}
        webservice boolean rsnp{get;set;}
        webservice String  rsnCode{get;set;}
        webservice boolean dcd1{get;set;}
        webservice String dt0{get;set;}
        webservice String dt1{get;set;}
        webservice String dt4{get;set;}
        webservice String dno{get;set;}
    }
    
    /**
    * This wrapper is used to send result from web service
    */
    global class CallInformationSyncResult{
        webservice Id sfdcId{get;set;}
        webservice boolean isSuccess{get;set;}
        webservice string errorMessage{get;set;}
        
        /**
        * Create success instance
        */
        CallInformationSyncResult(Id sfdcId){
            this.sfdcId = sfdcId;
            isSuccess = true;
        }
        
        /**
        * Create error instance
        */
        CallInformationSyncResult(String errorMessage){
            this.errorMessage = errorMessage;
            isSuccess = false;
        }
    }
    
   /**
    * This web service is used to check whether Call Information popup is 
    * enabled for current user
    */
    webservice static UserPrefValue  getUserPreference(){
        UserPrefValue  uValue = new UserPrefValue();
        List<User> lstUser = [Select Id, isCallInformationEnabled__c, CTIDNO__c,IsNotCallCarInformation__c,IsNotCallPhoneInformation__c,IsNotNotifyIotInfomation__c
                from User where Id = :Userinfo.getUserId()];
        if(lstUser != null && lstUser.size() == 1){
            uValue.isEnabledForUser = lstUser[0].isCallInformationEnabled__c;
            uValue.acceptDno = CommUtils.nullToBlank(lstUser[0].CTIDNO__c);
            uValue.isNotCallCarInformation = lstUser[0].IsNotCallCarInformation__c;
            uValue.isNotCallPhoneInformation = lstUser[0].IsNotCallPhoneInformation__c;
            uValue.isNotNotifyIotInfomation = lstUser[0].IsNotNotifyIotInfomation__c;
        }
        CommDefine__c commDef = CommDefine__c.getInstance();
        
        if(commDef != null && commDef.maxrecords_DSP__c != null){
            uValue.numberOfDisplayRec = Integer.valueOf(commDef.maxrecords_DSP__c);
            if(commDef.maxrecords_DB__c != null && commDef.maxrecords_DB__c < uValue.numberOfDisplayRec){
                uValue.numberOfDisplayRec = Integer.valueOf(commDef.maxrecords_DB__c);
            } 
        }
		/* 1. Find if the screen is alarm popup window or sticky window.
		   2. Assign the screen name.*/
        String screenName = '';
        if(commDef.CTI_type_window__c == 1){
            uValue.isStickyPopup = true;
            screenName = 'callinfostickywindow';
        }
        else if(commDef.CTI_type_window__c == 2){
            uValue.isAlarmPopup = true;
            screenName = 'alarmpopupwindow';
        }
        System.debug('CallInformationSync commDef.CTI_type_window__c '+commDef.CTI_type_window__c + 'screenName::  '+screenName);
        if (commDef.CTI_Call_Columns_xml_Name__c != null && commDef.CTI_Call_Columns_xml_Name__c != 'CTI Call Columns xml'){
        	System.debug('In if CallInformationSync');
			/* Get the screens node.*/
			DOM.XMLNode screenNode = DomXmlUtil.getXMLNodeByName(commDef.CTI_Call_Columns_xml_Name__c, screenName);
			if(screenNode != null){
				/*Get the width and size of the screen. */
				Integer[] sizing = DomXmlUtil.getSizing(screenNode);
				if(sizing[0] != 0 ){
					uValue.windowWidth = sizing[0]; 
				}
				
				if(sizing[1] != 0 ){
					uValue.windowHeight = sizing[1];
				}
			}
        }
        return uValue;
    }
    
    global class UserPrefValue{
    	
        webservice boolean isEnabledForUser{get;set;}   
        webservice Integer numberOfDisplayRec{get;set;}
        webservice boolean isAlarmPopup{get;set;}
        webservice boolean isStickyPopup{get;set;}
        webservice Integer windowWidth{get;set;}
        webservice Integer windowHeight{get;set;}
        webservice String  acceptDno{get;set;} // 2014/11/20 CTIのダイヤルイン番号情報、
        webservice boolean isNotCallCarInformation{get;set;}	// 2016/10/25 自動車ナンバーのポップアップと電話のポップアップをユーザー毎にするかしないかの設定を分離対応
        webservice boolean isNotCallPhoneInformation{get;set;}	// 2016/10/25 自動車ナンバーのポップアップと電話のポップアップをユーザー毎にするかしないかの設定を分離対応
        webservice boolean isNotNotifyIotInfomation{get;set;}	// 2016/10/25 自動車ナンバーのポップアップと電話のポップアップをユーザー毎にするかしないかの設定を分離対応
        UserPrefValue(){
            isEnabledForUser = false;
            numberOfDisplayRec = 6;
            isAlarmPopup = false;
            isStickyPopup = false;
            windowWidth = 350;
            isNotCallCarInformation = false;
            isNotCallPhoneInformation = false;
            isNotNotifyIotInfomation = false;
        }
    }
}