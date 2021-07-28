/**
 * ChatterFeedTriggerクラス
 * 
 * chatterに入力されたfeedをRECAIUSへ投稿します。
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 

trigger ChatterFeedPost on FeedItem (after insert, before insert,after update,before update) {
    // 2018/03/26 共通定義に機能有効フラグ追加 BEGIN
    if (!CommDefine__c.getOrgDefaults().RecaiusFlg__c) return;
    if (UserInfo.getUserType() == 'LicenseManager') return;
    // 2018/03/26 共通定義に機能有効フラグ追加 END
     if(Trigger.isInsert && Trigger.isAfter) {
        for( FeedItem fi : Trigger.new){
            
            Map<Id,String> mentionMap = new Map<Id, String> {};
                
            //add test post to speechviewer
            String postStr = '#';
            String postStr2 = 'system';
			System.debug('feed'+fi);            
            Boolean topicFlg = false;
            Boolean postFlg = false;            
            ConnectApi.FeedElement fe = ConnectApi.ChatterFeeds.getFeedElement(Network.getNetworkId(), fi.Id);
      	    System.debug('---------'+fe+'---------');
      		ConnectApi.FeedItem cFi = (ConnectApi.FeedItem)fe;
      		List<ConnectApi.MessageSegment> messag = cFi.body.messageSegments;
            String record;
      		//System.debug(messag);
      		for (ConnectApi.MessageSegment mes : messag) {
                if (mes instanceof ConnectApi.MentionSegment) {
                    ConnectApi.MentionSegment mentionSeg = (ConnectApi.MentionSegment)mes;
      				//system.debug(mentionSeg);
        			String toUser = mentionSeg.Name;
        	        record = mentionSeg.record.id;//.substring(0,15);
        			//System.debug(toUser);
        			System.debug(record);                	
                }
       		}        

            List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
            
            try{
                Ruser =[SELECT Id,Password__c, contactId__c, userId__c, RecaiusGroup__c, RecaiusGroup_Id__c, ChatterGroup__c, ChatterGroup_Id__c 
                        FROM RecaiusUserInfo__c 
                        WHERE ChatterGroup_Id__c =:fi.ParentId
                       ];
            }catch(Exception e){
                System.debug(e.getMessage());

            }
            List<RecaiusUserInfo__c> Ruserment = new List<RecaiusUserInfo__c>();
            if(record!=null){
				System.debug('mention id'+record);
                try{
                Ruserment =[SELECT Id,Password__c, contactId__c, userId__c, RecaiusGroup__c, RecaiusGroup_Id__c, ChatterGroup__c, ChatterGroup_Id__c 
                            FROM RecaiusUserInfo__c 
                            WHERE ChatterGroup_Id__c =:record
                           ];
                }catch(Exception e){
                System.debug(e.getMessage());

                }
            }
                        
            System.debug(Ruser);                                 
            //System.debug(Ruser[0].Password__c);
            System.debug(Ruser.size());
            //登録情報参照
            if(Ruser.size()==0 && Ruserment.size()==0){
                System.debug('not match group');
                return;
            }
            String postBody =fi.Body.replaceAll('<[^>]+>','');
            //投稿ユーザ情報取得
            List<User> feedusers = [SELECT Id,UserName,LastName,FirstName FROM User WHERE Id =: fi.CreatedById];
            if(feedusers.size() > 0){
                System.debug('user infomation'+feedusers.get(0));
                String s = '';
                if(String.isNotEmpty(feedusers.get(0).LastName)){
                    s = feedusers.get(0).LastName;
                }
                if(String.isNotEmpty(feedusers.get(0).FirstName)){
                    s = s +' '+ feedusers.get(0).FirstName;
                }
                postBody = s+'さんからの投稿です。\r\n'+postBody;
                System.debug(postBody);
            }
            if(fi.ParentId == record){
                for(Integer i=0,j=Ruser.size() ; i < j ; i++){
                
                    String Contact = Ruser[i].contactId__c;
                    String user = Ruser[i].userId__c;
                    String pass = Ruser[i].Password__c;
                    Decimal Rgroup_Id = Ruser[i].RecaiusGroup_Id__c;
                    System.debug('user: '+user+' feed: '+postBody);
                    
                    if(Rgroup_Id!=null){
                        System.debug('CallOut Start');
                        HttpCallout.RecaiusPost(Contact,user,pass,postBody,Rgroup_Id,fi.CreatedDate);
                        System.debug('End CallOut');
                    }                
                
                }
                return;
            }
            
            Set<Decimal> postsets = new Set<Decimal>();
            if(Ruser.size()>0){
                for(Integer i=0,j=Ruser.size() ; i < j ; i++){
                
                    String Contact = Ruser[i].contactId__c;
                    String user = Ruser[i].userId__c;
                    String pass = Ruser[i].Password__c;
                    Decimal Rgroup_Id = Ruser[i].RecaiusGroup_Id__c;
                    System.debug('user: '+user+' feed: '+postBody);
                    
                    if(Rgroup_Id!=null){
                        System.debug('CallOut Start');
                        HttpCallout.RecaiusPost(Contact,user,pass,postBody,Rgroup_Id,fi.CreatedDate);
                        System.debug('End CallOut');
                        postsets.add(Rgroup_Id);
                    }                
                
                }
            }
            if(Ruserment.size()>0){
                for(Integer i=0,j=Ruserment.size() ; i < j ; i++){                
                    String Contact = Ruserment[i].contactId__c;
                    String user = Ruserment[i].userId__c;
                    String pass = Ruserment[i].Password__c;
                    Decimal Rgroup_Id = Ruserment[i].RecaiusGroup_Id__c;
                    System.debug('user: '+user+' feed: '+postBody);
                    
                    if(Rgroup_Id!=null){
                        if(postsets.size()>0){
                            if(postsets.contains(Rgroup_Id)){
                                return;
                            }
                        }
                        System.debug('CallOut Start');
                        HttpCallout.RecaiusPost(Contact,user,pass,postBody,Rgroup_Id,fi.CreatedDate);
                        System.debug('End CallOut');
                    }                
                
                }
            }           
        }
     }

}