/**
 * ChatterFeedCommentTriggerクラス
 * 
 * chatterに入力されたcommentをRECAIUSへ投稿します。
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
trigger ChatterFeedCommentPost on FeedComment (after insert) {
    // 2018/03/26 共通定義に機能有効フラグ追加 BEGIN
    if (!CommDefine__c.getOrgDefaults().RecaiusFlg__c) return;
    if (UserInfo.getUserType() == 'LicenseManager') return;
    // 2018/03/26 共通定義に機能有効フラグ追加 END
    if(Trigger.isInsert&&Trigger.isAfter){
        for(FeedComment fc : Trigger.new){
            System.debug(fc);
            String commentBody = fc.CommentBody;
            String FitemId = fc.FeedItemId;
            String createUserId = fc.CreatedById;
            List<FeedItem> fi = [SELECT id,body,ParentId From FeedItem Where id=:FitemId limit 1];
            System.debug(fi);            
            List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
           

            //メンション情報取得 FeedComment
           // Boolean FeedCommentMentionFlg =false;
            ConnectApi.Comment feedc = ConnectApi.ChatterFeeds.getComment(Network.getNetworkId(), fc.Id);
            System.debug(feedc);
            List<ConnectApi.MessageSegment> msegc = feedc.body.messageSegments;
            for(ConnectApi.MessageSegment messagc:msegc){
                if(messagc instanceof ConnectApi.MentionSegment){
                    ConnectApi.MentionSegment mentionc =(ConnectApi.MentionSegment)messagc;
                    System.debug(mentionc);
                    String cName = mentionc.Name;
                    String cRecord = mentionc.record.id;
                    System.debug(cName);
                    System.debug(cRecord);
                     try{
                            Ruser =[SELECT Id,Password__c, contactId__c, userId__c, RecaiusGroup__c, RecaiusGroup_Id__c, ChatterGroup__c, ChatterGroup_Id__c 
                                    FROM RecaiusUserInfo__c 
                                    WHERE ChatterGroup_Id__c =:cRecord
                                   ];
                    }catch(Exception e){
                        System.debug(e.getMessage());

                    }                        
                }
            }

            if(Ruser.size()==0){
                System.debug('not match group');
                return;
            }

            String postBody =commentBody.replaceAll('<[^>]+>','');
            //投稿ユーザ情報取得
            List<User> feedusers = [SELECT Id,UserName,LastName,FirstName FROM User WHERE Id =: createUserId];
            if(feedusers.size() > 0){
                System.debug('user infomation'+feedusers.get(0));
                String s = '';
                if(String.isNotEmpty(feedusers.get(0).LastName)){
                    s = feedusers.get(0).LastName;
                }
                if(String.isNotEmpty(feedusers.get(0).FirstName)){
                    s = s +' '+ feedusers.get(0).FirstName;
                }
                postBody = s+'さんからのコメントです。\r\n'+postBody;
                System.debug(postBody);
            }

             for(Integer i=0,j=Ruser.size() ; i < j ; i++){
                
                String Contact = Ruser[i].contactId__c;
                String user = Ruser[i].userId__c;
                String pass = Ruser[i].Password__c;
                Decimal Rgroup_Id = Ruser[i].RecaiusGroup_Id__c;
                System.debug('user: '+user+' feed: '+postBody);
                
                if(Rgroup_Id!=null){
                    System.debug('CallOut Start');
                    HttpCallout.RecaiusPost(Contact,user,pass,postBody,Rgroup_Id,fc.CreatedDate);
                    System.debug('End CallOut');
                }                
                
            }           
        }
    }   

}