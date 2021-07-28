public class IncomeNewTab {

        public String currentUserId
        {get;set;}
        public User currentUser
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
        
        public boolean displayAnim
        {get; set;}
        
        public String requestLabel;        
        public String result
        {get;set;}
        
        public String requestLabelBulk;        
        public String resultBulk
        {get;set;}
        
        public static final String BASE_URI = 'http://54.238.145.18/api.php?';
        
        public IncomeNewTab() {
              //closeAnimPopup();
              enableUpdateExtBtn();
               currentUserId =  UserInfo.getUserId();
              currentUser = Database.query('SELECT id,online_status__c, Alias,AsteriskExtension__c,AsteriskPassword__c,Display_Name__c,Department, EmployeeCode__c,SmallPhotoUrl,Name From User Where id=:currentUserId'); 
              
        }
        
        
         //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Author: Zakaria Atom AP Group ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     

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
         //Method for developement time
         public void revertExistingUsers(){
            System.debug('------Inside revertExistingUsers------');
            List<User> userList = Database.query('SELECT id FROM User WHERE AsteriskPassword__c LIKE \''+AsteriskManager.getSecret()+'\'');
            if(userList.size()  > 0){
                System.debug('------if(userList.size()  > 0)------');
                try{
                    for(User user : userList){
                        user.AsteriskExtension__c =  NULL;
                        user.AsteriskPassword__c = NULL;
                        user.Display_Name__c = NULL;
                        update user;
                    }
                    enableTheButton();
                }
                catch(Exception e){
                    System.debug('An unexpected error has occurred: ' + e.getMessage());
                }
                System.debug('------enableBtn :'+enableBtn +'------');
            }
         }
         
         public PageReference redirect()
         {
             System.debug('------------------IncomeNewTab-redirect: Starting ------------------');
             PageReference pr = new PageReference('/apex/IncomeCallPageNew');
             return pr;
         }
         public PageReference registerName(){
            System.debug('------------------IncomeNewTab-egisterName: Starting ------------------');
            System.debug('---currentUser.Display_Name__c: '+currentUser.Display_Name__c+'; currentUser.Name: '+currentUser.Name+'---');
            if(currentUser.Display_Name__c != null && currentUser.Display_Name__c.indexOf(currentUser.Name) != -1){                
                return redirect();
            }
            else{
                updateDisplayName();
                System.debug('------------------not containing the name ------------------');
            }
            
            System.debug('------------------registerName: Ending ------------------');
            return null;
        }
        
         public Object addExtExistingUsers(){
            showAnimPopup();
            System.debug('------Inside addExtExistingUsers------');
            // Create continuation with a timeout
            Continuation con = new Continuation(120);
            // Set callback method
            con.continuationMethod='processResponseStart';
    
            // Create callout request
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint(BASE_URI+'status=1');
            System.debug('------------------req.setEndpoint:'+req.getEndpoint()+'------------------');
            // Add callout request to continuation
            this.requestLabel = con.addHttpRequest(req);
    
            // Return the continuation
            return con;
        }
        
        public Object processResponseStart() {
            // Get the response by using the unique label
            HttpResponse response = Continuation.getResponse(this.requestLabel);
            // Set the result variable that is displayed on the Visualforce page
            this.result = response.getBody();
            
            JSONParser parser = JSON.createParser(response.getBody());
            String st= '';
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'organization_extension')) {
                    // Get the value.
                    parser.nextToken();
                    st = parser.getText();
                }
            }
            system.debug('------------------SIP Start=' + st+'------------------');
            gStartInd = integer.valueof(st);
            gEndInd = new AsteriskManager().updateUsersExt(gStartInd);
            //disableTheButton();
            //closeAnimPopup();
            showPopup();
            // Return null to re-render the original Visualforce page
            return null;
        }
        
        public Object createBulkExt(){
            System.debug('------------------createBulkExt: Starting------------------');
            String org = getOrgName();
            // Create continuation with a timeout
            Continuation con = new Continuation(120);
            // Set callback method
            con.continuationMethod='processResponseBulk';
    
            // Create callout request
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            //gEndInd = gStartInd + 5;//test code
            System.debug('------'+BASE_URI+'status=2&org='+org+'&extension_string='+gStartInd+'-'+gEndInd+'-------');
            req.setEndpoint(BASE_URI+'status=2&org='+org+'&extension_string='+gStartInd+'-'+gEndInd);  
            //req.setEndpoint(BASE_URI+'status=2&org=Jinya connect&extension_string=1100005-1100008'); 
    
    
            // Add callout request to continuation
            this.requestLabelBulk = con.addHttpRequest(req);
            System.debug('------------------createBulkExt: Ending  -- '+req.getEndpoint()+'------------------');
            // Return the continuation
            return con;
        }
        
        public Object processResponseBulk(){
            System.debug('------------------processResponseBulk: Response Received------------------');
            System.debug('------------------processResponseBulk: Starting ------------------');
            // Get the response by using the unique label
            HttpResponse response = Continuation.getResponse(this.requestLabel);
            // Set the result variable that is displayed on the Visualforce page
            this.resultBulk = response.getBody();
            JSONParser parser = JSON.createParser(response.getBody());
            String nm= '';
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'success')) {
                    // Get the value.
                    parser.nextToken();
                    nm = parser.getText();
                }
            }
            system.debug('------------------SIP Start=' + nm+'------------------');
            disableTheButton();
            closePopup();
    
            // Return null to re-render the original Visualforce page
            return null;
    
            disableTheButton();
            System.debug('------------------processResponseBulk: Ending ------------------');
            return null;   
        }
        
        //@RemoteAction      
        public void updateDisplayName(){
            currentUser.Display_Name__c = getOrgName()+ '-' + currentUser.Name + '-' + currentUser.AsteriskExtension__c;
            update currentUser;
        }
        
        public String getOrgName(){
            return AsteriskManager.getOrgName();
        }
        
        public void closePopup() {
            displayPopup = false;
        }
        
        public void showPopup() {
            displayPopup = true;
        }
        
        public void showAnimPopup() {
            displayAnim = true;
        }
        
        public void closeAnimPopup() {
            displayPopup = false;
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