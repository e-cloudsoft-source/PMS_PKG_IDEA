public with sharing class BarcodeScript {

    private Map<String, String> NW7imageIndex = new Map<String, String>{};                                                      /* Map structure */
    public List<String> NW7BarcodeImage = new List<String>{};                                                                   /* <img src /> Tag ID of document of Barcode Image */
    public String customerId;                                                                                                   /* Customer ID */


    public BarcodeScript(ApexPages.StandardController contoroller ) {                                                           /* Constractor */       
//      customerId = String.valueOf(CustomObject1__c.ID333__c);                                                                 /* Put Customer ID */
                customerId = '000000123456789'; 
                string wstr = string.valueof([select Id, name, ID__c from Contact where Id = :contoroller.getId()].ID__c); 		/********* customer Id of getting current database record Id */
                string sero = '';                                                                                               /* Put Customer ID */
//                System.debug('**** wstr : ' + wstr );                                                                   		/* for debug */             
				if ( wstr != null ) {
	                if ( wstr.length() < 15 ) {
	                    for (integer i = 0; i < (15 - wstr.length()); i++ ) {
	                         sero += '0';
	                    }
	                    customerId = sero + wstr;
//	                    System.debug('**** customerId < 15 : ' + customerId );                                                      /* for debug */                 
	                } else {
	                    customerId = wstr;																						/* Case >=15 : Cut over */
//	                    System.debug('**** customerId : ' + customerId );                                                           /* for debug */                 
	                }
				} else {																										/* Case ID null */
					for (integer i = 0; i < 15; i++ ) {
                         sero += '0';
                    }
                    customerId = sero;
				}

                                                                                                                                /* for Map key + keyvale list Initialize */
        NW7imageIndex.clear();
        NW7imageIndex.put('0', 'ps__NW_0');
        NW7imageIndex.put('1', 'ps__NW_1');
        NW7imageIndex.put('2', 'ps__NW_2');
        NW7imageIndex.put('3', 'ps__NW_3');
        NW7imageIndex.put('4', 'ps__NW_4');
        NW7imageIndex.put('5', 'ps__NW_5');
        NW7imageIndex.put('6', 'ps__NW_6');
        NW7imageIndex.put('7', 'ps__NW_7');
        NW7imageIndex.put('8', 'ps__NW_8');
        NW7imageIndex.put('9', 'ps__NW_9');          
        NW7imageIndex.put('a', 'ps__NW_a_start');                                                                                  /* Start character code */
        NW7imageIndex.put('b', 'ps__NW_b_start');                                                                                  /* Stop character code */
        
        getimagetag();
    }
    
    
    
/*
*  function getimagetag: join NW7 barcode image index of each character data in document tab
*
*                 img tag of 18 numbers
*       return : '<img src=------/><img src=------/><img src=------/><img src=------/>------<img src=------/>'
*
*
*/
    public String getimagetag() {
        Integer Checkdigit = 0;
        String wcustomerId = customerId + ' ';                                                                                  /* Put space dummy for substring last character index */
        List<String> wk = new List<String>{};
        wk.clear();
        wk.add('a');                                                                                                            /* push start code */                                                                                           
        for ( Integer num = 0; num < 15; num++ ) {                                                                              /* Get Check digit */
            if ( math.mod(num+1,2) != 0 ) {                                                                                     /* Check ODD or EVEN */
                 Checkdigit += Integer.valueOf(wcustomerId.substring(num,num+1)) * 2;                                           /* ODD * 2 */
            } else {
                 Checkdigit += Integer.valueOf(wcustomerId.substring(num,num+1));                                               /* EVEN * 1 */              
            }
            wk.add(wcustomerId.substring(num,num+1));                                                                           /* Put one character of customer id */
        }
        
        if ( math.mod(Checkdigit,10) == 0 ) {
            wk.add('0');                                                                                                        /* Put Check digit */
        } else {
            wk.add(String.valueOf(10 - math.mod(Checkdigit,10)));                                                               /* Put remain Check digit */
        }
        wk.add('b');                                                                                                            /* push stop code */
                                                                                                                                /* Get img tag of Start character code */
                                                                                                                                /* Get img tag of Customer ID character code */
                                                                                                                                /* Get img tag of Check digit code */
//      String temp;                                                                                                                        /* Get img tag of Stop character code */
        NW7BarcodeImage.clear();                                                                                                /* Clear Map */
        for ( Integer nnum = 0; nnum < 18; nnum++ ) {
            NW7BarcodeImage.add('/resource/' + NW7imageIndex.get(wk[nnum]));                                                    /* Put image tag url */
//          NW7BarcodeImage.add('/servlet/servlet.FileDownload?file=' + NW7imageIndex.get(wk[nnum]));
            //NW7BarcodeImage += '<apex:image url="https://ap.salesforce.com/servlet/servlet.FileDownload?file=' + NW7imageIndex.get(wk[nnum]) + '" width="20" height="40"/>';                          /* Put image tag url */
            //NW7BarcodeImage += '<img src="/servlet/servlet.FileDownload?file=' + NW7imageIndex.get(wk[nnum]) + '" />';            /* Put img tag */
            //IMAGE("https://ap.salesforce.com/servlet/servlet.FileDownload?file=01510000000M1t9", "婚礼")
            //<apex:image url="https://ap.salesforce.com/servlet/servlet.FileDownload?file=01510000000MCZj"  width="20" height="40"/>
            //temp = 'https://ap.salesforce.com/servlet/servlet.FileDownload?file=' + NW7imageIndex.get(wk[nnum]);
        }           
//      System.debug('**** NW7BarcodeImage : ' + NW7BarcodeImage );                                                                 /* for debug */
//              System.debug('**** temp : ' + temp );                                                                   /* for debug */                 
        return 'Great'; 
    }
    /* Get barcode image width and height */
    public String getbwidth() {     return '"15"';  }
    public String getbheight() {    return '"40"';  }
    /* Get customer ID */
    public String getcustomerid() { return customerId; }
    /* Get url string of bar code image index  */
    public String getnum1() {       return NW7BarcodeImage[0];          }
    public String getnum2() {       return NW7BarcodeImage[1];          }
    public String getnum3() {       return NW7BarcodeImage[2];          }
    public String getnum4() {       return NW7BarcodeImage[3];          }
    public String getnum5() {       return NW7BarcodeImage[4];          }
    public String getnum6() {       return NW7BarcodeImage[5];          }
    public String getnum7() {       return NW7BarcodeImage[6];          }
    public String getnum8() {       return NW7BarcodeImage[7];          }
    public String getnum9() {       return NW7BarcodeImage[8];          }
    public String getnum10() {      return NW7BarcodeImage[9];          }
    public String getnum11() {      return NW7BarcodeImage[10];         }
    public String getnum12() {      return NW7BarcodeImage[11];         }
    public String getnum13() {      return NW7BarcodeImage[12];         }
    public String getnum14() {      return NW7BarcodeImage[13];         }
    public String getnum15() {      return NW7BarcodeImage[14];         }
    public String getnum16() {      return NW7BarcodeImage[15];         }
    public String getnum17() {      return NW7BarcodeImage[16];         }
    public String getnum18() {      return NW7BarcodeImage[17];         }
    
    
}