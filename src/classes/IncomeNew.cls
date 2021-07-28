// 2018/02/23 Security Check BEGIN
public with sharing class IncomeNew {
// 2018/02/23 Security Check END

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
        
        public IncomeNew() {
              currentUserId =  UserInfo.getUserId();
              currentUser = Database.query('SELECT id,online_status__c, Alias,AsteriskExtension__c,AsteriskPassword__c,Display_Name__c,Department, EmployeeCode__c,SmallPhotoUrl,Name From User Where id=:currentUserId'); 
              this.sortOrder = 'Name ASC';  
              asterisk = [SELECT Realm__c,Name,WebSocket_Server_URL__c From Asterisk__c where Active__c=true];
              //updateUserStatus();
              /*if(currentUser.online_status__c == false ){
                   currentUser.online_status__c = true;
                   System.debug('---IncomeNew : currentUser.online_status__c---'+currentUser.online_status__c);
                    // Make two separate calls 
                   // 1. This call is to update the user status.
                   update currentUser;
               } */
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
               update queriedUser ;
               return null;
        }

        public String updateUserStatus() {
                User queriedUser = Database.query('SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl,online_status__c From User Where Id =: currentUserId and isActive=true');
                System.debug('---updateUserStatus: queriedUser ---'+queriedUser );            
                // Update the user status
               if(queriedUser.online_status__c == false ){
                   queriedUser.online_status__c = true;
                   System.debug('---updateUserStatus : queriedUser.online_status__c---'+queriedUser.online_status__c);
                    // Make two separate calls 
                   // 1. This call is to update the user status.
                   update queriedUser ;
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
               update queriedUser ;
               return null;
        }

        public  String disconnect() {
               User queriedUser = Database.query('SELECT id, Alias, Department, EmployeeCode__c, SmallPhotoUrl,online_status__c From User Where Id =: currentUserId and isActive=true');
               System.debug('---queriedUser ---'+queriedUser );
               if( queriedUser.online_status__c == true){       
               queriedUser.online_status__c = false;
               System.debug('---queriedUser.online_status__c---'+queriedUser.online_status__c);
               update queriedUser ;
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
}