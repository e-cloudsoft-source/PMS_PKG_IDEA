/**
* This class is used to sync Account and Contact with call information object
* When new call comes and customer is not found then user can create new account/contact through link
* so when use create new account/contact, it will get updated on call information object
*/
public class CustomerCallInfoSyncHandler{
    
    /**
    * This method gets called from account and contact trigger
    */
    public static void afterInsertCustomer(List<Sobject> customerList){
        if(customerList != null && customerList.size() > 0){
            Map<String,Sobject> phoneNumbers = new Map<String,Sobject>();
            for(Sobject sobj: customerList){
                string phone = (sobj.get('Phone')+'');
                if(phone != null){
                    /**
                    * Replace any character other than digit to a blank value
                    * as sno in call information is without any special character
                    */
                    string phoneOnlyNumbers = phone.replaceAll('[^\\d]','');
                    phoneNumbers.put(phone,sobj);
                }
            }
            
            /**
            * Fetch call information with matching number
            */
            List<Call_Information__c> searchResult = [select id,SNO__c,isRSNP__c,isDCD1__c 
                                                        from call_information__c 
                                                        where sno__c in: phoneNumbers.keyset()];
            
            /**
            * This is used to check if the trigger is executed for account or contact
            */                                            
            Schema.SobjectType type = customerList[0].getSobjectType();
            
            for(Call_Information__c callInfo: searchResult){
                /**
                * If not RSNP then process
                */
                if(!callInfo.isRSNP__c){
                    /**
                    * For type 2 populate account
                    */
                    if(type == Account.sobjectType && callInfo.isDCD1__c){
                        callInfo.Account__c = phoneNumbers.get(callInfo.sno__c).Id;
                    }
                    else  if(type == Contact.sobjectType && !callInfo.isDCD1__c){
                        /**
                        * If other than type 2 then populate contact and account link should point to contact's
                        * account
                        */
                        callInfo.Contact__c = phoneNumbers.get(callInfo.sno__c).Id;
                        if(phoneNumbers.get(callInfo.sno__c).get('AccountId') != null){
                            callInfo.Account__c = phoneNumbers.get(callInfo.sno__c).get('AccountId') + '';
                        }
                    }
                    /**
                    * Set matching count to 1
                    */
                    callInfo.No_of_Matching_Customers__c = 1;
                    
                    /**
                    * This is used to check that record is updated from contact/account trigger
                    */
                    callInfo.IsCustomerUpdated__c = true;
                }
            }
            
            update searchResult;                
        }
    }
    
}