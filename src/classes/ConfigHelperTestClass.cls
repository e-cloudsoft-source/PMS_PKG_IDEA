@isTest(SeeAllData=false)
private class ConfigHelperTestClass {

    private String retUrl;    
    
   static testMethod void ConfigHelperTest() { 
 
        JinyaConfig__c config = new JinyaConfig__c(Name='idpurl',Value__c = 'https://jinya.my.salesforce.com/idp/login?app=0sp10000000CaZB');
        insert config;
        ConfigHelper ch  = new ConfigHelper(); 
        String retUrl = ch.getDiscussionUrl();
    
       System.debug('Jinya Config object value: ' + retUrl);

       // Test that the trigger correctly updated the price
      System.assertEquals('https://jinya.my.salesforce.com/idp/login?app=0sp10000000CaZB', retUrl);
      ch.sendImage();
      //ch.processResponse();
   
    }
}