/*
 * @Author: persistent systems ltd.
 * @Date: 4th December 2013 
 * @Description: This is a test class for CallInformationSync Controller
 */
@isTest(seeAllData=false)
private class CallInformationTest{

    static Contact con;
    static Account acc;
    
    /**
    * Create test data
    */
    static void createSetupData(){
        CommDefine__c def = new CommDefine__c(maxRecords_DB__c = 1, maxRecords_DSP__c = 1);
        insert def;
        con = new Contact(LastName = 'Test Contact', Phone = '1234567890');
        insert con;
        acc = new Account(Name= 'Test Account', Phone = '1234567890');
        insert acc;
        Test.setFixedSearchResults(new Id[]{con.Id,acc.Id});
        List<Document> docList = [select id from document where name = 'CTI Call Columns xml'];
        delete docList;
        
        Document doc = new Document(Name = 'CTI Call Columns xml');
        doc.FolderId = userinfo.getUserId();
        doc.Body = Blob.valueof('<fields>'+
	        						 '<field show="true">'+
	        						 	'<labelAPIName>Contact.Usage_Count__c:ご利用回数</labelAPIName>'+
	        						 '</field> 	'+
	        						 '<field show="true">  '+      	
	        						 	'<labelAPIName>Contact.Account.AccountType__c:取引先種別</labelAPIName>'+ 	
	        						 '</field>'+ 	 	
	        						 '<field show="true">'+ 		
	        						 	'<DefaultLayout>Lead__c-BookingRecType</DefaultLayout>'+ 		
	        						 	'<labelAPIName>Lead__c.Name:ご予約</labelAPIName>'+ 		
	        						 	'<latestCheckInDate>Contact-reservetg85__r.EntryTime__c</latestCheckInDate>'+ 		
	        						 	'<latestCheckInTime>Contact-reservetg85__r.Field4__c</latestCheckInTime>'+   	 	
	        						 '</field>'+ 	
	        						 '<field show="true">'+        	
	        						 	'<PageLayout>BookingApp</PageLayout>'+ 		
	        						 	'<labelAPIName>LeadIndex__c.Name:一括予約</labelAPIName>'+ 		
	        						 	'<latestCheckInDate>Contact-IndexContactRef__r.EntryDate__c</latestCheckInDate>'+ 		
	        						 	'<latestCheckInTime>Contact-IndexContactRef__r.EntryTime__c</latestCheckInTime>'+ 	
	        						 '</field>'+ 
        						 '</fields>');
        insert doc;
    }
    
    
     static void createSetupDataByScreenType(){
        CommDefine__c def = new CommDefine__c(maxRecords_DB__c = 1, maxRecords_DSP__c = 1, CTI_Call_Columns_xml_Name__c = 'CTI Call Columns xml V1.1');
        insert def;
        con = new Contact(LastName = 'Test Contact', Phone = '1234567890');
        insert con;
        acc = new Account(Name= 'Test Account', Phone = '1234567890');
        insert acc;
        Test.setFixedSearchResults(new Id[]{con.Id,acc.Id});
        List<Document> docList = [select id from document where name = 'CTI Call Columns xml'];
        delete docList;
        
        Document doc = new Document(Name = 'CTI Call Columns xml V1.1');
        doc.FolderId = userinfo.getUserId();
        doc.Body = Blob.valueof('<screens>'+
									'<screen name="callinfostickywindow">'+
										'<active>true</active>'+
										'<description>'+
										'</description>'+
										'<width>750</width>'+ 
										'<fields>'+	
											'<field show="false">'+
												'<labelAPIName>Contact.Usage_Count__c:ご利用回数</labelAPIName>'+
											'</field>'+
											'<field show="true">'+
												'<DefaultLayout>ps__Lead__c-BookingRecType</DefaultLayout>'+
												'<labelAPIName>Lead__c.Name:ご予約</labelAPIName>'+
												'<latestCheckInDate>Contact-reservetg85__r.EntryTime__c</latestCheckInDate>'+
												'<latestCheckInTime>Contact-reservetg85__r.Field4__c</latestCheckInTime>'+
												'<filters>ReservedStatus__c not in (\'NO SHOW\',\'キャンセル\',\'削除\')</filters>'+
											'</field>'+
											'<field show="true">'+
												'<PageLayout>BookingApp</PageLayout>'+
												'<labelAPIName>LeadIndex__c.Name:一括予約</labelAPIName>'+
												'<latestCheckInDate>Contact-IndexContactRef__r.EntryDate__c</latestCheckInDate>'+
												'<latestCheckInTime>Contact-IndexContactRef__r.EntryTime__c</latestCheckInTime>'+
												'<filters>StatusLst__c in (\'通常\')</filters>'+
												  
											'</field>'+
										'</fields>'+
									'</screen>'+
									'<screen name="alarmpopupwindow">'+
										'<active>true</active>'+
										'<description>'+
											
										'</description>'+
										'<fields>'+	
											'<field show="false">'+
												'<labelAPIName>Contact.Usage_Count__c:ご利用回数</labelAPIName>'+
											'</field>'+
											'<field show="true">'+
												'<DefaultLayout>ps__Lead__c-BookingRecType</DefaultLayout>'+
												'<labelAPIName>Lead__c.Name:ご予約</labelAPIName>'+
												'<latestCheckInDate>Contact-reservetg85__r.EntryTime__c</latestCheckInDate>'+
												'<latestCheckInTime>Contact-reservetg85__r.Field4__c</latestCheckInTime>'+
												'<filters>ReservedStatus__c not in (\'NO SHOW\',\'キャンセル\',\'削除\')</filters>'+
											'</field>'+
											'<field show="true">'+
												'<PageLayout>BookingApp</PageLayout>'+
												'<labelAPIName>LeadIndex__c.Name:一括予約</labelAPIName>'+
												'<latestCheckInDate>Contact-IndexContactRef__r.EntryDate__c</latestCheckInDate>'+
												'<latestCheckInTime>Contact-IndexContactRef__r.EntryTime__c</latestCheckInTime>'+
												'<filters>StatusLst__c in (\'通常\')</filters>'+
											'</field>'+
										'</fields>'+
									 '</screen>'+
								'</screens>');
        insert doc;
    }
    
    /**
    * This method test CallInformationSync's web service createCallInformation for type 1 call information
    */
    private static testmethod void testCreateCallInformationType1(){
        createSetupData();
        CallInformationSync.CallInformation cInfo = new CallInformationSync.CallInformation();
        cInfo.SNO = '1234567890';
        cInfo.cdt = '20131212';
        cInfo.ctm = '121212';
        cInfo.dcd1 = false;
        Test.startTest();
        CallInformationSync.CallInformationSyncResult result = CallInformationSync.createCallInformation(cInfo);
        Test.stopTest();
        System.assertNotEquals(0,[select id from Call_Information__c].size());
        System.assertEquals(con.Id,[select Contact__c from Call_Information__c][0].contact__c);
        System.assertEquals(true,result.isSuccess);
    }
    
    /**
    * This method test CallInformationSync's web service createCallInformation for type 2 call information
    */
    private static testmethod void testCreateCallInformationType2(){
        createSetupData();
        CallInformationSync.CallInformation cInfo = new CallInformationSync.CallInformation();
        cInfo.SNO = '1234567890';
        cInfo.dcd1 = true;
        cInfo.cdt = '20131212';
        cInfo.ctm = '121212';
        Test.startTest();
        CallInformationSync.CallInformationSyncResult result = CallInformationSync.createCallInformation(cInfo);
        Test.stopTest();
        System.assertNotEquals(0,[select id from Call_Information__c].size());
        System.assertEquals(acc.Id,[select Account__c from Call_Information__c][0].Account__c);
        System.assertEquals(true,result.isSuccess);
    }
    
    /**
    * This method test CallInformationSync's web service createCallInformation when maxRecords_DB is reached
    */
    private static testmethod void testCreateCallInformationMaxDBReached(){
        createSetupData();
        Call_information__c information = new Call_information__c(LNO__c = '01',SNO__c = '1234567899',Call_Time__c = System.now());
        insert information;
        CallInformationSync.CallInformation cInfo = new CallInformationSync.CallInformation();
        cInfo.SNO = '1234567890';
        cInfo.dcd1 = true;
        cInfo.cdt = '20131212';
        cInfo.ctm = '121212';
        Test.startTest();
        CallInformationSync.CallInformationSyncResult result = CallInformationSync.createCallInformation(cInfo);
        Test.stopTest();
        System.assertNotEquals(0,[select id from Call_Information__c].size());
        System.assertEquals(acc.Id,[select Account__c from Call_Information__c where id =: result.sfdcId][0].Account__c);
        System.assertEquals(true,result.isSuccess);
    }
    
    /**
    * This method test CallManagementController's Constructor
    */
    private static testmethod void testCallManagementController(){
        createSetupData();
        Call_information__c information = new Call_information__c(LNO__c = '01',SNO__c = '1234567899',Call_Time__c = System.now(),Contact__c = con.Id);
        insert information;
        Test.startTest();
        CallManagementController controller = new CallManagementController();
        Test.stopTest();
        System.assertNotEquals(0,controller.lstCallInfo.size());
    }
    
    /**
    * This method test CallManagementController's Constructor
    */
    private static testmethod void testCallManagementControllerByScreenName(){
        createSetupDataByScreenType();
        Call_information__c information = new Call_information__c(LNO__c = '01',SNO__c = '1234567899',Call_Time__c = System.now(),Contact__c = con.Id);
        insert information;
        Test.startTest();
        CallManagementController controller = new CallManagementController();
        Test.stopTest();
        System.assertNotEquals(0,controller.lstCallInfo.size());
    }
    
    /**
    * This method test CallManagementController's checkAlarmOpened method
    */
    private static testmethod void testCheckAlarmOpened(){
    	User curUser = [select id, isCallInformationEnabled__c from User where Id = :UserInfo.getUserId()];
    	curUser.isCallInformationEnabled__c = true;
    	update curUser;
    	System.runAs(curUser) {
        CallManagementController controller = new CallManagementController();
        Test.startTest();
        controller.checkAlarmOpened();
        Test.stopTest();
       	System.assertEquals(true,[select isCallInformationEnabled__c from User where id =: userinfo.getUserId()][0].isCallInformationEnabled__c);
    	}
    }

	 /**
    * This method test CallManagementController's checkAlarmOpened method
    */
    private static testmethod void testResetIsAlarmOpened(){
        CallManagementController controller = new CallManagementController();
        Test.startTest();
        controller.resetIsAlarmPopup();
        Test.stopTest();
        System.assertEquals(false,[select IsAlarmPopup__c from User where id =: userinfo.getUserId()][0].IsAlarmPopup__c);
      
    
    }
    
    private static testmethod void testCustomerCallInfoSyncHandler(){
    	Call_Information__c info = new Call_Information__c(sno__c = '1111111111');
    	insert info;
    	
    	Contact newContact = new Contact();
    	newContact.phone = '1111111111';
    	newContact.lastName = 'Test';
    	Test.startTest();
    	insert newContact;
    	Test.stopTest();
    	
    	System.assertEquals(newContact.id, [select contact__c from call_Information__c where id =: info.id][0].Contact__c);
    }
    
    static testMethod void TestContainsFun() {
    	String src = '中板 自家用 湘南580ひ33 中板 自家用 湘南580ひ3 中板 自家用 湘南580ひ3606';
    	String key = '湘南580ひ3';
    	System.assert(CallInformationSync.isContains(src, key));
    	key = '湘南580ひA';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ333';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ3606';
    	System.assert(CallInformationSync.isContains(src, key));
    	key = '湘南580ひ33';
    	System.assert(CallInformationSync.isContains(src, key));
    	src = '中板 自家用 湘南580ひ33\n'
    		+ '中板 自家用 湘南580ひ3\n'
    		+ '中板 自家用 湘南580ひ3606';
    	key = '湘南580ひ3';
    	System.assert(CallInformationSync.isContains(src, key));
    	key = '湘南580ひA';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ333';
    	System.assert(!CallInformationSync.isContains(src, key));
    	key = '湘南580ひ3606';
    	System.assert(CallInformationSync.isContains(src, key));
    	key = '湘南580ひ33';
    	System.assert(CallInformationSync.isContains(src, key));
    }
}