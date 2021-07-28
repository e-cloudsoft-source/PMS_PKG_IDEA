public with sharing class CateringPDF {
    
    private Lead__c booking;                                                                    /* Current Booking Record */
    private List<Lead__c> rbookings;                                                            /* Related Enkai Booking List */
    private List<BookingEstimateItem__c> beifood;                                               /* 'お料理' Item List */
    private List<BookingEstimateItem__c> beidrink;                                              /* 'お飲物' Item List */
    private List<BookingEstimateItem__c> beiother;                                              /* 'その他' Item List */
    private List<AccountMaster__c> amot;                                                        /* 'その他' Item Type List */
    
    public CateringPDF(ApexPages.StandardController controller){
                                                                                                /* query current 'ご予約' record */
        booking = [select Id, Name, Field4__c,Field3__c,Field372__c, Relcontact__r.Id, ReservedType__c, 
                    Femails__c, EntryTime__c, Week__c, ReservedDate__c, ReservedContact__c, Field352__c, 
                    Relcontact__r.Name, Relcontact__r.Katakana__c,Relcontact__r.Title,
                    Relcontact__r.Phone, Relcontact__r.Account.Phone,Relcontact__r.Fax, Relcontact__r.Account.Fax,
                    Field310__r.Name, Field310__r.AccountTotal__c,
                    Relcontact__r.Account.ShippingStreet, Relcontact__r.Account.ShippingCity, Relcontact__r.Account.ShippingState,Relcontact__r.Account.ShippingCountry,
                    FrontCheck__c, FrontChecker__c, FrontCheckTime__c, ServiceCheck__c, ServiceChecker__c, ServiceCheckTime__c, VBCheck__c, VBChecker__c, VBCheckTime__c, 
                    CnCookCheck__c, CnCookChecker__c, CnCookCheckTime__c, EuCookCheck__c, EuCookChecker__c, EuCookCheckTime__c, JpCookCheck__c, JpCookChecker__c, JpCookCheckTime__c, 
                    ReceptionCheck__c, ReceptionChecker__c, ReceptionCheckTime__c, 
                    Style__c, Rroom__r.name, StayPersons__c, room1__c, ManagerArrive__c, 
                    MealStyle__c, DrinkStyle__c, Comment3__c, Layout__c, 
                    BusWelcomeSend__c, BusPassengers__c, NumOfBus__c, BusArrivalTime__c, BusDepartureTime__c, BusDestination__c, BusOrigin__c, BusCapacity__c, 
                    Relcontact__r.Account.BillingCountry, Relcontact__r.Account.BillingPostalCode, Relcontact__r.Account.BillingState, Relcontact__r.Account.BillingCity, Relcontact__r.Account.BillingStreet, Relcontact__r.Account.Name , 
                    Relcontact__r.Department, Relcontact__r.Extension__c, 
                    PaymentWay__c, PaymentDate__c,FoodComment__c,DrinkComment__c,OtherComment__c,Comment2__c,Field357__c,Field373__c,Field374__c,Field375__c,Field376__c,Field377__c,Parking__c,
                    Older__c,Field384__c,Field382__c,Field383__c,Field378__c,Field379__c,Field380__c,Field381__c,touroku__c,Field385__c,kakunin__c,kessan__c,BillIssue__c,
                    PayDirect__c,PayConfirm__c,Field386__c,CateringType__c,EnkaiNO__c,Hall1__c,Hall2__c,Hall3__c,Hall4__c,Field387__c,
                    WDrink1__c,WDrink2__c,DrinkControl1__c,DrinkControl2__c,DrinkName__c,Meeting1__c,Meeting2__c,Party1__c,Party2__c,HallReserve1__c,HallReserve2__c
                    from Lead__c where Id =: controller.getID()];
        // 2018/12/15 APEXのVersion最新化対応  值为null的bug改正 zyz BY BEGIN
        if(booking.Party1__c == null) booking.Party1__c = '00:00';
        if(booking.Party2__c == null) booking.Party2__c = '00:00';
        // 2018/12/15 APEXのVersion最新化対応 值为null的bug改正 zyz BY END
        
                                                                                                /* query 3 related 'ご予約' record. Key: $到着日, お客様, 予約タイプ */
        rbookings = [select Id, Name, Style__c, Rroom__r.name, StayPersons__c, Field3__c, Field4__c, room1__c, ManagerArrive__c 
                    //from Lead__c where Field372__c =: booking.Field372__c and Relcontact__r.Id =: booking.Relcontact__r.Id and ReservedType__c =: booking.ReservedType__c limit 3];
                    from Lead__c where id = :booking.Id limit 3];   
                                                                                                /* IDs of 2nd, 3rd Booking Record */
        string bookingid2 = (rbookings.size() < 2)? '': rbookings[1].Id;
        string bookingid3 = (rbookings.size() < 3)? '': rbookings[2].Id;
        
                                                                                                /* query '予約見積明細' record of 3 related Booking Record ($集計対象外 = 1) */
        
                                                                                                /* お料理 */
        beifood  = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c,Field7__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: '料理' and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
                                                                                                /* お飲物 */
        beidrink = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c,Field7__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: '飲料' and (not refAccountMaster__r.EstimateFieldNo__c =: null) and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
                                                                                                /* その他 ＝備品　*/
        beiother = [select Id, Name,  UnitPrice__c, Amount__c, refAccountMaster__r.Name, refAccountMaster__r.OP__r.Name, refAccountMaster__r.Field4__r.Name, Total__c, refAccountMaster__r.EstimateFieldNo__c, Supplier__r.Name, Orderer__r.Name, OrderDate__c,Field7__c
                from BookingEstimateItem__c where (refbooking__c =: rbookings[0].Id or refbooking__c =: bookingid2 or refbooking__c =: bookingid3) and refAccountMaster__r.OP__r.Name =: 'その他' and (not refAccountMaster__r.EstimateFieldNo__c =: null) and AccountOutside__c =: 1 order by refAccountMaster__r.EstimateFieldNo__c];
        
        amot = [select Id, Name, EstimateFieldNo__c from AccountMaster__c where OP__r.Name =: 'その他' and (not EstimateFieldNo__c =: null) order by EstimateFieldNo__c];
        
    }
    
    public Lead__c getBooking(){                                                                /* get Current Booking Data */
        return booking;
    }
    
    public String getAddTime1(){                                                                /* 完スタ予定・入力された時間から計算 */
      Integer calcDate = -5;
      
      String skaisi='2012-01-01 '+booking.Party1__c+':00';
      Datetime dateTime1 = datetime.valueOf(skaisi);
      DateTime kaisi = dateTime1.addMinutes(calcDate);
       string time1= string.valueOf(kaisi);
       string time2= time1.substring(11,16);
       System.debug('最終：開始時間は'+ time2);
        return time2;
    }
    public String getAddTime2(){                                                                /* 料理アップ・入力された時間から計算 */
      Integer calcDate = -20;
      
      String skaisi='2012-01-01 '+booking.Party1__c+':00';
      Datetime dateTime1 = datetime.valueOf(skaisi);
      DateTime kaisi = dateTime1.addMinutes(calcDate);
       string time1= string.valueOf(kaisi);
       string time2= time1.substring(11,16);
        return time2;
    }
    public String getAddTime3(){                                                                /* 撤収・入力された時間から計算 */
      Integer calcDate = 30;
      
      String skaisi='2012-01-01 '+booking.Party2__c+':00';
      Datetime dateTime1 = datetime.valueOf(skaisi);
      DateTime kaisi = dateTime1.addMinutes(calcDate);
       string time1= string.valueOf(kaisi);
       string time2= time1.substring(11,16);
        return time2;
    }
    public String getAddTime4(){                                                                /* 到着予定・入力された時間から計算 */
      Integer calcDate = -10;
      
      String skaisi='2012-01-01 '+booking.Party1__c+':00';
      Datetime dateTime1 = datetime.valueOf(skaisi);
      DateTime kaisi = dateTime1.addMinutes(calcDate);
       string time1= string.valueOf(kaisi);
       string time2= time1.substring(11,16);
        return time2;
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
        integer num = 4;  //必要行数-1                                                                      /* Number of Item Types */
        for(integer i = 0; i < num+1 ; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            items[i].Amount__c = 0;//初期化
            items[i].refAccountMaster__c = null;//初期化
        }
    integer itemindex = num;
        integer oindex = 0;
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
        System.debug('食事の結果' + items);
        return items;
    }
    
    public List<BookingEstimateItem__c> getDrinks(){                                            /*** get Drink Item List ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 12;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
           // items[i].UnitPrice__c = 0;
            items[i].Amount__c = 0;
            items[i].refAccountMaster__c = null;
        }
        integer itemindex = num;
        integer oindex = 0;                                                                /* Item Type List Index */
        for(integer i = 0; i < beidrink.size(); i++ ){
            itemindex = (((beidrink[i].refAccountMaster__r.EstimateFieldNo__c != null)? beidrink[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > oindex)||(itemindex < 0)){
                itemindex = oindex;
                oindex = (oindex == num)? num :  oindex+1;
            }else{
            }
            items[itemindex] = beidrink.clone()[i];
           // items[itemindex].UnitPrice__c = (beidrink[i].UnitPrice__c != null)? beidrink[i].UnitPrice__c : 0;
           // items[itemindex].Amount__c += (beidrink[i].Amount__c != null)? beidrink[i].Amount__c : 0;
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
           // items[i].UnitPrice__c = (items[i].UnitPrice__c != null)? items[i].UnitPrice__c : 0;
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
        }
        return items;
    }
       public List<BookingEstimateItem__c> getOthers(){                                            /*** get Other Item List ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 7;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            items[i].Amount__c = 0;
            items[i].refAccountMaster__c = null;
        }
        integer itemindex = num;
        integer oindex = 0;                                                                /* Item Type List Index */
        for(integer i = 0; i < beiother.size(); i++ ){
            itemindex = (((beiother[i].refAccountMaster__r.EstimateFieldNo__c != null)? beiother[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > oindex)||(itemindex < 0)){
                itemindex = oindex;
                oindex = (oindex == num)? num :  oindex+1;
            }else{
            }
            items[itemindex] = beiother.clone()[i];
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
        }
        return items;
    }
       public List<BookingEstimateItem__c> getOthersTest(){                                            /*** 発注用の仮メソッド ***/
        List<BookingEstimateItem__c> items = new List<BookingEstimateItem__c>();                /* Create Display List */
        integer num = 5;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            items.add(new BookingEstimateItem__c());
            items[i].Amount__c = 0;
            items[i].refAccountMaster__c = null;
        }
        integer itemindex = num;
        integer oindex = 0;                                                                /* Item Type List Index */
        for(integer i = 0; i < beiother.size(); i++ ){
            itemindex = (((beiother[i].refAccountMaster__r.EstimateFieldNo__c != null)? beiother[i].refAccountMaster__r.EstimateFieldNo__c : 0)).intValue() - 1;
            if((itemindex > oindex)||(itemindex < 0)){
                itemindex = oindex;
                oindex = (oindex == num)? num :  oindex+1;
            }else{
            }
            items[itemindex] = beiother.clone()[i];
        }
        for(integer i = 0; i < num + 1; i++){                                                   /* put zero if null */
            items[i].Amount__c = (items[i].Amount__c != null)? items[i].Amount__c : 0;
            system.debug('サプライヤは'+items[i].Supplier__c);
            system.debug('備品名は'+items[i].Name);
        }
        return items;
    }
    
    
    
    public List<string> getOtherItemName(){                                                     /* get Other Item Name List （使用していないメソッド）*/
        List<string> iname = new List<string>();                                                /* Create Display List*/
        integer num = 20;                                                                       /* Number of Item Types */
        for(integer i = 0; i < num + 1; i++){                                                   /* initialize List ( index: num is dummy) */
            iname.add('');
        }
        integer itemindex = num ;
        for(integer i = 0; i < amot.size(); i++){
            itemindex = amot[i].EstimateFieldNo__c.intValue() - 1;
            if((itemindex > num)||(itemindex < 0)){                                             /* avoid reference forbidden index */
                itemindex = num;
            }else{
            }
            iname[itemindex] = amot[i].Name;
        }
        return iname;
    }
    
    public List<BookingEstimateItem__c> getOthersOld(){                                            /*** get Other Item List （使用していない）***/
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
    
    public decimal getFoodTotal(){                                                              /* Total Price of Food （使用していない）*/
        decimal total = 0;
        for(integer i = 0; i < beifood.size(); i++){
            total += beifood[i].Total__c;
        }
        return total;
    }
    
    public decimal getDrinkTotal(){                                                             /* Total Price of Free Drink（使用していない） */
        decimal total = 0;
        for(integer i = 0; i < beidrink.size(); i++){
            total += beidrink[i].Total__c;
        }
        return total;
    }

        public string getCateringPos(){                                                            /* Circle Position of CateringType */
        string pos = '0cm';
        if(booking.CateringType__c == 'サービス'){
            pos = '8.8cm';
        }else if(booking.CateringType__c == '和食'){
            pos = '10cm';
        }else if(booking.CateringType__c == '洋食'){
            pos = '11cm';
        }else if(booking.CateringType__c == '中華'){
            pos = '11.8cm';
        }else if(booking.CateringType__c == 'フロント'){
            pos = '13cm';
        }else if(booking.CateringType__c == 'ケータ'){
            pos = '14.2cm';
        }else{
        }
        return pos;
    }
    public string getNaiyouPos(){                                                            /* Circle Position of NaiyouKubun */
        string pos = '0cm';
        if(booking.Field384__c == '接待系'){
            pos = '6.8cm';
        }else if(booking.Field384__c == '食事系'){
            pos = '7.8cm';
        }else if(booking.Field384__c == '親睦系'){
            pos = '8.8cm';
        }else if(booking.Field384__c == '商談系'){
            pos = '9.8cm';
        }else{
        }
        return pos;
    }
    
    public string getPaymentPos(){                                                              /* Circle Position of Payment Way （使用していない）*/
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
    public string getTourokuPos(){                                                              /* Circle Position of Payment 登録書 */
        string pos = '0cm';
        if(booking.touroku__c == '有'){
            pos = '8.8cm';
        }else{
            pos = '9.4cm';
        }
        return pos;
    }
    public string getKakuninPos(){                                                              /* Circle Position of Payment 確認書 */
        string pos = '0cm';
        if(booking.kakunin__c == '有'){
            pos = '8.8cm';
        }else{
            pos = '9.4cm';
        }
        return pos;
    }
    public string getKessanPos(){                                                              /* Circle Position of Payment 決算書 */
        string pos = '0cm';
        if(booking.kessan__c == '未'){
            pos = '8.8cm';
        }else{
            pos = '9.4cm';
        }
        return pos;
    }
        public string getHakkouPos(){                                                              /* Circle Position of Payment 発行連絡 */
        string pos = '0cm';
        if(booking.Field386__c == '営業'){
            pos = '14.2cm';
        }else{
            pos = '16.6cm';
        }
        return pos;
    }
    
    public List<string> getComments(){                                                          /* Rows List of '案件情報' */
        if(booking.Comment3__c ==null){
            booking.Comment3__c = ' <br>';
        }else{
        }
        List<string> comments = booking.Comment3__c.split('<br>',0);
        return comments;
    }
    public List<string> getPayDirect(){                                                          /* Rows List of '請求指示' */
        if(booking.PayDirect__c ==null){
            booking.PayDirect__c = ' <br>';
        }else{
        }
        List<string> comments = booking.PayDirect__c.split('<br>',0);
        return comments;
    }
    public List<string> getPayConfirm(){                                                          /* Rows List of '支払い確認' */
        if(booking.PayConfirm__c ==null){
            booking.PayConfirm__c = ' <br>';
        }else{
        }
        List<string> comments = booking.PayConfirm__c.split('<br>',0);
        return comments;
    }
/**
*2015-11-18 
*テストクラスCateringPDFTestに移行する    
	@isTest
	static void testCase1() {
    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;

    	Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController handel = new ApexPages.StandardController(leadInfo);
    	CateringPDF contrl = new CateringPDF(handel);
    	Lead__c rsLead = contrl.getBooking();
    	System.assert(rsLead != null);
    	try {contrl.getAddTime1();} catch (Exception e) {}
    	try {contrl.getAddTime2();} catch (Exception e) {}
    	try {contrl.getAddTime3();} catch (Exception e) {}
    	try {contrl.getAddTime4();} catch (Exception e) {}
    	try {contrl.getFoods();} catch (Exception e) {}
    	try {contrl.getComments();} catch (Exception e) {}
    	try {contrl.getCateringPos();} catch (Exception e) {}
    	try {contrl.getDrinks();} catch (Exception e) {}
    	try {contrl.getDrinkTotal();} catch (Exception e) {}
    	try {contrl.getFoodTotal();} catch (Exception e) {}
    	try {contrl.getKakuninPos();} catch (Exception e) {}
    	try {contrl.getOthers();} catch (Exception e) {}
    	try {contrl.getKessanPos();} catch (Exception e) {}
    	try {contrl.getHakkouPos();} catch (Exception e) {}
    	try {contrl.getPayDirect();} catch (Exception e) {}
    	try {contrl.getPayConfirm();} catch (Exception e) {}
    	try {contrl.getOthersTest();} catch (Exception e) {}
    	try {contrl.getOtherItemName();} catch (Exception e) {}
    	try {contrl.getOthersOld();} catch (Exception e) {}
    	
	}
*/
}