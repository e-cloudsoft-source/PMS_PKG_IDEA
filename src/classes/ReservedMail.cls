/***
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 * 2014.01.09 Rev. Upate StayPersons__c Parse Formula
 * 2013.11.21 Rev. Add Mail FeedBack
 * 2013.06.11 Rev. Delete stay booking for YoyakuproAGT
 * 2011.11.25 Rev. Customer object -> Contact
 * 2010.12.26 Rev. Update customer object
 * 2010.12.26 Rev. About Customer object Insert and Reservation object, Change inserting two records to one record.
 * 2010.12.26 Rev. Put restrant or room or none in meal
 * 2010.12.23 Rev. N nights for reservation Name add
 * 2010.12.19 Rev. N room N nights -> add special description in N room, second nights is check-in time 0:00, and add "目" from second nights 
 * 2010.11.2 Rev. Decimal Invalid 
 * 2010.11.2 Rev. Change room charge to RC charge 
 * 2010.10.29 third Rev. solve INVALID day and time 
 * 2010.10.23 second Rev. add plan process of not nights
 * 2010.09.23 first Rev. Author by Ryoma Morimoto.
 *    Description : 
 *              Recieve reservation email from Yoyaku pro, Create Customer without existing, and Create reservation record.
 */
 
global class ReservedMail implements Messaging.InboundEmailHandler {

    /* Work area of reserved information */
    private List<ReservedInfo> Rsvinfo = new List<ReservedInfo>();
    /* This class is structure of reserved persons and room charge per one person */
    private class ReservedInfo { 
        private Decimal Persons;                    /* Stay persons */
        private Decimal Maleperson;                 /* Male persons */
        private Decimal Femaleperson;               /* Fem1ale persons */
        private Decimal Chargeofroom;               /* FCharge of room */
    }    

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        String[] emailBody = email.plainTextBody.split('\n', 0);                                                                                     /* Get email contexts */
        
	 	if ( Pattern.matches('【元湯陣屋】日帰り・団体プランのご予約', email.subject) ) {                                                                    /* Check New reservation-HIRU email from web-site */
                    Contact contact2 = new Contact();                   
                    Lead__c rsv = new Lead__c();                                                                                                     /* Create reservation */
                    rsv.email__c = email.plainTextBody;                                                                                              /* Put reserved mail context */
                    Datetime rsvnow = System.now();                                                                                                  /* for date and time formatting */
                    rsv.ReservedDate__c = datetime.valueOf(rsvnow.format('yyyy-MM-dd HH:mm:ss'));                                                    /* Recieved mail Day and time = Reserved date and time */
                    rsv.ReservedStatus__c = '確認中'   ;                                                                                              /* Put reservation status */
                    rsv.ReservedContact__c = '$Jinyaforce$';                                                                                         /* Put reservation contact */
                    rsv.Field2__c = '自社サイト';                                                                                                      /* Put reservation-channel */
                    rsv.Field308__c = 'その他';                                                                                                       /* Put CM */                                                                                                                                                

                    Integer wnextline = 1;
                    while ( !(emailBody[wnextline].contains('【お申し込み内容】')) ) {                                                                   /* Check loop for n lines for Plan */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                     /* Next line */         
                    String hPlanPlan = emailBody[wnextline];                                                                                         /* Save Plan name */ 
                    while ( !(emailBody[wnextline].contains('【ご利用日時】')) ) {                                                                      /* Check loop for check-in day and time */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                     /* Next line */
//                  if ( Pattern.matches('????年??月??日　 ??時??分', emailBody[wnextline]) ) { ????年??月??日　 ??時??分
                    System.debug('***Plan      : ' + hPlanPlan);
                    System.debug('***ご利用日時      : ' + emailBody[wnextline]);
                    
                    
                    String yyear = emailBody[wnextline].substring( 0, emailBody[wnextline].Indexof('年') );
                    String mmonth = emailBody[wnextline].substring( emailBody[wnextline].Indexof('年')+1, emailBody[wnextline].Indexof('月') );
                    String dday = emailBody[wnextline].substring( emailBody[wnextline].Indexof('月')+1, emailBody[wnextline].Indexof('日') );
                    String tttime = emailBody[wnextline].substring( emailBody[wnextline].Indexof('日')+2, emailBody[wnextline].Indexof('時') );
                    String mtttime = emailBody[wnextline].substring( emailBody[wnextline].Indexof('時')+1, emailBody[wnextline].Indexof('分') );
                    
//                  String[] yyear = emailBody[wnextline].split('年',2);                                                                                         /* Get year[0] */
//                                      System.debug('***yyear[1]      : ' + yyear[1]);
//                  String[] mmonth = yyear[1].split('月',2);                                                                                                    /* Get month[0] */
//                  String[] dday = mmonth[1].split('日',2);                                                                                                     /* Get day[0] */
//                  String[] tttime = dday[1].split('時',2);                                                                                                     /* Get time　hour */
//                  String[] mtttime = tttime[1].split('分',2);                                                                                                  /* Get time　minute */

                                                                                                                                                                /* Put Check-in day and time */
                    //String entrsvdates = yyear.trim() + '-' + mmonth.trim() + '-' + dday.trim() + ' ' + tttime.trim() + ':' + mtttime.trim() +  ':00';
//                                      String entrsvdates = yyear.trim() + '-' + mmonth.trim() + '-' + dday.trim();
//                  System.debug(' entrsvdates length : ' + entrsvdates.length() );
//                  Datetime entrsvdatec = datetime.valueOf(entrsvdates);/* 554 System.TypeException: Invalid date/time: 2010-10-28 11:30:00 */
                    DateTime entrsvdatec = DateTime.newInstance(Integer.valueof(yyear.trim()), Integer.valueof(mmonth.trim()), Integer.valueof(dday.trim()));   
                    System.debug(' entrsvdatec : ' + entrsvdatec );             
//                          Date today = system.today().toStartOfWeek();
//      DateTime dt = DateTime.newInstanceGmt(today.year(),today.month(),today.day());
                    
                    
                    
                    
                    
                    rsv.EntryTime__c = datetime.valueOf(entrsvdatec.format('yyyy-MM-dd HH:mm:ss'));                                                       /* Put Check-in day and time */
                    rsv.Field4__c = tttime + ':' + mtttime;                                                                                                     /* Put Check-in time */
                    Boolean ReservedHiru = true;                                                                                                                /* Put noon */
                    if ( rsv.Field4__c.compareTo('15'+':'+ mtttime) > 0 ) {                                                                                     /* Check hiru */
                        ReservedHiru = false;                                                                                                                   /* Put nights */
                    }
                    rsv.Departure__c = rsv.EntryTime__c;                                                                                                        /* Put Check-out day and time */
//                  rsv.Field3__c = String.valueof( (Decimal.valueof(tttime.trim()) + 3) ) + ':' + mtttime;                                                     /* Put departure time after 3.0h 554 System.TypeException: Invalid decimal: 11 */                                                                                                           
//                  rsv.Field3__c = (((rsv.Departure__c).addHours(3)).format('yyyy-MM-dd HH:mm:ss')).substring(11,16);                                          /* Put departure time after 3.0h */
                    String ttt = '';                                                                                                                            /* for 554 System.TypeException: Invalid decimal: 11 20101102 rev.*/
                    if ( tttime.trim() == '11'){                                                                                                                /* 20101102 rev.*/
                        ttt = '14';
                    } else if ( tttime.trim() == '12') {
                        ttt = '15';
                    } else if ( tttime.trim() == '13') {
                        ttt = '16';
                    } else if ( tttime.trim() == '14') {/* for last order*/
                        ttt = '17';
                    } else if ( tttime.trim() == '15') {
                        ttt = '18';
                    } else if ( tttime.trim() == '16') {
                        ttt = '19';
                    } else if ( tttime.trim() == '17') {
                        ttt = '20'; 
                    } else if ( tttime.trim() == '18') {
                        ttt = '21';
                    } else if ( tttime.trim() == '19') {
                        ttt = '21';
                    } else if ( tttime.trim() == '20') {/* for last order*/
                        ttt = '22';
                    } else {
                        ttt = '14';/* Put default */
                    }
                    rsv.Field3__c = ttt + ':' + mtttime;




                    while ( !(emailBody[wnextline].contains('【大人】')) ) {                                                                                    /* Check loop for reserved persons */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                              /* Next line */
//                  rsv.StayPersons__c = Decimal.valueOf( ((emailBody[wnextline].split('名',2))[0]).trim());                                                  /* Put Stay persons */
                    
                    string wabc = (emailBody[wnextline].split('名',2))[0] + ' ';
                    // Rev 2014.01.09 Modify Begin
                    //rsv.StayPersons__c = Decimal.valueOf(wabc.substring(wabc.length()-2,wabc.length()-1));
                    rsv.StayPersons__c = CommUtils.nullToZero(wabc.trim());
                    // Rev 2014.01.09 Modify End
                    while ( !(emailBody[wnextline].contains('【子供】')) ) {                                                                                    /* Check loop for reserved persons */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                              /* Next line */
                    if ( (emailBody[wnextline].split('名',2))[0] != '' ) {                                                                                     /* Check null of childs */
                        rsv.ChildFA__c = Decimal.valueOf( ((emailBody[wnextline].split('名',2))[0]).trim() );                                                  /* Put childs */
                    }
                    while ( !(emailBody[wnextline].contains('【代表者名】')) ) {                                                                                 /* Check loop for customer name  */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                               /* Next line */
                    contact2.LastName = emailBody[wnextline];                                                                                                  /* Put customer name */     
                    while ( !(emailBody[wnextline].contains('【代表者名ふりがな】')) ) {                                                                           /* Check loop for customer name KATAKANA */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.Katakana__c = emailBody[wnextline];                                                                                                /* Put customer name KATAKANA */
                    while ( !(emailBody[wnextline].contains('【電話番号】')) ) {                                                                                   /* Check loop for tel */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    
                    /********NEED** Check for tel no, and Formatting update ***************/                
//                  for ( Integer ii = 0 ; ii < emailBody[wnextline].length ; ii++ ) {
                        
//                  }
                    
                    contact2.Phone = emailBody[wnextline];                                                                                                   /* Put tel No */
                    while ( !(emailBody[wnextline].contains('【メールアドレス】')) ) {                                                                           /* Check loop for email address */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                             /* Next line */
                    contact2.Email = emailBody[wnextline];                                                                                                   /* Put email address */
                    while ( !(emailBody[wnextline].contains('【郵便番号】')) ) {                                                                                /* Check loop for ZIP Code  */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                             /* Next line */
                    contact2.MailingPostalCode = emailBody[wnextline];                                                                                       /* Put zip code */
                    while ( !(emailBody[wnextline].contains('【ご住所】')) ) {                                                                                 /* Check loop for address */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                             /* Next line */
                    contact2.MailingStreet = emailBody[wnextline];                                                                                           /* Get address of customer */
                    
//                  wnextline++;                                                                                                                             /* Next line */
//                  while ( !(emailBody[wnextline].contains('-------')) ) {                                                                                  /* Check loop for Note */
//                      if ( !(emailBody[wnextline] == '') ) {
//                          rsv.Comment2__c = rsv.Comment2__c + emailBody[wnextline];                                                                        /* Put comment <--- problem description */
//                      }
//                      wnextline++;            
//                  }
					// Ver2013/11/21 メール自動返信機能対応
					rsv.EventSource__c = 'メール取込';																								
					rsv.ContactKatakana__c = contact2.Katakana__c;
					rsv.ContactPhone__c = contact2.Phone;
					rsv.ContactEmail__c = contact2.Email;
					rsv.ContactPostalCode__c = contact2.MailingPostalCode;
					rsv.ContactAddress__c = contact2.MailingStreet;

                    Boolean newflag = false;
                    Database.SaveResult[] lsr;
                    
//                    Contact contact1 = new Contact();
//                    contact1.LastName = customer.Name;                                                                                              /* Put customer name */
//                    contact1.FirstName = '';                                                                                                /* Put customer name */
//                    contact1.Katakana__c = customer.Katakana__c;                                                                                /* Put Katakana */
//                    contact1.Phone = customer.TELofTAB__c;                                                                                      /* Put telephone# */
//                    contact1.MobilePhone = customer.KeitaiofTAB__c;                                                                         /* Put Mobile phone# */
//                    contact1.Email = customer.MAIL__c;                                                                                          /* Put Mail address */
//                    contact1.MailingPostalCode = customer.Field1__c;                                                                            /* Put zip code */
//                    contact1.MailingStreet = customer.Address1__c;

//                  List<CustomObject1__c> aa = [select Id, name, TELofTAB__c, Field1__c, Address1__c from CustomObject1__c where TELofTAB__c = :customer.TELofTAB__c];
                    List<Contact> aa = [select Id, name, Phone from Contact where Phone = :contact2.Phone limit 1]; 
                    if (aa.isEmpty()) {                                                                                                                         /* customer Not found ? --> new customer */
                        try {
                                newflag = true;
//                              lsr = Database.insert(new CustomObject1__c[]{customer, new CustomObject1__c()},false);
//                              lsr = Database.insert(new CustomObject1__c[]{customer},false);
                                lsr = Database.insert(new Contact[]{contact2},false);
                                for(Database.SaveResult sr:lsr){                                                                                                /* Iterate through the Save Results */
                                       if(!sr.isSuccess()) {
                                          Database.Error err = sr.getErrors()[0];                                                                               /* Put error */
                                          System.debug(' Database error :New customer: ' + contact2 );
                                       } else {
                                       }
                                 }
                            } catch (System.DmlException e) {
                                System.debug('New customer: ' + contact2 );
                            }
                    } else {
                        System.debug('Exsiting customer: ' + aa[0] );       
//                      customer.Id = aa[0].Id;                                                                                                          /* Not writeable */
//                      if ( aa[0].Field1__c == ''  ||  aa[0].Address1__c == '' ) {                                                                      /* Check zip code and address with null */
                            System.debug('Exsiting customer update ' + aa[0] );     
                            aa[0].LastName = contact2.LastName;                                                                                          /* Put customer name */
                            aa[0].FirstName = '';
                            aa[0].Katakana__c = contact2.Katakana__c;                                                                                    /* Put Katakana */
                            aa[0].Phone = contact2.Phone;                                                                                                /* Put telephone# */
                            aa[0].MobilePhone = contact2.MobilePhone;                                                                                    /* Put Mobile phone# */
                            aa[0].Email = contact2.Email;                                                                                                /* Put Mail address */
                            aa[0].MailingPostalCode = contact2.MailingPostalCode;                                                                        /* Put zip code */
                            aa[0].MailingStreet = contact2.MailingStreet;                                                                                /* Put address of customer */
                            Database.SaveResult SSR = Database.update(aa[0]);                                                                            /* Update customer */
                            for(Database.Error err: SSR.getErrors())    {                                                                                /* Check database error */
                                 System.debug(' Database error :Exsiting customer: ' + err );
                                // process any errors here
                            }
//                      }

                    }
                                                                                                                                                        /* reserved entry */
                    rsv.Name = contact2.LastName;                                                                                                       /* Put reservation name */
                    if (newflag){                                                                                                                       /* Case new customer */
                        if (lsr[0].isSuccess()) {
                            rsv.Relcontact__c = lsr[0].getId();                                                                                         /* Put customer Id of new record */
                        } else {
                            rsv.Relcontact__c = contact2.Id;                                                                                            /* Case error : Put Id of object customer without database Id */                    
                        }
                    } else {
                        rsv.Relcontact__c = aa[0].Id;                                                                                                   /* Put Customer name for reference field */
                    }


                    Boolean assginflag = false;                 
                    System.debug('***PLAN      : ' + hPlanPlan);                                                                                        /* for debug */         
                                                                                                                                                        /* Get Plan table list */
                    List<Plan__c> PlanTable = [select id, Seq__c, Name, Roomtype__r.Name, Roomname__c, mealcost__c, dinner__c, morning__c, Lunch__c, Charge1__c, Charge2__c, Charge3__c, ChargeRC__c from Plan__c where Name = :hPlanPlan order by Seq__c];                                                                                                                                                 
                    if ( !(PlanTable.isEmpty()) ) {                                                                                                     /* Check empty */
                                                                                                                                                        /* Put name and numbers of dinner */
                            rsv.Field310__c = PlanTable[0].id;                                                                                          /* Put referrence of Plan */
                            rsv.Femails__c = 0;                                                                                                         /* Put Female Clear for default */
                            rsv.Mans__c = 0;                                                                                                            /* Put male Clear for default */                        
                            if ( PlanTable[0].dinner__c != null && ReservedHiru == false ) {                                                            /* Check dinner */
                                rsv.OryourimeiX02__c = PlanTable[0].dinner__c;                                                                          /* Put dinner */
                                rsv.chuy__c = rsv.StayPersons__c;                                                                                       /* Put persons of dinner */
                            } else if ( PlanTable[0].Lunch__c != null && ReservedHiru == true ) {                                                       /* Check lunch */
                                rsv.lunchX02__c = PlanTable[0].Lunch__c;                                                                                /* Put lunch */
                                rsv.chu__c = rsv.StayPersons__c;                                                                                        /* Put persons of lunch */
                            } else {
                                /*********************************** Childs is not set */
                            }
                            Integer rsvnum = 0;
                            if ( PlanTable[0].Roomtype__r.Name == 'レストラン' && ReservedHiru == true ) {                                                 /* Check reservation type */
                                rsv.ReservedType__c = '昼 賑';                                                                                            /* Put reservation type */
                                rsvnum = 1;
                            } else if ( PlanTable[0].Roomtype__r.Name == 'レストラン' && ReservedHiru == false ){
                                rsv.ReservedType__c = '夕 賑';
                                rsvnum = 2;                             
                            } else if ( PlanTable[0].Roomtype__r.Name != 'レストラン' && ReservedHiru == true ) {
                                rsv.ReservedType__c = '昼 部屋';
                                rsvnum = 3;
                            } else if ( PlanTable[0].Roomtype__r.Name != 'レストラン' && ReservedHiru == false ) {
                                rsv.ReservedType__c = '夕 部屋';
                                rsvnum = 4;                             
                            } else {
                                /*********************************** Other reservation type  */
                            }
                            
//                          rsv.room1__c = PlanTable[0].ChargeRC__c;                                                                                    /* Put Charge of room */
                            rsv.R_C__c = PlanTable[0].ChargeRC__c;                                                                                      /* Put Charge of room 2010.11.02 rev.*/
                            rsv.Field311__c = PlanTable[0].Charge1__c;                                                                                  /* Onsen charge */
                            rsv.Field312__c = PlanTable[0].Charge2__c;                                                                                  /* Onsen-YUKATA charge */
                            rsv.Field313__c = PlanTable[0].Charge3__c;                                                                                  /* Onsen-BUSTAORU charge */
                                                        
                            Date wEntry = rsv.EntryTime__c.date();                                                                                      /* Get reservation date */
                                                                                                                                                        /* Assign room Algorithm */
                                                                                                                                                        /*  ->case 1 room type = restrant : noon meal and night meal at restrant    */
                                                                                                                                                        /*  ->case 2 1 nights             : noon meal only  */
                                                                                                                                                        /*  ->case 3 lunch in room        : night meal only */
                                                                                                                                                        /*  ->case 4 night in room        : noon meal only  */
                                                                                                                                                        /*  -> not assigned */
                                                                                                                                                        
                            for ( Plan__c ld : PlanTable ) {                                                                                            /* Get not reserved room of Plan */
                                                                                                                                                        /* Check reservation of reservation date and room */
                                List<Lead__c> assr = [select id, Name, ReservedType__c, EntryTime__c,Departure__c,Nights__c, Hiru__c, Rroom__r.Name from Lead__c where ReservationDate__c = :wEntry AND Rroom__c = :ld.Roomname__c AND CancelBool__c != 1];
                                if ( !(assr.isEmpty()) ) {                                                                                              /* Check empty of room */
                                    Integer nnights = 0;
                                    Integer nlunch = 0;
                                    Integer ndinner = 0;
                                    Boolean roomflag = false;
                                    for ( Lead__c lld : assr ) {                                                                                        /* loop room */
                                         if ( lld.Rroom__r.Name != '富月殿' ) {                                                                            /* Check restrant or room */
                                            roomflag = true;                                                                                            /* Put room */
                                         }
                                         if ( lld.Nights__c == 1 ) {                                                                                    /* Nights? for duble booking  */
                                            nnights++;                                                                                                  /* case Nights */
                                         } else if ( lld.Hiru__c == 1 ){                                                                                /* Noon?  */
                                            nlunch++;                                                                                                   /* Lunch only */
                                         } else {
                                            ndinner++;                                                                                                  /* Dinner only */
                                         }
                                    }
                                    
                                    if ( !roomflag ) {                                                                                                   /* Check case 1 at restrant */                                     
                                    
                                        /*********NEED************************* If the restrant is full persons, it's reservation is assigned to TAKEKAWA NO MA room, but TAKEKAWA is reserved, then waiting list. */
                                        rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put Assain room and break */
                                        assginflag = true;                                                                                                  /* Put assgin flag */
                                        break;
                                    } else {                                                                                                                /* Room assign */
                                        if ( nnights == 1  && nlunch == 0 && rsvnum == 3 ) {                                                                /* Check case 2 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;
                                        } else if ( nlunch >= 1 && rsvnum == 4 ) {                                                                          /* Check case 3 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;                                          
                                        } else if ( ndinner >= 1 && nlunch == 0 && rsvnum == 3 ) {                                                          /* Check case 4 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;                                          
                                        } else {
                                            assginflag = false;                                                                                             /* Put Not assgin flag */
                                        }
                                    }

                                } else {
                                    rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put assgin room and break */
                                    assginflag = true;                                                                                                  /* Put assgin flag */
                                    break;
                                }
                            }
                            
                            
                            if ( !assginflag ) {                                                                                                        /* Check Not Assigned ---> Put Seq#0 : Waiting list for no room */
                                                                                                                                                        /* Note : If room do not assgin for reservation, connect to waiting list box, and maybe you assign to other room type in manual.  */
                                Room__c ee = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                              /* Get ID of Waiting list box */
                                rsv.Rroom__c = ee.Id;                       
                            }
                    } else {
                                                                                                                                                        /***************** not exist plan in jinyaforce, but plan is exist in web site, so gettting plan data connection from web site due to API interface */
                        Room__c ww = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                                      /* Get ID of Waiting list box */
                        rsv.Rroom__c = ww.Id;                       
                        System.debug('What no plan ??? : ' + rsv );             
                    }

                    rsv.Comment3__c = '' + '<font color="#0000FF">' + hPlanPlan +  '<font color="#000000">' + ' /$Jinyaforce$';                         /* Put Plan name in special description and NAME Orange */
                    try {
//                          Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{rsv, new Lead__c()},false);
                            // 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
							CommLogicProcess logic = new CommLogicProcess();
							// 新規登録・変更対象データはチェック対象外に設定する
							logic.preventShopAuthCheckSetup(new Lead__c[]{rsv});
							// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
                            Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{rsv},false);
                            for(Database.SaveResult ssr:rsvlsr){                                                                                        /* Iterate through the Save Results */
                                   if(!ssr.isSuccess()) {
                                            Database.Error err = ssr.getErrors()[0];                                                                    /* Put error */
                                            System.debug(' Database error :New reservation: ' + err );
                                   } else {
                                   		// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
										List<Lead__c> restoreLeads = new List<Lead__c>();
										restoreLeads.addAll(new Lead__c[]{rsv});
										logic.restoreShopAuthCheckSetup(restoreLeads, true);
										// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
                                   }
                             }
                                                                                                                                                        /* Create reservation new record */
                    } catch (System.DmlException e) {
                        System.debug('New reservation: ' + rsv );
                    }
                  //delete contact2;
                  //delete rsv;                                          

                                
        } else {                                                                                                                                                /* Ignore email */
                                                                                                                                                                /* for future Other AGT */
        }
        
        
        return result;
    }
   
}