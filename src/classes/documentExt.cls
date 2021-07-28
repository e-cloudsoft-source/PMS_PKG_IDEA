/***
 * CSV file uploading services are automated processes that use Apex classes
 * to process the accounting of Jinya.
 *
 * 2013.02.11 Add Tax copy from Account Master to Tran
 * 2012.9.30 Add Posreg Process
 * 2012.7.12 update Not FOUND KEY process Error Top Index(Ccas : not connect account header record)
 * 2012.1.10 update checking KEY ( receipt#, sales day, and POS# )
 * 2012.1.9 update traffice year in file name
 * 2012.1.7 update table#2A, 3A, 4A,  .....
 * 2011.11.29 update customer object -> contact
 * 2011.08.03 Plan No.
 * 2011.05.31 Add sub price item in tran order record for free drinking.
 * 2011.05.13 Put cost of sales in Baratble
 * 2011.05.09 Check price ¥900 below () for one drink child
 * 2011.5.8 Sales account on 20110503,0504 two days is very stress data of item,item02 CSV file.
 * 2011.4.24 Parsing phone traffic data file 
 * 2011.4.12 Account of Persons, operating rate and amount without tax fee
 * 2011.4.5 SHIFT,ZTOTAL add
 * 2011.3.9  Bara process bug - when Price of M record is zero, error occurred.
 * 2010.12.28 first Rev. Author by Ryoma Morimoto.
 *    Description : 
 *              Import CSV file to Accounting database of Jinyaforce
 */

public with sharing class documentExt {

    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    private static final Integer posreg = Integer.valueOf(CommConst.APPOPTION_POST_REG);
/****************************************************************************/
/*                                                                          */          
/*  Constructor of class documentExt                                        */
/*                                                                          */
/*                                                                          */          
/*                                                                          */  
/****************************************************************************/  
    public documentExt() {                                                                                                                                                                                                  /* Constructor */
                                                                                                                                                                                                                            /* Clear array */
            wfmgrtbl = new List<fmgrtbl>();
            wfmgrtbl.clear();
            for ( integer i = 0; i < 16; i++) {
                wfmgrtbl.add(new fmgrtbl());                                                                                                                                                                                /* Add list for index = 0 is RFU(For future use) */
            }
                                                                                                                                                                                                                            /* for govener limit */
            ldp = [select Id, Name, Field1__c from DP__c where Name != '' And Field1__c != null];                                                                                                                                                                 /* Get DP master table */
            lgp = [select Id, Name, Field1__c from GP__c where Name != '' And Field1__c != null];                                                                                                                                                                 /* Get GP master table */
            lroom = [select Id, Name, Rnumber__c from Room__c where Name != ''];                                                                                                                                                                /* Get ROOM master table */
                                                                                                                                                                                                                            /* Get ACCOUNT master table */
            // 2012/09/14４桁商品コードだけ、処理対象データを取得する IF (LEN(ps__Field3__c) =4, 1, 0)
            laccount = [select Id, Name, Field3__c, SCP_5__c, detail13__c, GPChange__c, DPChange__c, Field5__c, Field13_del__c, Field4__c, nextitemcode__c, StsTaxfee__c, Field7__c, Field6__c,TaxRateCal__c,ServiceRate__c,SpecialTax__c from AccountMaster__c where Name != '' And CodeNumbers__c = 1];                         
            lworker = [select Id, Name, Field7__c from Worker__c where Name != ''];
            
            /* Product Hash code table for item code */
            /*  - 255 Clear Matrix table */
            itemhashcodetbale = new List<List<integer>>();
            for ( integer yy = 0; yy < 256; yy++ ) {
                itemhashcodetbale.add(new list<integer>());
                for ( integer xx = 0; xx < 256; xx++ ) {
                    itemhashcodetbale[yy].add(255);
                }
            }
            
            /********************************************************************/
            /*                                                                  */
            /* Matrix Table for Item code                                       */
            /*  - Hash code to Account Master record table                      */
            /* +-----------------+                                              */
            /* |                 |                  Account Master              */
            /* |     255*255     |            ー ー+-------------------------+    */           
            /* |             [-]------------->  | |                         |   */
            /* |                 |              | +-------------------------+   */
            /* +-----------------+              | |                         |   */
            /*                                  V |                         |   */           
            /*                               Hash |                         |   */           
            /*                                    |                         |   */           
            /*                                    +-------------------------+   */
            /*                                                                  */
            /********************************************************************/
            integer maxrecords = laccount.size();
            integer hashcode = 0;
            string witemc;
            while ( hashcode < maxrecords ) {
                witemc = laccount[hashcode].Field3__c + ' ';
                //2018/04/30 WSQ 会計商品は数字以外の場合、処理SKIP BEGIN
                String s = witemc.substring(0,2);
                if (!s.isNumeric()) {
                	break;
                }
                //2018/04/30 WSQ 会計商品は数字以外の場合、処理SKIP END
                itemhashcodetbale[integer.valueof(witemc.substring(0,2))][integer.valueof(witemc.substring(2,4))] = hashcode++;
            }
            
            /********************************************************************/
            /*                                                                  */
            /* Hash Table for SHIFT, ZTOTAL                                     */
            /* +--------------------------------------------+                   */
            /* |                    256(True or False)      |                   */
            /* +--------------------------------------------+                   */
            /* | Hash by Account No------------->           |                   */
            /*                                                                  */
            /*                                                                  */
            /********************************************************************/          
            actflagtbl = new List<boolean>();
            actflagtbl.clear();
            for ( integer sno = 0; sno < 256; sno++ ) {
                actflagtbl.add(false);
                /*           0           1            2            3             4           5            6            7             8             9             10            11            12            13           14 */
                 if ( sno == 7 || sno == 10 || sno == 11 || sno == 46 || sno == 47 || sno == 48 || sno == 78 || sno == 99 || sno == 112 || sno == 113 || sno == 114 || sno == 116 || sno == 233 || sno == 234 || sno == 235 ) {
                    actflagtbl[sno] = true;
                 }
            }
            /* Get Room ID */           
			if ( posreg == 1 ) {	/* Jinya Only */
				/* Get Room ID */           
            	Nigiwaiteiroomid = getroomidname('富月殿');
            	Takekawaroomid = getroomidname('竹河');
			}
            /********************************************************************/
            /*                                                                  */
            /* Hash Table for GP,DP                                             */
            /* +--------------------------------------------+                   */
            /* |                    256(Name)               |                   */
            /* +--------------------------------------------+                   */
            /* | Hash by GP or DP No------------->          |                   */
            /*                                                                  */
            /*                                                                  */
            /********************************************************************/          
            tgp = new List<Id>();
            tdp = new List<Id>();
            tgp.clear();
            tdp.clear();
             integer i;
            for ( i = 0; i < 255; i++ ) { tgp.add('00510000000UVSu');}/* Jinya user ID for dummy */
            for ( i = 0; i < 255; i++ ) { tdp.add('00510000000UVSu');}/* Jinya user ID for dummy */
            integer ii;
            ii = lgp.size();
            for ( i = 0; i < ii; i++ ) {
                tgp[integer.valueof(lgp[i].Field1__c)] = lgp[i].Id;             
            }                       
            ii = ldp.size();
            for ( i = 0; i < ii; i++ ) {
                tdp[integer.valueof(ldp[i].Field1__c)] = ldp[i].Id;             
            }                       
                        
    }
    private ID Nigiwaiteiroomid;
    private ID Takekawaroomid;
    
    public string mformat(integer i,decimal d) {                                                                                                                                                                            /* i:numbers,value  return format zero padding string */
        string sr = '';
        integer ii = (d.format()).length();
        if ( ii < i ) {
            string zero = '';
            for ( integer n = 0; n < i - ii ; n++ ) {
                zero += '0';
            }
            sr = zero + d.format();
        } else if ( ii == i ) {
            sr =  d.format();
        } else {
            /* nop */
        }
        return sr.replace(',','');
    }
    private void fconst ( string filen ) {
        wfmgrtbl[currentIndex].csvfilename = filen;                                                                                                                                                                         /* Put file name */
    }
//  private ID getdpid(string dp) {
//      ID rv;
//      integer ii = ldp.size();
//      if ( dp != '' ) {
//          for ( integer i = 0; i < ii; i++) {
//              rv = ldp[i].Id;
//              if ( ldp[i].Field1__c == dp ) 
//                  break;
//          }
//      } else rv = dp;
//      return rv;
//  }
//  private ID getgpid(string gp) {
//      ID rv;
//      integer ii = lgp.size();
//      if ( gp != '' ) {
//          for ( integer i = 0; i < ii; i++) {
//               rv = lgp[i].Id;
//              if ( lgp[i].Field1__c == gp )
//                  break;
//          }
//      } else rv = gp;
//      return rv;
//  }
//  private ID getaccountid(string parentcode) {
//      ID rv;
//      if ( parentcode.trim() != '' ) {
//          for ( integer i = 0; i < laccount.size(); i++) {
//               rv = laccount[i].Id;
//              if ( laccount[i].Field3__c == parentcode )
//                  break;
//          }
//          System.debug('*******NOT FOUND ID ' );
//      } else rv = parentcode;
//      return rv;
//  } 
    private ID getroomidname(string rname) {
        ID rv;
        integer ii = lroom.size();
        for ( integer i = 0; i < ii; i++) {
             rv = lroom[i].Id;
            if ( lroom[i].Name == rname )
                break;
        }
        return rv;
    }
    private ID getroomid(decimal tno) {
        integer i = 0;
        integer ii = lroom.size();
        while ( i < ii ) {
            if ( lroom[i].Rnumber__c == tno ) {
                break;
            }
            i++;
        }
        return lroom[i].Id;
    } 
//  private  AccountMaster__c getaccount(string itemcode) {
//      integer i = 0;
//      while ( i < laccount.size() ) {
//          if ( laccount[i].Field3__c == itemcode )
//              break;
//          i++;
//      }
//      return laccount[i];
//  }
//  private ID getaccountr(string rno) {
//      integer i = 0;
//      while ( i < laccountaccount.size() ) {
//          if ( laccountaccount[i].Field145__c == rno )
//              break;
//          i++;
//      }
//      return laccountaccount[i].Id;
//  }
    private  AccountAcount__c getaccountaccount(string rno, string rday, string rposno) {
        integer i = 0;
        integer ii = laccountaccount.size();
        while ( i < ii ) {
 //         if ( laccountaccount[i].Field145__c == rno ) {
            if ( laccountaccount[i].Field145__c == rno && laccountaccount[i].Field141__c == rday && laccountaccount[i].POSNo__c == rposno) {        /* update checking KEY ( receipt#, sales day, and POS# ) */
                break;
            }
            i++;
        }
        if ( i == ii) { /* Check last */
        	i = 0;/* Put Error Top Index */
        }
        return laccountaccount[i];
    }
    private ID getworkerid(string wno) {
        ID rv;
        if ( wno != '' ) {
            Decimal Enployeeno = Decimal.valueOf(wno);
            integer ii = lworker.size();
            for ( integer i = 0; i < ii; i++) {
                 rv = lworker[i].Id;
                if ( lworker[i].Field7__c == Enployeeno )
                    break;
            }
        } else rv = wno;
        return rv;
    } 
//  private Lead__c getreserve(ID roomid) {
//      integer i = 0;
//      System.debug('lreserve.size(): ' + lreserve.size() );
//      while ( i < lreserve.size() ) {
//          if ( lreserve[i].Rroom__c == roomid ) { break; }
//          i++;
//      }
//      return lreserve[i];
//  }
    private date getaccountdate(string wdate) {
        
        return date.newInstance(integer.valueOf(wdate.substring(0,4)), integer.valueOf(wdate.substring(4,6)), integer.valueOf(wdate.substring(6,8)));
        
    }
    private time getaccounttime(string wdate) {
        
        return time.newInstance(integer.valueOf(wdate.substring(8,10)), integer.valueOf(wdate.substring(10,12)), 0, 0);
        
    }
    
/****************************************************************************/
/*                                                                          */          
/*  Parsing traffic data                                                    */          
/*                                                                          */          
/*      input common local areaList<String> tlines                          */
/*                                                                          */  
/****************************************************************************/
    private integer nextindex = 0;
    private list<string> items;
    private boolean checknumeric( string sarg ) {
        boolean checknumeric = false;
        if ( sarg.contains('0') || sarg.contains('1') || sarg.contains('2') || sarg.contains('3') || sarg.contains('4') || sarg.contains('5') || sarg.contains('6') || sarg.contains('7') || sarg.contains('8') || sarg.contains('9') ) {
            checknumeric = true;
        }
        return checknumeric;
    }
    private string delspace(string tag, integer i ) {                                                               /* get parse space */
        string ret = '';
         integer s;
        if ( tag == 't' ) {                                                                                         /* Top ? */
            s = 0;
        } else {
            s = nextindex;
        }
        for ( ; s < i; s++ ) {                                                                                      /* get not null string within 10 loop */
            if ( checknumeric(items[s]) ) {
                ret = items[s];
                nextindex = s + 1;                                                                                  /* Put next point of array */
                break;
            }
        }
        return ret;
    }
    public void trafficparse(string syear) {
    	// 2017/04/13 Field Security Check BEGIN by wx
    	List<String> insChkFields = new List<String>{'TIME__c','REV60__c','REV60O__c','REV5__c','REV30__c','REV15__c',
													'RECIVINGTIME__c','RECIVINGTIMEAVG__c','RECIVINGCALLS__c','RECEIVING__c',
													'OVERFLOW__c','INCMP60__c','INCMP60O__c','INCMP5__c','INCMP30__c',
													'INCMP15__c','EXT__c','DIAL__c','DIALTIME__c','DIALTIMEAVG__c','DIALCALLS__c',
													'DAY__c','BUSY__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.MX_900IP__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2017/04/13 Field Security Check end by wx
        lmxp = new List<MX_900IP__c>();
        if ( tlines[(tlines.size() - 1)] != '' ) {                                                                  /* Check last lines */
                tlines.add('');                                                                                     /* for Block lines */
        }
        integer si;
        integer ls = tlines.size()/9;                                                                               /* math.mod = 0 */
        if ( math.mod(tlines.size(), 9) == 0 && tlines.size() >= 9 ) {                                              /* Check *9 */
                for ( integer j = 0; j < ls; j++ ) {                                                                /* loop block lines */
                        lmxp.add(new MX_900IP__c());                                                                /* Create one record */
                        si = j*9;                                                                                   /* Get source Index */
                                                                                                                    /* line#0 Day */
                        items = new list<string>();
                        items.clear();
                        items = tlines[si].split(' ');                                                              /* Get items */
                        
/*                      System.debug('items[0] ' + items[0] );
                        System.debug('items[1] ' + items[1] );
                        System.debug('items[3] ' + items[3] ); */
                        
                                                                                                                    /* Put log day  */
/*                      lmxp[j].DAY__c = date.newinstance((datetime.now()).year(), integer.valueof(items[3].substring(0,2)), integer.valueof(items[3].substring(3))); */
                        lmxp[j].DAY__c = date.newinstance(integer.valueof(syear), integer.valueof(items[3].substring(0,2)), integer.valueof(items[3].substring(3)));
                        lmxp[j].TIME__c = items[4].substring(0,items[4].length()-1);                                /* line#0 Time */
                                                                                                                    /* line#1 is comment line */
                        items.clear();
                        items = tlines[si+2].split(' ');                                                            /* Get items */
                        
/*                      System.debug('items ' + items.size() );
                        System.debug('items[0] ' + items[0] );
                        System.debug('items[1] ' + items[1] );
                        System.debug('items[2] ' + items[2] );
                        System.debug('items[3] ' + items[3] );
                        System.debug('items[4] ' + items[4] );
                        System.debug('items[5] ' + items[5] );
                        System.debug('items[6] ' + items[6] );
                        System.debug('items[7] ' + items[7] );*/
                        
                        lmxp[j].DIAL__c = decimal.valueof(items[5]);                                                /* lines#2 dial */                                                                  
                        lmxp[j].OVERFLOW__c = decimal.valueof(items[8]);
                        lmxp[j].BUSY__c = decimal.valueof(items[9]);
                        items.clear();
                        items = (tlines[si+2].substring(51)).split(' ');                                            /* Get items */

/*                      System.debug('items ' + items.size() );
                        System.debug('items[0] ' + items[0] );
                        System.debug('items[1] ' + items[1] );
                        System.debug('items[2] ' + items[2] );
                        System.debug('items[3] ' + items[3] );
                        System.debug('items[4] ' + items[4] );
                        System.debug('items[5] ' + items[5] );
                        System.debug('items[6] ' + items[6] );
                        System.debug('items[7] ' + items[7] );
                        System.debug('items[5] ' + items[8] );
                        System.debug('items[6] ' + items[9] );
                        System.debug('items[7] ' + items[10] );


                        
                        System.debug('substring(51) ' + tlines[si+2].substring(51) );
                        System.debug('***1st ' + delspace('t',items.size()) );
                        System.debug('***2nd ' + delspace('n',items.size()) );
                        System.debug('***3rd ' + delspace('n',items.size()) ); */

                                                                        
                        lmxp[j].DIALTIME__c = decimal.valueof( delspace('t',items.size()) );                        /* Top */
                        lmxp[j].DIALTIMEAVG__c = decimal.valueof( delspace('n',items.size()) );                     /* Next */
                        lmxp[j].DIALCALLS__c = decimal.valueof( delspace('n',items.size()) );                       /* Next */

                                                                                                                    /* line#3 reciving */
                        items.clear();
                        items = tlines[si+3].split(' ');                                                            /* Get items */
                        lmxp[j].RECEIVING__c = decimal.valueof(items[5]);
                        items.clear();
                        items = (tlines[si+3].substring(31)).split(' ');                                            /* Get items */
//                      System.debug('substring(51) ' + tlines[si+3].substring(31) );
                                                
                        lmxp[j].RECIVINGTIME__c = decimal.valueof( delspace('t',items.size()) );                    /* Top */
                        lmxp[j].RECIVINGTIMEAVG__c = decimal.valueof( delspace('n',items.size()) );                 /* Next */
                        lmxp[j].RECIVINGCALLS__c = decimal.valueof( delspace('n',items.size()) );                   /* Next */
                                                                                                                    /* line#5 */
                        items.clear();
                        items = tlines[si+5].split(' ');                                                            /* Get items */
                        lmxp[j].EXT__c = decimal.valueof(items[6].substring(4));
                                                                                                                    /* line#6 DELAY   */
                        items.clear();
                        items = tlines[si+6].split(' ');                                                            /* Get items */
                        lmxp[j].REV5__c = decimal.valueof(items[2].substring(2));
                        lmxp[j].REV15__c = decimal.valueof(items[3].substring(2));
                        lmxp[j].REV30__c = decimal.valueof(items[4].substring(2));
                        lmxp[j].REV60__c = decimal.valueof(items[5].substring(2));
                        lmxp[j].REV60O__c = decimal.valueof(items[6].substring(2,10));
                                                                                                                    /* line#7 INCMP   */
                        items.clear();
                        items = tlines[si+7].split(' ');                                                            /* Get items */
                        lmxp[j].INCMP5__c = decimal.valueof(items[2].substring(2));
                        lmxp[j].INCMP15__c = decimal.valueof(items[3].substring(2));
                        lmxp[j].INCMP30__c = decimal.valueof(items[4].substring(2));
                        lmxp[j].INCMP60__c = decimal.valueof(items[5].substring(2));
                        lmxp[j].INCMP60O__c = decimal.valueof(items[6].substring(2,10));
                        
                }
                /* Insert database */
                
/*              System.debug('traffic MX_900IP__c[0] ' + lmxp[0] );
                System.debug('traffic MX_900IP__c[1] ' + lmxp[1] );
                System.debug('traffic MX_900IP__c[2] ' + lmxp[2] ); */
                
                try {
                        insert lmxp;
                } catch (Exception e) {
                        ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in lmxp(Traffic log data). Please check the template or try again later');
                        ApexPages.addMessage(errormsg);
                }    
                                                
        } else {
                /* error exit */
                System.debug(' *** traffic log file format error ****');
        }
        
    }   
    
    
//  public enum ttotal {receiptno1, typeoftransaction2, voidreceipt3}
    private integer currentsts = 0;                                                                                                                                                                                                                 /* current status                                                                   0 : idle */
                                                                                                                                                                                                                                                    /*                                                                                  1 : TTOTAL */
                                                                                                                                                                                                                                                    /*                                                                                  2 : TEND */
                                                                                                                                                                                                                                                    /*                                                                                  3 : TITEM */
                                                                                                                                                                                                                                                    /*                                                                                                                              4 :Shift */                                                                                                                                                                                                                                                                                                                                                                                                                                     
    private integer currentIndex = 0;                                                                                                                                                                                                               /* Current process index of file manager table */
                                                                                                                                                                                                                                                    /*                                                                                                                              0 :idling */
                                                                                                                                                                                                                                                    /*                                 1 :ttotal.csv */
                                                                                                                                                                                                                                                    /*                                 2 :ttotal2.csv */
                                                                                                                                                                                                                                                    /*                                 3 :tend.csv */
                                                                                                                                                                                                                                                    /*                                 4 :tend2.csv */
                                                                                                                                                                                                                                                    /*                                 5 :titem.csv */
                                                                                                                                                                                                                                                    /*                                 6 :titem2.csv */
                                                                                                                                                                                                                                                    /*                                 7 :zshift.csv */
                                                                                                                                                                                                                                                    /*                                 8 :zshift2.csv */
                                                                                                                                                                                                                                                    /*                                 9 :total account */
    private List<fmgrtbl> wfmgrtbl;                                                                                                                                                                                                                 /* file manager table information */
    private class fmgrtbl {                                                                                                                                                                                                                         /* This class is structure of file manager table */
        private integer sts;                                                                                                                                                                                                                        /* status */
        private string csvfilename;                                                                                                                                                                                                                 /* csvfilename */
        private integer destindex;                                                                                                                                                                                                                  /* for Account object */
        private integer records;                                                                                                                                                                                                                    /* records */
        private string posno;                                                                                                                                                                                                                       /* POS# */
        private ID revref;                                                                                                                                                                                                                          /* revenue day reference Id */
        private date revenueday;                                                                                                                                                                                                                    /* revenue day */
        private string srevenueday;                                                                                                                                                                                                                 /* revenue day of string */
    }
    private integer BaraYindex = 0;
    private List<List<Baratbl>> BaraIndexTbale;
    private class Baratbl {                                                                                                                                                                                                                         /* This class is structure of Set menu manager table */
        private integer Index;                                                                                                                                                                                                                      /* Index of Jtitem array for Set menu */
        private ID gp;                                                                                                                                                                                                                              /* Change GP */
        private ID dp;                                                                                                                                                                                                                              /* Change DP */
        private decimal price;                                                                                                                                                                                                                      /* price */
        private decimal costofsales;
    }    
 
    
    private         RsvAccount__c rsvaccount;                                                                                                                                                                                                       /* JINYA REVENUE */
    private         List<AccountAcount__c> Jaccount;                                                                                                                                                                                                /* TTOTAL */
    private         List<TTend__c> Jtend;                                                                                                                                                                                                           /* TEND */
    private         List<Tran1__c> Jtitem;                                                                                                                                                                                                          /* TITEM */
 
    private         List<DP__c> ldp;                                                                                                                                                                                                                /* array of DP master */
    private         List<GP__c> lgp;                                                                                                                                                                                                                /* array of GP master */
    private         List<Room__c> lroom;                                                                                                                                                                                                            /* array of ROOM master */
    private         List<AccountMaster__c> laccount;                                                                                                                                                                                                /* array of ACCOUNT  master */
    private         List<AccountAcount__c> laccountaccount; 
    private         List<Worker__c> lworker; 
    private         List<Lead__c> lreserve;
    
    private         date accountdate;
    private         time accounttime;
    private         static time hirutime = time.newInstance(17, 0, 0, 0);
    private         static date ChangeBreakfastPricestartDate = date.newInstance(2011, 1, 5);                                                                                                                                                       /* Change Breakfast price +1000 */              
    private         static date ChangeBarastartDate = date.newInstance(2011, 2, 3);                                                                                                                                                                 /* Change Bara Start Date */
    
    private         List<List<integer>> itemhashcodetbale;
    
    private class acttbl {                                                                                                                                                                                                                          /* for Shift,Ztotal */
        private string actno;                                                                                                                                                                                                                       /* 集計番号 */
        private string actname;                                                                                                                                                                                                                     /* 名称 */
//      private string amtno;                                                                                                                                                                                                                       /* 金額 項番 */
        private decimal amtprice;                                                                                                                                                                                                                   /* 金額 カウンタ */
                                                                                                                                                                                                                                                    /* 点数 項番 */
                                                                                                                                                                                                                                                    /* 点数 カウンタ */
                                                                                                                                                                                                                                                    /* 回数 項番 */
                                                                                                                                                                                                                                                    /* 回数 カウンタ */
                                                                                                                                                                                                                                                    /* 枚数 項番 */
                                                                                                                                                                                                                                                    /* 枚数 カウンタ */
                                                                                                                                                                                                                                                    /* 組数 項番 */
                                                                                                                                                                                                                                                    /* 組数 カウンタ */
//      private string cusno;                                                                                                                                                                                                                       /* 客数 項番 */
        private decimal cuscounter;                                                                                                                                                                                                                 /* 客数 カウンタ */
   }    


    private         List<List<acttbl>> wacttbl;
    private         List<boolean> actflagtbl; 
    private         List<String> tlines;
    private         List<MX_900IP__c> lmxp;
    private         List<Id> tgp;
    private         List<Id> tdp;
 
    private string icode;   /* for work */
    
/****************************************************************************************/
/*                                                                                      */          
/*  Parsing CSV file of sales Account data                                              */          
/*                                                                                      */          
/*                                                                                      */  
/*          Calling sequence                                                            */  
/*              1) controller.nameFile = '***.csv';                                     */  
/*              2) controller.contentFile = Blob.valueOf('record content')              */  
/*                                                                                      */  
/*                                                                                      */  
/*                                                                                      */  
/****************************************************************************************/
    public Pagereference ReadFile() {                                                                                                                                                                                                               /* *****for CSV file */
    	// 2017/04/13 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'noneaccount__c','TaxRate__c','TableNo__c','Subprice__c','SpecialTax__c','ServiceRate__c',
													'RelAccount__c','POSNo__c','Field9__c','Field8__c','Field7__c','Field6__c','Field5__c',
													'Field4__c','Field45__c','Field3__c','Field38__c','Field37__c','Field36__c','Field35__c',
													'Field34__c','Field33__c','Field32__c','Field31__c','Field30__c','Field2__c','Field29__c',
													'Field28__c','Field27__c','Field26__c','Field25__c','Field24__c','Field23__c','Field22__c',
													'Field21__c','Field20__c','Field1__c','Field19__c','Field18__c','Field17__c','Field16__c',
													'Field15__c','Field14__c','Field13__c','Field12__c','Field11__c','Field10__c'};
		Map<String,Schema.SObjectField> tran = Schema.SObjectType.Tran1__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, tran)) {
			return null;
		}
		List<String> insChkFieldsLst = new List<String>{'noneaccount__c','RelAccount__c','POSNo__c','Field9__c','Field8__c','Field7__c',
														'Field6__c','Field5__c','Field4__c','Field34__c','Field25__c','Field24__c','Field23__c',
														'Field22__c','Field21__c','Field20__c','Field19__c','Field18__c','Field17__c',
														'Field16__c','Field15__c','Field14__c','Field13__c','Field10__c','Field2__c',
														'Field1__c','Field3__c'};
		Map<String,Schema.SObjectField> ttend = Schema.SObjectType.TTend__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFieldsLst, ttend)) {
			return null;
		}
		List<String> insChkFields1 = new List<String>{'Field68__c','Field67__c','Field66__c','Field65__c','Field64__c','Field63__c','Field62__c',
													'Field61__c','Field60__c','Field59__c','Field58__c','Field57__c','Field56__c','Field7__c',
													'Field54__c','Field53__c','Field85__c','Field51__c','Field50__c','Field49__c','Field48__c',
													'Field45__c','Field44__c','Field43__c','Field42__c','Field74__c','Field39__c','Field78__c',
													'Field70__c','Field76__c','Field84__c','Field75__c','Field83__c','Field82__c','Field81__c',
													'Field98__c','PlanNo__c','Field79__c','Field80__c','Field69__c','Field145__c','Field143__c',
													'Field142__c','Field141__c','Field140__c','Field139__c','Field138__c','Field137__c','Field136__c',
													'Field135__c','Field134__c','Field133__c','Field132__c','Field131__c','Field130__c','Field129__c',
													'Field128__c','Field127__c','Field126__c','Field125__c','Field124__c','Field123__c','Field122__c',
													'Field121__c','Field120__c','Field119__c','Field118__c','Field117__c','Field116__c','Field115__c',
													'Field114__c','Field113__c','Field112__c','Field111__c','Field110__c','Field109__c','Field108__c',
													'Field107__c','Field106__c','Field105__c','Field104__c','Field103__c','Field102__c','Field101__c',
													'Field100__c','Field96__c','Field93__c','Field92__c','Field95__c','Field94__c','Field89__c','Field88__c',
													'Field87__c','Field86__c','Field91__c','Field90__c','Field77__c','Field97__c','Field99__c','Field73__c'};
		Map<String,Schema.SObjectField> acc = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields1, acc)) {
			return null;
		}
		
		List<String> ChkFields = new List<String>{'Restrunt19__c','Restrunt26__c','Restrunt17__c','restraunt1__c','Restrunt25__c','Restrunt8__c',
									               'UchikinKomi__c','Persons__c','front14__c','front13__c','front6__c','front3__c','front9__c','front7__c',
									               'fornt2__c','front26__c','front17__c','front1__c','front25__c','front8__c','front10__c','restraunt4__c',
									               'femails__c','males__c','Restrunt11__c','Restrunt10__c','Restrunt15__c','KakeKeiKomi__c','front15__c',
									               'SalesAverageKomi__c','SalesAverage__c','Restrunt12__c','Restrunt18__c','restraunt3__c','restraunt2__c',
									               'GenkinkeiKomi__c','Field4__c','FRestrunt9__c','Discount2__c','CuponKomi__c','CreditKkomi__c','Childs__c',
									               'Name'}; 
		Map<String,Schema.SObjectField> rsv = Schema.SObjectType.RsvAccount__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(ChkFields, rsv)) {
			return null;
		}
		
		// 2017/04/13 Field Security Check End by wx                                                                                                                                                                                                               /* *****for CSV file */
        System.debug('CSV file name: ' + nameFile );                                                                                                                                                                                                /* Check filename */
        System.debug('currentIndex: ' + currentIndex );                                                                                                                                                                                             /* Check current Index */
        if ( nameFile == 'ttotal.csv' && currentIndex == 0) {                                                                                                                                                                                       /* total transaction ? */
            currentIndex = 1;                                                                                                                                                                                                                       /* Put Index */
            Jaccount = new List<AccountAcount__c>();
            Jaccount.clear();
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */                                                                                                                                                                                                                                                                                                                           
//      } else if ( nameFile == 'ttotal02.csv' && currentIndex == 1 ) {
        } else if ( nameFile == 'ttotal02.csv' ) {
            currentIndex = 2;                                                                                                                                                                                                                       /* Put Index */         
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            currentsts = 1;                                                                                                                                                                                                                         /* Put current status */
        } else if ( nameFile == 'ttend.csv' ) {
            currentIndex = 3;                                                                                                                                                                                                                       /* Put Index */
            Jtend = new List<TTend__c>();
            Jtend.clear();          
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */                                                                                                                                                                                                                                                                                                                           
        } else if ( nameFile == 'ttend02.csv' ) {
            currentIndex = 4;                                                                                                                                                                                                                       /* Put Index */         
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            currentsts = 2;                                                                                                                                                                                                                         /* Put current status */
        } else if ( nameFile == 'titem.csv' ) {
            currentIndex = 5;                                                                                                                                                                                                                       /* Put Index */
            Jtitem = new List<Tran1__c>();
            Jtitem.clear();
            BaraIndexTbale = new List<List<Baratbl>>();
            BaraIndexTbale.clear();
            BaraYindex = 0;         
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */                   
        } else if ( nameFile == 'titem02.csv' ) {
            currentIndex = 6;                                                                                                                                                                                                                       /* Put Index */         
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            currentsts = 3;                                                                                                                                                                                                                         /* Put current status */                                                                                                                                                                                                                                                                                                                            
        } else if ( nameFile == 'zshift01.csv' ) {
            currentIndex = 7;                                                                                                                                                                                                                       /* Put Index */         
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            wacttbl = new List<List<acttbl>>();
            wacttbl.clear();
            wacttbl.add(new List<acttbl>());                                                                                                                                                                                                                                                                                                                        
        } else if ( nameFile == 'zshift0102.csv' ) {
            currentIndex = 8;                                                                                                                                                                                                                       /* Put Index */
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            wacttbl.add(new List<acttbl>());                                                                                                                                                                                                                                                                                                                            
        } else if ( nameFile == 'ztotal.csv' ) {
            currentIndex = 9;                                                                                                                                                                                                                       /* Put Index */
            fconst(nameFile);                                                                                                                                                                                                                       /* Create one record of file manager table */
            currentsts = 4;                                                                                                                                                                                                                         /* Put current status */
            wacttbl.add(new List<acttbl>());                                                                                                                                                                                                                                                                                                                        
        } else if ( nameFile.contains('traffic')  ) {                                                                                                                                                                                               /* Check traffic data file name */

            string syear = nameFile.substring(7,11);/* get year */
            nameFile = contentFile.toString();                                                                                                                                                                                                      /* Get CSV file content */
            tlines = new List<String>();                                                                                                                                                                                                            /* define lines of CSV file */
            try {
                    tlines = nameFile.split('\n');                                                                                                                                                                                                  /* Get N lines */
            } catch (System.ListException e) {
                    System.debug('Limits exceeded?' + e.getMessage());
                    return null;                                                                                                                                                                                                                    /* exist with error */
            }
//          System.debug('traffic lines1' + tlines[0] );
//          System.debug('traffic lines2' + tlines[1] );
//          System.debug('traffic lines3' + tlines[2] );
//          System.debug('traffic lines4' + tlines[3] );
//          System.debug('traffic lines5' + tlines[4] );
//          System.debug('traffic lines6' + tlines[5] );
//          System.debug('traffic lines7' + tlines[6] );
//          System.debug('traffic lines8' + tlines[7] );
//          System.debug('traffic lines9' + tlines[8] );
//          System.debug('traffic lines10' + tlines[9] );
//          System.debug('traffic lines11' + tlines[10] ); */
            
            trafficparse(syear);                                                                                                                                                                                                                            /* parsing traffic log data */
            
            return null;                                                                                                                                                                                                                            /* exit */          
            
        } else {
            System.debug('Other CSV file name: ' + nameFile );                                                                                                                                                                                      /* other file or sequence>>> error  */
//          delete sfmgrtbl;                                                                                                                                                                                                                        /* Object release */
            return null;                                                                                                                                                                                                                            /* exit */
        }
        nameFile = contentFile.toString();                                                                                                                                                                                                          /* Get CSV file content */
//      System.debug('C***CSV Content: Line#1' + lines.get(0) );
//      System.debug('C***CSV Content: Line#2' + lines.get(1) );
//      System.debug('C***CSV Content: Line#3' + lines.get(2) );
//      System.debug('C***CSV Content: Lines' + lines.size() 
//      System.debug('CSV Content: ' + nameFile );
        List<String> lines = new List<String>();                                                                                                                                                                                                    /* define lines of CSV file */
        try {
                lines = nameFile.split('\n');                                                                                                                                                                                                       /* Get N lines */
        } catch (System.ListException e) {
                System.debug('Limits exceeded?' + e.getMessage());
                return null;                                                                                                                                                                                                                        /* exist with error */
        }
//      System.debug('C***CSV Content: Line#1' + lines.get(0) );
//      System.debug('C***CSV Content: Line#2' + lines.get(1) );
//      System.debug('C***CSV Content: Line#3' + lines.get(2) );        
        System.debug('currentIndex' + currentIndex);
        wfmgrtbl[currentIndex].records = lines.size() - 2;                                                                                                                                                                                          /* Put records */
        wfmgrtbl[currentIndex].destindex = 0;                                                                                                                                                                                                       /* Put destination index of account object */
        if ( math.mod(currentIndex, 2) == 0 && !(currentIndex == 7 || currentIndex == 8 || currentIndex == 9) ) {                                                                                                                                   /* Check index number is even (reminder)? */
            wfmgrtbl[currentIndex].destindex = wfmgrtbl[(currentIndex-1)].records;                                                                                                                                                                  /* Put destination index with even */
        }
        List<String> fields = new List<String>();                                                                                                                                                                                                   /* define lines of CSV file */
        fields = lines.get(0).split(',');                                                                                                                                                                                                           /* Get Header record of csv file */
        wfmgrtbl[currentIndex].posno =  fields.get(2);                                                                                                                                                                                              /* Put POS# */  
        wfmgrtbl[currentIndex].srevenueday = fields.get(3);                                                                                                                                                                                         /* Put Profit day */
        if ( !(currentindex == 1 || currentindex == 2) ) {                                                                                                                                                                                          /* Check item ? */
            string crevenueday = wfmgrtbl[currentIndex].srevenueday;
            laccountaccount = [select Id, Name, Field145__c, frs__r.Name, Relreserve__c, Field154__c, Field39__c, Field141__c, POSNo__c from AccountAcount__c where frs__r.Name = :crevenueday];                                                                            /* Get TOTAL Field154__c: reserved reception date */
        }
        Database.SaveResult[] lsr;
        rsvaccount = new RsvAccount__c();
        rsvaccount.Name = fields.get(3);                                                                                                                                                                                                            /* Get Profit day */
        List<RsvAccount__c> aa = [select Id, Name from RsvAccount__c where name = :rsvaccount.Name limit 1]; 
        if (aa.isEmpty()) {                                                                                                                                                                                                                         /* Checking profit day is exist ? */
            lsr = Database.insert(new RsvAccount__c[]{rsvaccount},false);                                                                                                                                                                           /* Create Profit day */
            for (Database.SaveResult sr:lsr){                                                                                                                                                                                                       /* Iterate through the Save Results */
                   if (!sr.isSuccess()) {
                      Database.Error err = sr.getErrors()[0];                                                                                                                                                                                       /************************************** Put error */
                      System.debug(' Database error :New rsvaccount: ' + err );
                   } else {
                   }
             }
             wfmgrtbl[currentIndex].revref = lsr[0].getId();                                                                                                                                                                                        /* Put Jinyarevenue Id of new record */
        } else {
             wfmgrtbl[currentIndex].revref = aa[0].Id;                                                                                                                                                                                              /* Put Jinyarevenue Id of existing record */
        }
        wfmgrtbl[currentIndex].revenueday  = [select Id, Name, Salesday__c from RsvAccount__c where name = :rsvaccount.Name limit 1].Salesday__c;                                                                                                   /* Put Jinya revenue day */
        date revday = wfmgrtbl[currentIndex].revenueday;                                                                                                                                                                                            /* Get Jinya revenue day */
//      lreserve = [select Id, Name, CustomerofReserve_del__c, ReservationDate__c, Rroom__c, Rroom__r.Name, CancelBool__c from Lead__c where ReservationDate__c = :revday and CancelBool__c != 1 order by Rroom__r.Seq__c ASC];
        lreserve = [select Id, Name, Relcontact__c, ReservationDate__c, Rroom__c, Rroom__r.Name, CancelBool__c from Lead__c where ReservationDate__c = :revday and CancelBool__c != 1 order by Rroom__r.Seq__c ASC];
        System.debug('****lreserve.size(): ' + lreserve.size() ); 
        System.debug('****lreserve: ' + lreserve ); 
        System.debug('****wfmgrtbl[currentIndex].revenueday: ' + wfmgrtbl[currentIndex].revenueday );
        Integer num = 0;                                                                                                                                                                                        /* Put source index */
        Integer di = wfmgrtbl[currentIndex].destindex;                                                                                                                                                          /* Put destination index */
        while ( num < wfmgrtbl[currentIndex].records ) {                                                                                                                                                        /* loop Lines source index = 2: destination index */
            fields = lines.get((num + 2)).split(',');                                                                                                                                                           /* Get fields of  next line */
            if ( currentIndex == 1 || currentIndex == 2 ) {                                                                                                                                                     /* TTOTAL */
                Jaccount.add(new AccountAcount__c());                                                                                                                                                           /* Get New TTOTAL Object */
                Jaccount[di].Field73__c = fields.get(42);                                                                                                                                                       /*  001 :   アイテム総点数 */                                                                                                                                                                                  
                Jaccount[di].Field56__c = fields.get(18);                                                                                                                                                       /*  002 :   オーダー人数 */                                                                                                                                                                                                   
                Jaccount[di].Field64__c = fields.get(30);                                                                                                                                                       /*  003 :   お通し人数 */                                                                                                                                                                                                        
                Jaccount[di].Field138__c = fields.get(157);                                                                                                                                                     /*  004 :   シフト精算／日計精算回数 */                 
                Jaccount[di].Field90__c = fields.get(59);                                                                                                                                                       /*  005 :   テイクアウト外税対象金額 */
                Jaccount[di].Field91__c = fields.get(60);                                                                                                                                                       /*  006 :   テイクアウト外税対象点数 */
                Jaccount[di].Field86__c = fields.get(55);                                                                                                                                                       /*  007 :   テイクアウト合計Ⅰ（内税抜き）金額 */                                                                                                                                                                                                        
                Jaccount[di].Field87__c = fields.get(56);                                                                                                                                                       /*  008 :   テイクアウト合計Ⅰ（内税抜き）点数 */                    
                Jaccount[di].Field88__c = fields.get(57);                                                                                                                                                       /*  009 :   テイクアウト合計Ⅱ（内税込み）金額 */
                Jaccount[di].Field89__c = fields.get(58);                                                                                                                                                       /*  010 :   テイクアウト合計Ⅱ（内税込み）点数 */
                Jaccount[di].Field94__c = fields.get(63);                                                                                                                                                       /*  011 :   テイクアウト内税対象（内税込み）金額 */                                                                                                                                                                                                       
                Jaccount[di].Field95__c = fields.get(64);                                                                                                                                                       /*  012 :   テイクアウト内税対象（内税込み）点数 */                   
                Jaccount[di].Field92__c = fields.get(61);                                                                                                                                                       /*  013 :   テイクアウト内税対象（内税抜き）金額 */
                Jaccount[di].Field93__c = fields.get(62);                                                                                                                                                       /*  014 :   テイクアウト内税対象（内税抜き）点数 */
                Jaccount[di].Field96__c = fields.get(65);                                                                                                                                                       /*  015 :   テイクアウト非課税対象金額 */
                Jaccount[di].Field97__c = fields.get(66);                                                                                                                                                       /*  016 :   テイクアウト非課税対象点数 */
//              Jaccount[num].Field71__c = fields.get(40);                                                                                                                                                      /*  :   ディッシュアップ時間帯開始時間 */ none
//              Jaccount[num].Field72__c = fields.get(41);                                                                                                                                                      /*  :   ディッシュアップ時間帯終了時間 */ none
                Jaccount[di].Field58__c = fields.get(20);                                                                                                                                                       /*  018 :   フリー１集計コード */
                Jaccount[di].Field59__c = fields.get(21);                                                                                                                                                       /*  019 :   フリー１集計名称 */
                Jaccount[di].Field145__c = fields.get(0);                                                                                                                                                       /*  020 :   レシートＮｏ． */
//              System.debug('reciept#' + fields.get(0) );              
                Jaccount[di].Field133__c = decimal.valueOf(fields.get(152));                                                                                                                                    /*  021 :   レシートＮｏ．（ＦＲＯＭ） */                                                                                                                                                                                    
                Jaccount[di].Field134__c = decimal.valueOf(fields.get(153));                                                                                                                                    /*  022 :   レシートＮｏ．（ＴＯ） */                                                                                                                                                                                                  
                Jaccount[di].Field102__c = fields.get(71);                                                                                                                                                      /*  023 :   レストラン売上外税対象金額 */                                                                                                                                                                                                        
                Jaccount[di].Field103__c = fields.get(72);                                                                                                                                                      /*  024 :   レストラン売上外税対象点数 */                    
                Jaccount[di].Field60__c = fields.get(26);                                                                                                                                                       /*  025 :   レストラン売上客数 */
                Jaccount[di].Field98__c = fields.get(67);                                                                                                                                                       /*  026 :   レストラン売上合計Ⅰ（内税抜き）金額 */
                Jaccount[di].Field99__c = fields.get(68);                                                                                                                                                       /*  027 :   レストラン売上合計Ⅰ（内税抜き）点数 */                                                                                                                                                                                                       
                Jaccount[di].Field100__c = fields.get(69);                                                                                                                                                      /*  028 :   レストラン売上合計Ⅱ（内税込み）金額 */                   
                Jaccount[di].Field101__c = fields.get(70);                                                                                                                                                      /*  029 :   レストラン売上合計Ⅱ（内税込み）点数 */
                Jaccount[di].Field106__c = fields.get(73);                                                                                                                                                      /*  030 :   レストラン売上内税対象（内税抜き）金額 */
                Jaccount[di].Field107__c = fields.get(74);                                                                                                                                                      /*  031 :   レストラン売上内税対象（内税抜き）点数 */
                Jaccount[di].Field104__c = fields.get(75);                                                                                                                                                      /*  032 :   レストラン売上内税対象（内税込み）金額 */
                Jaccount[di].Field105__c = fields.get(76);                                                                                                                                                      /*  033 :   レストラン売上内税対象（内税込み）点数 */
                Jaccount[di].Field108__c = fields.get(77);                                                                                                                                                      /*  034 :   レストラン売上非課税対象金額 */
                Jaccount[di].Field109__c = fields.get(78);                                                                                                                                                      /*  035 :   レストラン売上非課税対象点数 */
                Jaccount[di].Field141__c = wfmgrtbl[currentIndex].srevenueday;                                                                                                                                  /*  037 :   営業日付 */
                Jaccount[di].Field127__c = fields.get(129);                                                                                                                                                     /*  038 :   課税１　種別 */
                Jaccount[di].Field128__c = fields.get(130);                                                                                                                                                     /*  039 :   課税１　税率 */
                Jaccount[di].Field129__c = fields.get(131);                                                                                                                                                     /*  040 :   課税２　種別 */
                Jaccount[di].Field130__c = fields.get(132);                                                                                                                                                     /*  041 :   課税２　税率 */
                Jaccount[di].Field131__c = fields.get(133);                                                                                                                                                     /*  042 :   課税３　種別 */
                Jaccount[di].Field132__c = fields.get(134);                                                                                                                                                     /*  043 :   課税３　税率 */
                Jaccount[di].Field45__c = fields.get(7);                                                                                                                                                        /*  044 :   会計種別*/
                Jaccount[di].Field57__c = fields.get(19);                                                                                                                                                       /*  045 :   会計人数 */
                Jaccount[di].Field53__c = fields.get(15);                                                                                                                                                       /*  046 :   会計日時 */

                accountdate = getaccountdate(fields.get(15));
                accounttime = getaccounttime(fields.get(15));
                            
                Jaccount[di].Field66__c = fields.get(35);                                                                                                                                                       /*  047 :   客層１  Male */
                Jaccount[di].Field67__c = fields.get(36);                                                                                                                                                       /*  048 :   客層２  Female */
                Jaccount[di].Field68__c = fields.get(37);                                                                                                                                                       /*  049 :   客層３  Child */
                Jaccount[di].Field69__c = fields.get(38);                                                                                                                                                       /*  050 :   客層４ */
                Jaccount[di].Field70__c = fields.get(39);                                                                                                                                                       /*  051 :   客層５ */
                Jaccount[di].Field119__c = fields.get(119);                                                                                                                                                     /*  052 :   金券販売合計　回数 */
                Jaccount[di].Field118__c = fields.get(118);                                                                                                                                                     /*  053 :   金券販売合計　金額 */
                Jaccount[di].Field120__c = fields.get(120);                                                                                                                                                     /*  054 :   金券販売合計　枚数 */
                Jaccount[di].Field43__c = decimal.valueOf(fields.get(5));                                                                                                                                       /*  055 :   元扱者Ｎｏ． */
                Jaccount[di].Field44__c = decimal.valueOf(fields.get(6));                                                                                                                                       /*  056 :   元担当者Ｎｏ． */
                Jaccount[di].Field65__c = fields.get(31);                                                                                                                                                       /*  058 :   控え番号（任意情報１） */
                Jaccount[di].Field139__c = fields.get(158);                                                                                                                                                     /*  059 :   今回精算日時 */
                Jaccount[di].Field136__c = fields.get(155);                                                                                                                                                     /*  060 :   今回未精算　金額 */
                Jaccount[di].Field135__c = fields.get(154);                                                                                                                                                     /*  061 :   今回未精算　組数 */
                Jaccount[di].Field39__c = fields.get(1);                                                                                                                                                        /*  062 :   取引種別 */
                Jaccount[di].Field63__c = fields.get(29);                                                                                                                                                       /*  063 :   収入計客数 */
                Jaccount[di].Field125__c = fields.get(125);                                                                                                                                                     /*  064 :   消費税非課税対象額 */
                Jaccount[di].Field121__c = fields.get(121);                                                                                                                                                     /*  065 :   消費税（外） */
                Jaccount[di].Field123__c = fields.get(123);                                                                                                                                                     /*  066 :   消費税（外）対象額 */
                Jaccount[di].Field122__c = fields.get(122);                                                                                                                                                     /*  067 :   消費税（内） */
                Jaccount[di].Field124__c = fields.get(124);                                                                                                                                                     /*  068 :   消費税（内）対象額 */
                Jaccount[di].Field50__c = fields.get(12);                                                                                                                                                       /*  069 :   新規オーダー時刻 */
                Jaccount[di].Field126__c = fields.get(126);                                                                                                                                                     /*  070 :   請求金額 */
                Jaccount[di].Field54__c = fields.get(16);                                                                                                                                                       /*  071 :   組数 */
                Jaccount[di].Field42__c = decimal.valueOf(fields.get(4));                                                                                                                                       /*  072 :   担当者Ｎｏ． */
                Jaccount[di].Field51__c = fields.get(13);                                                                                                                                                       /*  073 :   追加オーダー時刻 */
                Jaccount[di].Field137__c = fields.get(156);                                                                                                                                                     /*  074 :   釣銭準備金 */
                Jaccount[di].Field61__c = fields.get(27);                                                                                                                                                       /*  075 :   店頭売上客数 */
                Jaccount[di].Field78__c = fields.get(47);                                                                                                                                                       /*  076 :   店内飲食外税対象金額 */
                Jaccount[di].Field79__c = fields.get(48);                                                                                                                                                       /*  077 :   店内飲食外税対象点数 */
                Jaccount[di].Field74__c = fields.get(43);                                                                                                                                                       /*  078 :   店内飲食合計Ⅰ（内税抜き）金額 */
                Jaccount[di].Field75__c = fields.get(44);                                                                                                                                                       /*  079 :   店内飲食合計Ⅰ（内税抜き）点数 */
                Jaccount[di].Field76__c = fields.get(45);                                                                                                                                                       /*  080 :   店内飲食合計Ⅱ（内税込み）金額 */
                Jaccount[di].Field77__c = fields.get(46);                                                                                                                                                       /*  081 :   店内飲食合計Ⅱ（内税込み）点数 */
                Jaccount[di].Field82__c = fields.get(51);                                                                                                                                                       /*  082 :   店内飲食内税対象（内税込み）金額 */
                Jaccount[di].Field83__c = fields.get(52);                                                                                                                                                       /*  083 :   店内飲食内税対象（内税込み）点数 */
                Jaccount[di].Field80__c = fields.get(49);                                                                                                                                                       /*  084 :   店内飲食内税対象（内税抜き）金額 */
                Jaccount[di].Field81__c = fields.get(50);                                                                                                                                                       /*  085 :   店内飲食内税対象（内税抜き）点数 */
                Jaccount[di].Field84__c = fields.get(53);                                                                                                                                                       /*  086 :   店内飲食非課税対象金額 */
                Jaccount[di].Field85__c = fields.get(54);                                                                                                                                                       /*  087 :   店内飲食非課税対象点数 */
                Jaccount[di].Field49__c = fields.get(11);                                                                                                                                                       /*  088 :   伝票一連Ｎｏ． */                          
//              System.debug('fields.get(10)' + fields.get(10) );
                if ( fields.get(10).trim() != '' ) {                                                                                                                                                            /* Check Blank Blank */
                    Jaccount[num].Field48__c = decimal.valueOf(fields.get(10));                                                                                                                                 /*  089 :   伝票枝番 */
                }
                Jaccount[di].Field7__c = fields.get(8);                                                                                                                                                         /*  090 :   伝票Ｎｏ． */                
                Jaccount[di].Field110__c = fields.get(104);                                                                                                                                                     /*  091 :   売上計Ⅰ（内税抜き）金額 */
                Jaccount[di].Field111__c = fields.get(105);                                                                                                                                                     /*  092 :   売上計Ⅰ（内税抜き）点数 */
                Jaccount[di].Field112__c = fields.get(106);                                                                                                                                                     /*  093 :   売上計Ⅱ（内税込み）金額 */
                Jaccount[di].Field113__c = fields.get(107);                                                                                                                                                     /*  094 :   売上計Ⅱ（内税込み）点数 */
                Jaccount[di].Field114__c = fields.get(108);                                                                                                                                                     /*  095 :   売上計Ⅲ（内税抜き）金額 */
                Jaccount[di].Field115__c = fields.get(109);                                                                                                                                                     /*  096 :   売上計Ⅲ（内税抜き）点数 */
                Jaccount[di].Field116__c = fields.get(110);                                                                                                                                                     /*  097 :   売上計Ⅳ（内税込み）金額 */
                Jaccount[di].Field117__c = fields.get(111);                                                                                                                                                     /*  098 :   売上計Ⅳ（内税込み）点数 */
                Jaccount[di].Field140__c = fields.get(159);                                                                                                                                                     /*  099 :   売上計Ⅴ(外税込み)金額 */
                Jaccount[di].Field62__c = fields.get(28);                                                                                                                                                       /*  100 :   売上高客数 */
                Jaccount[di].PlanNo__c = decimal.valueof(fields.get(166));                                                                                                                                      /*   :  Put Plan No. 20110803 */                
                Jaccount[di].Field143__c = fields.get(165);                                                                                                                                                     /*  101 :   明細数（支払） */
                Jaccount[di].Field142__c = fields.get(164);                                                                                                                                                     /*  102 :   明細数（商品／監査） */
                Jaccount[di].Field52__c = fields.get(14);                                                                                                                                                       /*  105 :   料理提供時刻 */
                Jaccount[di].Field55__c = fields.get(17);                                                                                                                                                       /************************************************  106 :    ＰＯＳ入力人数 ---> Base numbers of guests + 会計時刻またはオーダー時刻 AM,PM分けて */
                Jaccount[di].Field40__c = fields.get(2);                                                                                                                                                        /*  107 :   ＶＯＩＤレシートＮｏ． */
                Jaccount[di].frs__c = wfmgrtbl[currentIndex].revref;                                                                                                                                            /*  103 :   予約会計 reference */
                Jaccount[di].POSNo__c = wfmgrtbl[currentIndex].posno;                                                                                                                                           /*  104 :   POSNo reference */
                Jaccount[di].Field146__c = getworkerid((fields.get(3)).trim());                                                                                                                                 /* put reference Id of employee 036 :   扱者Ｎｏ． reference for enployee */
                boolean roomf = false;                                                                                                                                                                          /* define reference id */
                ID roomrefid;
                if ( (fields.get(9)).trim() != '' ) {                                                                                                                                                           /* Check Table# exist ? */
//                  System.debug('(fields.get(9)).trim(): ' + (fields.get(9)).trim() );
                    if ( !(fields.get(9)).trim().contains('A') ) {/* Check Aplha */
                        Decimal Tableno = Decimal.valueOf((fields.get(9)).trim());
			if ( posreg == 1 ) {	/* Jinya */                                                                                                                                  /* Get table# */
                        if ( (Tableno >= 200 && Tableno < 300) || (Tableno == 131) ) {                                                                                                                              /* Put table link when case VOID and TORIHIKI type != 00 */
                            roomf = true;
                            Jaccount[di].Field150__c = getroomid(Tableno);                                                                                                                                          /* Put Reference Id of room 017 :   テーブルＮｏ． reference for room */
                            roomrefid = Jaccount[di].Field150__c;
                        } else if ( Tableno > 0 && Tableno < 100 ) {                                                                                                                                                /* Check restrant */
                            Jaccount[di].TableNo__c = fields.get(9);                                                                                                                                                /* Put table# of restrant */
                            Jaccount[di].Field150__c = getroomidname('富月殿');                                                                                                                                        /* Put Reference Id of restrant */
                        } else if ( (Tableno > 100 && Tableno < 200) && (Tableno != 131) ) {                                                                                                                        /* Check TAKEKAWA */
                            Jaccount[di].TableNo__c = fields.get(9);                                                                                                                                                /* Put table# of TAKEKAWA */
                            Jaccount[di].Field150__c = getroomidname('竹河');                                                                                                                                     /* Put Reference Id of TAKEKAWA */                              
                        } else {
                            Jaccount[di].TableNo__c = fields.get(9);                                                                                                                                                /* Put table# */
                        }
			} else if ( posreg == 2 ) { 	/* HC */
                 if ( Tableno > 2300 && Tableno < 2740 ) {                                                                                                                              /* Put table link when case VOID and TORIHIKI type != 00 */
                      roomf = true;
                      Jaccount[di].Field150__c = getroomid(Tableno);                                                                                                                                          /* Put Reference Id of room 017 :   テーブルＮｏ． reference for room */
                      roomrefid = Jaccount[di].Field150__c;                                                                                                                                 /* Put Reference Id of TAKEKAWA */                              
                 } else {
                      Jaccount[di].TableNo__c = fields.get(9);                                                                                                                                                /* Put table# */
                 }
 			} else {	/* NOP */
				Jaccount[di].TableNo__c = fields.get(9); 
			}
                    } else {
                        Jaccount[di].TableNo__c = fields.get(9);/* Put table# */
                    }
                    
                    
                } else {                                                                                                                                                                                        /* table# none */
                }
                                                                                                                                                                                                                /* Check reservation object of Jinya revenue 1)reservation day 2)room name 3)cancelbool 4)*****???*AM/PM(Hiru,Yuu,Tomari-Nights__c in the room)***** 5)TORIHIKI type = '00' */
                if ( fields.get(1) == '00' && roomf && Jaccount[di].Field40__c == null ) {                                                                                                                      /* Check TORIHIKI type = normal and ＶＯＩＤレシートＮｏ null */
                    System.debug('******************revday: ' + revday );
                    System.debug('******************roomrefid: ' + roomrefid );
                    
//                  date revday = (wfmgrtbl[currentIndex].revenueday).addDays(-1);                                                                                                                              /* Get Jinya revenue day - 1 (before day) */
//                  date revday = wfmgrtbl[currentIndex].revenueday;                                                                                                                                            /* Get Jinya revenue day - 1 (before day) */
//                  System.debug('revday: ' + revday );
//                  List<Lead__c> mq = [select Id, Name, CustomerofReserve_del__c, Rroom__c, ReservationDate__c from Lead__c where ReservationDate__c = :revday and Rroom__c = :roomrefid and CancelBool__c != 1];
//                  List<Lead__c> mq = [select Id, Name, CustomerofReserve_del__c, ReservationDate__c, Rroom__c, Rroom__r.Name from Lead__c where Rroom__c = :[select Id, Name from Room__c where Rroom__c = :Jaccount[di].Field150__c].Name and ReservationDate__c = :revday and CancelBool__c != 1];
//                  List<Lead__c> mq = [select Id, Name, CustomerofReserve_del__c, ReservationDate__c, Rroom__c, CancelBool__c from Lead__c where ReservationDate__c = :revday and Rroom__c = :roomrefid and CancelBool__c != 1];
//                  List<Lead__c> mq = [select Id, Name, CustomerofReserve_del__c, ReservationDate__c, Rroom__c, CancelBool__c, Rroom__r.Id, Field4__c, Nights__c, checkoutdate__c, Hiru01__c, StayPersons__c from Lead__c where Rroom__c = :[select Id, Name from Room__c where Id = :roomrefid limit 1].Id and ReservationDate__c = :revday and CancelBool__c != 1];
                    List<Lead__c> mq = [select Id, Name, Relcontact__c, ReservationDate__c, Rroom__c, CancelBool__c, Rroom__r.Id, Field4__c, Nights__c, checkoutdate__c, Hiru01__c, StayPersons__c from Lead__c where Rroom__c = :[select Id, Name from Room__c where Id = :roomrefid limit 1].Id and ReservationDate__c = :revday and CancelBool__c != 1];
                    System.debug('****mq: ' + mq );
                    if (!( mq.isEmpty() ) ) {                                                                                                                                                                   /* Check Kara ? */
                        if ( mq.size() == 1 ) {                                                                                                                                                                 /* Check case 1 : {昼 | 夕 | 泊} */
//                          Jaccount[di].Field144__c = mq[0].CustomerofReserve_del__c;                                                                                                                          /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                            Jaccount[di].relaccount__c = mq[0].Relcontact__c;
                            Jaccount[di].Relreserve__c = mq[0].Id;                                                                                                                                              /* Put reference Id of reservation :    予約データへのリンク reference */                         
                        } else if ( mq.size() == 2 ) {                                                                                                                                                          /* Check case 2 : {昼と泊 | 昼と夕} */
                            if ( mq[0].Nights__c == 1 && mq[0].checkoutdate__c == accountdate ) {                                                                                                               /*  first reservation is Night ? */
//                              Jaccount[di].Field144__c = mq[0].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[0].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[0].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                             
                            } else if ( mq[1].Nights__c == 1 && mq[1].checkoutdate__c == accountdate ) {                                                                                                        /* second reservation is night ? */
//                              Jaccount[di].Field144__c = mq[1].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[1].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[1].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                             
                            } else if ( mq[0].Hiru01__c == 1 && hirutime > accounttime ) {                                                                                                                      /*  {昼と夕}   */
//                              Jaccount[di].Field144__c = mq[0].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[0].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[0].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                             
                            } else if ( mq[1].Hiru01__c == 1 && hirutime > accounttime ) {
//                              Jaccount[di].Field144__c = mq[1].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[1].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[1].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                                                             
                            } else if ( mq[0].Hiru01__c == 0 && hirutime < accounttime ) {                                                                                                                      /*  {昼と夕}   */
//                              Jaccount[di].Field144__c = mq[0].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[0].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[0].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                             
                            } else if ( mq[1].Hiru01__c == 0 && hirutime < accounttime ) {
//                              Jaccount[di].Field144__c = mq[1].CustomerofReserve_del__c;                                                                                                                      /* Put reference Id of customer 057 :   顧客コード／従業員コード  for customer reference */
                                Jaccount[di].relaccount__c = mq[1].Relcontact__c;
                                Jaccount[di].Relreserve__c = mq[1].Id;                                                                                                                                          /* Put reference Id of reservation :    予約データへのリンク reference */                                                             
                            } else {
                                System.debug('****One room is case eroor' + mq );
                            }
                        } else if ( mq.size() >= 3 ) {                                                                                                                                                          /* Case more than 3, Lunch or Dinner without night */
                            
                            
                            
                            
                        } else {
                            System.debug('****One room is over 2 reservation' + mq );
                        }
                    }/* reservation (Booking) empty */
                } else {                                                                                                                                                                                        /* Other Account TOTAL */
                    System.debug('****Not link of reservation');                                                                                                                                                /* Nop none link */
                }
            } else if ( currentIndex == 3 || currentIndex == 4 ) {                                                                                                                                              /* TEND */
                Jtend.add(new TTend__c());                                                                                                                                                                      /* Get New TEND Object */
//              Jtend[di].Field1__c = getaccountr((fields.get(0)).trim());                                                                                                                                      /* レシートＮｏ．(4Char)reference KEY is Jinya revenue day and receipt# */
                AccountAcount__c efef = getaccountaccount((fields.get(0)).trim(), wfmgrtbl[currentIndex].srevenueday, wfmgrtbl[currentIndex].posno);
                Jtend[di].Field1__c = efef.Id;                                                                                                                                                                  /* レシートＮｏ．(4Char)reference KEY is Jinya revenue day and receipt# */ 
                Jtend[di].Field4__c = fields.get(3);                                                                                                                                                            /* 処理　種別１ */
                Jtend[di].Field5__c = fields.get(4);                                                                                                                                                            /* 処理　種別２ */
                if (Jtend[di].Field4__c == '1' && Jtend[di].Field5__c == '1' && efef.Field39__c != '00' ) {                                                                                                     /* Check it that Shorishubetsu is normal and Torihikishubetsu is not normal. */     
                    Jtend[di].noneaccount__c = true;                                                                                                                                                            /* Put none account flag( without account ) */
                }                                                                                                                                                                                   
                Jtend[di].Field2__c = fields.get(1);                                                                                                                                                            /* メディア種別 */
                Jtend[di].Field3__c = fields.get(2);                                                                                                                                                            /* メディア名称 */
//              Jtend[di].Field4__c = fields.get(3);                                                                                                                                                            /* 処理　種別１ */
//              Jtend[di].Field5__c = fields.get(4);                                                                                                                                                            /* 処理　種別２ */
                Jtend[di].Field6__c = fields.get(5);                                                                                                                                                            /* 明細　種別 */
                Jtend[di].Field7__c = fields.get(6);                                                                                                                                                            /* 券種コード */
                Jtend[di].Field8__c = fields.get(7);                                                                                                                                                            /* 券名称 */
                Jtend[di].Field9__c = fields.get(8);                                                                                                                                                            /* 発行店番 */
                Jtend[di].Field10__c = fields.get(9);                                                                                                                                                           /* 値引／割引種別 */
//              if ( (fields.get(10)).trim() != '') {                                                                                                                                                           /* RFU(FOR FUTURED USE) */
//                  Jtend[di].Field27__c = getdpid((fields.get(10)).trim());                                                                                                                                    /* Put 対象ＤＰコード reference */
//              }
//              if ( (fields.get(11)).trim() != '' ) {
//                  Jtend[di].Field26__c = getaccountid((fields.get(11)).trim());                                                                                                                               /* 対象メニューコード reference index */
//              }
                Jtend[di].Field13__c = fields.get(12);                                                                                                                                                          /* 対象ＰＬＵコード */
                Jtend[di].Field14__c = fields.get(13);                                                                                                                                                          /* 値引／割引ステータス */
                Jtend[di].Field15__c = fields.get(14);                                                                                                                                                          /* 値割引対象額 */
                Jtend[di].Field16__c = fields.get(15);                                                                                                                                                          /* 単価 */
                Jtend[di].Field17__c = fields.get(16);                                                                                                                                                          /* 枚数 */
                Jtend[di].Field18__c = fields.get(17);                                                                                                                                                          /* 残枚数 */
                Jtend[di].Field19__c = fields.get(18);                                                                                                                                                          /* 預かり　金額 */
                Jtend[di].Field20__c = fields.get(19);                                                                                                                                                          /* 支払　金額 */
                Jtend[di].Field21__c = fields.get(20);                                                                                                                                                          /* 釣銭（差額）金額 */
                Jtend[di].Field22__c = fields.get(21);                                                                                                                                                          /* 釣銭（差額）種別 */
                Jtend[di].Field23__c = fields.get(22);                                                                                                                                                          /* 企業コード */
                Jtend[di].Field24__c = fields.get(23);                                                                                                                                                          /* 有効期限 */
                Jtend[di].Field25__c = fields.get(24);                                                                                                                                                          /* メディア毎消費税額 */
                Jtend[di].Field34__c = wfmgrtbl[currentIndex].srevenueday;                                                                                                                                      /* 営業日付 */
                Jtend[di].POSNo__c = wfmgrtbl[currentIndex].posno;                                                                                                                                              /* POSNo. */
                Jtend[di].RelAccount__c = wfmgrtbl[currentIndex].revref;                                                                                                                                        /* 予約会計 reference */

            } else if ( currentIndex == 5 || currentIndex == 6 ) {                                                                                                                                              /* TITEM */
                Jtitem.add(new Tran1__c());                                                                                                                                                                     /* Get New TITEM Object */
//              System.debug('getaccountaccount((fields.get(0)).trim()): ' + (fields[0]).trim() );
//              AccountAcount__c cdcd = getaccountaccount((fields[0]).trim());                                                                                                                                  /*** Get target TOTAL */
                AccountAcount__c cdcd = getaccountaccount(fields[0], wfmgrtbl[currentIndex].srevenueday, wfmgrtbl[currentIndex].posno);                                                                                                                                         /*** Get target TOTAL */
//              System.debug('cdcd: ' + cdcd );
//              System.debug('di: ' + di );
                Jtitem[di].Field1__c = cdcd.Id;                                                                                                                                                                 /* レシートＮｏ．(4Char)reference KEY is Jinya revenue day and receipt# */                                                                         
                Jtitem[di].Field2__c = fields[1];                                                                                                                                                               /* 商品種別 */  
                Jtitem[di].Field3__c = fields[2];                                                                                                                                                               /* 処理種別１ */ 
                Jtitem[di].Field4__c = fields[3];                                                                                                                                                               /* 処理種別２ */
                                                                                                                                                                                                                /* Too many script statements: 200001  master ----> Do not Search, Hash Algorithm */
                string itemcode = fields[4] + ' ';                                                                                                                                                              /* Get Item code */
                AccountMaster__c ab = laccount[itemhashcodetbale[integer.valueof(itemcode.substring(0,2))][integer.valueof(itemcode.substring(2,4))]];                                                          /* Get Target Item record by hash code Get target Account master Id : Field3__c(商品コード) */
                Jtitem[di].Field7__c = ab.Id;                                                                                                                                                                   /* 商品コード reference */
                Jtitem[di].TaxRate__c = ab.TaxRateCal__c;
                Jtitem[di].ServiceRate__c = ab.ServiceRate__c;
                Jtitem[di].SpecialTax__c = ab.SpecialTax__c;
                if ( ab.Field13_del__c != null && cdcd.Field154__c != null ) {                                                                                                                                  /* Check Change price ? (reference account mater ) and Check account date */
                    if ( cdcd.Field154__c < ChangeBreakfastPricestartDate ) {                                                                                                                                   /* Check Reserved reception date */
                        Jtitem[di].Field7__c = ab.Field13_del__c;                                                                                                                                               /* 商品コード reference for defferent price at same item */
                        string nextitemcode = ab.nextitemcode__c + ' ';
                        ab = laccount[itemhashcodetbale[integer.valueof(nextitemcode.substring(0,2))][integer.valueof(nextitemcode.substring(2,4))]];                                                           /* Change Master record for defferent price at same item */
                    }                           
                }

                AccountMaster__c abab;                                                                                                                                                                          /* for getting parent menu record */
                boolean pmenuf = false;
                icode = fields[9].trim();
                if ( icode != '' ) {                                                                                                                                                                            /* Check null */
                    if ( integer.valueof(icode) >= 4101 && integer.valueof(icode) <= 6099 ) {                                                                                                                   /* Check Item code */
                        string pitemcode = icode + ' ';
                        abab = laccount[itemhashcodetbale[integer.valueof(pitemcode.substring(0,2))][integer.valueof(pitemcode.substring(2,4))]];                                                               /*** for getting DP code 親メニューコード */
                        Jtitem[di].Field10__c = abab.Id;                                                                                                                                                        /* 親メニューコード reference */
                        pmenuf = true;
                    }
                }
                                                                                                                                                                                                                /* Entry Item in BaraIndexTbale */
//              if ( ab.detail13__c == true ) {                                                                                                                                                                 /* Bara switch on ! for set menu */
                if ( ab.detail13__c == true && wfmgrtbl[currentIndex].revenueday >= ChangeBarastartDate ) {                                                                                                     /* Bara switch on ! for set menu on Change Bara Start Date */
                    Baratbl wBaratbl = new Baratbl();                                                                                                                                                           /* Create Baratable 1 record */
                    wBaratbl.Index = di;                                                                                                                                                                        /* Index of Jtitem array for Set menu */
                    wBaratbl.gp = ab.GPChange__c;                                                                                                                                                               /* Change GP of account master */
                    wBaratbl.dp = ab.DPChange__c;                                                                                                                                                               /* Change DP of account master */
                    wBaratbl.costofsales = ab.Field7__c;
                    if ( ab.Field5__c == 0 ) {                                                                                                                                                                  /* Check open price of Account Master */
                                                                                                                                                                                                                /* Check Mainasu price(-price)? */
                        wBaratbl.price = decimal.valueof((fields[19]).substring(1));                                                                                                                            /* +price of transaction record */
                    } else {
                        wBaratbl.price = ab.Field5__c;                                                                                                                                                          /* price of account master */
                    }               
                    if (Jtitem[di].Field2__c == 'M') {                                                                                                                                                          /* Check item tag */
                        BaraYindex++;                                                                                                                                                                           /* Numbers of Bara */               
                        Jtitem[di].noneaccount__c = true;                                                                                                                                                       /* Put none account flag( without account ) */
                        BaraIndexTbale.add(new List<Baratbl>());                                                                                                                                                /* Create M,P,P,... 1 table */
                                                                                                                                                                                                                /* Check getting DP from parent menu */
//                  } else if ( Jtitem[di].Field2__c == 'P' && ab.DPChange__c == null && ab.GPChange__c == null && (fields.get(9)).trim() != '' && pmenuf ) {
                    } else if ( Jtitem[di].Field2__c == 'P' && ab.DPChange__c == null && (fields[9]).trim() != '' && pmenuf ) {                                                                                 /* GP code is define for room & breakfast */
                        wBaratbl.dp = abab.Field4__c;                                                                                                                                                           /* Put change DP for each room & breakfast */
                    }
                    BaraIndexTbale[(BaraYindex-1)].add(wBaratbl);                                                                                                                                               /* Put Baratable 1 record */
                }   

                Jtitem[di].Field5__c = fields[5];                                                                                                                                                               /* 商品名称（または券名称） */  
                Jtitem[di].Field8__c = fields[6];                                                                                                                                                               /* 伝票Ｎｏ． */ 
    
                icode = fields[7].trim();                                                                                                                                                                       /* テーブルＮｏ．reference */
                if ( icode != '' ) {                                                                                                                                                                            /* Check Table# exist ? */
                    if ( !icode.contains('A') ) {/* Check Aplha */
                        Decimal Tableno = Decimal.valueOf(icode);
			if ( posreg == 1 ) {	/* Jinya */                                                                                                                                                   /* Get table# */
                        if ( (Tableno >= 200 && Tableno < 300) || (Tableno == 131) ) {                                                                                                                              /* Put table link when case VOID and TORIHIKI type != 00 */
                            Jtitem[di].Field6__c = getroomid(Tableno);                                                                                                                                              /*** Put Reference Id of room 017 : テーブルＮｏ． reference for room */
                        } else if ( Tableno > 0 && Tableno < 100 ) {                                                                                                                                                /* Check restrant */
                            Jtitem[di].TableNo__c = icode;                                                                                                                                                          /* Put table# of restrant */
                            Jtitem[di].Field6__c = Nigiwaiteiroomid;                                                                                                                                                /*** Put Reference Id of restrant */
                        } else if ( (Tableno > 100 && Tableno < 200) && (Tableno != 131) ) {                                                                                                                        /* Check TAKEKAWA */
                            Jtitem[di].TableNo__c = icode;                                                                                                                                                          /* Put table# of TAKEKAWA */
                            Jtitem[di].Field6__c = Takekawaroomid;                                                                                                                                                  /*** Put Reference Id of TAKEKAWA */                                
                        } else {
                            Jtitem[di].TableNo__c = icode;                                                                                                                                                          /* Put table# */
                        }
			} else if ( posreg == 2 ) { 	/* HC */
                 if ( Tableno > 2300 && Tableno < 2740 ) {                                                                                                                              /* Put table link when case VOID and TORIHIKI type != 00 */
 					  Jtitem[di].Field6__c = getroomid(Tableno);                                                                                                                                  /* Put Reference Id of TAKEKAWA */                              
                 } else {
                      Jtitem[di].TableNo__c = icode;                                                                                                                                                 /* Put table# */
                 }
 			} else {	/* NOP */
				Jtitem[di].TableNo__c = icode;
			}
                    } else {
                        Jtitem[di].TableNo__c = icode;
                    }
                } else {                                                                                                                                                                                        /* table# none */
                }
                Jtitem[di].Field9__c = fields[8];                                                                                                                                                               /* オーダー時刻 */

                Jtitem[di].Field11__c = fields[10];                                                                                                                                                             /* 親メニュー名称 */   
                Jtitem[di].Field12__c = fields[11];                                                                                                                                                             /* 自社コード */ 
                Jtitem[di].Field13__c = fields[12];                                                                                                                                                             /* 売上集計リンクコード */    
                Jtitem[di].Field14__c = fields[13];                                                                                                                                                             /* テイクアウトフラグ */ 
                Jtitem[di].Field15__c = fields[14];                                                                                                                                                             /* 奉仕料２（深夜料）フラグ */  
                Jtitem[di].Field16__c = fields[15];                                                                                                                                                             /* ＳＴ１ */   
                Jtitem[di].Field17__c = fields[16];                                                                                                                                                             /* ＳＴ２ */   
                Jtitem[di].Field18__c = fields[17];                                                                                                                                                             /* ＳＴ３ */   
                Jtitem[di].Field19__c = fields[18];                                                                                                                                                             /* ＳＴ４ 0 bit : ON Sample data : 003 */
                Boolean isncalc = false;
                if ( (Integer.valueOf(fields[18]) & 1) == 1 ) {                                                                                                                                                 /* Check remain numbers */
                    isncalc = true;                                                                                                                                                                             /* Put calc numbers for change orders of menu */
                }
                Jtitem[di].Subprice__c = ab.Field6__c;                                                                                                                                                          /* マスタからサブ単価を取得 飲み放題のため */ 
                Jtitem[di].Field20__c = fields[19];                                                                                                                                                             /* 単価 Sample data : +006800 */  
                Jtitem[di].Field21__c = fields[20];                                                                                                                                                             /* 数量 Sample data :   +002 */   
                Jtitem[di].Field22__c = fields[21];                                                                                                                                                             /* 残数量 Sample data :  +002 */   
                Jtitem[di].Field23__c = fields[22];                                                                                                                                                             /* 合計金額 Sample data : +0013600 */
                Decimal Uprice = Decimal.valueOf(fields[19].substring(1));                                                                                                                                      /* a unit price */
                Decimal Unum = Decimal.valueOf(fields[20].substring(1));                                                                                                                                        /* numbers */
                Decimal Urnum = Decimal.valueOf(fields[21].substring(1));                                                                                                                                       /* remain numbers */
                Decimal Utotal = Decimal.valueOf(fields[22].substring(1));                                                                                                                                      /* total price */

//              integer iUprice = integer.valueof(Utotal);
//              integer iTaxfee = integer.valueof(Taxfee);                                                                                                                                                      /* Calculate Tax fee */
//              if ( ab.StsTaxfee__c == '0' && Utotal != 0 ) {
//                  if ( math.mod(iUprice,iTaxfee) == 0 ) {                                                                                                                                                     /* Check remain */
//                      Jtitem[di].TankawithoutTax__c = Utotal/Taxfee;                                                                                                                                          /* Put a unit price */
//                  } else {
//                      Jtitem[di].TankawithoutTax__c = (Utotal/Taxfee) + 1;                                                                                                                                    /* Put a unit price + 1 */
//                  }
//              } else {
//                  Jtitem[di].TankawithoutTax__c = Utotal;                                                                                                                                                     /* Put a unit price without tax fee */
//              }
                
                if ( (Unum > Urnum) && (Urnum != 0) && (isncalc == true) ) {                                                                                                                                    /* for Change order menu */
                    Jtitem[di].Field21__c = '+' + mformat(3,Urnum);                                                                                                                                             /* put numbers <- remain numbers '%03d' '{0, number, 000}'*/
                    Jtitem[di].Field23__c = '+' + mformat(7,(Urnum * Uprice));                                                                                                                                  /* Put total price */
                }
                Jtitem[di].Field24__c = fields[23];                                                                                                                                                             /* 原単価 */
//              Jtitem[di].Field25__c = getdpid((fields.get(24)).trim());                                                                                                                                       /*** リンクＤＰコード reference */
//              Jtitem[di].Field26__c = getgpid((fields.get(25)).trim());                                                                                                                                       /*** リンクＧＰコード reference */                  
                Jtitem[di].Field25__c = tdp[integer.valueof( fields[24].trim() )];                                                                                                                              /*** リンクＤＰコード reference */
                Jtitem[di].Field26__c = tgp[integer.valueof( fields[25].trim() )];                                                                                                                              /*** リンクＧＰコード reference */                  
                Jtitem[di].Field27__c = fields[26];                                                                                                                                                             /* 消費税　種別 */    
                Jtitem[di].Field28__c = fields[27];                                                                                                                                                             /* 正負フラグ */ 
                Jtitem[di].Field29__c = fields[28];                                                                                                                                                             /* 発行店番 */  
                Jtitem[di].Field30__c = fields[29];                                                                                                                                                             /* 階層／指示ステータス位置 */  
                Jtitem[di].Field31__c = fields[30];                                                                                                                                                             /* 指示ステータスＮｏ． */    
                Jtitem[di].Field32__c = fields[31];                                                                                                                                                             /* コメントＮｏ． */   
                Jtitem[di].Field33__c = fields[32];                                                                                                                                                             /* 値割引点数 */ 
                Jtitem[di].Field34__c = fields[33];                                                                                                                                                             /* 値割引金額 */ 
                Jtitem[di].Field35__c = fields[34];                                                                                                                                                             /* プロモ出数 */ 
                Jtitem[di].Field36__c = fields[35];                                                                                                                                                             /* キャンセルリンクシリアルＮｏ． */   
                Jtitem[di].Field37__c = fields[36];                                                                                                                                                             /* リンク値割引明細支払番号 */  
                Jtitem[di].Field38__c = fields[37];                                                                                                                                                             /* 奉仕料１フラグ */   
                Jtitem[di].Field45__c = wfmgrtbl[currentIndex].srevenueday;                                                                                                                                     /* 営業日付 */
                Jtitem[di].POSNo__c = wfmgrtbl[currentIndex].posno;                                                                                                                                             /* POSNo. */
                Jtitem[di].RelAccount__c = wfmgrtbl[currentIndex].revref;                                                                                                                                       /* 予約会計 reference */
            } else if ( currentIndex == 7 || currentIndex == 8 || currentIndex == 9 ) {                                                                                                                         /* SHIFT, ZTOTAL */
                integer accountindex = integer.valueof(fields.get(0));
                if  ( accountindex < 242 ) {                                                                                                                                                                    /* Check lines */
                    if ( actflagtbl[accountindex] ) {                                                                                                                                                           /* Target account ? */
                        acttbl wwacttbl = new acttbl();
                        wwacttbl.actno = fields.get(0);                                                                                                                                                         /* 集計番号 */
                        wwacttbl.actname = fields.get(1);                                                                                                                                                       /* 名称 */
                        wwacttbl.amtprice = decimal.valueof(fields.get(3));                                                                                                                                     /* 金額 カウンタ */
                        wwacttbl.cuscounter = decimal.valueof(fields.get(13));                                                                                                                                  /* 客数 カウンタ */
                        wacttbl[(currentIndex-7)].add(wwacttbl);
                    }
                }                                                                                                                                                                                                                                                                                                                       
            } else {                                                                                                                                                                                            /* Other current index */
                /* Nop */
            }
            num++;                                                                                                                                                                                              /* Next source line index */                            
            di++;                                                                                                                                                                                               /* Next destination line index */
        }                                                                                                                                                                                                       /* loop next line record for csv files */
                                                                                                                                                                                                                /*********************Create Account record to database */  
        if ( currentsts == 1 ) {                                                                                                                                                                                /* TTOTAL */                                                                                                                                                                                                                                                        
//              lsr = Database.insert(new AccountAcount__c[]{Jaccount},false);                                                                                                                                  /* Create Profit day */
//              for (Database.SaveResult sr:lsr){                                                                                                                                                               /* Iterate through the Save Results */
//                     if (!sr.isSuccess()) {
//                        Database.Error err = sr.getErrors()[0];                                                                                                                                               /************************************** Put error */
//                        System.debug(' Database error :New rsvaccount: ' + err );
//                     } else {
//                     }
//               }
                try {
                    System.debug(' Jaccount: ' + Jaccount );
                        insert Jaccount;
                } catch (Exception e) {
                        ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in TTOTAL. Please check the template or try again later');
                        ApexPages.addMessage(errormsg);
                }    
                 
        } else if ( currentsts == 2 ) {                                                                                                                                                                         /* TEND */
                try {
                        insert Jtend;
                } catch (Exception e) {
                        ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in TEND. Please check the template or try again later');
                        ApexPages.addMessage(errormsg);
                }    

        } else if ( currentsts == 3 ) {                                                                                                                                                                         /* TITEM */

//              /* System.debug('********BaraIndexTbale: ' + BaraIndexTbale.size() );
//              System.debug('********BaraIndexTbale[0]: ' + BaraIndexTbale[0].size() );
//              System.debug('********BaraIndexTbale[0][0].Index: ' + BaraIndexTbale[0][0].Index );
//              ystem.debug('********BaraIndexTbale[0][0].price: ' + BaraIndexTbale[0][0].price );
//              System.debug('********BaraIndexTbale[0][1].Index: ' + BaraIndexTbale[0][1].Index );
//              System.debug('********BaraIndexTbale[0][1].price: ' + BaraIndexTbale[0][1].price );
//              System.debug('********BaraIndexTbale[0][2].Index: ' + BaraIndexTbale[0][2].Index );
//              System.debug('********BaraIndexTbale[0][2].price: ' + BaraIndexTbale[0][2].price );
//              System.debug('********BaraIndexTbale[1]: ' + BaraIndexTbale[1].size() );
//              System.debug('********BaraIndexTbale[1][0].Index: ' + BaraIndexTbale[1][0].Index );
//              System.debug('********BaraIndexTbale[1][0].price: ' + BaraIndexTbale[1][0].price );
//              System.debug('********BaraIndexTbale[1][1].Index: ' + BaraIndexTbale[1][1].Index );
//              System.debug('********BaraIndexTbale[1][1].price: ' + BaraIndexTbale[1][1].price );
//              System.debug('********BaraIndexTbale[1][2].Index: ' + BaraIndexTbale[1][2].Index );
//              System.debug('********BaraIndexTbale[1][2].price: ' + BaraIndexTbale[1][2].price );*/

/****************************************************************************************************/
/*                                                                                                  */                  
/*                       [0]      [1]     [2]    [3]                                                */
/*      BaraIndexTbale  +----------------------------------------+                                  */
/*                  [0] | M       $P       P      P      P  ...  |                                  */
/*                      +----------------------------------------+                                  */
/*                  [1] | M       $P       P      P     ...      |                                  */
/*                      +----------------------------------------+                                  */
/*                  [2] | M       $P       P          ...        |                                  */
/*                      +----------------------------------------+                                  */
/*                  .                                                                               */
/*                  .                                                                               */
/*                  .                                                                               */
/*                  $:Put remain price in last P <------------------------------                    */
/*                                                                                                  */
/****************************************************************************************************/
                integer wi = 0;
                while ( BaraYindex > 0 ) {
                    integer i = BaraIndexTbale[wi].size() - 1;                                                                                                                                                  /* get end point without M */
                    decimal remain = BaraIndexTbale[wi][0].price;                                                                                                                                               /* price of M for remain currency */
                    if ( remain < 900 ) {                                                                                                                                                                       /* Check price ¥900 below () for one drink child */
                        i = 0;                                                                                                                                                                                  /* Loop break of One M */
                    }
//                  System.debug('***remain: ' + remain );              
//                  System.debug('***BaraYindex: ' + BaraYindex );              
                    while ( i > 0 ) {
                        integer si = BaraIndexTbale[wi][i].Index;
                        decimal nm = Decimal.valueOf((Jtitem[si].Field21__c).substring(1));                                                                                                                     /* Get numbers for total amount */
                        Jtitem[si].Field24__c = '+' + mformat(6,BaraIndexTbale[wi][i].costofsales);
                        if ( i == 1 ) {                                                                                                                                                                         /* Check last P from end point */
                            Jtitem[si].Field20__c = '+' + mformat(6,remain);                                                                                                                                    /* Put price string of P */
                            Jtitem[si].Field23__c = '+' + mformat(7,(remain * nm));                                                                                                                             /* Put Total Amount */
                        } else {
                            remain = remain - BaraIndexTbale[wi][i].price;
                            Jtitem[si].Field20__c = '+' + mformat(6,BaraIndexTbale[wi][i].price);                                                                                                               /* Put price string of P */
                            Jtitem[si].Field23__c = '+' + mformat(7,(BaraIndexTbale[wi][i].price * nm));                                                                                                        /* Put Total Amount */
                        }
                        if ( !(BaraIndexTbale[wi][i].dp == null) ) {                                                                                                                                            /* Check null */
                            Jtitem[si].Field25__c = BaraIndexTbale[wi][i].dp;                                                                                                                                   /* Put DP reference */
                        }
                        if ( !(BaraIndexTbale[wi][i].gp == null) ) {                                                                                                                                            /* Check null */
                            Jtitem[si].Field26__c = BaraIndexTbale[wi][i].gp;                                                                                                                                   /* Put GP reference */
                        }                       
                        i--;
                    }
                    BaraYindex--;                                                                                                                                                                               /* Nums of M loop */                                                                                                                                                                                                    
                    wi++;                                                                                                                                                                                       /* Index of M,P,P loop */
                }
                
                try {
                        insert Jtitem;
                } catch (Exception e) {
                        ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in TITEM. Please check the template or try again later');
                        ApexPages.addMessage(errormsg);
                }    
            currentIndex = 0;                                                                                                                                                                                   /* Idle current  Index */           
            currentsts = 0;                                                                                                                                                                                     /* Idle current status */                                                                                                                                                                                                                                                                                                               
        } else if ( currentsts == 4 ) {                                                                                                                                                                         /* SHIFT, ZTOTAL */
            RsvAccount__c uprsvaccount = [select Id, Name from RsvAccount__c where name = :rsvaccount.Name limit 1];
//          System.debug(' uprsvaccount: ' + uprsvaccount );
                                                                                                                                                                                                                                                /*** 0:SHIFT01 */
            uprsvaccount.front10__c = wacttbl[0][0].cuscounter;                                                                                                                                                                                 /* 本館-客数 */
            uprsvaccount.front9__c = wacttbl[0][1].amtprice;                                                                                                                                                                                    /* 本館-客単価 */
            uprsvaccount.front8__c = wacttbl[0][2].amtprice;                                                                                                                                                                                    /* 本館-客単価(税込) */
            uprsvaccount.front25__c = wacttbl[0][3].amtprice;                                                                                                                                                                                   /* 本館-売上 */
            uprsvaccount.front1__c = wacttbl[0][4].amtprice;                                                                                                                                                                                    /* 本館-売上(税込) */
            uprsvaccount.front17__c = wacttbl[0][5].amtprice;                                                                                                                                                                                   /* 本館-割引値引合計 */
            uprsvaccount.front26__c = wacttbl[0][6].amtprice;                                                                                                                                                                                   /* 本館-消費税 */
            uprsvaccount.fornt2__c = wacttbl[0][7].amtprice;                                                                                                                                                                                    /* 本館-クーポン合計 */
            uprsvaccount.front7__c = wacttbl[0][8].amtprice;                                                                                                                                                                                    /* 本館-現　計 */
            uprsvaccount.Field4__c = wacttbl[0][9].amtprice;                                                                                                                                                                                    /* 本館-クレジット */
            uprsvaccount.front3__c = wacttbl[0][10].amtprice;                                                                                                                                                                                   /* 本館-掛　計 */
            uprsvaccount.front6__c = wacttbl[0][11].amtprice;                                                                                                                                                                                   /* 本館-内金 */
            uprsvaccount.front13__c = wacttbl[0][12].cuscounter;                                                                                                                                                                                /* 本館-男性 */
            uprsvaccount.front14__c = wacttbl[0][13].cuscounter;                                                                                                                                                                                /* 本館-女性 */
            uprsvaccount.front15__c = wacttbl[0][14].cuscounter;                                                                                                                                                                                /* 本館-子供 */
                                                                                                                                                                                                                                                /*** 1:SHIFT02 Restrunt */
            uprsvaccount.Restrunt15__c = wacttbl[1][0].cuscounter;                                                                                                                                                                              /* 客数 */
            uprsvaccount.FRestrunt9__c = wacttbl[1][1].amtprice;                                                                                                                                                                                /* 客単価 */
            uprsvaccount.Restrunt8__c = wacttbl[1][2].amtprice;                                                                                                                                                                                 /* 客単価(税込) */
            uprsvaccount.Restrunt25__c = wacttbl[1][3].amtprice;                                                                                                                                                                                /* 売上 */
            uprsvaccount.restraunt1__c = wacttbl[1][4].amtprice;                                                                                                                                                                                /* 売上(税込) */
            uprsvaccount.Restrunt17__c = wacttbl[1][5].amtprice;                                                                                                                                                                                /* 割引値引合計 */
            uprsvaccount.Restrunt26__c = wacttbl[1][6].amtprice;                                                                                                                                                                                /* 消費税 */
            uprsvaccount.Restrunt19__c = wacttbl[1][7].amtprice;                                                                                                                                                                                /* クーポン合計 */
            uprsvaccount.restraunt2__c = wacttbl[1][8].amtprice;                                                                                                                                                                                /* 現　計 */
            uprsvaccount.restraunt3__c = wacttbl[1][9].amtprice;                                                                                                                                                                                /* クレジット */
            uprsvaccount.restraunt4__c = wacttbl[1][10].amtprice;                                                                                                                                                                               /* 掛　計 */
            uprsvaccount.Restrunt18__c = wacttbl[1][11].amtprice;                                                                                                                                                                               /* 内金 */
            uprsvaccount.Restrunt10__c = wacttbl[1][12].cuscounter;                                                                                                                                                                             /* 男性 */
            uprsvaccount.Restrunt11__c = wacttbl[1][13].cuscounter;                                                                                                                                                                             /* 女性 */
            uprsvaccount.Restrunt12__c = wacttbl[1][14].cuscounter;                                                                                                                                                                             /* 子供 */
                                                                                                                                                                                                                                                /*** 2:ZTOTAL */            
            uprsvaccount.Persons__c = wacttbl[2][0].cuscounter;                                                                                                                                                                                 /* 客数 */
            uprsvaccount.SalesAverage__c = wacttbl[2][1].amtprice;                                                                                                                                                                              /* 客単価 */
            uprsvaccount.SalesAverageKomi__c = wacttbl[2][2].amtprice;                                                                                                                                                                          /* 客単価(税込) */
//          uprsvaccount.front25__c = wacttbl[2][3].amtprice;                                                                                                                                                                                   /* 売上 */
//          uprsvaccount.front1__c = wacttbl[2][4].amtprice;                                                                                                                                                                                    /* 売上(税込) */
            uprsvaccount.Discount2__c = wacttbl[2][5].amtprice;                                                                                                                                                                                 /* 割引値引合計 */
//          uprsvaccount.CuponKomi__c = wacttbl[2][6].amtprice;                                                                                                                                                                                 /* 消費税 */
            uprsvaccount.CuponKomi__c = wacttbl[2][7].amtprice;                                                                                                                                                                                 /* クーポン合計 */
            uprsvaccount.GenkinkeiKomi__c = wacttbl[2][8].amtprice;                                                                                                                                                                             /* 現　計 */
            uprsvaccount.CreditKkomi__c = wacttbl[2][9].amtprice;                                                                                                                                                                               /* クレジット */
            uprsvaccount.KakeKeiKomi__c = wacttbl[2][10].amtprice;                                                                                                                                                                              /* 掛　計 */
            uprsvaccount.UchikinKomi__c = wacttbl[2][11].amtprice;                                                                                                                                                                              /* 内金 */
            uprsvaccount.males__c = wacttbl[2][12].cuscounter;                                                                                                                                                                                  /* 男性 */
            uprsvaccount.femails__c = wacttbl[2][13].cuscounter;                                                                                                                                                                                /* 女性 */
            uprsvaccount.Childs__c = wacttbl[2][14].cuscounter;                                                                                                                                                                                 /* 子供 */
            
/****************************************************************************/
/*                                                                          */          
/* Accounting of Operating rate and persons                                 */
/*                                                                          */  
/****************************************************************************/






            
                                                                                                                                                                                                                                                /* Update Jinya revenue for sales one day */
            Database.SaveResult SR = Database.update(uprsvaccount);                                                                                                                                                                             /* Update Jinya revenue */
            for(Database.Error err: SR.getErrors()) {                                                                                                                                                                                           /* Check database error */
                 System.debug(' Database error :Exsiting customer: ' + err );
                // process any errors here
            }
            
            
            
            
                        
        } else {                                                                                                                                                                                                                                /* Other currentsts */
            /* Nop */
        }
        
        
        
        return null;                                                                                                                                                                                                                            /* Exit normal */
    }

/****************************************************************************************/
/*                                                                                      */          
/*  Update sales account                                                                */          
/*                                                                                      */          
/*                                                                                      */  
/*          Calling sequence                                                            */  
/*                  Button Event                                                        */  
/*                                                                                      */  
/*                                                                                      */  
/****************************************************************************************/
    private         List<RsvAccount__c> lrevenue;
    private         List<Lead__c> lbook;
// 2017/06/21 不要な処理するため、該当Logicを削除 WSQ    
     public void UpdateforSalesforcast() {                                                                                                                                                                                                               /* *****for CSV file */
            
//                                                                                                 /* Get Max sales account day */
//             String str = 'select Id, Name, Salesday__c, FutureYen__c from RsvAccount__c where Salesday__c >= ' + string.valueof(date.today()) + ' order by Salesday__c DESC';
//             lrevenue = Database.query(str);
//             if ( !(lrevenue.isEmpty()) ) {                                                      /* Check empty */
//                     date maxrevenueday = lrevenue[0].Salesday__c;
//                     System.debug(' ********Max sales account day : ' + maxrevenueday );
//                     integer i = 0;
//                     integer ii = lrevenue.size();
// //                  if ( ii >= 90 ) {
// //                      ii = 90;/* for gaver limit */
// //                  }
//                     integer bi,bii;
//                     decimal wSalesaccount;
//                     date wrevenuetoday;
//                     while ( i < ii ) {                                                          /* Loop by last sales day */
//                         wrevenuetoday = lrevenue[i].Salesday__c;
//                         lbook = [select Id, Name, CancelBool__c, ReservationDate__c, Salesaccount__c from Lead__c where ReservationDate__c = :wrevenuetoday and CancelBool__c != 1];
//                         bi = 0;
//                         bii = lbook.size();
//                         wSalesaccount = 0;
//                         while ( bi < bii ) {
//                             wSalesaccount += lbook[bi].Salesaccount__c;
//                             bi++;
//                         }
//                         lrevenue[i].FutureYen__c = wSalesaccount;
//                         i++;                                                                    /* Next array of revenue */
//                     }                                                               
//                                                                                                 /* Update sales account */
//                     try {
//                         update lrevenue;
//                     } catch (Exception e) {
//                         ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in RsvAccount__c. Please check the object or try again later');
//                         ApexPages.addMessage(errormsg);
//                     }
//             } else {
//                     System.debug(' Sales account is empty ');
//             }    

            
     }

//          date wrevenuetoday = date.today();
//          lrevenue = [select Id, Name, Salesday__c, FutureYen__c from RsvAccount__c where Salesday__c >= :wrevenuetoday order by Salesday__c DESC];

//      String str = 'select Id, Name, Salesday__c from RsvAccount__c where Salesday__c >= ' + string.valueof(date.today());
//      lrevenue = Database.query(str);
            
//          AggregateResult[] groupedResults = [SELECT AVG(Amount)aver FROM Opportunity];
//          Object avgAmount = groupedResults[0].get('aver');


}


/*
public class FileUploader 
{
    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    String[] filelines = new String[]{};
    List<Account> accstoupload;
    
    public Pagereference ReadFile()
    {
        nameFile=contentFile.toString();
        filelines = nameFile.split('\n');
        accstoupload = new List<Account>();
        for (Integer i=1;i<filelines.size();i++)
        {
            String[] inputvalues = new String[]{};
            inputvalues = filelines[i].split(',');
            
            Account a = new Account();
            a.Name = inputvalues[0];
            a.ShippingStreet = inputvalues[1];       
            a.ShippingCity = inputvalues[2];
            a.ShippingState = inputvalues[3];
            a.ShippingPostalCode = inputvalues[4];
            a.ShippingCountry = inputvalues[5];

            accstoupload.add(a);
        }
        try{
        insert accstoupload;
        }
        catch (Exception e)
        {
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured. Please check the template or try again later');
            ApexPages.addMessage(errormsg);
        }    
        return null;
    }
    
    public List<Account> getuploadedAccounts()
    {
        if (accstoupload!= NULL)
            if (accstoupload.size() > 0)
                return accstoupload;
            else
                return null;                    
        else
            return null;
    }            
}
*/



/*
    private static string DecimaltoCurrency(Decimal val) {
        if (val==0) return '0.00';
        string str = val.divide(1,2,RoundingMode.HALF_UP).format()+'.00';
        integer dec = str.lastindexOf('.');
        system.debug('-------DecimaltoCurrency: -str/dec/len------------->'+str + '/'+dec+'/'+str.length());
        if (dec==-1 ) return str.substring(0,str.length()-2)+'.00';
        //else if (dec==str.length()-1) return str+'0';
        else return str.substring(0,dec+3);
    }

public string getTotalAmount() {
    double rtn=0.00;
    system.debug('newItems:'+newItems);
    
    if (newItems!=null && newItems.size()>0) {
        for (LineItem li : newItems.values()) {
            if (li.item!=null)
             rtn+=(li.item.UnitPrice__c * li.item.Quantity__c);
        }
    }
     return DecimaltoCurrency(rtn);
 }


private void renumItems() {
    map<integer,LineItem> items = new map<integer,LineItem>();
    for (LineItem li : newItems.values()) {
        items.put(items.size(),li);
    }
    newItems=items;
}

******************************************************

In Visualforce reference the variable:

    Invoice Total Amount : <h3>{!TotalAmount}</h3>
    */