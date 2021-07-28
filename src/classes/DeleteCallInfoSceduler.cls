/*
 * @Date: August 14, 2013
 * @Description: Scheduler class to delete Call Information 
            & utility method to check cal information permission for the logged in user
 */
global with sharing class DeleteCallInfoSceduler implements Schedulable{
    
    //Execute method called when sceduler is invoked
    global void execute(SchedulableContext SC) {
        /*List<Call_Information__c> lstCallInformation = [Select Id 
                from Call_Information__c 
                where CreatedDate <= :System.now()];
        try{
            delete lstCallInformation;
        }catch(Exception ex){
            system.debug('--Exception: ' + ex.getMessage());
        }*/
    }
    
    //Function to check call information popup permissin for the logged in user
    webservice static Boolean checkCallInformationPermission(){
        /*List<User> lstUser = [Select Id, isCallInformationEnabled__c 
                from User where Id = :Userinfo.getUserId()];
        if(lstUser != null && lstUser.size() == 1){
            return lstUser[0].isCallInformationEnabled__c;
        }
        */
        return false;
    }
    
    //@Description global class to implement http mock callout
     
    global class HttpCalloutMockImpl implements HttpCalloutMock{
         
         //~Usage: function to implement http response
         global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            Boolean permission = true;
            res.setBody('' + permission);
            res.setStatusCode(200);
            return res;
        }
    }
    
}