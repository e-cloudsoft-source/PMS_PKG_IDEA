/**
 * RecaiusUserInfoControllerテストクラス
 * 
 * 本番組織リリース時に必要なテストクラス
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
@isTest
public class RecaiusUserInfoControllerTest {
    
    public static testMethod void testController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();     
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();
         //Map<String,HttpRequest> requests2 = conti2.getRequests();
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(200);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
        
        Continuation conti2 = (Continuation)controller.processInitialResponse(); 
        HttpResponse res2 = new HttpResponse();
        res2.setHeader('Content-Type','application/json');
        res2.setBody('[{"id":433,"name":"音声通知グループ（開発）","model_id":483,"model_id_en":5,"model_id_zh":7,"owner_id":1703,"icon":{"id":6,"filename":"gr01.png","icon_type":2,"owner_user_id":0,"owner_group_id":0},"current_language":"ja_JP","use_group_model":true,"notes":""}]');
        res2.setStatusCode(200);
        Test.setContinuationResponse(controller.requestLabel2, res2);
        
         //Invoke callback method
        //Object result1 = Test.invokeContinuationMethod(controller,conti);                  
        Object result2 = Test.invokeContinuationMethod(controller,conti2);
        
        String groupSetpage = controller.next_groupSetting().getUrl();
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerinfogroupset', groupSetPage); 
        System.debug(groupSetpage);    
        
        collaborationGroup testGroup = new collaborationGroup(Name='testOnly',CollaborationType='Private');
        insert testGroup;
        List<collaborationGroup> insgroups = [SELECT Id,Name From collaborationGroup WHERE Name='testOnly'];
        controller.selectValue = insgroups[0].Id; 
        
        pageReference change = controller.change();
        System.debug(change);
        
        pageReference save = controller.save();
        System.debug(save);
        
        controller = new RecaiusUserInfo();
        pageReference save_false = controller.save();
        pageReference groupSetpage_false = controller.next_groupSetting();
        System.debug(save_false);
        System.debug(groupSetpage_false);
    }
    
    public static testMethod void getListBodyExceptionController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();        
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();         
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(200);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
        
        Continuation conti2 = (Continuation)controller.processInitialResponse(); 
        HttpResponse res2 = new HttpResponse();
        res2.setHeader('Content-Type','application/json');
        res2.setBody('[{"model_id":483,"model_id_en":5,"model_id_zh":7,"owner_id":1703,"icon":{"id":6,"filename":"gr01.png","icon_type":2,"owner_user_id":0,"owner_group_id":0},"current_language":"ja_JP","use_group_model":true,"notes":""}]');
        res2.setStatusCode(200);
        Test.setContinuationResponse(controller.requestLabel2, res2);
        
         //Invoke callback method
        //Object result1 = Test.invokeContinuationMethod(controller,conti);           
       
        Object result2 = Test.invokeContinuationMethod(controller,conti2);
                
    }
    
    public static testMethod void getListBodynullController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();        
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();
         //Map<String,HttpRequest> requests2 = conti2.getRequests();
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(200);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
        
        Continuation conti2 = (Continuation)controller.processInitialResponse(); 
        HttpResponse res2 = new HttpResponse();
        res2.setHeader('Content-Type','application/json');
        res2.setBody('');
        res2.setStatusCode(200);
        Test.setContinuationResponse(controller.requestLabel2, res2);
        
         //Invoke callback method
        //Object result1 = Test.invokeContinuationMethod(controller,conti);           
       
        Object result2 = Test.invokeContinuationMethod(controller,conti2);
        
        //controller.userInfo.ContactId__c('test');
    }
    
    public static testMethod void getListErrorController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();
        //String nextPage = controller.next_groupSetting().getUrl();
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();
         //Map<String,HttpRequest> requests2 = conti2.getRequests();
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(200);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
        
        Continuation conti2 = (Continuation)controller.processInitialResponse(); 
        HttpResponse res2 = new HttpResponse();
        res2.setHeader('Content-Type','application/json');
        res2.setBody('[{"id":433,"name":"音声通知グループ（開発）","model_id":483,"model_id_en":5,"model_id_zh":7,"owner_id":1703,"icon":{"id":6,"filename":"gr01.png","icon_type":2,"owner_user_id":0,"owner_group_id":0},"current_language":"ja_JP","use_group_model":true,"notes":""}]');
        res2.setStatusCode(401);
        Test.setContinuationResponse(controller.requestLabel2, res2);
        
         //Invoke callback method
        //Object result1 = Test.invokeContinuationMethod(controller,conti);           
       
        Object result2 = Test.invokeContinuationMethod(controller,conti2);
        
        //controller.userInfo.ContactId__c('test');
    }
    
    public static testMethod void getListError2Controller(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();
        //String nextPage = controller.next_groupSetting().getUrl();
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();         
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(200);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
        
        Continuation conti2 = (Continuation)controller.processInitialResponse(); 
        HttpResponse res2 = new HttpResponse();
        res2.setHeader('Content-Type','application/json');
        res2.setBody('[{"id":433,"name":"音声通知グループ（開発）","model_id":483,"model_id_en":5,"model_id_zh":7,"owner_id":1703,"icon":{"id":6,"filename":"gr01.png","icon_type":2,"owner_user_id":0,"owner_group_id":0},"current_language":"ja_JP","use_group_model":true,"notes":""}]');
        res2.setStatusCode(500);
        Test.setContinuationResponse(controller.requestLabel2, res2);
        
         //Invoke callback method
        //Object result1 = Test.invokeContinuationMethod(controller,conti);           
       
        Object result2 = Test.invokeContinuationMethod(controller,conti2);        
    }
    
    public static testMethod void loginErrorController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        Object nextPa = controller.invokeInitialRequest();        
        System.debug(nextPa);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';        
        Continuation conti = (Continuation)controller.invokeInitialRequest();        
        //Verify that the contiuation has the proper requests
        Map<String,HttpRequest> requests = conti.getRequests();         
        System.assert(requests.size()==1);
        System.assert(requests.get(controller.requestLabel1)!=null);
        
        //Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody('{"token_key":"test1048"}');
        res.setStatusCode(400);
        //set the fake response for the continuation
        Test.setContinuationResponse(controller.requestLabel1, res);
         //Invoke callback method
        Object result1 = Test.invokeContinuationMethod(controller,conti);               
    }
    public static testMethod void showdetailController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        
        RecaiusUserInfo controller = new RecaiusUserInfo();
        String showdetail = controller.showDetail().getUrl();
        System.debug(showdetail);
                
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        controller.userInfo.RecaiusGroup__c ='test';
        insert controller.userInfo;
        List<RecaiusUserInfo__c> user = [Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where Userid__c='test' limit 1];
        controller.selectedId = user[0].Id;
        showdetail = controller.showDetail().getUrl();        
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerupdate', showdetail);        
    }
    
   
     public static testMethod void deleteRecordController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);        
        RecaiusUserInfo controller = new RecaiusUserInfo();        
        PageReference deleteRecord_sizeNull = controller.deleteRecord();
        System.assertEquals(null,deleteRecord_sizeNull);
         
        controller = new RecaiusUserInfo(); 
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        controller.userInfo.RecaiusGroup__c ='test';
        insert controller.userInfo;
        List<RecaiusUserInfo__c> user = [Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where Userid__c='test' limit 1];
        controller.selectedId = user[0].Id;
        PageReference deleteRecord = controller.deleteRecord();        
        System.assertEquals(null, deleteRecord); 
        
    }
    
    public static testMethod void userUpdatetestController(){   
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        RecaiusUserInfo controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        controller.userInfo.RecaiusGroup__c ='test';
        insert controller.userInfo;
        List<RecaiusUserInfo__c> user = [Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where Userid__c='test' limit 1];
        controller.selectedId = user[0].Id;
        
        collaborationGroup testGroup = new collaborationGroup(Name='testOnly',CollaborationType='Private');
        insert testGroup;
        List<collaborationGroup> insgroups = [SELECT Id,Name From collaborationGroup WHERE Name='testOnly'];
        controller.selectValue = insgroups[0].Id;  
        
        controller.userInfoUpdate.add(new RecaiusUserInfo__c());
        controller.userInfoupdate[0].ContactId__c ='test';
        controller.userInfoupdate[0].UserId__c ='test';
        controller.userInfoupdate[0].Password__c ='test';
        controller.userInfoupdate[0].RecaiusGroup__c ='test';
         
        PageReference pageRef2 = Page.RecaiusUserUpdate;
        Test.setCurrentPage(pageRef2);
        PageReference testpage = controller.test();
        System.debug(testpage);
        String userUpdate = controller.updateInfo().getUrl();                        
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerinfo', userUpdate);
        String updateCancel = controller.updatecansel().getUrl();
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerinfo', updateCancel);
        pageReference updateUserInfo = controller.updateUserInfo();
        System.debug(updateUserInfo);
        System.assertEquals(null, updateUserInfo);
        controller.showFlg = true;
        String updateUserInfo_success = controller.updateUserInfo().getUrl();
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerupdategroupset', updateUserInfo_success);
        
        controller = new RecaiusUserInfo();
        String test_false = controller.test().getUrl();
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerinfo', test_false);
    }
    
    public static testMethod void groupSetCanselController(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        RecaiusUserInfo controller = new RecaiusUserInfo();
        controller.userInfoUpdate.add(new RecaiusUserInfo__c());
        controller.userInfoupdate[0].ContactId__c ='test';
        controller.userInfoupdate[0].UserId__c ='test';
        controller.userInfoupdate[0].Password__c ='test';
        controller.userInfoupdate[0].RecaiusGroup__c ='test';
        PageReference pageRef = Page.RecaiusUserInfoGroupSet;
        Test.setCurrentPage(pageRef);
        PageReference groupSetpage = controller.RecaiusGroupSetInit();
        System.debug(groupSetpage);
        String GroupSetCansel = controller.GroupSet_cancel().getUrl();        
        System.assertEquals('/apex/'+comdef.AppNS__c+'recaiususerinfo', GroupSetCansel);
        
        controller = new RecaiusUserInfo();
        controller.userInfo.ContactId__c ='test';
        controller.userInfo.UserId__c ='test';
        controller.userInfo.Password__c ='test';
        controller.userInfo.RecaiusGroup__c ='test';
        controller.selectValue2 = 'test';
        PageReference groupSetpage2 = controller.RecaiusGroupSetInit();
        System.debug(groupSetpage2);
        
    }
    
    public static testMethod void getOptionsController(){        
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        RecaiusUserInfo controller = new RecaiusUserInfo();
        collaborationGroup testGroup = new collaborationGroup(Name='testOnly',CollaborationType='Private');
        insert testGroup;
        List<collaborationGroup> insgroups = [SELECT Id,Name From collaborationGroup WHERE Name='testOnly'];
        String selectValue = insgroups[0].Id; 
        PageReference pageRef = Page.RecaiusUserInfo;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        List<selectOption> getOp = controller.getoptions();
        List<RecaiusUserInfo__c> testuser = controller.RecaiusUser;        
        List<selectOption> Op2 = controller.options2;
        List<RecaiusUserInfo__c> RecaiusUserUpdate = controller.RecaiusUserUpdate;
        Test.stopTest();        
        System.assertEquals(selectValue, getOp.get(0).getValue());
        System.assertEquals(0, testuser.size());
        //System.assertEquals('', grId);
        System.assertEquals(null, Op2);
        System.assertEquals(0, RecaiusUserUpdate.size());
    }  
    
    public static testMethod void userInfoTestgetGroupId(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        PageReference pageRef = Page.RecaiusUserUpdate;
        Test.setCurrentPage(pageRef);
        RecaiusUserInfo con = new RecaiusUserInfo();
        con.selectValue2 = 'test';
        String grId = con.getRecaiusGroupId();
        System.assertEquals('test', grId);
        con = new RecaiusUserInfo();
        String grId_null = con.getRecaiusGroupId();
        System.assertEquals('', grId_null);
    }
}