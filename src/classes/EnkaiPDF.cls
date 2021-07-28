public with sharing class EnkaiPDF {
    
    @TestVisible private Lead__c booking;                                                                    /* Current Booking Record */
    private List<Lead__c> rbookings;                                                            /* Related Enkai Booking List */
    private List<BookingEstimateItem__c> beifood;                                               /* 'お料理' Item List */
    private List<BookingEstimateItem__c> beidrink;                                              /* 'お飲物' Item List */
    private List<BookingEstimateItem__c> beiother;                                              /* 'その他' Item List */
    private List<AccountMaster__c> amother;                                                     /* 'その他' Item Type List */
    
    public EnkaiPDF(ApexPages.StandardController controller){
                                                                                                /* query current 'ご予約' record */
        booking = [select Id, Name, Field372__c, Relcontact__r.Id, ReservedType__c, 
 //                   EntryTime__c, Week__c, ReservedDate__c, ReservedContact__c, Field352__c,
                    EntryTime__c, Week__c, ReservedDate__c, ReservedContact__c, Field352__c, ReservationDate__c,
                    Relcontact__r.Name, Relcontact__r.Katakana__c, 
                    Relcontact__r.MailingCountry, Relcontact__r.MailingPostalCode, Relcontact__r.MailingState, Relcontact__r.MailingCity, Relcontact__r.MailingStreet, 
                    Relcontact__r.Phone, Relcontact__r.Account.Phone, 
                    Field310__r.Name, Field310__r.AccountTotal__c, 
                    FrontCheck__c, FrontChecker__c, FrontCheckTime__c, ServiceCheck__c, ServiceChecker__c, ServiceCheckTime__c, VBCheck__c, VBChecker__c, VBCheckTime__c, 
                    CnCookCheck__c, CnCookChecker__c, CnCookCheckTime__c, EuCookCheck__c, EuCookChecker__c, EuCookCheckTime__c, JpCookCheck__c, JpCookChecker__c, JpCookCheckTime__c, 
                    ReceptionCheck__c, ReceptionChecker__c, ReceptionCheckTime__c, 
                    Style__c, Rroom__r.name, StayPersons__c, room1__c, ManagerArrive__c, 
                    MealStyle__c, DrinkStyle__c, Comment3__c, Layout__c, 
                    BusWelcomeSend__c, BusPassengers__c, NumOfBus__c, BusArrivalTime__c, BusDepartureTime__c, BusDestination__c, BusOrigin__c, BusCapacity__c, 
                    Relcontact__r.Account.BillingCountry, Relcontact__r.Account.BillingPostalCode, Relcontact__r.Account.BillingState, Relcontact__r.Account.BillingCity, Relcontact__r.Account.BillingStreet, Relcontact__r.Account.Name , 
                    Relcontact__r.Department, Relcontact__r.Extension__c, 
                    PaymentWay__c, PaymentDate__c
                    from Lead__c where Id =: controller.getID()];
        
                                                                                                /* query 3 related 'ご予約' record. Key: $到着日, お客様, 予約タイプ */
//        rbookings = [select Id, Name, Style__c, Rroom__r.name, StayPersons__c, Field3__c, Field4__c, room1__c, ManagerArrive__c 
//                    from Lead__c where Field372__c =: booking.Field372__c and Relcontact__r.Id =: booking.Relcontact__r.Id and ReservedType__c =: booking.ReservedType__c limit 3];
        rbookings = [select Id, Name, Style__c, Rroom__r.name, StayPersons__c, Field3__c, Field4__c, room1__c, ManagerArrive__c 
                    from Lead__c where ReservationDate__c =: booking.ReservationDate__c and Relcontact__r.Id =: booking.Relcontact__r.Id and ReservedType__c =: booking.ReservedType__c limit 3];
        
                                                                                                /* IDs of 2nd, 3rd Booking Record */
        string bookingid2 = (rbookings.size() < 2)? '': rbookings[1].Id;
        string bookingid3 = (rbookings.size() < 3)? '': rbookings[2].Id;
        
                                                                                                /* query '予約見積明細' record of 3 related Booking Record ($集計対象外 = 1) */
        
                                                                                                /* お料理 */
        beifood  = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: '料理' and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
                                                                                                /* お飲物 */
        beidrink = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: '飲料' and (not refAccountMaster__r.EstimateFieldNo__c =: null) and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
                                                                                                /* その他 */
        beiother = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: 'その他' and (not refAccountMaster__r.EstimateFieldNo__c =: null) and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
        amother = [select Id, Name, EstimateFieldNo__c from AccountMaster__c where OP__r.Name =: 'その他' and (not EstimateFieldNo__c =: null) order by EstimateFieldNo__c];
        
    }
    
    public Lead__c getBooking(){                                                                /* get Current Booking Data */
        return booking;
    }
    
    public List<Lead__c> getRbookings(){                                                        /* get related Booking Data */
        List<Lead__c> crbookings = new List<Lead__c>();
        for(integer i = 0; i < 3; i++){
            crbookings.add((rbookings.size() < i+1)? new Lead__c() : rbookings[i]);
        }
        return crbookings;
    }
    
    public List<BookingEstimateItem__c> getFoods(){                                             /*** get Food Item List ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 7;                                                                        /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            items[i].Amount__c = 0;
            items[i].refAccountMaster__c = null;
        }
        
        integer itemindex = num;                                                                /* Item Type List Index */
        integer oindex = 3;                                                                 /* Other Item Index */
        for(integer i = 0; i < beifood.size(); i++ ){
            itemindex = (((beifood[i].refAccountMaster__r.EstimateFieldNo__c != null)? beifood[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > oindex)||(itemindex < 0)){
                itemindex = oindex;
                oindex = (oindex == num)? num :  oindex+1;
            }else{
            }
            items[itemindex] = beifood.clone()[i];
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
        }
        return items;
    }
    
    public List<BookingEstimateItem__c> getDrinks(){                                            /*** get Drink Item List ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 15;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            //items[i].UnitPrice__c = 0;
            items[i].Amount__c = 0;
        }
        integer itemindex = num;                                                                /* Item Type List Index */
        for(integer i = 0; i < beidrink.size(); i++ ){
            itemindex = (((beidrink[i].refAccountMaster__r.EstimateFieldNo__c != null)? beidrink[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > num)||(itemindex < 0)){
                itemindex = num;
            }else{
            }
            items[itemindex].UnitPrice__c = (beidrink[i].UnitPrice__c != null)? beidrink[i].UnitPrice__c : 0;
            items[itemindex].Amount__c += (beidrink[i].Amount__c != null)? beidrink[i].Amount__c : 0;
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
            //items[i].UnitPrice__c = (items[i].UnitPrice__c != null)? items[i].UnitPrice__c : 0;
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
        }
        return items;
    }
    
    public List<string> getOtherItemName(){                                                     /* get Other Item Name List */
        List<string> iname = new List<string>();                                                /* Create Display List*/
        integer num = 20;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            iname.add('');
        }
        integer itemindex = num ;
        for(integer i = 0; i < amother.size(); i++){
            itemindex = amother[i].EstimateFieldNo__c.intValue() - 1;
            if((itemindex > num)||(itemindex < 0)){                                             /* avoid reference forbidden index */
                itemindex = num;
            }else{
            }
            iname[itemindex] = amother[i].Name;
        }
        return iname;
    }
    
    public List<BookingEstimateItem__c> getOthers(){                                            /*** get Other Item List ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 20;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            items[i].UnitPrice__c = 0;
            items[i].Amount__c = 0;
        }
        integer itemindex = num;                                                                /* Item Type List Index */
        integer preindex = num;                                                                 /* Prev Item Type List Index */
        decimal amount = 0;
        for(integer i = 0; i < beiother.size(); i++ ){
            itemindex = (((beiother[i].refAccountMaster__r.EstimateFieldNo__c != null)? beiother[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > num)||(itemindex < 0)){                                             /* avoid reference forbidden index */
                itemindex = num;
            }else{
            }
            if(!((items[itemindex].Supplier__r.Name != null)||(items[itemindex].Orderer__r.Name != null))){
                items[itemindex] = beiother[i].clone();                                         /* to copy relation */
            }else{
            }
            if(beiother.size() == 1){                                                           /* put Item Amount */
                amount += (beiother[i].Amount__c != null)? beiother[i].Amount__c : 0;
                items[itemindex].Amount__c = amount;
            }else if(preindex != itemindex){
                items[preindex].Amount__c = amount;
                amount = 0;
                amount += (beiother[i].Amount__c != null)? beiother[i].Amount__c : 0;
            }else if(preindex == itemindex){
                amount += (beiother[i].Amount__c != null)? beiother[i].Amount__c : 0;
                items[preindex].Amount__c = amount;
            }else if(i == beiother.size() -1){
                items[preindex].Amount__c = amount;
            }else{
                amount += (beiother[i].Amount__c != null)? beiother[i].Amount__c : 0;
            }
            
            preindex = itemindex;
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
            items[i].UnitPrice__c = (items[i].UnitPrice__c != null)? items[i].UnitPrice__c : 0;
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
        }
        
        return items;
    }
    
    public decimal getFoodTotal(){                                                              /* Total Price of Food */
        decimal total = 0;
        for(integer i = 0; i < beifood.size(); i++){
            total += beifood[i].Total__c;
        }
        return total;
    }
    
    public decimal getDrinkTotal(){                                                             /* Total Price of Free Drink */
        decimal total = 0;
        for(integer i = 0; i < beidrink.size(); i++){
            total += beidrink[i].Total__c;
        }
        return total;
    }
    
    public decimal getOtherTotal(){                                                             /* Total Price of Other Service */
        decimal total = 0;
        for(integer i = 0; i < beiother.size(); i++){
            if(!(beiother[i].refAccountMaster__r.Name.contains('バス'))){
                total += beiother[i].Total__c;
            }else{
            }
        }
        return total;
    }
    
    public decimal getRoomTotal(){                                                              /* Total Price of Room */
        decimal total = 0;
        for(integer i = 0; i < rbookings.size(); i++){
            total += (rbookings[i].room1__c != null)? rbookings[i].room1__c: 0;
        }
        return total;
    }
    
    public decimal getBusTotal(){                                                               /* Total Price of Bus */
        decimal total = 0;
        for(integer i = 0; i < beiother.size(); i++){
            if(beiother[i].refAccountMaster__r.Name.contains('バス')){
                total += beiother[i].Total__c;
            }else{
            }
        }
        return total;
    }
    
    public string getMealStylePos(){                                                            /* Circle Position of MealStyle */
        string pos = '50cm';
        if(booking.MealStyle__c == '卓盛り'){
            pos = '0.2cm';
        }else if(booking.MealStyle__c == 'コース'){
            pos = '1.4cm';
        }else if(booking.MealStyle__c == '会席'){
            pos = '2.4cm';
        }else if(booking.MealStyle__c == 'ビュッフェ'){
            pos = '3.7cm';
        }else{
        }
        return pos;
    }
    
    public string getDrinkStylePos(){                                                           /* Circle Position of DrinkStyle */
        string pos = '50cm';
        if(booking.DrinkStyle__c == 'フリードリンク'){
            pos = '5.7cm';
        }else if(booking.DrinkStyle__c == 'カウント'){
            pos = '7.55cm';
        }else{
        }
        return pos;
    }
    
    public string getBusWSPos(){                                                                /* Circle Position of Bus Welcome/Send */
        string pos = '50cm';
        if(booking.BusWelcomeSend__c == 'お迎え'){
            pos = '14.2cm';
        }else if(booking.BusWelcomeSend__c == 'お送り'){
            pos = '15.42cm';
        }else{
        }
        return pos;
    }
    
    public string getPaymentPos(){                                                              /* Circle Position of Payment Way */
        string pos = '50cm';
        if(booking.PaymentWay__c == '現金'){
            pos = '10.4cm';
        }else if(booking.PaymentWay__c == '集金'){
            pos = '11.3cm';
        }else if(booking.PaymentWay__c == '振込'){
            pos = '12.23cm';
        }else{
        }
        return pos;
    }
    
    public string getLayoutURL(){                                                               /* get URL of "会場プラン" Image from HTML Tag in the Lich Text Field */
        string url = (booking.Layout__c != null)? booking.Layout__c : '';
        if(url.contains('<img')){
            url = url.substring(url.indexOf('src="') + 5);
            url = url.substring(0, url.indexOf('"'));
        }else{
            url = '';
        }
        return url;
    }
    
    public List<string> getComments(){                                                          /* Rows List of '特記事項' */
        if(booking.Comment3__c ==null){
            booking.Comment3__c = ' <br>';
        }else{
        }
        List<string> comments = booking.Comment3__c.split('<br>',0);
        return comments;
    }

}