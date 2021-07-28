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
private class BI_LeadInfoSyncTest {

    static testMethod void myUnitTest() {
        BI_LeadInfoSync.BI_SyncInfo info = new BI_LeadInfoSync.BI_SyncInfo();
        info.dmlAction = BI_LeadInfoSync.BI_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
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
        info.GrandTotalPaxCount = 3;
        info.TravelAgencyBookingNumber = 'F2112333';
        info.OtherServiceInformation = '禁煙必要';
        //info.TotalAccommodationCharge = 145000;
        
        BI_LeadInfoSync.BI_BasicRateInformation basicRate = new BI_LeadInfoSync.BI_BasicRateInformation();
        basicRate.RoomRateOrPersonalRate = 'RoomRate';
        basicRate.TaxServiceFee = 'IncludingServiceAndTax';
        //basicRate.Payment = '事前決済';
        basicRate.TotalAccommodationCharge = 145000;
        info.basicRateInfo = basicRate;
        
		info.roomAndGuestLst = new List<BI_LeadInfoSync.BI_RoomAndGuestInfo>();
        // RoomInfo
        BI_LeadInfoSync.BI_RoomsInfo room = new BI_LeadInfoSync.BI_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        //Member
        BI_LeadInfoSync.BI_MemberInfo member = new BI_LeadInfoSync.BI_MemberInfo();
		member.UserKana = 'ﾊｾｶﾞﾜ ﾏｻﾄ';
		member.UserTel = '0424-88-5936';
		member.UserMailAddr = 'hayashi.n@seanuts.co.jp';
		//member.UserCorp = '';
		member.UserUsePoints = 123;
		member.AmountClaimed = 33;
		info.member = member;
        // Guest
        BI_LeadInfoSync.BI_GuestInfo guest = new BI_LeadInfoSync.BI_GuestInfo();

        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';

        // BI_RoomAndGuestInfo
        BI_LeadInfoSync.BI_RoomAndGuestInfo roomGuest = new BI_LeadInfoSync.BI_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_LeadInfoSync.BI_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomDateLst = new List<Date>();
		roomGuest.roomDateLst.add(Date.today());

		info.roomAndGuestLst.add(roomGuest);

		BI_LeadInfoSync.BI_SyncResult rs = BI_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs != null);
		System.assert(rs.result == BI_LeadInfoSync.BI_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
		String orgDataId = info.DataID;
		// Update
        info = new BI_LeadInfoSync.BI_SyncInfo();
        info.dmlAction = BI_LeadInfoSync.BI_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
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
        info.OtherServiceInformation = '禁煙必要';
        //info.TotalAccommodationCharge = 145000;
        
        //BI_BasicRateInformation basicRate = new BI_BasicRateInformation();
        basicRate.RoomRateOrPersonalRate = 'PersonalRate';
        basicRate.TaxServiceFee = 'IncludingServiceAndTax';
        //basicRate.Payment = '事前決済';
        basicRate.TotalAccommodationCharge = 145000;
        info.basicRateInfo = basicRate;
        
        
		info.roomAndGuestLst = new List<BI_LeadInfoSync.BI_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_LeadInfoSync.BI_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_LeadInfoSync.BI_GuestInfo();

        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';

        // BI_RoomAndGuestInfo
        roomGuest = new BI_LeadInfoSync.BI_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_LeadInfoSync.BI_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomDateLst = new List<Date>();
		roomGuest.roomDateLst.add(Date.today());

		info.roomAndGuestLst.add(roomGuest);
		
		rs = BI_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_LeadInfoSync.BI_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
    
    	info.DataFrom = info.DataFrom + '1';
		rs = BI_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_LeadInfoSync.BI_Result.OK);
        System.assert(rs.sfdcId == null);
        System.assert(String.isEmpty(rs.message));
    }
    static testMethod void myUnitTest2() {
        BI_LeadInfoSync.BI_SyncInfo info = new BI_LeadInfoSync.BI_SyncInfo();
        info.dmlAction = BI_LeadInfoSync.BI_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        //info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        info.SpecialServiceRequest = 'ZZ2014-01-07 大人:9980円×1＝9980円 夕食:選択なし朝食:選択なし,ZZ2014-01-08 大人:9980円×1＝9980円 夕食:選択なし朝食:選択なし,ZZ2014-01-09 大人:9980円×1＝9980円 夕食:選択なし朝食:選択なし';
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
        info.GrandTotalPaxCount = 3;
        info.OtherServiceInformation = '禁煙必要';
        //info.TotalAccommodationCharge = 145000;
        
        BI_LeadInfoSync.BI_BasicRateInformation basicRate = new BI_LeadInfoSync.BI_BasicRateInformation();
        basicRate.RoomRateOrPersonalRate = 'RoomRate';
        basicRate.TaxServiceFee = 'IncludingServiceAndTax';
        //basicRate.Payment = '事前決済';
        basicRate.TotalAccommodationCharge = 145000;
        info.basicRateInfo = basicRate;

		info.roomAndGuestLst = new List<BI_LeadInfoSync.BI_RoomAndGuestInfo>();
        // RoomInfo
        BI_LeadInfoSync.BI_RoomsInfo room = new BI_LeadInfoSync.BI_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_LeadInfoSync.BI_GuestInfo guest = new BI_LeadInfoSync.BI_GuestInfo();

        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';

        // BI_RoomAndGuestInfo
        BI_LeadInfoSync.BI_RoomAndGuestInfo roomGuest = new BI_LeadInfoSync.BI_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_LeadInfoSync.BI_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomDateLst = new List<Date>();
		roomGuest.roomDateLst.add(Date.today());

		info.roomAndGuestLst.add(roomGuest);

		BI_LeadInfoSync.BI_SyncResult rs = BI_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs != null);
		System.assert(rs.result == BI_LeadInfoSync.BI_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
    }
}