/**
 * VisualforceControllerクラス
 * 
 * ユーザ情報登録用、ページの表示制御をする
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
public with sharing class RecaiusUserInfo {
    
   //chatter group 選択リスト
    public List<SelectOption> CollaborationGroupList {get; set;}
    //Recaiusユーザ新規登録用
    public RecaiusUserInfo__c userInfo {get;set;}
    //Chatter group選択値
    public String selectValue {get;set;}
    //Recaius 更新ユーザ
    public List<RecaiusUserInfo__c> userInfoupdate {get;set;}
    //Recaius group選択リスト表示判定
    public Boolean showFlg {get;set;}
    //Recaius login error
    public Boolean loginErrorFlg {get;set;}
    //エラーメッセージ
    public String warningMsg{get;set;}
    //更新ユーザID選択値
    public Id selectedId{get;set;}
    // Unique label for the initial callout request
    public String requestLabel1;
    // Unique label for the chained callout request
    public String requestLabel2;
    // Result of initial callout
    public String result1 {get;set;}
    // Result of chained callout
    public String result2 {get;set;}
    // Endpoint of long-running service :login
    private static final String LONG_RUNNING_SERVICE_URL1 = 
         'https://spviewer.recaius.jp/logindex/v1';
        //  field voice dev        
        //  https://spviewer.dev.recaius.jp/logindex/v1
    // Endpoint of long-running service :get/list
    private static final String LONG_RUNNING_SERVICE_URL2 = 
        'https://spviewer.recaius.jp/logindex/v1';
    //Recaius group選択値
    public String selectValue2 {get;set;}
    
    public List<SelectOption> selectoptions {get; set;}
    //Recaius group　選択リストId、Ｌａｂｅｌ用マップ
    private Map<String,String> RegroupMap {get;set;}
    //Recaius 更新用
    String ContactUpdate ;
    //chatter group取得
    public List<selectOption> getoptions(){
        List<SelectOption> options = new List<SelectOption>();
        List<collaborationGroup> groups = [SELECT Id,Name From collaborationGroup];
        Integer j = groups.size();
        for(Integer i=0;i<j;i++){
            options.add(new SelectOption(groups[i].Id,groups[i].Name));
        }
        return options;
    }
    //登録済みリスト取得
    public List<RecaiusUserInfo__c> RecaiusUser{
        get{
            List<RecaiusUserInfo__c> user =[Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c,chatterGroup__c From RecaiusUserInfo__c];
            return user;
        }
    }
    //選択されたRecaius group値取得
    public String getRecaiusGroupId(){
        String reGrId = '';
         if(this.selectValue2==null | this.selectValue2==''){
             return reGrId;
         }
         System.debug(this.RegroupMap);
         System.debug(this.RegroupMap.get(this.selectValue2));
          //  System.debug(this.options2.getLabel());
        
        return this.selectValue2;        
    }
    //Recaius gtoup選択リスト
    public List<selectOption> options2{        
        get{
            System.debug(selectoptions);
        	List<SelectOption> options = selectoptions;      
        
            return options;
        }        
    }    
    //選択ユーザ情報取得
    public List<RecaiusUserInfo__c> RecaiusUserUpdate{
        get{
            List<RecaiusUserInfo__c> user =[Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where id=:this.selectedId limit 1];
            return user;
        }
        set;
    }

   
   
    //ページ呼び出し時の処理
    public RecaiusUserInfo(){       
		showFlg = false;
        loginErrorFlg = false;
        userInfo = new RecaiusUserInfo__c();
        userInfoupdate = new list<RecaiusUserInfo__c>();
        RegroupMap =new Map<String,String>();
    }

    //Recaius group選択リスト変更時
    public PageReference change(){ 
        return null;
    }

    //test 更新ページ表示時処理
    public PageReference test(){
        
        //更新ページ　ユーザ情報ない場合登録ページにリダイレクト
        if( userInfoupdate.size()==0){        
            return Page.RecaiusUserInfo.setRedirect(false);
        }
      
        
        //選択リストデフォルト値
        //options
        userInfo.UserId__c = userInfoupdate[0].UserId__c;
        userInfo.ContactId__c = userInfoupdate[0].ContactId__c;        
        userInfo.Password__c = '';
        userInfo.RecaiusGroup__c = userInfoupdate[0].RecaiusGroup__c;
        //System.debug('userInfo'+userInfo.UserId__c +'userUpdate'+userInfoupdate[0].UserId__c);
        return null;
        
    }

    public PageReference RecaiusGroupSetInit(){
        if(userInfo.UserId__c==''| userInfo.UserId__c==null |
           userInfo.ContactId__c=='' | userInfo.ContactId__c==null |
           userInfo.Password__c=='' | userInfo.Password__c==null |
           selectValue2=='' | selectValue2==null){
               return page.RecaiusUserInfo;
        }
        return null;
    }
    
    
   
    //更新選択時
    public PageReference showDetail(){        
        List<RecaiusUserInfo__c> user=[Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where id=:this.selectedId limit 1];
        userInfoupdate = user.clone();
        //System.debug(user);
        selectedId =ApexPages.currentPage().getParameters().get('recaId');
        return page.RecaiusUserUpdate.setRedirect(false);
    }
    
    //削除選択
    public PageReference deleteRecord(){
        try{
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(RecaiusUserInfo__c.getSObjectType())) {
				return null;
			}
			// 2018/03/07 Security Check END
            List<RecaiusUserInfo__c> duser=[Select Id From RecaiusUserInfo__c where id=:this.selectedId limit 1];
            if(duser.size()==0){
                return null;
            }
        	delete duser;
        	//System.debug('delete'+duser);            
        }catch(Exception e){
            System.debug('Exception');
        }        
        return null;
    }

   //新規ユーザ登録
    public PageReference save(){
        
       //入力チェック
        if(userInfo.ContactId__c==null || userInfo.UserId__c==null ||userInfo.Password__c==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'error','recaius'));
            return null;
        }
        
        try{
            // 2018/03/07 Security Check BEGIN
            List<String> chkFieldsLst = new List<String>{'chattergroup__c','chattergroup_id__c','recaiusgroup__c','recaiusgroup_id__c'};
            Map<String,Schema.SObjectField> mm = Schema.SObjectType.RecaiusUserInfo__c.fields.getMap();
            if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
            	return null;
            }
            // 2018/03/07 Security Check END
            userInfo.chatterGroup_Id__c = selectValue;
            List<collaborationGroup> insgroups = [SELECT Id,Name From collaborationGroup WHERE id=:selectValue];
            userInfo.chatterGroup__c = insgroups[0].Name;
            userInfo.RecaiusGroup_Id__c = Decimal.valueOf(this.selectValue2);
            userInfo.RecaiusGroup__c = this.RegroupMap.get(this.selectValue2);            
            insert(userInfo);
        }catch(System.DmlException e){
            ApexPages.addMessages(e);
            return null;
        }
        //PageReference redirectSuccess = new ApexPages.
        userInfo = new RecaiusUserInfo__c();
        return page.RecaiusUserInfo.setRedirect(true);         
    }

    
    public PageReference GroupSet_cancel(){
        userInfo = new RecaiusUserInfo__c();
        return Page.RecaiusUserInfo.setRedirect(true);
    }
	
    
    public PageReference next_groupSetting(){
    	//System.debug('groupsetting');
        //System.debug(showFlg);
        if(showFlg){
            //System.debug('page groupsetting');
            return page.RecaiusUserInfoGroupSet.setRedirect(false);
        }        
        return null;        
    }
        
    // Action method　Recaius login
    public Object invokeInitialRequest() {        
        //System.debug('Login');
        showFlg = false;
        loginErrorFlg = false;
        //入力チェック
        if(userInfo.ContactId__c=='' | userInfo.ContactId__c==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'契約IDを入力して下さい'));
        }
        if(userInfo.UserId__c=='' | userInfo.UserId__c==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ユーザIDを入力して下さい'));
        }
        if(userInfo.Password__c=='' | userInfo.Password__c==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'パスワードを入力して下さい'));
        }
        
        if(userInfo.ContactId__c=='' | userInfo.UserId__c=='' | userInfo.Password__c=='' |userInfo.ContactId__c==null | userInfo.UserId__c==null | userInfo.Password__c==null){          
           //System.debug('test2');
           this.requestLabel1 = 'error';
           return null;
        }
        // Create continuation with a timeout
        Continuation con = new Continuation(60);
        // Set callback method
        con.continuationMethod='processInitialResponse';
      
        //Create first callout request
        // Create callout request      
        HttpRequest request = new HttpRequest();
        request.setEndpoint(LONG_RUNNING_SERVICE_URL1+'/login');
        request.setMethod('POST');
        request.setHeader('Accept','application/json, */*');
        request.setHeader('Accept-Encoding','gzip, deflate, br');
        request.setHeader('Accept-Language','ja,en-US;q=0.8,en;q=0.6');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Type','application/json');
        String pass = userInfo.Password__c;
        String reId = userInfo.ContactId__c;
        String account= userInfo.UserId__c;
        //パスワードをMD5化
        string passwordConv = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(pass)));
      
        Map<String, String> param = new Map<String, String>{};
        param.put('account', account);
        param.put('application_id','fieldvoice_jinyachatter');
        param.put('contract_id', reId);
        param.put('password', passwordConv);

        request.setBody(JSON.serialize(param));        
      
        // Add initial callout request to continuation
        this.requestLabel1 = con.addHttpRequest(request);              
      
        // Return the continuation
        //System.debug(con);
        return con;  
        
    }
    
    // Callback method for initial request
    public Object processInitialResponse() {   
        // Get the response by using the unique label
        HttpResponse response = Continuation.getResponse(this.requestLabel1);
        // Set the result variable that is displayed on the Visualforce page
        String responseBody = response.getBody();     
        //レスポンスチェック
        Continuation chainedContinuation = null;
        if (response.getStatusCode() == 200) {
            //成功時に実行したい処理
            //System.debug('Callout success: ');
            //System.debug('Callout success: ' + responseBody);
	
            try{
                Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                // Chain continuation if some condition is met
                // Create a second continuation group list 取得
                chainedContinuation = new Continuation(60);
                // Set callback method
                chainedContinuation.continuationMethod='processChainedResponse';
                //String groupName='音声';
                // Create callout request
                HttpRequest req2 = new HttpRequest();
                //req2.setEndpoint(LONG_RUNNING_SERVICE_URL2+'/group/list?query='+groupName);
                req2.setEndpoint(LONG_RUNNING_SERVICE_URL2+'/group/list');
                req2.setMethod('GET');
                req2.setHeader('Accept','application/json, */*');
                req2.setHeader('Accept-Encoding','gzip, deflate, br');
                req2.setHeader('Accept-Language','ja,en-US;q=0.8,en;q=0.6');
                req2.setHeader('Connection','keep-alive');
                req2.setHeader('Content-Type','application/json');
                req2.setHeader('X-AUTH-TOKEN', (String)m.get('token_key'));            
                // Add callout request to continuation
                this.result1 = response.getBody();
                this.requestLabel2 = chainedContinuation.addHttpRequest(req2); 
            }catch(Exception e){
                //System.debug('Exception: ' + e.getMessage());
                this.result1 = 'Exception: ';
                warningMsg = 'Login Exception';
            	loginErrorFlg = true;
            }
        } else {
            //System.debug('Callout failed: ' + response);
            //System.debug('Callout failed: ' + responseBody);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'契約ID、ユーザーIDまたはパスワードが正しくありません。'));
            this.result1 = '契約ID、ユーザーIDまたはパスワードが正しくありません。';
            warningMsg = '契約ID、ユーザーIDまたはパスワードが正しくありません。';
            loginErrorFlg = true;
        }
        // Start another continuation 
        return chainedContinuation;
    }    
    
    // Callback method for chained request
    public Object processChainedResponse() {               
        // Get the response for the chained request
        HttpResponse response = Continuation.getResponse(this.requestLabel2);
        // Set the result variable that is displayed on the Visualforce page
        String responseBody = response.getBody();        
        
        //レスポンスチェック
        List<SelectOption> options = new List<SelectOption>();
        if (response.getStatusCode() == 200) {
            //成功時に実行したい処理
            try{
                List<Object> oo =(List<Object>) JSON.deserializeUntyped(responseBody);
                String surface;
                for(Integer i=0,j=oo.size();i<j;i++){
                    Map<String, Object> m = (Map<String, Object>)oo[i];
                    surface =(String)m.get('name');
                    Integer gId =(Integer)m.get('id');
                    String sId = String.valueOf(gId);                    
                    options.add(new SelectOption(sId,surface));
                    RegroupMap.put(sId, surface);
                    //選択リスト値初期値設定
                    if(i==0){
                        this.selectValue2 =sId;
                    }
                }                
                
                this.selectoptions = options;			    
			    this.showFlg = true;                
            }catch(Exception e){                
                warningMsg = 'group list Exception';
            	loginErrorFlg = true;
                return null;
            }                       
        } else if (response.getStatusCode() == 401) {
            warningMsg = 'group list error 401';
            loginErrorFlg = true;
        } else{
            warningMsg = 'group list error';
            loginErrorFlg = true;
        }      
        this.result2 = response.getBody();        
        // Return null to re-render the original Visualforce page
        return null;        
    }
    
    //更新ページ
    //更新ページキャンセル
    public PageReference updatecansel(){        
        userInfo = new RecaiusUserInfo__c();
        return page.RecaiusUserInfo.setRedirect(true);
    }

    //更新ページ Recaius group 判定
    public PageReference updateUserInfo(){                
        if(showFlg){            
            return page.RecaiusUserUpdateGroupSet.setRedirect(false);
        }        
        return null;        
    }
    
    //更新ページ更新
    public PageReference updateInfo(){
        List<RecaiusUserInfo__c> userupdate =[Select Id,ContactId__c,UserID__c,RecaiusGroup__c,Password__c From RecaiusUserInfo__c where id=:this.selectedId limit 1];        
        try{
            // 2018/03/07 Security Check BEGIN
            List<String> chkFieldsLst = new List<String>{'chattergroup__c','userid__c','recaiusgroup__c','password__c','contactid__c'};
            Map<String,Schema.SObjectField> mm = Schema.SObjectType.User.fields.getMap();
            if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
            	return null;
            }
            // 2018/03/07 Security Check END
            userupdate[0].ContactId__c =userInfo.ContactId__c;
            userupdate[0].UserId__c =userInfo.UserId__c;
        	userupdate[0].Password__c = userInfo.Password__c;
        	userupdate[0].RecaiusGroup__c = this.RegroupMap.get(this.selectValue2);
            List<collaborationGroup> insgroups = [SELECT Id,Name From collaborationGroup WHERE id=:selectValue limit 1];
            userupdate[0].chatterGroup__c=insgroups[0].Name;
            update userupdate;
        }catch(System.DmlException e){
            ApexPages.addMessages(e);
            return null;
        }             
        return page.RecaiusUserInfo.setRedirect(true);
    }

}