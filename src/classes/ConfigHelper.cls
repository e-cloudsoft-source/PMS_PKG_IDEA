public with sharing class ConfigHelper {
       
    private String retUrl;
    public string Photolink ; 
  
    
    private JinyaConfig__c jinyaConfig ;
    private String key;
     public String getDiscussionUrl() {
             key =  'idpurl';
             jinyaConfig = Database.query('SELECT Value__c  From JinyaConfig__c Where    Name =:key'); 
             //retUrl = jinyaConfig.Value__c+'?userId='+UserInfo.getUserId();
             retUrl = jinyaConfig.Value__c;
             return retUrl;
             //return jinyaConfig.Value__c;
        }
    
    
    public Void sendImage(){
        // AWS側の提供する予定情報
        //  組織名
        //  お客様名
        //  組織/店舗ロゴ
        //  組織/店舗名
        
        User u = [Select u.SmallPhotoUrl, u.FullPhotoUrl From User u where u.id=:Userinfo.getUserid()];
        this.Photolink = u.SmallPhotoUrl;
        try {
            // 2018/03/07 Security Check BEGIN
            List<String> chkFieldsLst = new List<String>{'syncshopname__c','syncshoplogo__c','userphotourl__c'};
            Map<String,Schema.SObjectField> mm = Schema.SObjectType.User.fields.getMap();
            if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
            	return ;
            }
            // 2018/03/07 Security Check END
            // Query for the contact, which has been associated with an account.
            User uu  = [Select uu.userPhotourl__c, SyncShopLogo__c ,SyncShopName__c
                        From User uu where uu.id=:Userinfo.getUserid()];
            // Update the contact's phone number
            uu.userPhotourl__c = Photolink;            

            // 店舗ロゴ
            uu.SyncShopLogo__c = '';
            // 組織名
            uu.SyncShopName__c = ([Select Name From Organization limit 1][0]).name;
            list<UserAppMenuItem> appMenus = [select Id, LogoUrl, name from UserAppMenuItem where name = 'Jinyaconnect' and LogoUrl != null];
            // LogoURLが存在すると、該当URLのID情報を取得する、該当IDは項目に設定する
            if (!appMenus.isEmpty()) {
                UserAppMenuItem appMenu = appMenus[0];
                String docId = appMenu.LogoUrl.substringBetween('id=','&');
                uu.SyncShopLogo__c = docId;
            }
            uu.SyncShopLogo__c += ';';
            // 該当ユーザーの店舗名と店舗コード情報を項目に設定を行う
            try {
                ReportLogo__c rep = CommRepUtils.getReportTitleInfo(); 
                String logoUrl = CommUtils.nullToBlank(rep.ReportLogo__c);
				String reporLogotURL = CommUtils.nullToBlank(logoUrl.substringBetween( ' src="', '"' ));
                if (!CommUtils.isBlank(reporLogotURL)) uu.SyncShopLogo__c += reporLogotURL;
                if (!CommUtils.isBlank(rep.ShopInfoRef__r.Name)) uu.SyncShopName__c = rep.ShopInfoRef__r.Name;
                // ロゴ
            } catch (CommException e) {}
            // 店舗名情報を設定する
            
            update uu;
        } catch(Exception e) {
            System.debug(loggingLevel.info,'An unexpected error has occurred: ' + e.getMessage());
        }
        Rubel0071(Photolink);
        // 2018/11/15 AWSへRequest情報をログに記録する WSQ BEGIN
        CommLogUtils log = new CommLogUtils('DiscussionForum',true);
        log.write_method_start('accesslog');
        map<String, String> mapHeaders = ApexPages.currentPage().getHeaders();
        for (String key : mapHeaders.keyset()) {
        	log.write_log(key+'= '+mapHeaders.get(key));
        }
        log.write_method_end();
        CommLogUtils.saveLogToDb(log.getAllLog(),CommLogUtils.LogType.DISCUSSION,1000);
        // 2018/11/15 AWSへRequest情報をログに記録する WSQ END
    }
        
    public Object Rubel0071(String Photolink){
        system.debug('Inside 71: '+Photolink);
        return null;
    }
    public String requestLabel;
    public String result {get;set;}
        
    public Object Rubel007(String Photolink){
        system.debug(Photolink);   
           
        Continuation con = new Continuation(40);     
        con.continuationMethod='processResponse';

       
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('http://54.64.141.227/curl.php?rubel=00000000'); 
        system.debug('--------'+req.getEndpoint()+'---------');

        // Add callout request to continuation
        this.requestLabel = con.addHttpRequest(req);

        // Return the continuation             
        //req.setEndpoint('https://jinyadiscussionforum.com/communityHome/getCurlResponse?rubel=gm'); 
        //req.setBody('userid:userid&imagedata: '+strBase64);
        //req.setBody('mithu');    
        System.debug(req);

        return this.requestLabel;
                
    }
    
     public Object processResponse() {   
        HttpResponse response = Continuation.getResponse(this.requestLabel);
        this.result = response.getBody();
        system.debug('this.result=' + this.result);
        return null;
    }
    
}