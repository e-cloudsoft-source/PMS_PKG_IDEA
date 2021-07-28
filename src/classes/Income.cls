// 2018/03/07 Security Check BEGIN
public with sharing class Income {
// 2018/03/07 Security Check END

        public String userId
        {get;set;}
        public String msg
        {get;set;}
        private String sortOrder;
        public String currentUserId
        {get;set;}
        public User currentUser
        {get;set;}
        public Asterisk__c asterisk
        {get;set;}
        
        public integer gStartInd
        {get; set;}
        public integer gEndInd
        {get; set;}
        public string sCustomObjSelected
        {get;set;}
        public boolean displayPopup
        {get; set;}
        public boolean enableBtn
        {get; set;}
        
        public boolean disableBtn
        {get; set;}
        

        public Income() {
              enableUpdateExtBtn();
              currentUserId =  UserInfo.getUserId();
              currentUser = Database.query('SELECT id,online_status__c, Alias,AsteriskExtension__c,AsteriskPassword__c,Display_Name__c,Department, EmployeeCode__c,SmallPhotoUrl,Name From User Where id=:currentUserId'); 
              this.sortOrder = 'Name ASC';  
              asterisk = [SELECT Realm__c,Name,WebSocket_Server_URL__c From Asterisk__c where Active__c=true]; 

        }
    
        @RemoteAction
        public static String updateUser(string ID) {
               System.debug('---ID---'+ID);
               User queriedUser = [SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl,Name From User Where EmployeeCode__c=:ID and isActive=true];
               System.debug('---queriedUser ---'+queriedUser );            
               // Update the user status
               queriedUser.online_status__c = true;
               System.debug('---queriedUser.online_status__c---'+queriedUser.online_status__c);
               // Make two separate calls 
               // 1. This call is to update the user status.
               // 2018/03/07 Security Check BEGIN
               if (CommSecurityUtils.isCanUpdateable(User.getSObjectType())) {
               // 2018/03/07 Security Check END
               update queriedUser ;
               // 2018/03/07 Security Check BEGIN
               }
               // 2018/03/07 Security Check END
               return null;
        }

        public String updateUserStatus() {
                User queriedUser = Database.query('SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl,online_status__c From User Where Id =: currentUserId and isActive=true');
                System.debug('---queriedUser ---'+queriedUser );            
                // Update the user status
               if(queriedUser.online_status__c == false ){
                   queriedUser.online_status__c = true;
                   System.debug('---queriedUser.online_status__c---'+queriedUser.online_status__c);
                    // Make two separate calls 
                   // 1. This call is to update the user status.
                   // 2018/03/07 Security Check BEGIN
                   if (CommSecurityUtils.isCanUpdateable(User.getSObjectType())) {
                   // 2018/03/07 Security Check END
                   update queriedUser ;
                   // 2018/03/07 Security Check BEGIN
                   }
                   // 2018/03/07 Security Check END
               }
               return null;
           
        }

        @RemoteAction
        public static String disconnectUser(string ID) {
               System.debug('---ID2---'+ID);
               User queriedUser = [SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl From User Where EmployeeCode__c=:ID and isActive=true];
               System.debug('---queriedUser2 ---'+queriedUser ); 
               queriedUser.online_status__c = false;
               System.debug('---queriedUser.online_status__c2---'+queriedUser.online_status__c);
               // 2018/03/07 Security Check BEGIN
               if (CommSecurityUtils.isCanUpdateable(User.getSObjectType())) {
               // 2018/03/07 Security Check END
               update queriedUser ;
               // 2018/03/07 Security Check BEGIN
               }
               // 2018/03/07 Security Check END
               return null;
        }

        public  String disconnect() {
               User queriedUser = Database.query('SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl,online_status__c From User Where Id =: currentUserId and isActive=true');
               System.debug('---queriedUser ---'+queriedUser );
               if( queriedUser.online_status__c == true){       
               queriedUser.online_status__c = false;
               System.debug('---queriedUser.online_status__c---'+queriedUser.online_status__c);
               // 2018/03/07 Security Check BEGIN
               if (CommSecurityUtils.isCanUpdateable(User.getSObjectType())) {
               // 2018/03/07 Security Check END
               update queriedUser ;
               // 2018/03/07 Security Check BEGIN
               }
               // 2018/03/07 Security Check END
               }
               return null;
        }
    
        public List<User> getUsers(){
           String tempEmpcod = '\''+currentUser.id+'\'';
           list<user> users= Database.query(
                  'SELECT id, EmployeeCode__c, Alias, Department, SmallPhotoUrl,Name FROM User Where  online_status__c=true and IsActive=true and id <>' +tempEmpcod+
                  'ORDER BY ' + sortOrder);
              System.debug('--users---'+users); 
              System.debug('--users---'+users);     
              return users;
        }

        public List<User> getOfflineUsers(){
           System.debug('offline');
           String tempEmpcod = '\''+currentUser.id+'\'';
           List<User> users1= Database.query(
                  'SELECT id, EmployeeCode__c, Name , Alias, Department, SmallPhotoUrl FROM User Where online_status__c=false and IsActive=true and id <>' +tempEmpcod+
                  'ORDER BY ' + sortOrder);
        
              System.debug('--users1---'+users1);  
              System.debug('--users1111---'+users1);    
              return users1;
        }

        public void PostToChatter() {
           List<User> userlist=new List<User>();
           List<FeedItem> feedlist=new List<FeedItem>();
           String tempEmpcod = '\''+currentUser.id+'\'';
           userlist=[select id,name,online_status__c from User where online_status__c=false and id <>: tempEmpcod];
           for(User usr:userlist)
              {
               FeedItem post = new FeedItem();
               post.ParentID = usr.id;
               post.Body = msg;
               feedlist.add(post);
               System.debug('--feedlist--'+feedlist);
               }
               insert feedlist;
            }
        
            // Sort by EmployeeNumber
            public void sortByEmployeeNumber() {
               if(sortOrder == 'EmployeeCode__c ASC') {
                   this.sortOrder = 'EmployeeCode__c DESC';
               }
               else {
                   this.sortOrder = 'EmployeeCode__c ASC';
               }
      
            }

            // Sort by department
            public void sortByDepartment() {
                if(sortOrder == 'Department ASC') {
                    this.sortOrder = 'Department DESC';
                }
                else {
                    this.sortOrder = 'Department ASC';
                }
            }

            public void singleMessage(){
                FeedItem post = new FeedItem();
                post.ParentID = userId;
                post.Body = msg;
                System.debug('--feedlist--'+post);
                insert post;
            }
            
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Author: Zakaria Atom AP Group ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /*public void wait3Seconds() {
        Long startTime = DateTime.now().getTime();
        while(DateTime.now().getTime()-startTime<3000);
    }*/
    
     public void enableUpdateExtBtn(){
         System.debug('------Inside enableUpdateExtBtn------');
        List<User> userList = Database.query('SELECT id FROM User WHERE NOT AsteriskPassword__c LIKE \''+AsteriskManager.getSecret()+'\'');
        System.debug('------userList.size() : '+userList.size()+'------');
        if(userList.size()  > 0){
            enableTheButton();
        }
        else{
            disableTheButton();
        }
     }
     
     
     public String requestLabel;
     public String result {get;set;}
     
     public Object addExtExistingUsers(){
        // Create continuation with a timeout
        Continuation con = new Continuation(40);
        // Set callback method
        con.continuationMethod='processResponse';

        // Create callout request
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('http://54.64.141.227/api.php?status=2&org=Jinya222&extension_string=33700004-33700004'); 
        //req.setEndpoint('http://54.64.141.227/curl.php?rubel=happy');
        
        system.debug('--------'+req.getEndpoint()+'---------');

        // Add callout request to continuation
        this.requestLabel = con.addHttpRequest(req);

        // Return the continuation
        return con;
    }
    
    // Callback method 
    public Object processResponse() {   
        // Get the response by using the unique label
        HttpResponse response = Continuation.getResponse(this.requestLabel);
        // Set the result variable that is displayed on the Visualforce page
        this.result = response.getBody();
        system.debug('------------------this.result=' + this.result+'------------------');
        JSONParser parser = JSON.createParser(response.getBody());
        String nm= '';
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == 'message')) {
                // Get the value.
                parser.nextToken();
                nm = parser.getText();
            }
        }
        system.debug('------------------SIP Start=' + nm+'------------------');
        disableTheButton();

        // Return null to re-render the original Visualforce page
        return null;
    }
    
    public void closePopup() {
        displayPopup = false;
    }

    public void showPopup() {
        displayPopup = true;
    }
    
    public void enableTheButton() {
        System.debug('------enableTheButton------');
        enableBtn = true;
        disableBtn = false;
    }

    public void disableTheButton() {
        System.debug('------disableTheButton------');
        enableBtn = false;
        disableBtn = true;
    }

}