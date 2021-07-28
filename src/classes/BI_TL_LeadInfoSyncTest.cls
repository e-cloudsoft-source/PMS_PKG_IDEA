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
private class BI_TL_LeadInfoSyncTest {


    static testMethod void myUnitTest() {
    	
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = COmmUtils.getRandom(10);
    	update planItem;
    	
        BI_TL_LeadInfoSync.BI_TL_SyncInfo info = new BI_TL_LeadInfoSync.BI_TL_SyncInfo();
        info.dmlAction = BI_TL_LeadInfoSync.BI_TL_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = planItem.packageCode__c;
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
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo>();
        // RoomInfo
        BI_TL_LeadInfoSync.BI_TL_RoomsInfo room = new BI_TL_LeadInfoSync.BI_TL_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TL_LeadInfoSync.BI_TL_GuestInfo guest = new BI_TL_LeadInfoSync.BI_TL_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation roomRate = new BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo roomGuest = new BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TL_LeadInfoSync.BI_TL_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation>();
		roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		// メール電文
		BI_TL_LeadInfoSync.BI_TL_RisaplBasic basicInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplBasic();
		BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation risaplsInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation();
		BI_TL_LeadInfoSync.BI_TL_Risaplsinformation risapls = new BI_TL_LeadInfoSync.BI_TL_Risaplsinformation();
		basicInfo.TelegramData = 'メール本文処理を行う';
		basicInfo.SalesOfficeCompanyCode = info.SalesOfficeCompanyCode;
		risaplsInfo.risaplBasic = basicInfo;
		risapls.risaplsCommonInformation = risaplsInfo;
		info.risaplsinformation = risapls;

		BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TL_LeadInfoSync.BI_TL_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
		String orgDataId = info.DataID;
		// Update
     	info = new BI_TL_LeadInfoSync.BI_TL_SyncInfo();
        info.dmlAction = BI_TL_LeadInfoSync.BI_TL_DmlAction.UPD;
        info.DataFrom = 'TestDataFrom';
        info.DataID = orgDataId;
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
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo>();
        // RoomInfo
        room = new BI_TL_LeadInfoSync.BI_TL_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        guest = new BI_TL_LeadInfoSync.BI_TL_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		roomRate = new BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        roomGuest = new BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TL_LeadInfoSync.BI_TL_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation>();
		roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TL_LeadInfoSync.BI_TL_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        
    	info.DataFrom = info.DataFrom + '1';
		rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
		System.assert(rs.result == BI_TL_LeadInfoSync.BI_TL_Result.OK);
        System.assert(rs.sfdcId == null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
    }
    static testMethod void myUnitTest2() {
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = COmmUtils.getRandom(10);
    	update planItem;
    	
        BI_TL_LeadInfoSync.BI_TL_SyncInfo info = new BI_TL_LeadInfoSync.BI_TL_SyncInfo();
        info.dmlAction = BI_TL_LeadInfoSync.BI_TL_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        //info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = planItem.Name;
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
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo>();
        // RoomInfo
        BI_TL_LeadInfoSync.BI_TL_RoomsInfo room = new BI_TL_LeadInfoSync.BI_TL_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TL_LeadInfoSync.BI_TL_GuestInfo guest = new BI_TL_LeadInfoSync.BI_TL_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation roomRate = new BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo roomGuest = new BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TL_LeadInfoSync.BI_TL_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation>();
		roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		// メール電文
		BI_TL_LeadInfoSync.BI_TL_RisaplBasic basicInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplBasic();
		BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation risaplsInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation();
		BI_TL_LeadInfoSync.BI_TL_Risaplsinformation risapls = new BI_TL_LeadInfoSync.BI_TL_Risaplsinformation();
		basicInfo.TelegramData = 'メール本文処理を行う';
		basicInfo.SalesOfficeCompanyCode = info.SalesOfficeCompanyCode;
		risaplsInfo.risaplBasic = basicInfo;
		risapls.risaplsCommonInformation = risaplsInfo;
		info.risaplsinformation = risapls;

		BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TL_LeadInfoSync.BI_TL_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
    }
    static testMethod void myUnitTest3() {
        Account travel = TestCommon.createTravelCompany();
    	Plan__c planItem = TestCommon.createPlan();
    	planItem.packageCode__c = CommUtils.getRandom(10);
    	planItem.client__c = travel.Id;
    	update planItem;

        BI_TL_LeadInfoSync.BI_TL_SyncInfo info = new BI_TL_LeadInfoSync.BI_TL_SyncInfo();
        info.dmlAction = BI_TL_LeadInfoSync.BI_TL_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        //info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        //info.CheckOutTime = Time.newInstance(10, 25, 0, 0);
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = planItem.Name;
        //　旅行会社
        info.TravelAgencyBookingDate = Date.today();
        info.TravelAgencyBookingTime = Time.newInstance(0, 2, 0, 0);
        //info.SalesOfficeCompanyCode = travel.SalesOfficeCompanyCode__c;		// こちの設定がないはず
        info.SalesOfficeCompanyName = travel.Name;
        //info.SalesOfficeCode = 'SUB0001';
        //info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo>();
        // RoomInfo
        BI_TL_LeadInfoSync.BI_TL_RoomsInfo room = new BI_TL_LeadInfoSync.BI_TL_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TL_LeadInfoSync.BI_TL_GuestInfo guest = new BI_TL_LeadInfoSync.BI_TL_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation roomRate = new BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo roomGuest = new BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TL_LeadInfoSync.BI_TL_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation>();
		roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		// メール電文
		BI_TL_LeadInfoSync.BI_TL_RisaplBasic basicInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplBasic();
		BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation risaplsInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation();
		BI_TL_LeadInfoSync.BI_TL_Risaplsinformation risapls = new BI_TL_LeadInfoSync.BI_TL_Risaplsinformation();
		basicInfo.TelegramData = 'メール本文処理を行う';
		basicInfo.SalesOfficeCompanyCode = travel.SalesOfficeCompanyCode__c;
		risaplsInfo.risaplBasic = basicInfo;
		risapls.risaplsCommonInformation = risaplsInfo;
		info.risaplsinformation = risapls;

		BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);
        List<Lead__c> leadInfo = [select email__c from Lead__c where LeadIndexRef__c = :rs.sfdcId];
        System.assertEquals('メール本文処理を行う', leadInfo[0].email__c);
		System.assert(rs.result == BI_TL_LeadInfoSync.BI_TL_Result.OK);
        System.assert(rs.sfdcId != null);
        System.assert(String.isEmpty(rs.message));
        // 予約にプラン設定されている
        List<Lead__c> leads = [select id ,Field310__c from Lead__c limit 1];
        System.assertEquals(leads[0].Field310__c, planItem.Id);
        
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = CommUtils.getRandom(10);
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = CommUtils.getRandom(10);
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// プランコードの再設定
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	// AGT情報を再設定
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	String packageCode = CommUtils.getRandom(10);
    	String packageName = CommUtils.getRandom(10);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	//info.PackagePlanName = packageName;
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	//info.PackagePlanCode = packageCode;
    	info.PackagePlanName = packageName;
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, null, leadRs); // 新規プラン自動作成
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs); 
    	System.assertNotEquals(leadRs[0].Field310__c, plan2.Id, leadRs); 
    	List<Plan__c> existPlans = [select id,ShopInfoRef__c from plan__c where PackageCode__c = null And  Name = :packageName And ShopInfoRef__c = :shop.Id And client__c = :travleComp.Id];
    	System.assertEquals(existPlans.size(), 1, existPlans);
    	System.assertEquals(existPlans[0].ShopInfoRef__c, shop.Id, existPlans); 
    }

	// 店舗あり場合[店舗別プラン機能が展開する場合][AGT対応なし+PACKCODE]「店舗コードがマスタに存在」
    @isTest(seeAllData=false) static void myUnitTest8_4() {
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
    	travleComp.SalesOfficeCompanyCode__c = CommUtils.getRandom(10);
    	travleComp.SalesOfficeCode__c = CommUtils.getRandom(10);
    	update travleComp;
    	// この後、中継アプリ情報を設定する
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.shopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = plan2.Name;
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = CommUtils.getRandom(10);
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = plan2.Name;
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = CommUtils.getRandom(10);
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = CommUtils.getRandom(10);
    	info.PackagePlanName = packageName;
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCode = null;
    	info.SalesOfficeName = null;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = null;//shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = packageCode;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	// 旅行会社のコードを更新する
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
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
    	BI_TL_LeadInfoSync.BI_TL_SyncInfo info = createNormalSyncInfo();
    	// 店舗コード再設定
    	info.AccommodationCode = null;//shop.ShopCode__c;
    	// AGT情報を再設定
    	// プランコードを作成する
    	info.PackagePlanCode = null;
    	info.PackagePlanName = CommUtils.getRandom(10);
    	//info.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	info.SalesOfficeCompanyName = travleComp.Name;
    	info.risaplsinformation.risaplsCommonInformation.risaplBasic.SalesOfficeCompanyCode = travleComp.SalesOfficeCompanyCode__c;
    	// 旅行会社のコードを更新する
    	info.SalesOfficeCode = travleComp.SalesOfficeCode__c;
    	info.SalesOfficeName = travleComp.Name;
    	// 情報をSF側へ送信する
    	BI_TL_LeadInfoSync.BI_TL_SyncResult rs = BI_TL_LeadInfoSync.upsertLeadInfo(info);
    	// 作成した予約データのプランはPlan1で設定を行う
    	List<Lead__c> leadRs = [select id, Field310__c, Field310__r.Name from lead__c limit 1];
    	System.assert(!leadRs.isEmpty());
    	System.assertNotEquals(leadRs[0].Field310__c, plan1.Id, leadRs);
    	System.assertEquals(leadRs[0].Field310__r.Name, info.PackagePlanName, leadRs);
    	
	}	
    // テスト用共通設定情報
    private static BI_TL_LeadInfoSync.BI_TL_SyncInfo createNormalSyncInfo () {
    	
    	//Plan__c planItem = TestCommon.createPlan();
    	//planItem.packageCode__c = COmmUtils.getRandom(10);
    	//update planItem;
    	
        BI_TL_LeadInfoSync.BI_TL_SyncInfo info = new BI_TL_LeadInfoSync.BI_TL_SyncInfo();
        info.dmlAction = BI_TL_LeadInfoSync.BI_TL_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
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
        info.GrandTotalPaxCount = 3;
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.TravelAgencyBookingDate = Date.today() + 4;
		info.roomAndGuestLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo>();
        // RoomInfo
        BI_TL_LeadInfoSync.BI_TL_RoomsInfo room = new BI_TL_LeadInfoSync.BI_TL_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TL_LeadInfoSync.BI_TL_GuestInfo guest = new BI_TL_LeadInfoSync.BI_TL_GuestInfo();
        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
		// GuestRate
		BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation roomRate = new BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation();
		roomRate.RoomDate = Date.today();

        // BI_RoomAndGuestInfo
        BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo roomGuest = new BI_TL_LeadInfoSync.BI_TL_RoomAndGuestInfo();

		roomGuest.room = room;
		roomGuest.guestLst = new List<BI_TL_LeadInfoSync.BI_TL_GuestInfo>();
		roomGuest.guestLst.add(guest);
		roomGuest.roomRateLst = new List<BI_TL_LeadInfoSync.BI_TL_RoomRateInfomation>();
		roomGuest.roomRateLst.add(roomRate);

		info.roomAndGuestLst.add(roomGuest);

		// メール電文
		BI_TL_LeadInfoSync.BI_TL_RisaplBasic basicInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplBasic();
		BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation risaplsInfo = new BI_TL_LeadInfoSync.BI_TL_RisaplsCommonInformation();
		BI_TL_LeadInfoSync.BI_TL_Risaplsinformation risapls = new BI_TL_LeadInfoSync.BI_TL_Risaplsinformation();
		basicInfo.TelegramData = 'メール本文処理を行う';
		basicInfo.SalesOfficeCompanyCode = info.SalesOfficeCompanyCode;
		BI_TL_LeadInfoSync.BI_TL_Member member = new BI_TL_LeadInfoSync.BI_TL_Member();
		member.UserName = '予約者・会員名漢字 ';
		member.UserKana = '予約者・会員名カタカナ';
		member.UserTel = '予約者・会員電話番号';
		member.UserMailAddr = '予約者・会員Email';
		member.UserZip = '予約者・会員郵便番号';
		member.UserAddr = '予約者・会員住所';
		member.UserCorp = '予約者・会員会社';
		member.UserDep = '予約者・会員所属部署';
		member.UserID = '予約者・会員番号';
		member.UserGivingPoints = '付与ポイント';
		member.UserUsePoints = '使用ポイント';
		member.UserType = '会員種別';
		member.UserDateOfBirth = '予約者生年月日';
		member.UserGendar = '予約者性別';
		member.UserEmergencyPhoneNumber = '予約者緊急連絡先番号(携帯等)';
		member.UserOfficePhone = '予約者勤務先電話番号';
		member.UserCorpID = '予約者・会員会社コード';
		member.UserCorpKana = '予約者・会員会社名カナ';
		risaplsInfo.risaplBasic = basicInfo;
		risaplsInfo.member = member;
		risapls.risaplsCommonInformation = risaplsInfo;
		info.risaplsinformation = risapls;
		return info;
    }
}