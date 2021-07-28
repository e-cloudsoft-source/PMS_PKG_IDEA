/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class RoomTypeInventoryTests {
    /*テストロジック*/
    static testMethod void myUnitTest() {
        createDocument();
        List<TypeOfRooms__c> roomTypeList = createTestData();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 旧暦
        boolean isshowQreqki = ctl.isShowQreqki;
        string netAgt = ctl.CONST_PAGELAYOUT_TLSTATUS_NETSALES;
        boolean isRightPos = ctl.yearMonthRightPosition;
        string todaystr = ctl.processDtStr;
        // 来月
        ctl.toNext();
        // 先月
        ctl.toPrev();
        //
        ctl.gotoYearMonth();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = roomTypeList[0].Id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        Test.startTest();
        // 予約作成
        ctl.bookingCreate();
        Test.stopTest();

        ctl.refreshStockInfo();
        System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR), Apexpages.getMessages());
    }
    
    static testmethod void check0nightsTimes() {

        List<TypeOfRooms__c> roomTypeList = createTestData();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = roomTypeList[0].Id;
        ctl.staysNums = 0;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
       
        // 予約作成
        ctl.bookingCreate();
        // 時刻設定問題なし、登録可能
        System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR));
        
        Test.startTest();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.roomType = roomTypeList[0].Id;
        ctl.staysNums = 0;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '18:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate();
        System.assert(Apexpages.hasMessages(Apexpages.Severity.ERROR));
        Date todayDt = system.today();
        Test.stopTest();   
    }
    
    /*テストデータ*/
    static List<TypeOfRooms__c> createTestData(){
        TestCommon.createCommDefine();
        TestCommon.createTl2WayConfigDoc();
        // 部屋タイプ
        List<TypeOfRooms__c> roomTypeList = new List<TypeOfRooms__c>();
        roomTypeList.add(new TypeOfRooms__c(Name='テストコード用仮部屋タイプ１',Seq__c=9991,MaxRooms__c=10));
        roomTypeList.add(new TypeOfRooms__c(Name='テストコード用仮部屋タイプ２',Seq__c=9992,MaxRooms__c=10, ActionType__c = CommConst.ROOMTYPE_EB));
        insert roomTypeList;

        // 部屋在庫管理
        List<GuestRoomStock__c> roomStockList = new List<GuestRoomStock__c>();
        Date processDay = Date.today();
        // 処理年の設定
        Integer thisYear = processDay.year();
        // 処理月の設定
        Integer thisMonth = processDay.month();
        // 処理月・日数の設定
        Integer daysInMonth = Date.daysInMonth(thisYear, thisMonth);
        for(Integer i = 0; i < daysInMonth; i ++){
            roomStockList.add(new GuestRoomStock__c(QtyOfStock__c = 10,StockDate__c=Date.newinstance(thisYear, thisMonth, i),RoomTypeRef__c=roomTypeList[0].Id));
        }
        insert roomStockList;
        return roomTypeList;
    }

    /*
    testmethod static void TestGetDateRange() {
        RoomTypeInventory p = new RoomTypeInventory();
        Date st = Date.today();
        List<Date> r1 = p.getDateRange(st, st.addDays(0));
        List<Date> r2 = p.getDateRange(st, st.addDays(1));
        List<Date> r3 = p.getDateRange(st, st.addDays(2));
        List<Date> r4 = p.getDateRange(st, st.addDays(3));
        System.assertEquals(r1.size(), 1, r1);
        System.assertEquals(r2.size(), 2, r2);
        System.assertEquals(r3.size(), 3, r3);
        System.assertEquals(r4.size(), 4, r4);
        System.debug(r1);
        System.debug(r2);
        System.debug(r3);
        System.debug(r4);
    }*/
    // 故障部屋の統計値確認
    testmethod static void TestBadRoomInfo() {
        
        TestCommon.createCommDefine();
        CommDefine__c comDef = [select RoomUseEbFlg__c from CommDefine__c];
        comDef.RoomUseEbFlg__c = true;
        update comDef;
    
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        TestCommon.createTl2WayConfigDoc();
        
        // 部屋タイプを定義する
        TypeOfRooms__c typeRoom1 = TestCommon.createTypeOfRoom(10);
        TypeOfRooms__c typeRoom2 = TestCommon.createTypeOfRoom(15);
        TypeOfRooms__c typeRoom3 = TestCommon.createTypeOfRoom(20);
//System.debug(loggingLevel.ERROR, 'typeRoom1::' + [select ActionType__c from TypeOfRooms__c]); 
        // 当日から３日分の故障部屋１件：ステータス「故障」処理結果：NULL　部屋A
        // 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理中 部屋A
        // 当日は１日分の故障部屋１件：　ステータス「NULL」処理結果：NULL 部屋C
        // 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理中 部屋B
        // 当日は１日分の故障部屋１件：　ステータス「故障」処理結果：修理済 部屋A
        Date startDate = Date.newInstance(2013, 9, 15);
        // 処理結果：当日分の故障部屋数：2件
        Room__c roomA = TestCommon.createRooms(typeRoom1.Id);
        Room__c roomB = TestCommon.createRooms(typeRoom2.Id);
        Room__c roomC = TestCommon.createRooms(typeRoom3.Id);
        
        RoomsStatus__c rStatus1 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate.addDays(3));
        RoomsStatus__c rStatus2 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate,
                                                        Result__c = '修理中'); 
        RoomsStatus__c rStatus3 = new RoomsStatus__c(   RoomRef__c=roomC.Id, 
                                                        Status__c = null,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate,
                                                        Result__c = null);  
        RoomsStatus__c rStatus4 = new RoomsStatus__c(   RoomRef__c=roomB.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate,
                                                        Result__c = '修理中'); 
        RoomsStatus__c rStatus5 = new RoomsStatus__c(   RoomRef__c=roomA.Id, 
                                                        Status__c=CommConst.ROOM_ST_TYPE_BED,
                                                        StatusBeginDate__c=startDate,
                                                        StatusEndDate__c = startDate,
                                                        Result__c = CommConst.ROOM_ST_TYPE_BED_FIN);
        List<RoomsStatus__c> insRooms = new List<RoomsStatus__c>();
        insRooms.add(rStatus1);
        insRooms.add(rStatus2);
        insRooms.add(rStatus3);
        insRooms.add(rStatus4);
        insRooms.add(rStatus5);
        insert insRooms;
        

        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.thisYear = startDate.year();
        ctl.thisMonth = startDate.month();
        // 予約データを作成する
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = typeRoom1.Id;
        ctl.staysNums = 0;
        ctl.startDays = startDate.format();     // 2013.09.15
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate();
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = typeRoom2.Id;
        ctl.staysNums = 1;
        ctl.startDays = startDate.addDays(1).format();  // 2013.09.16
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate();  
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = typeRoom3.Id;
        ctl.staysNums = 3;
        ctl.startDays = startDate.addDays(1).format();  // 2013.09.16-2013.09.18
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate(); 
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());       
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = typeRoom3.Id;
        ctl.staysNums = 2;
        ctl.startDays = startDate.addDays(1).format();  // 2013.09.16-2013.09.17
        ctl.bookingRooms = 3;
        ctl.newLead.ExtraBedChk__c = false;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        Test.startTest();
        // 予約作成
        ctl.bookingCreate(); 
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());        
        // キャンセルされた予約データは影響なしの確認
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = typeRoom3.Id;
        ctl.staysNums = 1;
        ctl.startDays = startDate.addDays(5).format(); // 2013.09.19
        ctl.bookingRooms = 1;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate(); 
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());
        
        List<Lead__c> canlcelLst = [select id,ReservedStatus__c from lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :startDate.addDays(5)];
        for (Lead__c lead : canlcelLst) {
            lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
        }
        update canlcelLst;


        Date firstDay = Date.newInstance(startDate.Year(), startDate.month(), 1);
        Integer index = firstDay.daysBetween(startDate)+1;
        // 在庫数統計
        // 最大部屋数確認
        Decimal maxRooms = typeRoom1.MaxRooms__c + typeRoom2.MaxRooms__c + typeRoom3.MaxRooms__c;
//for (Lead__c lead : [select id,ReservedStatus__c,ExtraBedChk__c,EntryTime__c from lead__c]){
//System.debug(loggingLevel.ERROR, '[LEAD:]'+lead);
//}
        RoomTypeInventory ctl2 = new RoomTypeInventory();
        // 初期処理
        ctl2.init();
        ctl2.thisYear = startDate.year();
        ctl2.thisMonth = startDate.month();
        ctl2.gotoYearMonth();
        // 部屋数確認
for (Integer i = 1; i <= ctl2.sumEbRoomMap.keySet().size(); i++) {
    System.debug(loggingLevel.ERROR, ctl2.sumEbRoomMap.get(i));
}
for (RoomTypeInventory.dispHeader item: ctl2.dispHeaders) {
    System.debug(loggingLevel.ERROR, item);
}

        System.assertEquals(ctl2.sumEbRoomMap.get(index-1), 0); // 14
        System.assertEquals(ctl2.sumEbRoomMap.get(index), 2, ctl2.sumEbRoomMap);    // 15
        System.assertEquals(ctl2.sumEbRoomMap.get(index+1), 4); // 16
        System.assertEquals(ctl2.sumEbRoomMap.get(index+2), 2);
        System.assertEquals(ctl2.sumEbRoomMap.get(index+3), 2);
        System.assertEquals(ctl2.sumEbRoomMap.get(index+4), 0);
        
        // 故障部屋の確認
        System.assertEquals(ctl2.badRoomsMap.get(index), 2);
        System.assertEquals(ctl2.badRoomsMap.get(index+1), 1);
        System.assertEquals(ctl2.badRoomsMap.get(index+2), 1);
        
        // 部屋数設定確認
        System.assertEquals(ctl2.usedRoomsMap.get(index-1), 0);
        System.assertEquals(ctl2.usedRoomsMap.get(index), 2);
        System.assertEquals(ctl2.usedRoomsMap.get(index+1), 7);
        System.assertEquals(ctl2.usedRoomsMap.get(index+2), 5);
        System.assertEquals(ctl2.usedRoomsMap.get(index+3), 2);
        System.assertEquals(ctl2.usedRoomsMap.get(index+4), 0);

        RoomTypeInventory.dispRecord row1 = ctl2.dispRecordMap.get(typeRoom1.Id);
        RoomTypeInventory.dispRecord row2 = ctl2.dispRecordMap.get(typeRoom2.Id);
        RoomTypeInventory.dispRecord row3 = ctl2.dispRecordMap.get(typeRoom3.Id);
        //row.roomList[表示する場合、故障部屋数も減らすが必要]
        System.assertEquals(row1.roomList[index-2].stock.QtyOfStock__c, typeRoom1.MaxRooms__c );      // 14
        System.assertEquals(row1.roomList[index-1].stock.QtyOfStock__c, typeRoom1.MaxRooms__c - 3);   // 15[故障数1]
        System.assertEquals(row1.roomList[index].stock.QtyOfStock__c, typeRoom1.MaxRooms__c - 1);     // 16[故障数1]
        System.assertEquals(row1.roomList[index+1].stock.QtyOfStock__c, typeRoom1.MaxRooms__c - 1);   // 17[故障数1]
        
        System.assertEquals(row2.roomList[index-2].stock.QtyOfStock__c, typeRoom2.MaxRooms__c);   // 14
        System.assertEquals(row2.roomList[index-1].stock.QtyOfStock__c, typeRoom2.MaxRooms__c - 1);   // 15[故障数1]
        System.assertEquals(row2.roomList[index].stock.QtyOfStock__c, typeRoom2.MaxRooms__c - 2); // 16
        System.assertEquals(row2.roomList[index+1].stock.QtyOfStock__c, typeRoom2.MaxRooms__c);   // 17

        
        System.assertEquals(row3.roomList[index-2].stock.QtyOfStock__c, typeRoom3.MaxRooms__c);   // 14
        System.assertEquals(row3.roomList[index-1].stock.QtyOfStock__c, typeRoom3.MaxRooms__c);   // 15
        System.assertEquals(row3.roomList[index].stock.QtyOfStock__c, typeRoom3.MaxRooms__c - 5); // 16
        System.assertEquals(row3.roomList[index+1].stock.QtyOfStock__c, typeRoom3.MaxRooms__c - 5);   // 17
        System.assertEquals(row3.roomList[index+2].stock.QtyOfStock__c, typeRoom3.MaxRooms__c - 2);   // 18
        
        Test.stopTest();
    }
    
    // 既にアサイン済みの部屋は再割合不可チェックのテスト
    testMethod static void testAssingedRoomIsNg() {
        List<TypeOfRooms__c> roomTypeList = createTestData();
        Lead__c preLead = TestCommon.createLead();

        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 1;
        ctl.roomType = roomTypeList[0].Id;
        ctl.staysNums = 0;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 部屋は重複アサインする
        ctl.newLead.Rroom__c = preLead.Rroom__c;
        // 予約作成
        ctl.bookingCreate();
        // 時刻設定問題なし、登録可能
        System.assert(Apexpages.hasMessages(Apexpages.Severity.ERROR));
        Apexpages.Message errMsg = Apexpages.getMessages()[0];
        System.assertEquals(errMsg.getDetail(), Label.MSG_0010,errMsg);
    } 
    
    
    /**
    * リアルAGT在庫統計情報をテストケース
    **/
    /**
    * リアルAGT残室数確認(支店なし)
    * 予約ポップ開始日モード：月の１日から設定が必要の場合、テストPASS
    **/
    @isTest(SeeAllData=true)
    static void RealAGT_SHOW_Case1() {
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.RoomPriceProdName__c = 'TEST室料';
        // 2020/06/30 在庫計算ロジック改修 WGCH BEGIN
        comDef.StockSyncIsMode__c = '1';
        // 2020/06/30 在庫計算ロジック改修 WGCH END
        update comDef;
        
        String csvBody =    '旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
        realAgtBefore();
        // 取引先情報を作成する
        List<Account> accs = CreateTravelAccount(3);
        
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(null, 3);
        for (integer i =0; i<typeOfRooms1.size(); i++) {
            typeOfRooms1[i].seq__c = i+1;
        }
        update TypeOfRooms1;
        
        Date today = Date.today();
        DateTime startTime = DateTime.newInstance(today.year(),today.month(),today.day());
        DateTime endTime = startTime.addYears(1);
        String strStartDate = startTime.format('yyyy/MM/dd');
        String strEndDate = endTime.format('yyyy/MM/dd');
        // CSVアップロード内容設定
        csvBody +=  accs[0].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '9\n'+
                    accs[0].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '8\n'+
                    accs[0].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '7\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '6\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '5\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '4\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n';
        Test.startTest();
        // ファイルアップロード処理
        FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
        fileHandel.filehand.setFileName('TestUploadFile');
        fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
        fileHandel.processCsvFile();
        System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
        // 汎用マスタのリアルAGT情報を確認する
        // 旅行会社１関連データは３件、部屋タイプは
        String querySql = CommSqlUtils.generateQueryString('RealAGT__c');
        List<RealAGT__c> totalNums = DataBase.query(querySql);
        System.assertEquals(totalNums.size(), 9);
        
        DateTime sdt = System.now();
        // 予約データ作成する[2件作成する、]
        List<Lead__c> Leads1 = createLeads(3,TypeOfRooms1[0].Id, accs[0].Id, sdt);
        List<Lead__c> Leads2 = createLeads(3,TypeOfRooms1[1].Id, accs[1].Id, sdt.addDays(1));
        List<Lead__c> Leads3 = createLeads(3,TypeOfRooms1[2].Id, accs[2].Id, sdt.addDays(2));
        // 表示結果を確認する（当日分の残室数結果を確認する)
        RoomTypeInventory realAgt = new RoomTypeInventory();
        realAgt.init();
        
        Map<Id, RoomTypeInventory.TrvaleRecord> travelMap = realAgt.dispAgtRecordMap;
        System.assertEquals(travelMap.size(), 3);
        RoomTypeInventory.TrvaleRecord travelRec1 = travelMap.get(accs[0].Id);
        RoomTypeInventory.TrvaleRecord travelRec2 = travelMap.get(accs[1].Id);
        RoomTypeInventory.TrvaleRecord travelRec3 = travelMap.get(accs[2].Id);
        
        List<RoomTypeInventory.dispRecord> dispLst1 = travelRec1.getRoomTypes();
        List<RoomTypeInventory.dispRecord> dispLst2 = travelRec2.getRoomTypes();
        List<RoomTypeInventory.dispRecord> dispLst3 = travelRec3.getRoomTypes();
        
        System.assertEquals(dispLst1.size(), 3);
        System.assertEquals(dispLst2.size(), 3);
        System.assertEquals(dispLst3.size(), 3);
        // 販売数判別する
        RoomTypeInventory.dispRecord disp1 = dispLst1[0];
        RoomTypeInventory.dispRecord disp2 = dispLst2[1];
        RoomTypeInventory.dispRecord disp3 = dispLst3[2];
        
        Date todayDt = Date.today();
        Date firstDt = Date.newInstance(todayDt.year(), todayDt.month(), 1);
        Integer diffDays = firstDt.daysBetween(todayDt);
        
        System.assertEquals(disp1.roomList[diffDays].stock.QtyOfStock__c, 6);
        //System.assertEquals(disp2.roomList[diffDays+1].QtyOfStock__c, 2);
        //System.assertEquals(disp3.roomList[diffDays+2].QtyOfStock__c, -2);
        
        // 販売済み部屋数
        Map<Integer, Decimal> usedAgtMap =  realAgt.usedAgtRoomsMap;
        //System.assertEquals(usedAgtMap.get(diffDays+1), 3);
        //System.assertEquals(usedAgtMap.get(diffDays+2), 3);
        //System.assertEquals(usedAgtMap.get(diffDays+3), 3);
        // 総提供数
        Map<Integer, Decimal> mstAgtMap =  realAgt.mstAgtRoomsMap;
        System.assertEquals(mstAgtMap.get(diffDays+1),   45);
        //System.assertEquals(mstAgtMap.get(diffDays+1), 45);
        //System.assertEquals(mstAgtMap.get(diffDays+2), 45);
        //System.assertEquals(mstAgtMap.get(diffDays+3), 45);
        // 支店リストなし
        System.assertEquals(realAgt.branchShopLst.size(), 0);

        Test.stopTest();
    }
    
    /**
    * リアルAGT残室数確認(支店あり)
    * 予約ポップ開始日モード：月の１日から設定が必要の場合、テストPASS
    **/
    @isTest(SeeAllData=true)
    static void RealAGT_SHOW_Case2() {
        String csvBody =    '旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
        realAgtBefore();
        // 取引先情報を作成する
        List<Account> accs = CreateTravelAccount(3);
        // 支店情報を作成する
        ShopInformation__c shop1 = TestCommon.createShopInfo();
        ShopInformation__c shop2 = TestCommon.createShopInfo();
        ShopInformation__c shop3 = TestCommon.createShopInfo();

        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = shop1.shopCode__c;
        update loginUser;

		CommDefine__c def = TestCommon.createCommDefine();
		def.AccountEditAuthCheckFlg__c = false;
		// 2020/06/30 在庫計算ロジック改修 WGCH BEGIN
        def.StockSyncIsMode__c = '1';
        // 2020/06/30 在庫計算ロジック改修 WGCH END
		update def;
 
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 3);
        List<TypeOfRooms__c> TypeOfRooms2 = TestCommon.createTypeOfRoomByShop(shop2.Id, 3);
        List<TypeOfRooms__c> TypeOfRooms3 = TestCommon.createTypeOfRoomByShop(shop3.Id, 3);
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> updRoomsLst = new List<TypeOfRooms__c>();
        updRoomsLst.addAll(TypeOfRooms1);
        updRoomsLst.addAll(TypeOfRooms2);
        updRoomsLst.addAll(TypeOfRooms3);
        for (integer i =0; i<updRoomsLst.size(); i++) {
            updRoomsLst[i].seq__c = i+1;
        }
        update updRoomsLst;
        
        Date today = Date.today();
        DateTime startTime = DateTime.newInstance(today.year(),today.month(),today.day());
        DateTime endTime = startTime.addYears(1);
        String strStartDate = startTime.format('yyyy/MM/dd');
        String strEndDate = endTime.format('yyyy/MM/dd');
        // CSVアップロード内容設定
        csvBody +=  accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '9\n'+
                    accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '8\n'+
                    accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '7\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '6\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '5\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '4\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n';
        Test.startTest();
        // ファイルアップロード処理
        FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
        fileHandel.filehand.setFileName('TestUploadFile');
        fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
        fileHandel.processCsvFile();
        System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
        // 汎用マスタのリアルAGT情報を確認する
        // 旅行会社１関連データは３件、部屋タイプは
        String querySql = CommSqlUtils.generateQueryString('RealAGT__c');
        List<RealAGT__c> totalNums = DataBase.query(querySql);
        System.assertEquals(totalNums.size(), 9);
        
        DateTime sdt = System.now();
        // 予約データ作成する[2件作成する、]
        List<Lead__c> Leads1 = createLeads(3,TypeOfRooms1[0].Id, accs[0].Id, sdt);
        List<Lead__c> Leads2 = createLeads(3,TypeOfRooms2[1].Id, accs[1].Id, sdt.addDays(1));
        List<Lead__c> Leads3 = createLeads(3,TypeOfRooms3[2].Id, accs[2].Id, sdt.addDays(2));
        // 表示結果を確認する（当日分の残室数結果を確認する)
        RoomTypeInventory realAgt = new RoomTypeInventory();
        realAgt.init();
        realAgt.branchShopNm = shop1.ShopCode__c;
        realAgt.changeBranchShop();
        
        Map<Id, RoomTypeInventory.TrvaleRecord> travelMap = realAgt.dispAgtRecordMap;
        System.assertEquals(travelMap.size(), 1);
        RoomTypeInventory.TrvaleRecord travelRec1 = travelMap.get(accs[0].Id);
        
        List<RoomTypeInventory.dispRecord> dispLst1 = travelRec1.getRoomTypes();
        
        System.assertEquals(dispLst1.size(), 3);
        // 販売数判別する
        RoomTypeInventory.dispRecord disp1 = dispLst1[0];
        
        Date todayDt = Date.today();
        Date firstDt = Date.newInstance(todayDt.year(), todayDt.month(), 1);
        Integer diffDays = firstDt.daysBetween(todayDt);
        
        System.assertEquals(disp1.roomList[diffDays].stock.QtyOfStock__c, 6);
        
        // 販売済み部屋数
        Map<Integer, Decimal> usedAgtMap =  realAgt.usedAgtRoomsMap;
        //System.assertEquals(usedAgtMap.get(diffDays+1), 3);
        // 総提供数
        Map<Integer, Decimal> mstAgtMap =  realAgt.mstAgtRoomsMap;
        System.assertEquals(mstAgtMap.get(diffDays+1),   24);
        //System.assertEquals(mstAgtMap.get(diffDays+1), 24);
        
        // 支店リストあり
        System.assertEquals(realAgt.branchShopLst.size(), 3);
        
        Test.stopTest();
    }
    // 2020/06/30 在庫計算ロジック改修 WGCH BEGIN
    /**
    * リアルAGT在庫統計情報をテストケース
    **/
    /**
    * リアルAGT残室数確認(支店なし)
    * 予約ポップ開始日モード：月の１日から設定が必要の場合、テストPASS
    **/
    @isTest(SeeAllData=true)
    static void RealAGT_SHOW_Case3() {
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.RoomPriceProdName__c = 'TEST室料';
        update comDef;
        
        String csvBody =    '旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
        realAgtBefore();
        // 取引先情報を作成する
        List<Account> accs = CreateTravelAccountLock(3);
        
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(null, 3);
        for (integer i =0; i<typeOfRooms1.size(); i++) {
            typeOfRooms1[i].seq__c = i+1;
        }
        update TypeOfRooms1;
        
        Date today = Date.today();
        DateTime startTime = DateTime.newInstance(today.year(),today.month(),today.day());
        DateTime endTime = startTime.addYears(1);
        String strStartDate = startTime.format('yyyy/MM/dd');
        String strEndDate = endTime.format('yyyy/MM/dd');
        // CSVアップロード内容設定
        csvBody +=  accs[0].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '9\n'+
                    accs[0].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '8\n'+
                    accs[0].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '7\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '6\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '5\n'+
                    accs[1].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '4\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
                    accs[2].Name + ',' + '' + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n';
        Test.startTest();
        // ファイルアップロード処理
        FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
        fileHandel.filehand.setFileName('TestUploadFile');
        fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
        fileHandel.processCsvFile();
        System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
        // 汎用マスタのリアルAGT情報を確認する
        // 旅行会社１関連データは３件、部屋タイプは
        String querySql = CommSqlUtils.generateQueryString('RealAGT__c');
        List<RealAGT__c> totalNums = DataBase.query(querySql);
        System.assertEquals(totalNums.size(), 9);
        
        DateTime sdt = System.now();
        // 予約データ作成する[2件作成する、]
        List<Lead__c> Leads1 = createLeads(3,TypeOfRooms1[0].Id, accs[0].Id, sdt);
        List<Lead__c> Leads2 = createLeads(3,TypeOfRooms1[1].Id, accs[1].Id, sdt.addDays(1));
        List<Lead__c> Leads3 = createLeads(3,TypeOfRooms1[2].Id, accs[2].Id, sdt.addDays(2));
        // 表示結果を確認する（当日分の残室数結果を確認する)
        RoomTypeInventory realAgt = new RoomTypeInventory();
        realAgt.init();
        
        Map<Id, RoomTypeInventory.TrvaleRecord> travelMap = realAgt.dispAgtRecordMap;
        System.assertEquals(travelMap.size(), 3);
        RoomTypeInventory.TrvaleRecord travelRec1 = travelMap.get(accs[0].Id);
        RoomTypeInventory.TrvaleRecord travelRec2 = travelMap.get(accs[1].Id);
        RoomTypeInventory.TrvaleRecord travelRec3 = travelMap.get(accs[2].Id);
        
        List<RoomTypeInventory.dispRecord> dispLst1 = travelRec1.getRoomTypes();
        List<RoomTypeInventory.dispRecord> dispLst2 = travelRec2.getRoomTypes();
        List<RoomTypeInventory.dispRecord> dispLst3 = travelRec3.getRoomTypes();
        
        System.assertEquals(dispLst1.size(), 3);
        System.assertEquals(dispLst2.size(), 3);
        System.assertEquals(dispLst3.size(), 3);
        // 販売数判別する
        RoomTypeInventory.dispRecord disp1 = dispLst1[0];
        RoomTypeInventory.dispRecord disp2 = dispLst2[1];
        RoomTypeInventory.dispRecord disp3 = dispLst3[2];
        
        Date todayDt = Date.today();
        Date firstDt = Date.newInstance(todayDt.year(), todayDt.month(), 1);
        Integer diffDays = firstDt.daysBetween(todayDt);
        
        System.assertEquals(disp1.roomList[diffDays].stock.QtyOfStock__c, 6);
        //System.assertEquals(disp2.roomList[diffDays+1].QtyOfStock__c, 2);
        //System.assertEquals(disp3.roomList[diffDays+2].QtyOfStock__c, -2);
        
        // 販売済み部屋数
        Map<Integer, Decimal> usedAgtMap =  realAgt.usedAgtRoomsMap;
        //System.assertEquals(usedAgtMap.get(diffDays+1), 3);
        //System.assertEquals(usedAgtMap.get(diffDays+2), 3);
        //System.assertEquals(usedAgtMap.get(diffDays+3), 3);
        // 総提供数
        Map<Integer, Decimal> mstAgtMap =  realAgt.mstAgtRoomsMap;
        System.assertEquals(mstAgtMap.get(diffDays+1),   45);
        //System.assertEquals(mstAgtMap.get(diffDays+1), 45);
        //System.assertEquals(mstAgtMap.get(diffDays+2), 45);
        //System.assertEquals(mstAgtMap.get(diffDays+3), 45);
        // 支店リストなし
        System.assertEquals(realAgt.branchShopLst.size(), 0);

        Test.stopTest();
    }
    
    /**
    * リアルAGT残室数確認(支店あり)
    * 予約ポップ開始日モード：月の１日から設定が必要の場合、テストPASS
    **/
    @isTest(SeeAllData=true)
    static void RealAGT_SHOW_Case4() {
        String csvBody =    '旅行会社名,店舗名,部屋タイプ名,開始日付,終了日付,部屋数\n';
        realAgtBefore();
        // 取引先情報を作成する
        List<Account> accs = CreateTravelAccountLock(3);
        // 支店情報を作成する
        ShopInformation__c shop1 = TestCommon.createShopInfo();
        ShopInformation__c shop2 = TestCommon.createShopInfo();
        ShopInformation__c shop3 = TestCommon.createShopInfo();

        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = shop1.shopCode__c;
        update loginUser;

		CommDefine__c def = TestCommon.createCommDefine();
		def.AccountEditAuthCheckFlg__c = false;
		update def;
 
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(shop1.Id, 3);
        List<TypeOfRooms__c> TypeOfRooms2 = TestCommon.createTypeOfRoomByShop(shop2.Id, 3);
        List<TypeOfRooms__c> TypeOfRooms3 = TestCommon.createTypeOfRoomByShop(shop3.Id, 3);
        // 部屋タイプ情報を作成する
        List<TypeOfRooms__c> updRoomsLst = new List<TypeOfRooms__c>();
        updRoomsLst.addAll(TypeOfRooms1);
        updRoomsLst.addAll(TypeOfRooms2);
        updRoomsLst.addAll(TypeOfRooms3);
        for (integer i =0; i<updRoomsLst.size(); i++) {
            updRoomsLst[i].seq__c = i+1;
        }
        update updRoomsLst;
        
        Date today = Date.today();
        DateTime startTime = DateTime.newInstance(today.year(),today.month(),today.day());
        DateTime endTime = startTime.addYears(1);
        String strStartDate = startTime.format('yyyy/MM/dd');
        String strEndDate = endTime.format('yyyy/MM/dd');
        // CSVアップロード内容設定
        csvBody +=  accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '9\n'+
                    accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '8\n'+
                    accs[0].Name + ',' + shop1.Name + ',' + TypeOfRooms1[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '7\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '6\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '5\n'+
                    accs[1].Name + ',' + shop2.Name + ',' + TypeOfRooms2[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '4\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[0].Name + ',' + strStartDate + ',' + strEndDate + ',' + '3\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[1].Name + ',' + strStartDate + ',' + strEndDate + ',' + '2\n'+
                    accs[2].Name + ',' + shop3.Name + ',' + TypeOfRooms3[2].Name + ',' + strStartDate + ',' + strEndDate + ',' + '1\n';
        Test.startTest();
        // ファイルアップロード処理
        FileUploadImpForRealAGT fileHandel = new FileUploadImpForRealAGT();
        fileHandel.filehand.setFileName('TestUploadFile');
        fileHandel.filehand.setFileBody(Blob.valueOf(csvBody));
        fileHandel.processCsvFile();
        System.assert(!fileHandel.filehand.result.isHasErrMsg,fileHandel.filehand.result);
        // 汎用マスタのリアルAGT情報を確認する
        // 旅行会社１関連データは３件、部屋タイプは
        String querySql = CommSqlUtils.generateQueryString('RealAGT__c');
        List<RealAGT__c> totalNums = DataBase.query(querySql);
        System.assertEquals(totalNums.size(), 9);
        
        DateTime sdt = System.now();
        // 予約データ作成する[2件作成する、]
        List<Lead__c> Leads1 = createLeads(3,TypeOfRooms1[0].Id, accs[0].Id, sdt);
        List<Lead__c> Leads2 = createLeads(3,TypeOfRooms2[1].Id, accs[1].Id, sdt.addDays(1));
        List<Lead__c> Leads3 = createLeads(3,TypeOfRooms3[2].Id, accs[2].Id, sdt.addDays(2));
        // 表示結果を確認する（当日分の残室数結果を確認する)
        RoomTypeInventory realAgt = new RoomTypeInventory();
        realAgt.init();
        realAgt.branchShopNm = shop1.ShopCode__c;
        realAgt.changeBranchShop();
        
        Map<Id, RoomTypeInventory.TrvaleRecord> travelMap = realAgt.dispAgtRecordMap;
        System.assertEquals(travelMap.size(), 1);
        RoomTypeInventory.TrvaleRecord travelRec1 = travelMap.get(accs[0].Id);
        
        List<RoomTypeInventory.dispRecord> dispLst1 = travelRec1.getRoomTypes();
        
        System.assertEquals(dispLst1.size(), 3);
        // 販売数判別する
        RoomTypeInventory.dispRecord disp1 = dispLst1[0];
        
        Date todayDt = Date.today();
        Date firstDt = Date.newInstance(todayDt.year(), todayDt.month(), 1);
        Integer diffDays = firstDt.daysBetween(todayDt);
        
        System.assertEquals(disp1.roomList[diffDays].stock.QtyOfStock__c, 6);
        
        // 販売済み部屋数
        Map<Integer, Decimal> usedAgtMap =  realAgt.usedAgtRoomsMap;
        //System.assertEquals(usedAgtMap.get(diffDays+1), 3);
        // 総提供数
        Map<Integer, Decimal> mstAgtMap =  realAgt.mstAgtRoomsMap;
        System.assertEquals(mstAgtMap.get(diffDays+1),   24);
        //System.assertEquals(mstAgtMap.get(diffDays+1), 24);
        
        // 支店リストあり
        System.assertEquals(realAgt.branchShopLst.size(), 3);
        
        Test.stopTest();
    }
    // 2020/06/30 在庫計算ロジック改修 WGCH END
    
    static testmethod void checkXmlRead() {
        createDocument();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'RoomTypeInventoryLeadInputExtendFieldsXml'].size(), 1);
        // 2015/12/01 Assert END

        TestCommon.createCommDefine();
        CommDefine__c comDef = [select RoomUseEbFlg__c from CommDefine__c];
        comDef.RoomUseEbFlg__c = true;
        update comDef;
    
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        TestCommon.createTl2WayConfigDoc();
        
        Contact guest = TestCommon.createContact();
        Test.startTest();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.branchShopNm = '';
        ctl.getInputExtendFields();
        RoomTypeInventory.refreshContcatInfo(guest.Id, guest.LastName + ' ' + guest.firstName);
        // 2way照会
        ctl.actionModeType = '残室数[AGT]';
        ctl.switchPage();
        Test.stopTest();
    }
    // 当日は開始日として、データ表示したい場合
    static testmethod void testTodayToStartShow() {
        
        TestCommon.createCommDefine();
        CommDefine__c comDef = [select RoomTypeStartDateMode__c from CommDefine__c];
        comDef.RoomTypeStartDateMode__c = '2';
        update comDef;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from CommDefine__c].size(), 1);
        // 2015/12/01 Assert END
        List<TypeOfRooms__c> roomTypeList = createTestData();
        Lead__c preLead = TestCommon.createLead();
        Test.startTest();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // Tier設定する
        RoomTypeInventory.TierSetupInfo tierInfo = ctl.tierInfo;
        tierInfo.tier = '3';
        tierInfo.isWeekRepeat = true;
        tierInfo.weekOpts = 'Tuesday,Thursday';
        tierInfo.startDate = system.now().format('yyyy/MM/dd');
        tierInfo.endDate = system.now().addDays(30).format('yyyy/MM/dd');
        Test.stopTest();
        ctl.createRaceTableDetail();
        
       RoomTypeInventory.HotelStatusInfo hotelInf = ctl.hotelInf;
       hotelInf.hotelStatus = '休館';
       hotelInf.startDate = tierInfo.startDate;
       hotelInf.endDate = tierInfo.endDate;
       ctl.updateHotelStatus();
       
       Boolean isShowTier = ctl.isShowTierHeader;
        
    }
    static testmethod void testRateRateShow() {
        
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.RoomPriceProdName__c = 'TEST室料';
        update comDef;
        TestCommon.createTl2WayConfigDoc();
        
        TypeOfRooms__c TypeOfRooms1 = TestCommon.createTypeOfRoom();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from TypeOfRooms__c].size(), 1);
        // 2015/12/01 Assert END
        String tier = 'tier1';
        String peoples = '2';
        Decimal price = 10000;
        Integer days = 5;
        // CREATE RACKRATE
        TestCommon.createRaceRateMst(TypeOfRooms1.Id, tier, peoples, price);
        TestCommon.createRaceRateDetail(tier, peoples, days);
        Date startDate = Date.today();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // ラックレート
        ctl.actionModeType = 'ラックレート';
        ctl.switchPage();
        // Base Plan Mode
        List<AccountMaster__c> roomRateList = TestCommon.createProductMst(1); 
        roomRateList[0].Name = comDef.RoomPriceProdName__c;
        roomRateList[0].ActionType__c =CommConst.PROD_ACTION_TYPE_RP;
        update roomRateList[0];
        
        // 予約新規作成
        // 予約データを作成する
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.newLead.StayPersons__c = 2;
        ctl.roomType = TypeOfRooms1.Id;
        ctl.staysNums = 1;
        ctl.startDays = startDate.format();     // 2013.09.15
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        ctl.newLead.Field4__c = '8:00';
        ctl.newLead.Field3__c = '16:30';
        // 予約作成
        ctl.bookingCreate();
        
    }
    
    private static void createDocument(){
        String csv = '<?xml version="1.0" encoding="utf-8"?><root><SHOP><SHOPCODE></SHOPCODE><COLNUMS>2</COLNUMS><FIELDS>Mans__c,Femails__c,CouponTypeLst__c,Field354__c</FIELDS></SHOP></root>';

        Document StaffScheduleConfigXml = new Document();
        StaffScheduleConfigXml.Name = 'RoomTypeInventoryLeadInputExtendFieldsXml';
        StaffScheduleConfigXml.DeveloperName = StaffScheduleConfigXml.Name;
        StaffScheduleConfigXml.FolderId = UserInfo.getUserId();
        StaffScheduleConfigXml.Body = Blob.valueOf(csv);
        insert StaffScheduleConfigXml;
    }
    /**
    * 旅行会社取引先情報を作成する
    **/
    private static List<Account> CreateTravelAccount(Integer rsSize) { 
        List<Account> items = new List<Account>();
        for (Integer i=0; i<rsSize; i++) {
            Account acc = new Account(
                Name = 'ACC_' + i,
                AccountType__c = '旅行会社'
            );
            items.add(acc);
        }
        insert items;
        return items;
    }
    // 2020/06/30 在庫計算ロジック改修 WGCH BEGIN
    /**
    * 旅行会社-リアル-取引先情報を作成する
    **/
    private static List<Account> CreateTravelAccountLock(Integer rsSize) { 
        List<Account> items = new List<Account>();
        for (Integer i=0; i<rsSize; i++) {
            Account acc = new Account(
                Name = 'ACC_' + i,
                AccountType__c = '旅行会社',
                SalesOfficeCompanyType__c = 'リアル'
            );
            items.add(acc);
        }
        insert items;
        return items;
    }
    // 2020/06/30 在庫計算ロジック改修 WGCH END
    /**
    * 予約情報を作成する
    **/
    private static List<Lead__c> createLeads(Integer rsSzie, Id roomTypeId, Id travelId, DateTime startDt) {
        
        Contact contactId = TestCommon.createContact();
        Id recTypeId = CommLogicProcess.getLeadBookingRecType();
        //Date startDate = Date.today();
        List<Lead__c> insLst = new List<Lead__c>();
        
        for (Integer i=0; i<rsSzie; i++) {
            Lead__c item = new Lead__c(
               RecordTypeId = recTypeId,
               SalesOfficeInfoRef__c = travelId,
               name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
               Relcontact__c = contactId.Id,                  // 顧客名
               ReservedStatus__c = '確認中',
               ReservedDate__c = System.now(),
               ReservedContact__c = 'Ono',
               EntryTime__c = startDt,
               Field4__c = '15:30',
               Departure__c = startDt.addDays(1),
               Field3__c = '10:00',
               StayPersons__c = 4,
               Field2__c = 'FAX',
               refTypeOfRooms__c = roomTypeId);
            insLst.add(item);   
        }
        insert insLst;
        return insLst;
    }
    
    private static void realAgtBefore() {
        delete [select id from ShopInformation__c];
        delete [select id from TypeOfRooms__c];
        delete [select id from RealAGT__c];
    }
    
	static testMethod void RoomSelectorTest() {
		Room__c newRoom = TestCommon.createRooms();
		RoomSelector roomSec = new RoomSelector();
		roomSec.init();
		roomSec.c_roomNm = newRoom.name;
		roomSec.queryInfo();
		List<Room__c> roomLst = roomSec.roomLst;
		System.assertEquals(roomLst.size(), 0);
	}
	// 2015/12/30 ADD CASE
	static testMethod void RoomSelectorADDCase() {
		Room__c newRoom = TestCommon.createRooms();
		Test.startTest();
		ApexPages.currentPage().getParameters().put('pdt',String.valueOf(Date.today()));
		ApexPages.currentPage().getParameters().put('pde',String.valueOf(Date.today()));
		Pagereference pg = ApexPages.currentPage();
		Test.setCurrentPage(pg);
		RoomSelector roomSec = new RoomSelector();
		roomSec.init();
		roomSec.c_roomNm = newRoom.name;
		roomSec.queryInfo();
		List<Room__c> roomLst = roomSec.roomLst;
		System.assertEquals(roomLst.size(), 0);
		Test.stopTest();
	}
	// TA2way在庫情報表示機能確認
	static testMethod void ta2WayStockSum_Case001() {
        createDocument();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'RoomTypeInventoryLeadInputExtendFieldsXml'].size(), 1);
        // 2015/12/01 Assert END

        TestCommon.createCommDefine();
        CommDefine__c comDef = [select RoomUseEbFlg__c from CommDefine__c];
        comDef.RoomUseEbFlg__c = true;
        update comDef;
    
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        Contact guest = TestCommon.createContact();
	    List<String> roomTypeCdLst = new List<String>{'002','100'};
		TestCommon.createTypeOfRoom(roomTypeCdLst);
		
        TestCommon.createTl2WayConfigDoc();
        TestCommon.createTa2WayConfigDoc();
        
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.branchShopNm = '';
        ctl.getInputExtendFields();
        RoomTypeInventory.refreshContcatInfo(guest.Id, guest.LastName + ' ' + guest.firstName);
	   	// 2way照会
        ctl.actionModeType = '残室数[AGT]';
        ctl.switchPage();
        Test.stopTest();
	}
	// TA2way在庫情報表示機能確認
	static testMethod void tl2WayStockSum_Case001() {
        createDocument();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'RoomTypeInventoryLeadInputExtendFieldsXml'].size(), 1);
        // 2015/12/01 Assert END

        TestCommon.createCommDefine();
        CommDefine__c comDef = [select RoomUseEbFlg__c from CommDefine__c];
        comDef.RoomUseEbFlg__c = true;
        update comDef;
    
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
        TestCommon.createTl2WayConfigDoc();
        TestCommon.createTa2WayConfigDoc();
        
        Contact guest = TestCommon.createContact();
	    List<String> roomTypeCdLst = new List<String>{'002','100'};
		TestCommon.createTypeOfRoom(roomTypeCdLst);
         
		Test.startTest();
		Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.branchShopNm = '';
        ctl.getInputExtendFields();
        RoomTypeInventory.refreshContcatInfo(guest.Id, guest.LastName + ' ' + guest.firstName);
	   	// 2way照会
        ctl.actionModeType = '残室数[AGT]';
        ctl.switchPage();
        Test.stopTest();
	}
	 /*在庫設定*/
    static testMethod void StockSettingTest() {
        createDocument();
        List<TypeOfRooms__c> roomTypeList = createTestData();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        Test.startTest();
        ctl.actionModeType = '在庫設定';
        ctl.switchPage();
        Date todayDt = system.today();
		String key = roomTypeList[0].Id + '_' + todayDt.format();
        Map<String,Object> reusltMap = new Map<String,Object>{
        	key => new map<String,Object>{'qtyOfStock' => 39,'roomTypeId' => roomTypeList[0].Id,'stockDate' => system.now().format('yyyy-MM-dd')}
        };
        ctl.requestStr = JSON.serialize(reusltMap);
        ctl.updateSalesType();
        reusltMap = new Map<String,Object>{
        	key => new map<String,Object>{'qtyOfStock' => 38,'roomTypeId' => roomTypeList[0].Id,
        					'stockDate' => system.now().format('yyyy-MM-dd')}
        };
        ctl.requestStr = JSON.serialize(reusltMap);
        ctl.updateSalesType();
        reusltMap = new Map<String,Object>{
        	'beg' => todayDt.format(),
        	'endDt' => todayDt.format(),
        	'remanMap' => new Map<String,object>{key => 20},
        	'rtps' => new List<String>{roomTypeList[0].Id},
        	'salesType' => '2',
        	'weekOpts' => new LIst<String>{system.now().format('EEEE')},
        	'diffRoomMap' => new Map<String,object>{key => 10}
        };
        ctl.requestStr = JSON.serialize(reusltMap);
        ctl.updateWeekOpts();
        ctl.updateWeekOpt();
        reusltMap = new Map<String,Object>{
        	'beg' => todayDt.format(),
        	'endDt' => todayDt.format(),
        	'remanMap' => new Map<String,object>{key => 20},
        	'rtps' => new List<String>{roomTypeList[0].Id},
        	'salesType' => '1',
        	'weekOpts' => new LIst<String>{system.now().format('EEEE')},
        	'diffRoomMap' => new Map<String,object>{key => 10}
        };
        ctl.requestStr = JSON.serialize(reusltMap);
        ctl.updateWeekOpts();
        ctl.updateWeekOpt();
        Test.stopTest();
    }
    static testMethod void myUnitTest2() {
        createDocument();
        List<TypeOfRooms__c> roomTypeList = createTestData();
		Plan__c plan = TestCommon.createPlan();
		plan.BasePlanFlg__c = true;
		update plan;
		Date processDay = Date.today();
		String dateStr = system.now().format('yyyy-MM-dd HH:mm:ss');
		String searchKey = plan.id + '_VIP_' + dateStr;
		Map<String,object> req = new Map<String,object>{'searchKey'=>searchKey,'setupDate'=>dateStr,'basePlanId'=>plan.id,
														'salesType'=>'1','vipType'=>'VIP'};
		map<String,Map<String,object>> reqMap = new Map<String,Map<String,object>>{ searchKey => req};
        Test.startTest();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.planOneJsonStr = JSON.serialize(reqMap);
        ctl.updPlanDetailInfo();
        Test.stopTest();
        ctl.refreshStockInfo();
        System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR), Apexpages.getMessages());
    }
    static testMethod void myUnitTest1() {
        createDocument();
        List<TypeOfRooms__c> roomTypeList = createTestData();
        // プラン情報を作成する
		Plan__c plan = TestCommon.createPlanIncRoom0();
		plan.BasePlanFlg__c = true;
		update plan;
		Date processDay = Date.today();
		String dateStr = system.now().format('yyyy-MM-dd HH:mm:ss');
		String searchKey = plan.id + '_VIP_' + dateStr;
		Map<String,object> reqs = new Map<String,object>{'beg' => processDay.format(),'endDt' => processDay.format(),
        												'plps' => new List<Id>{plan.id},'weekOpts' => new LIst<String>{system.now().format('EEEE')},
        												'tierType' => 'tier2','salesType' => '1',
        												'vipType' => 'VIP','allPlanFlg' => 'true'};
        Test.startTest();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        ctl.planJsonStr = JSON.serialize(reqs);
        ctl.updPlanDetailInfo();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ZeroRoomPriceAutoSetupFlg__c = false;
        update comDef;
        
        // 該当プランによて、関連の会計商品（プラン）を取得する
        Lead__c preLead = TestCommon.createLead();
        preLead.guestType__c = 'VIP';
        // if (!accs.isEmpty())
        preLead.field310__c = plan.id;
        Test.stopTest();
        update preLead;
        ctl.refreshStockInfo();
        System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR), Apexpages.getMessages());
        String data = '{"queryDt":"2020/05/09","spcd":"02","typeId":"' + roomTypeList[0].id + '"}';
        object res = RoomTypeInventory.remoteCenter('getTierMapInfo',data);
    }
}