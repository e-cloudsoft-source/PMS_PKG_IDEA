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
@isTest
private class BI_TR_LeadInfoSyncTest {

    static testMethod void myUnitTest() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        info.Payment = 'カード決済';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.PerPaxRate = 12053;
		roomRate.TotalPerRoomRate = 11801;
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        /*System.assertEquals('予約通知： UT000S991旅行会社'+ '\n' +
'予約番号： 1111 鉄道システム旅館様'+'\n' +'\n' +
'宿泊者情報：'+'\n' +
'テストユーザー００１(UnitTestUser_GuestHalfName)'+'\n' +
'Mail: yamaguchi@clips.co.jp'+'\n' +
'住所: 新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ'+'\n' +
' 電話: 01-3001-9999'+'\n' +'\n' +
'予約者情報：'+'\n' +
'予約者・会員名漢字'+'\n' +
'予約者・会員名カタカナ'+'\n' +'\n' +
'プラン名：らくじゃんらくらくプラン(plan01)'+'\n' +'\n' +
'2016年09月20日 から1泊他  サ込税込'+'\n' +
'入込方法： チェックイン時間：16:00'+'\n' +
'人員総数：3人  内訳：'+'\n' +
'客室総数：1'+'\n' +'\n' +
'2016年09月20日 9999901 (テスト部屋タイプ) @'+'\n' +
'大人（男） 2名'+'\n' +
'大人（女） 1名'+'\n' +'\n' +
'宿泊料金計: ¥145000'+'\n' +'\n' +'\n' +
'-------------------------------------------------'+'\n' +
'支払い方法: '+'\n' +
'料金区分: 人員単価'+'\n' +'\n' +
'ご確認事項：'+'\n' +
'他'+ '\n' +
'メール本文処理を行う', leadInfo[0].email__c);*/
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
		String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.PerPaxRate = 12043;
        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        
        // Cancel
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.CANCEL;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads1 = [select id ,Field310__c from Lead__c limit 1];
        System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        Test.stopTest();
    }
    
    //0泊数据 无CheckOutTime not have plan
    static testMethod void myUnitTest1_2() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	/*Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;*/
    	JMST__c taxMst =  TestCommon.createTaxMst();
        // option会計商品
        AccountMaster__c shitulyoItem = new AccountMaster__c(
           Name = '食事1',
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '100999',         // 商品コード
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert shitulyoItem;
    	TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '9999901',
            MaxRooms__c = 1); 
        insert typeItem;
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
		RoomsStatus__c roomsStatus = new RoomsStatus__c(RoomRef__c = roomItem.id,
        									Status__c = '故障',
        									StatusBeginDate__c = CommUtils.stringToDate('2013-08-18'),
        									StatusEndDate__c =  CommUtils.stringToDate('2013-08-19'));
        insert RoomsStatus;
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.MealCondition = '食事';
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        BI_TR_LeadInfoSync.BI_TR_Option option = new BI_TR_LeadInfoSync.BI_TR_Option();
		option.OptionDate = Date.today();
		option.Name = '食事1';
		option.OptionCount = 2;
		option.OptionRate = 1000;
        info.optionLst = new List<BI_TR_LeadInfoSync.BI_TR_Option>();
        info.optionLst.add(option);
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 0;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = '9087';
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'WithoutServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = '純和風客室(バスルーム無し)';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        room.RoomSpecialRequest = '特別リクエスト';
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.TotalPerRoomRate = 11837;
		BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation roomRateDetailInfo = new BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation();
		roomRateDetailInfo.RateCategory = 1;
		roomRateDetailInfo.RoomRate = 500;
		roomRateDetailInfo.RatePaxCount = 2;
		roomRateDetailInfo.RateDetailInformation = '露天風呂付き';
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
        roomRate.detailInfoLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation>();
        roomRate.detailInfoLst.add(roomRateDetailInfo);
        roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
        String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 2;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.PerPaxRate = 11379;
        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        
        // Cancel
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.CANCEL;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads1 = [select id ,Field310__c from Lead__c limit 1];
        Test.stopTest();
    }
    
    //Nights = 2 无CheckOutTime 料金区分:人員単価(按人分别算)   have plan no detail
    static testMethod void myUnitTest1_3() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	Plan__c planItem = new Plan__c();
    	planItem.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	planItem.PlanNo__c = CommUtils.getRandom(10);
    	planItem.Price__c = 35000;
    	planItem.PackageCode__c = '3333';
    	planItem.JmstRef__c = taxMst.Id;
    	planItem.IsClosed__c = false;
    	planItem.PlanNo__c = '00000001';
    	insert planItem;
    	
    	CommDefine__c newDef = new CommDefine__c(
	    	RoomTypeReport__c = '$0001 客室タイプ別予約表',
	    	Posreg__c = '0',
	    	UnitPriceDefKb__c = 2,
	    	ScheduleResultMailAddress__c = '1@a.com,2@b.com,3@c.com,4@d.com,5@e.com,6@f.com',
			RoomIndicatorInfoMaxLength__c = 4,
			RoomSortDiv__c = '1',
			BookingMansDef__c = 1,
			BookingFemailsDef__c = 0,
			BookingChildrenDef__c = 0,
			LeadSplitDivCode__c = 1
		);
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 2;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'WithoutServiceAndIncludingTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.PerRoomPaxCount = 10;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 1;
        room.RoomChildB50Count = 2;
        room.RoomChildC30Count = 1;
        room.RoomChildDNoneCount = 1;
        room.RoomChildECount = 1;
        room.RoomChildFCount = 1;
        room.RoomChildOtherCount = 1;
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        /*guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';*/
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.PerPaxRate = 12000;
		roomRate.PerChildA70Rate = 6000;
		roomRate.PerChildB50Rate = 1200;
		roomRate.PerChildC30Rate = 8400;
		roomRate.PerChildDRate = 3600;
		roomRate.PerChildERate = 3600;
		roomRate.PerChildFRate = 8400;
		roomRate.PerChildOtherRate = 1200;
		roomRate.TotalPerRoomRate = 11800;
		
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = 'テストユーザー００１';
        member.UserKana = 'UnitTestUser_GuestHalfName';
        member.UserZip = '41526';
        member.UserAddr = '新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
        String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 2;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        
        // Cancel
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.CANCEL;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads1 = [select id ,Field310__c from Lead__c limit 1];
        System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        Test.stopTest();
    }
    
    //料金区分:人員単価  TotalPerRoomRate
    static testMethod void myUnitTest1_4() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.GuestOrGroupNameDoubleByte = 'ユーザ123';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 2;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'IncludingServiceWithOutTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.PerRoomPaxCount = 10;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 1;
        room.RoomChildB50Count = 2;
        room.RoomChildC30Count = 1;
        room.RoomChildDNoneCount = 1;
        room.RoomChildECount = 1;
        room.RoomChildFCount = 1;
        room.RoomChildOtherCount = 1;
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テスト';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='岩手県二戸市福岡字中村６４－１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.TotalPerRoomRate = 11800;
		
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
        String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 2;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        Test.stopTest();
    }
    
    //料金区分:部屋単価    not have have detail  室料 = 0
    static testMethod void myUnitTest1_5() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	/*Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;*/
    	createPlanHadHoomZero(null);
    	createCommonAcc();
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 2;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = '3333';
        info.PackagePlanName = 'テストプランデータ' + CommUtils.getRandom(5);
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.PerRoomPaxCount = 10;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 1;
        room.RoomChildB50Count = 2;
        room.RoomChildC30Count = 1;
        room.RoomChildDNoneCount = 1;
        room.RoomChildECount = 1;
        room.RoomChildFCount = 1;
        room.RoomChildOtherCount = 1;
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        /*guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';*/
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.TotalPerRoomRate = 11800;
		
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = 'テストユーザー００１';
        member.UserKana = 'UnitTestUser_GuestHalfName';
        member.UserZip = '41526';
        member.UserAddr = '新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
        String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.RetailerCompanyName = 'テスト123';
        info.TotalRoomCount = 2;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		
		
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        Test.stopTest();
    }
    
    //料金区分:部屋単価  PerRoomPaxCount= RoomPaxMaleCount+RoomPaxFemaleCount   not have have detail  室料 > 0
    static testMethod void myUnitTest1_6() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	/*Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;*/
    	
    	createPlanHadHoomNoZero();
    	createCommonAcc();
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 2;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = '3333';
        info.PackagePlanName = 'テストプランデータ' + CommUtils.getRandom(5);
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.PerRoomPaxCount = 2;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();
		roomRate.TotalPerRoomRate = 11200;
		
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message)); 
        String orgDataId = info.DataID;
		Test.startTest();
		// Update
     	info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.AccommodationName = '鉄道システム旅館';
        info.TravelAgencyBookingNumber = '1111';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 2;
        info.GrandTotalPaxCount = 3;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
        guest.GuestStateProvidence='岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手県1岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二戸市福岡字中村６４－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
        
		// GuestRate
		roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	//info.DataFrom = 'TestDataFrom' + '1';
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        //System.assertNotEquals(leads[0].Field310__c, planItem.Id);
        Test.stopTest();
    }
    
    //異常データ個別処理 roomAndGuest.roomRateLst.isEmpty() && nights == 1   PerRoomPaxCount == null  料金明細
    static testMethod void myUnitTest1_7() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.AdvancesReceivedChk__c = true;
    	update comDef;
    	
    	TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '9999901',
            MaxRooms__c = 99); 
        insert typeItem;
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
    	
    	createCommonAcc();
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        BI_TR_LeadInfoSync.BI_TR_Option option = new BI_TR_LeadInfoSync.BI_TR_Option();
		option.OptionDate = Date.today();
		option.Name = '食事1';
		option.OptionCount = 2;
		option.OptionRate = 1000;
        info.optionLst = new List<BI_TR_LeadInfoSync.BI_TR_Option>();
        info.optionLst.add(option);
        
        info.AccommodationName = '鉄道システム旅館';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalAccommodationCharge = 3000;
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 3;
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = '純和風客室(バスルーム無し)';
        //room.PerRoomPaxCount = 2;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        room.RoomSpecialRequest = '特別リクエスト';
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        /*guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手県1岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二戸市福岡字中村６４－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
        guest.GuestPhoneNumber = '01-3001-9999';*/
		
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.TotalPerlRoomHotSpringTax = 1000;
		roomRate.TotalPerRoomServiceFee = 500;
		BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation roomRateDetailInfo = new BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation();
		roomRateDetailInfo.RateCategory = 1;
		roomRateDetailInfo.RoomRate = 500;
		roomRateDetailInfo.RatePaxCount = 2;
		roomRateDetailInfo.RateDetailInformation = '露天風呂付き';
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
        roomRate.detailInfoLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation>();
        roomRate.detailInfoLst.add(roomRateDetailInfo);
        roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);
        
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = 'テストユーザー００１';
        member.UserKana = 'UnitTestUser_GuestHalfName';
        member.UserZip = '41526';
        member.UserAddr = '岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手県1岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二戸市福岡字中村６４－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
		member.UserGivinPoints = 500;
		member.UserUsePoints = 100;
		member.AmountClaimed = 2000;
		member.UserTel = '090-222-346';
		
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'02');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        //System.assert(rs != null);
        //System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
    }
    
    // guest
    static testMethod void myUnitTest1_8() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.AdvancesReceivedChk__c = true;
    	update comDef;
    	
    	TypeOfRooms__c typeItem = new TypeOfRooms__c(
            Name = '純和風客室(バスルーム無し)',
            RoomTypeCode__c = '9999901',
            MaxRooms__c = 99); 
        insert typeItem;
        Room__c roomItem = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = typeItem.Id,
    		heyadashiryou__c = 25000);
		insert roomItem;
        
        Contact contact = new Contact(
            LastName = '上様',
            ID__c = '19901'); 
        insert contact;
        
    	createPlanHadHoomNoZero();
    	/*Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = 'plan01';
    	update planItem;*/
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.SpecificMealCondition = '食事';
        BI_TR_LeadInfoSync.BI_TR_Option option = new BI_TR_LeadInfoSync.BI_TR_Option();
		option.OptionDate = Date.today();
		option.Name = 'テストプランデータ' + CommUtils.getRandom(5);
		option.OptionCount = 2;
		option.OptionRate = 1000;
        
        
        info.AccommodationName = '鉄道システム旅館123';
        // SalesOfficeInformation
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        info.TotalAccommodationCharge = 3000;
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName2';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００2';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 3;
        info.TotalPaxMaleCount = 2;
        info.TotalPaxFemaleCount = 1;
        info.TotalChildA70Count = 1;
        info.TotalChildB50Count = 1;
        info.GrandTotalPaxCount = 5;

        info.PackagePlanCode = '3333';
        info.PackagePlanName = 'テストプランデータ' + CommUtils.getRandom(5);
        
        info.MealCondition = '禁煙必要';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = 'PersonalRate';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = '部屋テスト' + CommUtils.getRandom(6);
        //room.PerRoomPaxCount = 2;
        room.RoomPaxMaleCount = 1;
        room.RoomPaxFemaleCount = 1;
        room.RoomSpecialRequest = '特別リクエスト';
        
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手県1岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二戸市福岡字中村６４－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
        guest.GuestPhoneNumber = '01-3001-9999';
		
		// GuestRate
		/*BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.TotalPerlRoomHotSpringTax = 1000;
		roomRate.TotalPerRoomServiceFee = 500;
		BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation roomRateDetailInfo = new BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation();
		roomRateDetailInfo.RateCategory = 1;
		roomRateDetailInfo.RoomRate = 500;
		roomRateDetailInfo.RatePaxCount = 2;
		roomRateDetailInfo.RateDetailInformation = '露天風呂付き';*/
        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
        /*roomRate.detailInfoLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateDetailInfomation>();
        roomRate.detailInfoLst.add(roomRateDetailInfo);
        roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);*/
        
		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = 'テストユーザー００3';
        member.UserKana = 'UnitTestUser_GuestHalfName3';
        member.UserZip = '41526';
        member.UserAddr = '岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手岩手県1岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二戸市福岡字中村６４－１岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県岩手県二岩手県岩手県岩手県岩手県岩124567890';
		member.UserGivinPoints = 500;
		member.UserUsePoints = 100;
		member.AmountClaimed = 2000;
		member.UserTel = '07012345678';
		
		info.member = member;
		info.optionLst = new List<BI_TR_LeadInfoSync.BI_TR_Option>();
        info.optionLst.add(option);
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        //System.assert(rs != null);
        //System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK,rs);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
    }

    static testMethod void myUnitTest2() {
    	
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = COmmUtils.getRandom(10);
    	update planItem;
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
       info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
       info.SystemDate = Date.today();
       info.SystemTime = Time.newInstance(10,11,23,0);
       info.AccommodationName = '􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚鉄道システム旅館';
       info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '禁煙必要';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'IncludingServiceWithOutTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        //System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
    }

    static testMethod void myUnitTest3() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
        Account travel = TestCommon.createTravelCompany();
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = CommUtils.getRandom(10);
    	planItem.client__c = travel.Id;
    	update planItem;

        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.AccommodationName = '􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚鉄道システム旅館';
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '禁煙必要';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'WithoutServiceAndIncludingTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        //System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
        
    }
    
    //变更
    static testMethod void myUnitTest4_1() {
    	Boolean autoAssingRoomFlg = CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c;
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
        Account travel = TestCommon.createTravelCompany();
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = CommUtils.getRandom(10);
    	planItem.client__c = travel.Id;
    	update planItem;

        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.AccommodationName = '鉄道システム旅館';
        //info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        //info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'WithoutServiceAndIncludingTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		rs.result = BI_TR_LeadInfoSync.BI_TR_Result.NG;
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
		//System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.NG);
        //System.assert(rs.sfdcId != null);
        //System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        //System.assertEquals(leads[0].Field310__c, planItem.Id);
    }
    
    //CANCEL
    static testMethod void myUnitTest4_2() {
    	Boolean autoAssingRoomFlg = CommDefine__c.getOrgDefaults().AdvancesReceivedChk__c;
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
        Account travel = TestCommon.createTravelCompany();
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = CommUtils.getRandom(10);
    	planItem.client__c = travel.Id;
    	update planItem;

        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.CANCEL;
        info.DataFrom = 'TestDataFrom';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.AccommodationName = '鉄道システム旅館';
        //info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        //info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'WithoutServiceAndIncludingTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
		//System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.NG);
        //System.assert(rs.sfdcId != null);
        //System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        //System.assertEquals(leads[0].Field310__c, planItem.Id);
    }

    // 店舗情報マスタに定義情報なし
    // 店舗別プラン機能FALSE　AGT存在　PACKAGEコード一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest5_1() {
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	//travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	//update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }
    
    // 店舗別プラン機能FALSE　AGT存在　PACKAGE名一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest5_2() {
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	plan2.Name = packageName;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan2.Id, leadRs);
    }
    
    // プランの自動作成関連機能確認１：
    // 店舗別プラン機能FALSE　AGT非存在　PACKAGEコード一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest5_3() {
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	//plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	update plan2;
    	// 旅行会社のコードを更新する
    	//travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	//travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	//update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = CommUtils.getRandom(10);
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }
    // 店舗別プラン機能FALSE　AGT非存在　PACKAGE名一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest5_4() {
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	//plan1.PackageCode__c = packageCode;
    	update plan1;
    	//plan2.client__c = travleComp.Id;
    	plan2.Name = packageName;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = packageCode;
    	travleComp.SalesOfficeCode__c = packageName;
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = CommUtils.getRandom(10);
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan2.Id, leadRs);
    }
    
    // 店舗情報マスタに定義情報あり
    // 店舗別プラン機能FALSE　AGT存在　PACKAGEコード一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest6_1() {
		// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }
    // 店舗別プラン機能FALSE　AGT存在　PACKAGE名一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest6_2() {
		// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	plan2.Name = packageName;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan2.Id, leadRs);
    }
    
    // プランの自動作成関連機能確認１：
    // 店舗別プラン機能FALSE　AGT非存在　PACKAGEコード一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest6_3() {
		// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	//plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }
    // 店舗別プラン機能FALSE　AGT非存在　PACKAGE名一致、プランをそのまま使う
    @isTest(seeAllData=false) static void myUnitTest6_4() {
		// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// プラン情報更新
    	plan1.client__c = travleComp.Id;
    	//plan1.PackageCode__c = packageCode;
    	update plan1;
    	//plan2.client__c = travleComp.Id;
    	plan2.Name = packageName;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan2.Id, leadRs);
    }

    // 店舗情報マスタ情報が存在
	// [店舗別プラン機能が展開する場合][AGT+PACKAGECODE]
    @isTest(seeAllData=false) static void myUnitTest8_1() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	shop.shopCode__c = '02';
    	update shop;
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	//Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = CommUtils.getRandom(10);
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT+PACKNAME]「店舗コードがマスタに非存在」
    @isTest(seeAllData=false) static void myUnitTest8_2() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗あり、AGTあり、PACKAGEコードあり、PACKAGE名前同じは2件プランあり（コードの一致が1件、名の一致が1件）
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	ShopInformation__c shop2 = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	//Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = 'A268Q';
    	String packageName = 'らくじゃんらくらくプラン1';
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	plan2.client__c = travleComp.Id;
    	plan2.Name = packageName;
    	update plan2;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = 'A268Q';
    	info.PackagePlanName = '';
    	//packageName;
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, null, leadRs); // 新規プラン自動作成
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs); 
    	System.assertNotEquals(leadRs[0].Field310__c, plan2.Id, leadRs); 
    	List<Plan__c> existPlans = [select id,ShopInfoRef__c from plan__c where PackageCode__c = :packageCode And ShopInfoRef__c = null And client__c = :travleComp.Id];
    	System.assertEquals(existPlans.size(), 1, existPlans);
    	System.assertEquals(existPlans[0].ShopInfoRef__c, null, existPlans); 
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT+PACKNAME]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest8_3() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	//shop.shopCode__c = '02';
    	//update shop;
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	//Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = packageName;
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = CommUtils.getRandom(10);
    	update plan1;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	//info.PackagePlanCode = packageCode;
    	info.PackagePlanName = packageName;
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, null, leadRs); // 新規プラン自動作成
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs); 
    	System.assertNotEquals(leadRs[0].Field310__c, plan2.Id, leadRs); 
    	List<Plan__c> existPlans = [select id,ShopInfoRef__c from plan__c where PackageCode__c = null And  Name = :packageName And ShopInfoRef__c = :shop.Id And client__c = :travleComp.Id];
    	//System.assertEquals(existPlans.size(), 1, existPlans);
    	//System.assertEquals(existPlans[0].ShopInfoRef__c, shop.Id, existPlans); 
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT対応なし+PACKCODE]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest8_4() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗あり、AGTあり、PACKAGEコードあり、PACKAGE名前同じは2件プランあり（コードの一致が1件、名の一致が1件）
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	shop.shopCode__c = '02';
    	update shop;
    	ShopInformation__c shop2 = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = CommUtils.getRandom(10);
    	plan1.client__c = dumpTravleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.shopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = plan2.Name;
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT対応なし+PACKCODE]「店舗コードがマスタに非存在」
    @isTest(seeAllData=false) static void myUnitTest8_5() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗あり、AGTあり、PACKAGEコードあり、PACKAGE名前同じは2件プランあり（コードの一致が1件、名の一致が1件）
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	ShopInformation__c shop2 = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = CommUtils.getRandom(10);
    	plan1.client__c = dumpTravleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	// 旅行会社のコードを更新する
    	//travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	//travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	//update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = plan2.Name;
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = CommUtils.getRandom(10);
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, null, leadRs); // 新規プラン自動作成
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs); 
    	System.assertNotEquals(leadRs[0].Field310__c, plan2.Id, leadRs); 

    	List<Plan__c> existPlans = [select id,Name,PackageCode__c,client__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c from plan__c where id = :leadRs[0].Field310__c];
    	System.assertEquals(existPlans.size(), 1, existPlans);
    	System.assertEquals(existPlans[0].ShopInfoRef__c, null, existPlans); 
    	System.assertEquals(existPlans[0].Name, info.PackagePlanName, existPlans); 
    	System.assertEquals(existPlans[0].PackageCode__c, info.PackagePlanCode, existPlans); 
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT対応なし+PACKNAME]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest8_6() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗あり、AGTあり、PACKAGEコードあり、PACKAGE名前同じは2件プランあり（コードの一致が1件、名の一致が1件）
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	shop.shopCode__c = '02';
    	update shop;
    	ShopInformation__c shop2 = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// AGT
    	plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = packageName;
    	plan1.client__c = dumpTravleComp.Id;
    	//plan1.PackageCode__c = packageCode;
    	update plan1;
    	// 旅行会社のコードを更新する
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, null, leadRs); // 新規プラン自動作成
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs); 
    	System.assertNotEquals(leadRs[0].Field310__c, plan2.Id, leadRs); 
    	List<Plan__c> existPlans = [select id,ShopInfoRef__c from plan__c where PackageCode__c = :info.PackagePlanCode And Name = :info.PackagePlanName];
    	System.assertEquals(existPlans.size(), 1, existPlans);
    	System.assertEquals(existPlans[0].ShopInfoRef__c, shop.Id, existPlans); 
	}
	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT対応あり+PACKNAME]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest9_1() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	//Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// AGT
    	//plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = CommUtils.getRandom(10);
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = packageCode;
    	update plan1;
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = null;//shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	// 旅行会社のコードを更新する
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
	}
	// [AGT対応あり+店舗設定なし＋PACKAGEコード設定なし]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest9_2() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ShopPlanSetupFlg__c = true;
    	update comDef;
    	// 店舗情報用意
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	// プラン作成を行う
    	Plan__c plan1 = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
    	// AGT作成を行う
    	Account travleComp = TestCommon.createTravelCompany();
    	//Account dumpTravleComp = TestCommon.createTravelCompany();
    	// AGTに更新を行う
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
    	// AGT
    	//plan1.ShopInfoRef__c = shop.Id;
    	plan1.name = CommUtils.getRandom(10);
    	plan1.client__c = travleComp.Id;
    	plan1.PackageCode__c = null;
    	update plan1;
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = null;//shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = null;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	//info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	// 旅行会社のコードを更新する
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c, Field310__r.Name from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    	System.assertEquals(leadRs[0].Field310__r.Name, info.PackagePlanName, leadRs);
    	
    }

    // 2016/07/04 TR機能改善対応
    @isTest(seeAllData=false) static void myUnitTest10_1() {
    	List<String> plusProducds = new list<string>{'90001','S0000','M90215','M90216'};
    	List<AccountMaster__c> accmsts =  TestCommon.createPayProductMst(plusProducds);
    	// 消費税の単価は１５０円設定
    	accmsts[0].Field5__c = 150;
    	accmsts[0].jmstRef__c= null;
    	accmsts[0].ServiceRate__c = 0;
    	accmsts[0].SpecialTax__c = 0;
    	update accmsts[0];
    	// 店舗情報
    	ShopInformation__c shop = TestCommon.createShopInfo();
    	shop.ShopCode__c = '02';
    	update shop;
    	
    	TypeOfRooms__c typeOfRoom = TestCommon.createTypeOfRoom();
    	typeOfRoom.RoomTypeCode__c = '9999901';
    	update typeOfRoom;
    	// プランを作成する
    	Plan__c basePlan = TestCommon.createPlan();
    	Plan__c childRenPlan1 = TestCommon.createPlan();
    	Plan__c childRenPlan2 = TestCommon.createPlan();
    	Plan__c childRenPlan3 = TestCommon.createPlan();
    	Plan__c childRenPlan4 = TestCommon.createPlan();
		childRenPlan1.PlanNo__c = '00000001';
		childRenPlan2.PlanNo__c = '00000002';
		childRenPlan3.PlanNo__c = '00000003';
		childRenPlan4.PlanNo__c = '00000004';
		list<Plan__c> childrenPlans = new list<Plan__c>();
		childrenPlans.add(childRenPlan1);
		childrenPlans.add(childRenPlan2);
		childrenPlans.add(childRenPlan3);
		childrenPlans.add(childRenPlan4);
		update childrenPlans;
    	// 
    	BI_TR_LeadInfoSync.BI_TR_SyncInfo info = createNormalSyncInfo ();
    	// テスト実施を行う
    	info.SalesOfficeCompanyCode = '60';
    	info.Payment = '精算不要(ｶｰﾄﾞ決済)';
		Test.startTest();
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		// XML変更処理
		info.CheckInTime = Time.newInstance(18, 0, 0, 0);
		info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.UPD;
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		// XMLキャンセル処理
		info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.CANCEL;
		rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
		
		Test.stopTest();
    }
    
    //bookingNumber is Blank
    static testMethod void myUnitTest11() {
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
        Account travel = TestCommon.createTravelCompany();
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = CommUtils.getRandom(10);
    	planItem.client__c = travel.Id;
    	update planItem;

        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        //info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = '1111';
        info.SystemDate = Date.today();
        info.SystemTime = Time.newInstance(10,11,23,0);
        info.AccommodationName = '􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚􏰀􏰁􏰄􏰅􏰆􏰇􏱹􏳌􏱚鉄道システム旅館';
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficeFaxNumber = '03-0211215';
        
        //　旅行会社
        info.TravelAgencyBookingNumber = '1111';
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);

        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;

        info.PackagePlanCode = planItem.packageCode__c;
        info.PackagePlanName = 'らくじゃんらくらくプラン';
        
        info.MealCondition = '他';
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.RoomRateOrPersonalRate = '人員単価';
        info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestEmail='yamaguchi@clips.co.jp';
        guest.GuestStateProvidence='新潟市中央区鐙西２－２９－１５　ピュアコートベル３Ｆ';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);
		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字';
        member.UserKana = '予約者・会員名カタカナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'');
		BI_TR_LeadInfoSync.BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        //System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TR_LeadInfoSync.BI_TR_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
        
    }
    
    
    // テスト用共通設定情報
    private static BI_TR_LeadInfoSync.BI_TR_SyncInfo createNormalSyncInfo () {
    	
    	//Plan__c planItem = TestCommon.createPlan();
    	//planItem.packageCode__c = COmmUtils.getRandom(10);
    	//update planItem;
    	String bookingNo = String.valueOf(Crypto.getRandomInteger());
    	
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.TravelAgencyBookingNumber = bookingNo;
        info.AccommodationName = '宿泊施設名_'+CommUtils.getRandom(10);
        info.AccommodationCode = CommUtils.getRandom(10);
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        //info.PackagePlanCode = planItem.packageCode__c;
        //info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 4;
        info.SpecialServiceRequest = 'メール本文処理を行う';
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 150300;
        info.TravelAgencyBookingDate = Date.today() + 4;
    	info.TaxServiceFee = 'IncludingServiceAndTax';
		info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 1;
        room.PerRoomPaxCount = 4;
        // RoomRate
        BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
        roomRate.RoomDate = info.CheckInDate;
        roomRate.PerPaxRate = 60000;
        roomRate.PerChildB50Rate = 60000;
        roomRate.PerChildA70Rate = 30000;
        roomRate.TotalPerlRoomHotSpringTax = 300;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';

        // BI_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		BI_TR_LeadInfoSync.BI_TR_MemberInfo member = new BI_TR_LeadInfoSync.BI_TR_MemberInfo();
		member.UserName = '予約者・会員名漢字 ';
		member.UserKana = '予約者・会員名カタカナ';
		member.UserTel = '(03)-12111021';
		member.UserMailAddr = 'test@xxxxunittest.com';
		member.UserZip = '111-01112';
		member.UserAddr = '予約者・会員住所';
		member.UserCorp = '予約者・会員会社';
		member.UserDep = '予約者・会員所属部署';
		member.UserID = '予約者・会員番号';
		//member.VIPcode = 'S1IVIP001';
		//member.UserGivingPoints = '付与ポイント';
		//member.UserUsePoints = '使用ポイント';
		//member.UserType = '会員種別';
		//member.UserDateOfBirth = '予約者生年月日';
		member.UserUsePoints = 500;
		member.TotalAccommodationDecleasePoints = 25000;
		//member.UserEmergencyPhoneNumber = '予約者緊急連絡先番号(携帯等)';
		//member.UserOfficePhone = '予約者勤務先電話番号';
		//member.UserCorpID = '予約者・会員会社コード';
		//member.UserCorpKana = '予約者・会員会社名カナ';
		info.member = member;
		
		createPlusConfig(info.AccommodationName,'02');
		return info;
    }
    
    public static void createPlusConfig(String AccommodationName, String shopCode){
    	// 90001: 入湯税、S0000：サビース料、M90215：割引ポイント、M90201：事前決済カード、
    	//List<String> productCodes = new List<string>{'90001','S0000'};
    	//AccountMaster__c products = TestCommon.createPayProductMst(productCodes);
    	delete [select id from document where DeveloperName = 'TRServiceConfigXml'];
		String configXml = '<root>'+
		'<COMMON>'+
		'<SHOPCODE_MATCH>'+
		' <RULE XMLSHOPNAME="'+AccommodationName+'">'+shopCode+'</RULE>'+
		'</SHOPCODE_MATCH>'+
		'</COMMON>'+
		' <SHOP>'+
		'<SHOPCODE>'+shopCode+'</SHOPCODE>'+
		'<APPCONFIG>'+
		'  <UCACTISSYNC>TRUE</UCACTISSYNC>'+
		'  <ROOMAUTOASSIGN>true</ROOMAUTOASSIGN>'+
		'  <ROOMSORT>ASC</ROOMSORT>'+
		'</APPCONFIG>'+
		'<ACCOUNTCONFIG>'+
		'  <NYUUTOUACCOUNT>90001</NYUUTOUACCOUNT>'+
		'  <SERVICEACCOUNT>S0000</SERVICEACCOUNT>'+
		'</ACCOUNTCONFIG>'+
		'<PLANCODE_CONVERT>'+
		'<AGT NAME="UT000S991旅行会社">'+
		'<CONVERT>'+
		'<AGTPACKAGECODE>3333,A268Q,A2681</AGTPACKAGECODE>'+
		'<SFPLANNO>00000001</SFPLANNO>'+
		'</CONVERT>'+
		'</AGT>'+
		'</PLANCODE_CONVERT>'+
		'<PAYMENT_CONVERTS>'+
		'<POINT_CONVERT PAYKBN="現地決済">'+
		'<CONVERT AGTCODE="60">M90215</CONVERT>'+
		'</POINT_CONVERT>'+
		'<POINT_CONVERT PAYKBN="精算不要(ｶｰﾄﾞ決済)">'+
		'<CONVERT AGTCODE="60">M90216</CONVERT>'+
		'</POINT_CONVERT>'+
		'<PAYMENT_CONVERT PAYKBN="カード決済">'+
        '<CONVERT AGTCODE="UT000S991">M90201</CONVERT>'+
   		'</PAYMENT_CONVERT>'+
		'</PAYMENT_CONVERTS>'+
		'<PRE_PAYMENT_DEF>'+
		'<CRAD>精算不要(ｶｰﾄﾞ決済)</CRAD>'+
		'<CREDIT>JTB事前決済_HR2,精算不要(ﾊﾟｯｹｰｼﾞ),精算不要(事後ｶｰﾄﾞ決済)</CREDIT>'+
		'</PRE_PAYMENT_DEF>'+
		'<CHILD_PLAN_CONVERT>'+
		' <MATCH RATE="70">00000001</MATCH>'+
		' <MATCH RATE="50">00000002</MATCH>'+
		' <MATCH RATE="30">00000003</MATCH>'+
		' <MATCH RATE="10">00000004</MATCH>'+
		'</CHILD_PLAN_CONVERT>'+
		'</SHOP>'+
		'</root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'TRServiceConfigXml';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	
    	TestCommon.createBillSimpleHelpConfigDoc();

        List<String> products = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
        List<AccountMaster__c> accMst = TestCommon.createPayProductMst(products);
    }
    
    private static void createCommonAcc(){
    	
        JMST__c taxMst =  TestCommon.createTaxMst();
        // 室単料　会計商品
        AccountMaster__c shitulyoItem = new AccountMaster__c(
           Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME,
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '100999',         // 商品コード
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert shitulyoItem;
        
        // 入湯料　会計商品
        AccountMaster__c nyuutouItem = new AccountMaster__c(
           Name = '入湯料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '5041',         // 商品コード
           Field5__c = 150,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert nyuutouItem;
        
        // サービス料　会計商品
        AccountMaster__c serviceItem = new AccountMaster__c(
           Name = 'サービス料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = 'S0000',         // 商品コード
           Field5__c = 1550,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert serviceItem;
        //createConfigBill();
    }
    private static void createConfigBill(){
    	Document BillSimpleHelpConfig = new Document();
        BillSimpleHelpConfig.Name = 'BillSimpleHelpConfig';
        BillSimpleHelpConfig.DeveloperName = BillSimpleHelpConfig.Name;
        BillSimpleHelpConfig.FolderId = UserInfo.getUserId();
        BillSimpleHelpConfig.Body = Blob.valueOf(getCsvSetupConfig());
        insert BillSimpleHelpConfig;

        List<String> products = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
        List<AccountMaster__c> accMst = TestCommon.createPayProductMst(products);
    }
    private static String getCsvSetupConfig() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP>'
                    + '</root>';
        return csv;
    }
	
	private static Plan__c createPlanHadHoomNoZero(){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11200;
    	plan.PackageCode__c = '3333';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 10000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 200;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 1000;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    }
    private static Plan__c createPlanHadHoomZero(String packageCode){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	if(CommUtils.isBlank(packageCode)) packageCode = '3333';
    	Plan__c plan = new Plan__c();
    	plan.name = 'テストプランデータ' + CommUtils.getRandom(5);
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11500;
    	plan.PackageCode__c = '3333';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 1000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 1500;
        planDeLst[1].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 0;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = productLst[3].Name;
        planDeLst[3].sobj.AccountMasterRef__c = productLst[3].Id;
        planDeLst[3].sobj.Price__c = 300;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[4].productNm = productLst[4].Name;
        planDeLst[4].sobj.AccountMasterRef__c = productLst[4].Id;
        planDeLst[4].sobj.Price__c = 500;
        planDeLst[4].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    } 
}