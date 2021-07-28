public with sharing class frontaccount {

    private AccountMaster__c master;
    
public frontaccount(ApexPages.StandardController controller){
        
        //query '会計マスター' current page      
        
        master = [select id,name from AccountMaster__C limit 50000];
  
}    
      //return system.now ;
/**
*2015-11-18 
*テストクラスfrontaccountTestに移行する
	@isTest 
	static void testCase1() {
		List<AccountMaster__c> accMstLst = TestCommon.createProductMst(1);
    	ApexPages.StandardController handel = new ApexPages.StandardController(accMstLst[0]);
    	frontaccount contrl = new frontaccount(handel);
    	System.assert(contrl != null);
	}
*/
}