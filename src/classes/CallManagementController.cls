/*
 * @Author: persistent systems ltd.
 * @Date: August 26, 2013
 * @Description: Controller class for call management page
 */
global with sharing class CallManagementController {
    
    /**
    * List of Call Information to be shown on call popup
    */
    public transient list<Call_information__c> lstCallInfo{get;set;}
    
    /**
    * Salesforce base url
    */
    public transient String baseURL{get;set;}
    
    /**
    * Offset between GMT and Current User timezone
    */
    public transient Integer timeZoneGMTOffset{get;set;}
    
    /**
    * Store whether Call Information Popup is enabled for current user
    */
    public boolean isEnabledForUser{get;set;}
    
    /**
    * Current Session Id
    */
    public transient string sessionId{get;set;}
    
    /**
    * Stores number of records to be displayed on call popup
    */
    public Integer numberOfDispRec{get;set;}
    
    public CallInformationSync.UserPrefValue userPrefValue{get;set;}
    
    //public  boolean isAlarmOpened{get;set;}
	
	public  boolean openAlarmPopup{get;set;}
    public integer callInforRowCount{get;set;} 
    
    public transient list<RowInfo> callList{get;set;}
    
    public transient List<String> otherHeaders{get;set;}
	public transient string otherColumnData{get;set;}
    public transient string sno{get;set;}
     
	public string contactQuery{get;set;}
	public string accountQuery{get;set;}    
    Map<String,Id> recTypeNameObjIdMap = new Map<String,Id>();
    Map<String,String> sobjPrefixMap = new Map<String,String>();
    List<XMLField> xmlFields = new List<XMLField>();
    Map<String,String> objectAPIContactFieldIdMap = new Map<String,String>();
    // 2015/10/08 CarNo Search Function add BEGIN
    public String PhoneTypeKey{get{return CallInformationSync.PhoneKey;}}
    public String CarTypeKey{get{return CallInformationSync.CarNoKey;}}
    public String IotTypeKey{get{return IOTInformationSync.IotKey;}}
    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
    public String CoTypeKey{get{return LeadTriggerProcess.CoKey;}}
    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
    public String CiTypeKey{get{return LeadTriggerProcess.CiKey;}}
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
    // 2015/10/08 CarNo Search Function add END
    /**
    * Constructor
    */
    public CallManagementController(){
        /**
        * Default records to be displayed if custom setting does not have any value
        */
        numberOfDispRec = 6;
        baseURL = Url.getSalesforceBaseUrl().toExternalForm();
        timeZoneGMTOffset = getGMTTimeZoneOffset();
        timeZoneGMTOffset  = timeZoneGMTOffset  /1000;
        userPrefValue = (CallInformationSync.getUserPreference());
        isEnabledForUser = userPrefValue.isEnabledForUser;
        numberOfDispRec = userPrefValue.numberOfDisplayRec;
        sessionId = userinfo.getSessionId();
        generateCallInfoList();
        otherColumnData = '{}';
    }
    
    /**
    * Calcualte Offset between GMT and Current Logged in user timezone
    */
    private Integer getGMTTimeZoneOffset(){
        TimeZone tz = UserInfo.getTimeZone();
        System.debug('ID: ' + tz.getID());
        return tz.getOffset(system.now());
    }
    
    /**
    * Function to get call details and limiting it to the number of records to be displayed
    */
    public void generateCallInfoList(){
        
		try{
        lstCallInfo = [Select Id,isRSNP__c, Time__c,isDCD1__c, SNO__c, 
                          NAM__c, LNO__c, DT4__c, DT1__c, DT0__c, 
                          Call_Time__c,Account__c,Contact__c, 
                          Contact__r.Id, Contact__r.Name, 
                          Account__r.Name, Account__r.Id,
    					  No_of_Matching_Customers__c,
    					  RSN_Code__c
    					  // 2015/10/08 CarNo Search Function add BEGIN
                          ,CallType__c, CarModel__c, CarColor__c, ImgHex64Info__c
    					  // 2015/10/08 CarNo Search Function add END
                    from Call_information__c 
                    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
                    //where CallType__c != :IotTypeKey
                    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
                    // where CallType__c != :IotTypeKey AND CallType__c != :CoTypeKey
                    where CallType__c != :IotTypeKey AND CallType__c != :CoTypeKey AND CallType__c != :CiTypeKey
                    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
                    // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
                    order BY Call_Time__c DESC, LastModifiedDate DESC, Id Desc 
                    limit: numberOfDispRec];
    
			Set<Id> contactIds = new Set<Id>();
			Set<Id> accountIds = new Set<Id>();
			
        if(lstCallInfo != null && lstCallInfo.size() > 0){
            for(Call_information__c callInformation: lstCallInfo){
                if(callInformation.Call_Time__c != null){
                    callInformation.Time__c = callInformation.Call_Time__c.format('MM/dd/YYYY HH:mm:ss');
                }
					if(callInformation.Contact__c != null){
						contactIds.add(callInformation.Contact__c);
					}
					if(callInformation.Account__c != null){
						accountIds.add(callInformation.Account__c);
					}
				}	
			}
        
			/*XMLField f = new XMLField();
			f.labelAPIName = 'Lead__c.Name:ご予約';
			f.DefaultLayout = 'Lead__c-BookingRecType';
			f.latestCheckInDate = 'Contact&reservetg85__r.EntryTime__c';
			f.latestCheckInTime = 'Contact&reservetg85__r.Field4__c';
			xmlFields.add(f);
			
			f = new XMLField();
			f.labelAPIName = 'LeadIndex__c.Name:一括予約';
			f.pageLayout = 'BookingApp';
			f.latestCheckInDate = 'Contact&IndexContactRef__r.EntryDate__c';
			f.latestCheckInTime = 'Contact&IndexContactRef__r.EntryTime__c';
			xmlFields.add(f);
			
			f = new XMLField();
			f.labelAPIName = 'Contact.Usage_Count__c:ご利用回数';
			xmlFields.add(f);
			
			f = new XMLField();
			f.labelAPIName = 'Contact.Account.AccountType__c:取引先種別';
			xmlFields.add(f);
			*/
			
			/** 
			* Read fields from xml file uploaded in document
			*/
			
			CommDefine__c commDef = CommDefine__c.getInstance();
			//System.debug('Get field values for commDef.ResContRef__c:: '+commDef.ResContRef__c+'  CommDef.ResAccRef__c:: '+commDef.ResAccRef__c +'  commDef.ResPhoneRef__c  :: '+commDef.ResPhoneRef__c);
			
			xmlFields = getXMLFieldInfo(commDef.CTI_type_window__c, commDef.CTI_Call_Columns_xml_Name__c);
			
			// Headers label to be shown on page
			otherHeaders = new List<String>();
			
			/**
			* Dynamic query which gets created using xml fields
			*/
			contactQuery = 'select id, ';
			accountQuery = 'select id, ';
        
			
			boolean performAccountQuery = false;
			boolean performContactQuery = false;
			
			// Record Type name is stored here which is used to query record type id
			Set<String> recordTypeNameSet = new Set<String>();
			
			// Record Type sobject type is store which is used to query recordtype
			Set<String> recordTypeSobjSet = new Set<String>();
        
        	String addLeadFields = ',';
        	String addLeadIndexFields = ',';
        	
			/**
        	* Iterate through all the xml fields and create dynamic query to fetch information to be shown on page
        	*/
			for(XMLField field: xmlFields){
			
				system.debug('field: '+field);
			
				String query = '';            
				
				String columnLabel = '';
				
				if(field.defaultLayout != null && field.defaultLayout != ''){
					
					String sObj = field.defaultLayout.SubstringBefore('-');
					String apiname = field.latestCheckInDate.SubstringBetween('-','.');
					String dateOrderField = field.latestCheckInDate.SubstringAfter('.');
					String timeOrderField = field.latestCheckInTime.SubstringAfter('.');
					String nameField = field.labelAPIName.SubstringBetween('.',':');
					columnLabel = field.labelAPIName.SubstringAfter(':');
					query += '( select id, '+ nameField+' from '+apiname;
					String recordTypeName = field.defaultLayout.SubstringAfter('-');
					system.debug('recordTypeName: '+recordTypeName);
					query += ' where recordType.DeveloperName = \''+recordTypeName +'\'';
					recordTypeNameSet.add(recordTypeName);
					recordTypeSobjSet.add(sObj);
					system.debug('apiname: '+apiname);
					
					/*Filter confition.*/
					if(field.filter != null && field.filter != ''){
						if(query.contains(' where ')){
							query += '  and ';
						}
						else{ 
							query += ' where ';
						}
						query += field.filter;
					}
					
					query += ' order by ' + dateOrderField + ' desc, ' + timeOrderField + ' desc, name desc limit 1),';
					objectAPIContactFieldIdMap.put(apiname,null);
				}
			    else if(field.pageLayout  != null && field.pageLayout != ''){
					String apiname = field.latestCheckInDate.SubstringBetween('-','.');
					String dateOrderField = field.latestCheckInDate.SubstringAfter('.');
					String timeOrderField = field.latestCheckInTime.SubstringAfter('.');
					String nameField = field.labelAPIName.SubstringBetween('.',':');
					columnLabel = field.labelAPIName.SubstringAfter(':');
					query += '( select id, '+nameField+' from '+apiName;
					/* Add filter condition*/
					if(field.filter != null && field.filter != ''){
						if(query.contains(' where ')){
							query += '  and ';
						}
						else{ 
							query += ' where ';
						}
						query += field.filter;
					}
					
					query += ' order by ' + dateOrderField + ' desc, ' + timeOrderField + ' desc, name desc limit 1),';
				}
				else{
					String fieldToQuery = field.labelAPIName.SubstringBetween('.',':');
					columnLabel = field.labelAPIName.SubstringAfter(':');
					query += fieldToQuery+',';
					
					/*Get additional field names for Lead__c and LeadIndex__c objects. */	
					if(field.labelAPIName.StartsWith('Lead__c.')){
						addLeadFields = addLeadFields + fieldToQuery +',' ;
					}else if(field.labelAPIName.StartsWith('LeadIndex__c.')){
						addLeadIndexFields = addLeadIndexFields + fieldToQuery + ',' ;
					}
				}
				if(field.labelAPIName.StartsWith('Contact.') || (field.latestCheckInDate != null && field.latestCheckInDate.StartsWith('Contact-'))){
					contactQuery +=  query;
					performContactQuery = true;
				}
				else if(field.labelAPIName.StartsWith('Account.') || (field.latestCheckInDate != null && field.latestCheckInDate.StartsWith('Account-'))){
					accountQuery +=  query;
					performAccountQuery = true;
				}
				otherHeaders.add(columnLabel);
			}
			contactQuery = contactQuery.removeEnd(',');
			contactQuery += ',Account.name, name from contact where id in: contactIds';
			
			
			accountQuery = accountQuery.removeEnd(',');
			accountQuery += ',name from Account where id in: accountIds';
        
        
        	addLeadFields = addLeadFields.removeEnd(',');
        	addLeadIndexFields = addLeadIndexFields.removeEnd(',');
        	
        	/* Adding additionl columns related to Lead__c in contact query*/
        	if(contactQuery.indexOf('reservetg85__r') !=-1 &&  !String.isEmpty(addLeadFields.trim())){
        		System.debug('***********'+ contactQuery.indexOf('reservetg85__r'));
				integer ldindx = contactQuery.substring(0, contactQuery.indexOf('reservetg85__r')).lastIndexOf('from');
				System.debug('ldindx = '+ldindx);
				contactQuery  = contactQuery.subString(0, ldindx) + addLeadFields + ' ' + contactQuery.subString( ldindx, contactQuery.length());
				System.debug ('contactQuery for Lead__c'+ contactQuery);
        	}
        	
        	/* Adding additionl columns related to LeadIndex__c in contact query*/
        	if(contactQuery.indexOf('IndexContactRef__r') !=-1 && !String.isEmpty(addLeadIndexFields.trim())){
        		System.debug('***********'+ contactQuery.indexOf('IndexContactRef__r'));
				integer icindx = contactQuery.substring(0, contactQuery.indexOf('IndexContactRef__r')).lastIndexOf('from');
				System.debug('icindx  = '+icindx );
				contactQuery  = contactQuery.subString(0, icindx ) + addLeadIndexFields + ' ' + contactQuery.subString( icindx , contactQuery.length());
				System.debug ('contactQuery for LeadIndex__c'+ contactQuery);
        	}
        	
        	
			system.debug('contactQuery: '+contactQuery);
			
			Map<Id,Contact> contactsMap = New Map<Id,Contact>();
			if(performContactQuery){
				contactsMap = New Map<Id,Contact>((List<Contact>)Database.query(contactQuery));
            }
			else{
				contactQuery = '';
			}

			system.debug('accountQuery: '+accountQuery);
			Map<Id,Account> accountsMap = New Map<Id,Account>();
			if(performAccountQuery){
				accountsMap = New Map<Id,Account>((List<Account>)Database.query(accountQuery));
        	}
			else{
				accountQuery = '';
    		}
    
			system.debug('recordTypeSobjSet:'+recordTypeSobjSet);
			system.debug('recordTypeNameSet:'+recordTypeNameSet);
			
			List<RecordType> recordTypeList = [select id,DeveloperName, SobjectType 
											   from recordType 
											   where DeveloperName in:recordTypeNameSet 
													 and SobjectType in:recordTypeSobjSet];

			for(RecordType recType: recordTypeList){
				recTypeNameObjIdMap.put(recType.SobjectType+'-'+recType.DeveloperName,recType.Id);        	
			}
			
			Map<String, Schema.SObjectType> globalDescribeResult = Schema.getGlobalDescribe();
			for(String sObj: recordTypeSobjSet){
				if(globalDescribeResult.containsKey(sObj)){
					sobjPrefixMap.put(sObj, globalDescribeResult.get(sObj).getDescribe().getKeyPrefix());
				}
			}
					 
			callList = new List<RowInfo>();
			
			if(lstCallInfo != null && lstCallInfo.size() > 0){
				
				for(Call_information__c callInformation: lstCallInfo){
					RowInfo info = new RowInfo(callInformation);
					Account acc;
					Contact con;
					if(callInformation.Contact__c != null && contactsMap.containsKey(callInformation.Contact__c)){
						con = contactsMap.get(callInformation.Contact__c);
					}
					if(callInformation.Account__c != null && accountsMap.containsKey(callInformation.Account__c)){
						acc = accountsMap.get(callInformation.Account__c);
					}
				
					if(!callInformation.isRSNP__c){
						//info.otherColumns = createOtherColumns(acc,con,callInformation.isDCD1__c);
						info.otherColumns = createOtherColumns(acc,con,callInformation.isDCD1__c, callInformation.SNO__c, commDef.ResContRef__c, commDef.ResAccRef__c, commDef.ResPhoneRef__c);
					}
					else{
						info.otherColumns = new List<ColumnInfo>();
						for(XMLField field: xmlFields){
							info.otherColumns.add(new ColumnInfo());
						}
					}
					callList.add(info);
				}
			}
		}
		catch(Exception ex){
			ApexPages.addMessages(ex);
		}
    }
    
    private List<ColumnInfo> createOtherColumns(Account account, Contact contact,boolean isDCD1, String phoneNumber, String resContactReference, String resAccountReference, String resPhoneReference){
		List<ColumnInfo> cInfoList = new List<ColumnInfo>();
    	try{
			for(XMLField field: xmlFields){
				Sobject parentObj;
            	ColumnInfo cInfo = new ColumnInfo();
            	
            	boolean isRelatedToContact = false;
				//if((field.labelAPIName.StartsWith('Contact.') || (field.latestCheckInDate != null && field.latestCheckInDate.StartsWith('Contact-')))){
				if((field.labelAPIName.StartsWith('Contact.') || field.labelAPIName.StartsWith('Lead__c') || field.labelAPIName.StartsWith('LeadIndex__c') || (field.latestCheckInDate != null && field.latestCheckInDate.StartsWith('Contact-')))){
	            	parentObj = contact;
	            	isRelatedToContact = true;
	            }
	            else if(field.labelAPIName.StartsWith('Account.') || (field.latestCheckInDate != null && field.latestCheckInDate.StartsWith('Account-'))){
	            	parentObj = account; 
	            	isRelatedToContact = false;
	            }
        		system.debug('field: '+field + 'parentObject: '+parentObj + 'isRelatedToContact '+isRelatedToContact );
        		if(field.defaultLayout != null && field.defaultLayout != ''){
                    cInfo.isLink = true;
                    String apiname = field.latestCheckInDate.SubstringBetween('-','.');
	                String nameField = field.labelAPIName.SubstringBetween('.',':');
                    boolean createNewLink = false;
                    String sObj = field.defaultLayout.SubstringBefore('-');
                    if(parentObj != null){
	                	List<Sobject> child = parentObj.getSObjects(apiname);
	                	system.debug('child: '+child);
	                    if(child != null && child.size() > 0){
	                        cInfo.link = '/'+child[0].Id;
	                        cInfo.text = child[0].get(nameField)+'';
	                    }
	                    else {
	                    	createNewLink = true;
	                    }
                    }
                    /*else{
                    	createNewLink = true;
                    }*/
                    if(createNewLink && ((isRelatedToContact && !isDCD1) || (!isRelatedToContact  && isDCD1))){
                    	cInfo.link = '/'+sobjPrefixMap.get(sObj)+'/e?'+ ((recTypeNameObjIdMap.containsKey(field.defaultLayout) ? 'RecordType='+recTypeNameObjIdMap.get(field.defaultLayout):''))+'&Name='+(contact!=null ? contact.name: '')+'&'+resContactReference+'='+(contact!= null ? contact.Name : '')+'&'+resAccountReference+'='+((contact!= null && contact.Account!= null) ? contact.Account.Name : '')+'&'+resPhoneReference+'='+phoneNumber;
                    	//cInfo.link = '/'+sobjPrefixMap.get(sObj)+'/e?'+ (recTypeNameObjIdMap.containsKey(field.defaultLayout) ? 'RecordType='+recTypeNameObjIdMap.get(field.defaultLayout):'');
                    	/*String fieldId = objectAPIContactFieldIdMap.get(apiname.tolowercase());
						if(parentObj != null){
							cInfo.link += '&'+field.parentFieldId+'_lkid='+parentObj.Id+'&'+field.parentFieldId+'='+parentObj.get('Name')+'&Name='+parentObj.get('Name');
                    	}*/
                    	cInfo.text = 'Create New';
                    }
                }        
                else if(field.pageLayout != null && field.pageLayout != ''){
                    cInfo.isLink = true;
                    boolean createNewLink = false;
                    String apiname = field.latestCheckInDate.SubstringBetween('-','.');
	                String nameField = field.labelAPIName.SubstringBetween('.',':');
                    if(parentObj != null){
                        List<Sobject> child = parentObj.getSObjects(apiname);
                        system.debug('child: '+child);
                        if(child != null && child.size() > 0){
                            cInfo.link = '/apex/'+field.pageLayout+'?id='+child[0].Id;
                            cInfo.text = child[0].get(nameField)+'';
                        }
                        else{
                         	createNewLink = true;
                     	}
                    }
                    /*else{
                    	createNewLink = true;
                    }*/
					if(createNewLink && ((isRelatedToContact && !isDCD1) || (!isRelatedToContact  && isDCD1))){
						// 2016/12/27  CTI予約 BEGIN zyz
						cInfo.link = '/apex/'+field.pageLayout+'?contactid='+contact.Id +'&contactnm='+(contact!=null ? contact.name: '');
						//cInfo.link = '/apex/'+field.pageLayout+'?contactid='+contact.Id;
						// 2016/12/27  CTI予約 BEGIN zyz
						//cInfo.link = '/apex/'+field.pageLayout;
                 		/*if(parentObj != null){
							cInfo.link  += ('?'+ ((parentobj instanceof contact)? 'contactId=' : 'accountId=' ) + parentObj.Id);
                 		}*/
                        cInfo.text = 'Create New';
                 	}
                }else if(field.labelAPIName.StartsWith('Lead__c') || field.labelAPIName.StartsWith('LeadIndex__c')){
                	String apiName = field.labelAPIName.SubstringBetween('.',':');
                	String refName = field.labelAPIName.StartsWith('Lead__c') ? 'reservetg85__r' : ((field.labelAPIName.StartsWith('LeadIndex__c') ? 'IndexContactRef__r' : ''));
                	//System.debug('apiName :: '+apiName);
                	//System.debug('refName :: '+refName);
                	//System.debug('parentObj :: '+parentObj);
                	if(apiName != '' && parentObj!=null){
                		List<Sobject> child = parentObj.getSObjects(refName);
                    	//system.debug('child *** : '+child);
                    	if(child != null && child.size() > 0){
                            cInfo.text = child[0].get(apiName)+'';
                            if(cInfo.text == null || cInfo.text == 'null'){
                            	cInfo.text = '';
                            }
                    	}
                	}
                	
                }
                else {
                	if(parentObj != null){
                		String apiName = field.labelAPIName.SubstringBetween('.',':');
                		if(apiName.contains('.')){
                			String refObj = apiName.SubstringBefore('.');
                			apiName = apiName.SubstringAfter('.');
                			parentObj = parentObj.getSobject(refObj);
                		}
                		cInfo.text = (parentObj != null && parentObj.get(apiName) != null)? parentObj.get(apiName)+'' : '';
                		if(cInfo.text == null || cInfo.text == 'null'){
                        	cInfo.text = '';
                        }
                	}
                }
				cInfoList.add(cInfo);   
			}
		}
    	catch(Exception ex){
    		ApexPages.addMessage(new ApexPages.Message(ApexPAges.severity.error,ex.getMessage()));
    	}
        return cInfoList;
    }
    
    @remoteAction
    global static String getCarImgInfo(String callInfId) {
    	List<Call_information__c> calls = [select ImgHex64Info__c from Call_information__c where id = :callInfId];
    	if (calls.isEmpty()) return '';
    	return CommUtils.isBlank(calls[0].ImgHex64Info__c) ? '' : 'data:image/png;base64,' + calls[0].ImgHex64Info__c;
    }
    
    public void getOtherColumnDataJson(){
    	String contactId = ApexPages.CurrentPage().getParameters().get('conId');
    	String accountId = ApexPages.CurrentPage().getParameters().get('accId');
    	String sno = ApexPages.CurrentPage().getParameters().get('sno');
    	String DCD1 = ApexPages.CurrentPage().getParameters().get('isDCD1');
    	boolean isDCD1 = false;
    	if(DCD1 != null){
    		isDCD1 = boolean.valueof(DCD1);
    	}
    	Contact con;
    	Account acc;
    	if(contactQuery != null && contactQuery != '' && contactId != ''){
    		Set<Id> contactIds = new Set<Id>{contactId};
    		List<Contact> contactList = Database.query(contactQuery);
    		if(!contactList.isEmpty()){
    			con = contactList[0];
    		}
    	}
    	
    	if(accountQuery != null && accountQuery != '' && accountId != ''){
    		Set<Id> accountIds = new Set<Id>{accountid};
    		List<Account> accountList = Database.query(accountQuery);
    		if(!accountList.isEmpty()){
    			acc = accountList[0];
    		}
    	}
    	
    	CommDefine__c commDef = CommDefine__c.getInstance();
    	List<ColumnInfo> otherColumns = createOtherColumns(acc,con,isDCD1, sno, commDef.ResContRef__c, commDef.ResAccRef__c, commDef.ResPhoneRef__c);
    	//List<ColumnInfo> otherColumns = createOtherColumns(acc,con,isDCD1);
    	otherColumnData = Json.Serialize(otherColumns);
    }

    /* This method will return the value owhetrer to open alarm popup or not*/
	public void checkAlarmOpened(){
		try{
			
			String userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
			String ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
			
			System.debug('userAgent '+userAgent);
			System.debug('ipAddress '+ipAddress);
			
			/* Get the Alarm popup entry from the Alarm_Popup_Access Object. */
			List<Alarm_Popup_Access__c> userAccessList = [select User_Name__c, Last_Call_Information_Received__c,IP_Address__c from Alarm_Popup_Access__c where User_Name__c =: userinfo.getUserName() and IP_Address__c =: ipAddress and Browser__c =:userAgent LIMIT 1 FOR UPDATE];
			 
			Alarm_Popup_Access__c popuprecord = null; 
			 
			/* Get all record information.*/ 
			List<Call_information__c> callInfoRecList = [Select LastModifiedDate from Call_information__c
																						 order BY LastModifiedDate desc];
																						 
			/* Check if the call records count*/
			if(callInfoRecList != null && callInfoRecList.size() >0){
				callInforRowCount = callInfoRecList.size();
				/* If there is no entry in Alarm_Popup_Access__c for the user with the combination of IP Address and Browser type.
				   If there is no entry then create a new record else update the existing record with the last modified date of Call Info Data*/
				if(userAccessList == null || userAccessList.size() == 0){
					System.debug(' in if');
					popuprecord =  new Alarm_Popup_Access__c (User_Name__c = userinfo.getUserName(), Browser__c = userAgent, IP_Address__c = ipAddress, Last_Call_Information_Received__c = callInfoRecList[0].LastModifiedDate);
					insert popuprecord;
				 	openAlarmPopup = true;
				}else{
					System.debug(' in else');
					popuprecord = userAccessList[0];
				
					if(callInfoRecList[0].LastModifiedDate > userAccessList[0].Last_Call_Information_Received__c){
						userAccessList[0].Last_Call_Information_Received__c = callInfoRecList[0].LastModifiedDate;
						update popuprecord;
						openAlarmPopup = true;
					}else{
						openAlarmPopup = false;
					}
				}
			}else{
				openAlarmPopup = false;
			}
		}catch(Exception e){
			System.debug(' Exception occured::  '+e);
			openAlarmPopup = false;
		}
		
    }
    

    public void resetIsAlarmPopup(){
    	List<User> userList = [select IsAlarmPopup__c from user where id =: userinfo.getUserId()];
    	if(!userList.isEmpty()){
    		userList[0].IsAlarmPopup__c = false;
	   	}	
   		update userList[0];
    }
    
    class ColumnInfo{
        public boolean isLink{get;set;}
        public string text{get;set;}
        public string link{get;set;}
    }
    
    class RowInfo{
        public Call_Information__c callInfo{get;set;}
        public List<ColumnInfo> otherColumns{get;set;}
        public String conFirstName{get;set;}
        public String conLastName{get;set;}
        public String imgData{get;set;}
        public RowInfo(Call_Information__c callInfo){
            this.callInfo = callInfo;
            otherColumns = new List<ColumnInfo>();
            String[] nameArray = getNameDetails(callInfo.DT0__c);
            conFirstName = nameArray [1];
            conLastName = nameArray [0];
            imgData = CommUtils.isBlank(callInfo.ImgHex64Info__c) ? '': 'data:image/png;base64,' + callInfo.ImgHex64Info__c;
        }
    }    
    /* This method will return first name and last name for a contact.*/
    private static String[] getNameDetails(String str){
		String[] nameArray =  new List<String>{'',''};
     	if(str!= null){
         	str = str.trim();
        	if(str.indexOf(' ')!=-1){
				nameArray[0] = str.substring(str.lastIndexOf(' ')+1, str.length());
				nameArray[1] = str.substring(0,str.lastIndexOf(' '));
			}else{
				nameArray[0] = str;
			}
     	}
		return nameArray;
    }
    
        
    public List<XMLField> getXMLFieldInfo(decimal ctiWIndowType, String xmlFileName){
    	System.debug(' IN getXMLFieldInfo ctiWIndowType getXMLFieldInfo:: '+ctiWIndowType + ' xmlFileName::  '+xmlFileName);
    	if (xmlFileName != null && xmlFileName != 'CTI Call Columns xml'){
    		System.debug('In if');
    		String screenName = '';
		    if(ctiWIndowType == 1){
		    	screenName = 'callinfostickywindow';
		    }else if(ctiWIndowType == 2){
		    	screenName = 'alarmpopupwindow';
		    }	
		    return getXMLFieldInfoByScreenName(xmlFileName, screenName);
    	}else{
    		System.debug('In else');
    		return getXMLFieldInfo();
    	}
    }
    
    public List<XMLField> getXMLFieldInfo(){
		// read the xml file in document folder abc.xml
		List<Document> docs = [select id, name, body from Document where name = 'CTI Call Columns xml'];
		
		//creating list for storing fields present in XML file           
		list <XMLField> fieldsToBeShown = new list<XMLField>();
		
		if(!docs.isEmpty()){ 
			String xmlBody = docs[0].body.toString(); 
			DOM.Document xmlDOC = new DOM.Document();
	
			//loading the XML string in object of type DOM.Document
			xmlDOC.load(xmlBody);
    
			//get root element i.e. <fields> tag is root element
			DOM.XMLNode rootElement = xmlDOC.getRootElement();
	
			for(DOM.XMLNode xmlnodeobj : xmlDOC.getRootElement().getChildElements()){       
				//child element of <fields> in our case are <field> tags
				String visible = xmlnodeobj.getAttribute('show','');//get value of show attribute
				if(visible == 'true'){
					XMLField TempDS = new XMLField();
					for(Dom.XMLNode child : xmlnodeobj.getChildElements()){
						if(child.getText()!= null){
	
							String attributeName = child.getName();
							String attributeValue = child.getText();
	
							if(attributeName.equalsIgnoreCase('labelAPIName')){
								TempDS.labelAPIName = attributeValue;
							}
							else if(attributeName.equalsIgnoreCase('latestCheckInDate')){
								TempDS.latestCheckInDate = attributeValue;
							}
							else if(attributeName.equalsIgnoreCase('latestCheckInTime')){
								TempDS.latestCheckInTime = attributeValue;
							}
							else if(attributeName.equalsIgnoreCase('PageLayout')){
								TempDS.PageLayout = attributeValue;
							}
							else if(attributeName.equalsIgnoreCase('DefaultLayout')){
								TempDS.DefaultLayout = attributeValue;
							}
						}
					}
					fieldsToBeshown.add(TempDS);// adding the inner class instance in list
				}
			}     
		}
		return fieldsToBeshown;
	}
    public static List<XMLField> getXMLFieldInfoByScreenName(String xmlFileName,String screenName){
		
		//creating list for storing fields present in XML file           
		list <XMLField> fieldsToBeShown = new list<XMLField>();
		
		
		
		/* Get screens tag for screen name*/		
		DOM.XMLNode screenNode = DomXmlUtil.getXMLNodeByName(xmlFileName, screenName);
		
		if(screenNode != null){
			DOM.XMLNode  fieldsNode = DomXmlUtil.getFieldsNode(screenNode);
			if(fieldsNode != null){
				for(DOM.XMLNode childNode : fieldsNode.getChildElements()){
					//child element of <fields> in our case are <field> tags
					if(childNode.getName() == 'field' && childNode.getAttribute('show','') == 'true'){
						XMLField TempDS = new XMLField();
						for(Dom.XMLNode child : childNode.getChildElements()){
							if(child.getText()!= null){
		
								String attributeName = child.getName();
								String attributeValue = child.getText();
		
								if(attributeName.equalsIgnoreCase('labelAPIName')){
									TempDS.labelAPIName = attributeValue;
								}
								else if(attributeName.equalsIgnoreCase('latestCheckInDate')){
									TempDS.latestCheckInDate = attributeValue;
								}
								else if(attributeName.equalsIgnoreCase('latestCheckInTime')){
									TempDS.latestCheckInTime = attributeValue;
								}
								else if(attributeName.equalsIgnoreCase('PageLayout')){
									TempDS.PageLayout = attributeValue;
								}
								else if(attributeName.equalsIgnoreCase('DefaultLayout')){
									TempDS.DefaultLayout = attributeValue;
								}
								else if(attributeName.equalsIgnoreCase('filters')){
									
									TempDS.filter = attributeValue;
								}
							}
						}
						fieldsToBeshown.add(TempDS);// adding the inner class instance in list
					}
				}
			}
		}
		return fieldsToBeshown;
	}
        
    public class XMLField{
        String labelAPIName;
        String defaultLayout;
        String pageLayout;
        String latestCheckInDate;
        String latestCheckInTime;
        String parentFieldId{get{return 'CF00N10000002qYzd';}set;}
		String filter;
    }
	// 2017/04/17 Source Security Fix BEGIN
	public String getCtiCarNoSpeechFlgStr() {
		return (CommDefine__c.getOrgDefaults().CTI_CarNo_Speech__c != true ? 'false' : 'true');
	}
	// 2017/07/04 チェックアウト音通知機能追加対応
	public String getCtiCoNoSpeechFlgStr() {
        return (CommConst.NOTIFY_CO_IS_SPEECHALERT != true ? 'false' : 'true');
    }
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
	public String getCtiCiNoSpeechFlgStr() {
        return (CommConst.NOTIFY_CI_IS_SPEECHALERT != true ? 'false' : 'true');
    }
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
	// 2017/04/17 Source Security Fix END
}