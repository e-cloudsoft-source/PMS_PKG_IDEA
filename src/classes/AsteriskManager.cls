public class AsteriskManager{

    static final String SECRET = '53CR3T';
    
    static final integer DELAY = 12;
    
    private static String startExt = NULL;
    
    private static integer bulkCrtStatusCode = -999;
    
    private static String gExtension
        {get;set;}
    
    /*public integer processResponseStart(HttpResponse response) { 
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
        system.debug('------------------SIP Start=' + st +'------------------');
        integer enExt = updateUsersExt(integer.valueof(st));
        system.debug('------------------SIP end=' + enExt +'------------------');
        // Return null to re-render the original Visualforce page
        return enExt;
    }*/
    
    public integer updateUsersExt(integer iStExt){
        System.debug('------------------updateUsersExt------------------');
        List<User> userList = Database.query('SELECT id FROM User WHERE NOT AsteriskPassword__c LIKE \''+AsteriskManager.getSecret()+'\'');
        if(userList.size() <=0 || iStExt== NULL){
            //TODO failed processing
            System.debug('------------------updateUsersExt if(stExt == NULL)------------------');
            return 0;
        }
        
        try{ 
            System.debug('------------------updateUsersExt try Starting------------------');            
            for(User user : userList){
                //System.debug('------------------for(User user : userList):START------------------');
                user.AsteriskExtension__c = iStExt+'';
                user.AsteriskPassword__c = AsteriskManager.getSecret();
                user.Display_Name__c = getOrgName()+'-'+iStExt;
                //update user;
                iStExt = iStExt+1;
                //System.debug('------------------for(User user : userList):END------------------');
            }
            //Call Astersik server to bulk register users
             update userList;
             System.debug('------------------updateUsersExt try closing------------------');
            //TODO if statusCode == 200 then Success else filed and process failed 
            return iStExt -1;
        }
        catch(Exception e){
            System.debug('An unexpected error has occurred: ' + e.getMessage());
            //TODO Process rollback
        }
        return 0;        
    }  
    
    public static void injectExt(User[] userList) {
        System.debug('Inside Apex: AsteriskManager.injectExt()'+userList.size());
        //impl inject Ext
        for(User user : userList){
            String extension = user.AsteriskExtension__c;
            System.debug('Inside Apex: AsteriskManager.injectExt()-> gExtension: '+gExtension );
            createNewExt(extension );
            
        }
    }
    
    @future (callout=true)
    public static void createNewExt(String extension){
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String org = getOrgName();
        
        req.setEndpoint(IncomeNewTab.BASE_URI +'status=3&org='+org+'&extension='+extension); 
        System.debug('Inside createNewExt:'+ req.getEndpoint());

        Http http = new Http();
      
        try {
            System.debug('Inside AsteriskManager.createNewExt()->try');
            //Execute web service call here     
            HTTPResponse res = http.send(req); 
            
            //System.debug(res.getBody());
            System.debug('STATUS:'+res.getStatus());
            System.debug('STATUS_CODE:'+res.getStatusCode());
            
        } catch(System.CalloutException e) {
            //Exception handling goes here....
            System.debug('Inside Apex: AsteriskManager.createNewExt()->catch');
        }
    }  
    
    //Getter and Setters
    public static String getSecret(){
        return SECRET;
    }
    
    public static String getNewExt(){
        AggregateResult[] groupedResults = [SELECT MAX(AsteriskExtension__c)maxext FROM User WHERE AsteriskPassword__c LIKE '53CR3T'];
        System.debug('getNewExt:'+ groupedResults );
        if(groupedResults == null || groupedResults.size() > 0){
            Object maxext = groupedResults[0].get('maxext');
            System.debug('getNewExt: maxext '+ maxext );
            integer iMaxExt = integer.valueof(maxext)+1;
            System.debug('getNewExt: iMaxExt '+ iMaxExt );
            return iMaxExt +'';
        }
        else{
            return '100001';
        }
        
    }
    
    public static string orgName
    {get; set;}
    
    public static string getOrgName(){
        if(OrgName == null){
            Organization myOrg = [Select o.Name From Organization o];
            orgName = myOrg.Name;
        }
        
        return replaceSpace(orgName);
    }
    
    public static string replaceSpace(string s){
        s = s.replaceAll(' ','%20');
        return s;
    }
    
    public static void sleep(integer m){
        Long startingTime = System.now().getTime(); // Num milliseconds since Jan 1 1970
        Integer delayInMilliseconds = 1000; // One-second delay
        while (System.now().getTime() - startingTime < m*delayInMilliseconds)  {
                // Do nothing until desired delay has passed
        }
    }
    
    public static String getStartExt(){
        System.debug('------------------getStartExt: Start------------------');
        integer i = 0;
        for(i = 0; i < DELAY; i++){
            if(startExt != NULL){
                return startExt;
            }
            else{
                sleep(1);
            }
        }
        System.debug('------------------getStartExt: Start:'+i+'------------------');
        return NULL;
    }
    
    public static void resetStartExt(){
        startExt = NULL;
    }
    
    public static integer getBulkCrtStatusCode(){
        for(integer i = 0; i < DELAY; i++){
            if(bulkCrtStatusCode != NULL){
                return bulkCrtStatusCode;
            }
            //sleep for 1 sec
            for(integer j = 0; j < 1000; j++){
            }
        }
        return -999;
    }
    
    public static void resetBulkCrtStatusCode(){
        bulkCrtStatusCode = -999;
    }

}