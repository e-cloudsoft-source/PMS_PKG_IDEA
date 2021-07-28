public with sharing class CntNearByAccount {
//    public Contact a{get; private set;}

//    public CntNearByAccount(ApexPages.StandardController stdController) {
//        a = (Contact)stdController.getRecord();																							/* Get current customer record */
//        if (  a.MailingStreet == null ) {
//            a.MailingStreet = '1 Place Charles de Gaulle 75008 Paris'; 																	/* for default */
//            a.MailingStreet = getDefaultMaddr();																						/* for default */
//        } else {
//        	if ( a.MailingPostalCode != null ) { 
//       		a.MailingPostalCode = getRemovedScri(a.MailingPostalCode);
//        	}
//        	if ( a.MailingState != null ) { 
//        		a.MailingState = getRemovedScri(a.MailingState);
//        	}
//        	if ( a.MailingCity != null ) { 
//        		a.MailingCity = getRemovedScri(a.MailingCity);
//        	}
//       		a.MailingStreet = getRemovedScri(a.MailingStreet);
//        }
//    }
    
//    public string getDefaultMaddr () {
//    	return '450 Serra Mall Stanford, CA 94305, United States';
//    }
//    private string keyName;
//    private List<Contact> AccountsData;
//    public Object[] getAccountsData(){
//        Object[] jsonData = new Object[]{};
//        AccountsData = new List<Contact>();
        
//       System.debug(' ********getAccountsData ');
        																																/* Near by current contact */
/*        string patterns;
        if ( (a.MailingCity == null && a.MailingState == null) && a.MailingStreet != null ) {
            patterns = '%' + a.MailingStreet.substring(0,4) + '%';
            AccountsData = [SELECT Id, Name, MailingPostalCode, MailingState, MailingCity, MailingStreet, Description FROM Contact where Id != :a.Id and MailingStreet like :patterns limit 10];
        } else {
            patterns = '%' + a.MailingCity + '%';
            AccountsData = [SELECT Id, Name, MailingPostalCode, MailingState, MailingCity, MailingStreet, Description FROM Contact where Id != :a.Id and MailingCity like :patterns limit 10];
        }
*/ 
//        for (integer i = 0; i < AccountsData.size(); i++ ) {  
//            jsonData.add(
//                '{name:\'' + AccountsData[i].Name + 
//                    '\', address:\'' + AccountsData[i].MailingPostalCode + AccountsData[i].MailingState + AccountsData[i].MailingCity + AccountsData[i].MailingStreet +
//                    '\', id:\'' + AccountsData[i].Id + 
//                    '\', info:\'' + AccountsData[i].MailingState + AccountsData[i].MailingCity + AccountsData[i].MailingStreet + 
//                '\'}'
//            );
//        }
//       System.debug(' ***Json data: ' + jsonData );
//        return null;
//    }
    
    
//    public string getRemovedScriName() {
//    	return getRemovedScri(a.Name);
//    }
//    public string getRemovedScriAddr() {
//    	return getRemovedScri(a.MailingPostalCode + a.MailingState + a.MailingCity + a.MailingStreet);
//		System.debug('***********What'+(a.MailingStreet));
//    	return (a.MailingPostalCode + a.MailingState + a.MailingCity + a.MailingStreet);
//    	return (a.MailingStreet);
//    }
    // for script
//    private string getRemovedScri(string argstr) {
//    	System.debug(' ********BEFORE Current Contact ' + argstr);
//    	System.debug(' ********AFTER Current Contact ' + rargstr);
//    	return (string.escapeSingleQuotes(argstr)).replaceAll('[\"/<>{}%=;:()&+-]', '');
//    }
    
    
    
}