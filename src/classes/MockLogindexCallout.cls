/**
 * テスト用HttpCalloutモッククラス
 * 
 * 本番組織リリース時に必要なテストクラス
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
@isTest
global class MockLogindexCallout implements HttpCalloutMock {
    	public static Boolean LogindexStatusCode = false;
   	    public static Boolean LogindexSpeechStatusCode = false;
    	public static Boolean LogindexLogoutStatusCode = false;
	    public static Boolean LogindexexceptionStatusCode = false;
    
    	global HTTPResponse respond(HTTPRequest req){
        HTTPResponse res = new HTTPResponse();
           
        if(req.getEndpoint().startswithIgnoreCase('https://spviewer.recaius.jp/logindex/v1/login')){
            if(LogindexStatusCode){
        		res.setStatusCode(401);
            	System.debug('httpStatus401');
            }else if(LogindexexceptionStatusCode&&LogindexSpeechStatusCode){                
        		res.setHeader('Content-Type','application/json');        		
        		res.setStatusCode(200);
            }else{            	
        		res.setHeader('Content-Type','application/json');
        		res.setBody('{"token_key":"test1048"}');
        		res.setStatusCode(200);
            }
        }
        
        else if(req.getEndpoint().startswithIgnoreCase('https://spviewer.recaius.jp/logindex/v1/speech?group_id=' + 443)){
            if(LogindexSpeechStatusCode){
                res.setStatusCode(401);
                System.debug('--SpeechFalse401--');
            }else if(LogindexexceptionStatusCode&&LogindexLogoutStatusCode){
                res.setStatusCode(400);
                System.debug('--SpeechFalse400--');
            }else{            	
        		res.setHeader('Content-Type','application/json');
            	res.setHeader('X-AUTH-TOKEN', 'test1048');
        		res.setBody('{"recog_content:"test","session_key":"3ohenwioseiu9","speech_id":"oewqe308hfngnbi","token_key":"test1048"}');
        		res.setStatusCode(200);
            }
         }  
        else if(req.getEndpoint().startswithIgnoreCase('https://spviewer.recaius.jp/logindex/v1/logout')){
            if(LogindexLogoutStatusCode){
                res.setStatusCode(401);
                System.debug('--LogoutResponseFalse--');
            }else{
             res.setStatusCode(200);
            }
        }else{system.debug('--else--');}
        return res;
    }

}