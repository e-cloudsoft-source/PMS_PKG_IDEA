/**
 * RecaiusCalloutクラス
 * 
 * RECAIUSにログイン、テキスト投稿を行う
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
public class HttpCallout {
    public static Boolean isRecaiusTestFlg = false;

    @Future(callout=true)    
    public static void RecaiusPost(String contracts,String user,String pass,String feedBody,Decimal groupId,Datetime speechTime){
        System.debug('recaiusPost start');
         if(isRecaiusTestFlg){
             return;
         }
        calloutHttpLogin(contracts,user,pass,feedBody,groupId,speechTime,0);
    }
    
    
    private static void calloutHttpLogin(String contracts,String user,String pass,String feedBody,Decimal groupId,Datetime speechTime,Integer retryCount){
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://spviewer.recaius.jp/logindex/v1/login');
        
        request.setMethod('POST');
        request.setHeader('Accept','application/json,*/*');
        request.setHeader('Accept-Encoding','gzip,deflate,br');
        request.setHeader('Accept-Language','ja,en-US;q=0.8,en;q=0.6');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Type',' application/json');
        
        String account=user;        
        String password = pass;
        String contract = contracts;
        String application = 'fieldvoice_jinyachatter';
        String passwordConv = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(password)));
   		
        Map<String,object> mapLogin=new Map<String,object>();
        mapLogin.put('account',account);
        mapLogin.put('password',passwordConv);
        mapLogin.put('contract_id',contract);
        mapLogin.put('application_id', application);
        String JSONString=JSON.serialize(mapLogin);
        request.setBody(JSONString);
        System.debug('loginJson'+JSONString);       
        
        HttpResponse res =http.send(request) ;
		 
        if(res.getStatusCode()==200){
            System.debug(res.getBody());            
            try{
                Map<string,object> resultJSON=(Map<String,object>) JSON.deserializeUntyped(res.getBody());                
                calloutHttpSpeech(contracts,user,pass,feedBody,groupId,(String)resultJSON.get('token_key'),speechTime,retryCount);
            }catch(Exception e){
                System.debug('Exception:'+e.getMessage());
            }        	
            
            
        }else{
            System.debug('CallOut faild'+res);
        }
    }    
    
    private static void calloutHttpSpeech(String contracts,String user,String pass,String feedBody,Decimal groupId,String tokenkey,Datetime speechTime,Integer retryCount){
        System.debug('speechCallOut Start => retryCount:' + retryCount);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://spviewer.recaius.jp/logindex/v1/speech?group_id='+groupId);
        request.setMethod('POST');
        request.setHeader('Accept','application/json, */*');
        request.setHeader('Accept-Encoding','gzip, deflate, br');
        request.setHeader('Accept-Language','ja,en-US;q=0.8,en;q=0.6');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Type','application/json');
        request.setHeader('X-AUTH-TOKEN', tokenkey);
        
        String jsonString = JSON.serialize(new Map<String,Object> {
            'recog_content' => feedBody,
            'speech_timestamp' => speechtime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'UTC'),
            'meta_data' => new Map<String,Object> {
                    'isChatter' => true
                }
        });        
        System.debug('RecaiusLogindexHttpCallout speechCallOut => jsonString:' + jsonString);       
        request.setBody(JSONString);
        
        if(retryCount <4){

            HttpResponse res =http.send(request);        
            if(res.getStatusCode()==200){
                System.debug(res.getBody());                
                calloutHttpLogout(tokenkey);            
            }else if(res.getStatusCode() == 401) {
                System.debug('speechCallOut failed: ' + res);
                calloutHttpLogin(contracts,user,pass,feedBody,groupId,speechTime,retryCount+1);                
            }else{
                System.debug('CallOut faild'+res);
                calloutHttpLogout(tokenkey);
            }

        }else{
            calloutHttpLogout(tokenkey);
        }
        
    }    
  
    private static void calloutHttpLogout(String tokenkey){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint('https://spviewer.recaius.jp/logindex/v1/logout');
        request.setMethod('GET');
        request.setHeader('Accept','application/json, */*');
        request.setHeader('Accept-Encoding','gzip, deflate, br');
        request.setHeader('Accept-Language','ja,en-US;q=0.8,en;q=0.6');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Type','application/json');
        request.setHeader('X-AUTH-TOKEN', tokenkey);
        
        HttpResponse res =http.send(request) ;
        if(res.getStatusCode()==200){
            System.debug('LogoutOK');            
        }else{
            System.debug('CallOut faild'+res);
        }
    }
}