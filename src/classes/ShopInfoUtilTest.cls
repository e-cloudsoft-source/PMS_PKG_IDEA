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
private class ShopInfoUtilTest {
	// 店舗コード設定の確認
	// 支店情報がない場合
    static testMethod void Case1() {
    	ShopInformation__c shopInfo = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    		,ColorRSRoomAssigned__c = 'darkcyan'
    		,ColorRSRoomChkOutDay__c = 'darkmagenta'
    		,ColorRSRoomChkOut__c = 'darkorange'
    		,ColorRSRoomNoClean__c = 'deepskyblue'
    		,ColorRSRoomBad__c = 'gray'
    		,ColorRSRoomStay__c = 'darkgoldenrod'
    	);
    	insert shopInfo;
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select EnglishTaxLabel__c from CommDefine__c];
        String englishLabel = ShopInfoUtil.getTaxEnglishLabel(null);
        List<SelectOption> branchShop = ShopInfoUtil.getBranchShopLst(null);
        Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap(null);
        List<ShopInformation__c> branchShopInfLst = ShopInfoUtil.getBranchShopInfLst(null);
        Boolean serviceCharge = ShopInfoUtil.isShowServiceCharge(null);
        String serviceChargeMode = ShopInfoUtil.getShowServiceChargeMode(null);
        ShopInfoUtil.Color statusColor = ShopInfoUtil.getStatusColor(shopInfo.shopCode__c); 
        System.assert(!CommUtils.isBlank(englishLabel));
        System.assertEquals(englishLabel, def.EnglishTaxLabel__c);
    }
    // 支店情報あり、該当支店に文言が未設定する場合
    static testMethod void Case2() {
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select EnglishTaxLabel__c from CommDefine__c];
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
        shopInfo.EnglishTaxLabel__c = null;
    	shopInfo.ShopCode__c = '02';
        update shopInfo;
        Test.startTest();
        String englishLabel = ShopInfoUtil.getTaxEnglishLabel(shopInfo.ShopCode__c);
		String serviceChargeMode = ShopInfoUtil.getShowServiceChargeMode(shopInfo.ShopCode__c);
		Boolean serviceCharge = ShopInfoUtil.isShowServiceCharge(shopInfo.shopCode__c);
		ShopInfoUtil.Color statusColor = ShopInfoUtil.getStatusColor(null);
        System.assert(!CommUtils.isBlank(englishLabel));
        System.assertEquals(englishLabel, def.EnglishTaxLabel__c);
        Test.stopTest();
    }
    // 支店情報あり、該当支店に文言が設定する場合[ABC]
    static testMethod void Case3() {
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select EnglishTaxLabel__c from CommDefine__c];
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
        String taxStr = 'ABC'+CommUtils.getRandom(10);
        shopInfo.EnglishTaxLabel__c = taxStr;
    	shopInfo.ShopCode__c = '02';
        update shopInfo;
        Test.startTest();
        String englishLabel = ShopInfoUtil.getTaxEnglishLabel(shopInfo.ShopCode__c);
        String serviceChargeMode = ShopInfoUtil.getShowServiceChargeMode(shopInfo.ShopCode__c);
        Boolean serviceCharge = ShopInfoUtil.isShowServiceCharge(shopInfo.shopCode__c);
        System.assert(!CommUtils.isBlank(englishLabel));
        System.assertEquals(englishLabel, taxStr);
        Test.stopTest();
    }
    // 支店情報あり、指定の支店コードは支店情報に未登録する場合
    static testMethod void Case4() {
    	
        // カスタム設定情報により、支店情報コードがNULLの場合、カスタム設定から取得する
        TestCommon.createCommDefine();
        CommDefine__c def = [select EnglishTaxLabel__c from CommDefine__c];
        ShopInformation__c shopInfo = TestCommon.createShopInfo();
        String taxStr = 'ABC'+CommUtils.getRandom(10);
        shopInfo.EnglishTaxLabel__c = taxStr;
    	shopInfo.ShopCode__c = '02';
        update shopInfo;
        Test.startTest();
        String englishLabel = ShopInfoUtil.getTaxEnglishLabel(CommUtils.getRandom(5));
        String serviceChargeMode = ShopInfoUtil.getShowServiceChargeMode(CommUtils.getRandom(10));
        Boolean serviceCharge = ShopInfoUtil.isShowServiceCharge(CommUtils.getRandom(10));
        System.assert(!CommUtils.isBlank(englishLabel));
        System.assertEquals(englishLabel, def.EnglishTaxLabel__c);
        User usr = [select ShopCode__c from User where id = :Userinfo.getUserId()];
        usr.ShopCode__c = shopInfo.ShopCode__c;
        System.runAs(usr) {
        	String facCode = ShopInfoUtil.getShopFacilityCode(usr.ShopCode__c);
        	List<String> canSelectShopLst = ShopInfoUtil.getCanSelectShopLst(usr.id);
        	System.assertEquals(facCode, shopInfo.FacilityCode__c);	
        }
        Test.stopTest();
    }
    // 店舗リスト一覧
    static testMethod void Case5() {
    	// 
    	ShopInformation__c shopInfo = TestCommon.createShopInfo();
    	ShopInformation__c shopInfo2 = TestCommon.createShopInfo();
    	String[] shopCds = new String[]{shopInfo.ShopCode__c,shopInfo2.ShopCode__c};
    	List<SelectOption> rs1 = ShopInfoUtil.getBranchShopLst(shopCds);
    	Map<String,ShopInformation__c> rs2 = ShopInfoUtil.getShopInfoMap(shopCds);
    	List<ShopInformation__c> rs3 = ShopInfoUtil.getBranchShopInfLst(shopCds);
    	System.assertEquals(rs1.size(),2,rs1);
    	System.assertEquals(rs2.size(),2,rs2);
    	System.assertEquals(rs3.size(),2,rs3);
    }
    // 店舗別カスタマイズ定義情報機能確認
    static testMethod void Case6() {
        /*
        public Boolean isDefaultFlg{get;private set;}
        public Integer defStayNums{get;private set;}               // デフォルト値泊数
        public Time defCheckInTime{get;private set;}
        public Time defCheckOtTime{get;private set;}
        public string defCheckInTimeStr{get;private set;}          // 到着時刻
        public string defCheckOtTimeStr{get;private set;}          // 出発時刻
        public string defDayUseCheckInTimeStr{get; private set;}   // DAYUSEのデフォルト到着時刻
        public string defDayUseCheckOtTimeStr{get; private set;}   // DAYUSEのデフォルト出発時刻
        */
        TestCommon.createCommDefine();
        CommDefine__c def = [select ShopLeadDefaultInfo__c from CommDefine__c];
        def.ShopLeadDefaultInfo__c = '01,02&1,17:30,09:30;03,04&0,13:10,15:30;$1,17:00,06:00';
        update def;
        //
        String shopCd = '01';
        ShopInfoUtil.ShopLeadInfo rs = ShopInfoUtil.getShopDefInfo(shopCd);
        System.assertEquals(rs.defStayNums, 1, rs);
        System.assertEquals(rs.defCheckInTimeStr, '17:30', rs);
        System.assertEquals(rs.defCheckOtTimeStr, '09:30', rs);
        System.assertEquals(rs.defDayUseCheckInTimeStr, CommConst.DEF_DAYUSE_CHECKIN_TIME, rs);
        System.assertEquals(rs.defDayUseCheckOtTimeStr, getTimeStr(CommConst.DEF_DAYUSE_CHECKIN_TIME, CommConst.DEF_DAYUSE_STAY_HOURS), rs);
        
        shopCd = '03';
        rs = ShopInfoUtil.getShopDefInfo(shopCd);
        System.assertEquals(rs.defStayNums, 0, rs);
        System.assertEquals(rs.isDefaultFlg, false, rs);
        System.assertEquals(rs.defCheckInTimeStr, '13:10', rs);
        System.assertEquals(rs.defCheckOtTimeStr, '15:30', rs);
        System.assertEquals(rs.defDayUseCheckInTimeStr, '13:10', rs);
        System.assertEquals(rs.defDayUseCheckOtTimeStr, '15:30', rs);
    
        shopCd = '05';
        rs = ShopInfoUtil.getShopDefInfo(shopCd);
        System.assertEquals(rs.defStayNums, 1, rs);
        System.assertEquals(rs.isDefaultFlg, true, rs);
        System.assertEquals(rs.defCheckInTimeStr, CommConst.DEF_CHECKIN_TIME, rs);
        System.assertEquals(rs.defCheckOtTimeStr, CommConst.DEF_CHECKOT_TIME, rs);
        System.assertEquals(rs.defDayUseCheckInTimeStr, CommConst.DEF_DAYUSE_CHECKIN_TIME, rs);
        System.assertEquals(rs.defDayUseCheckOtTimeStr, getTimeStr(CommConst.DEF_DAYUSE_CHECKIN_TIME, CommConst.DEF_DAYUSE_STAY_HOURS), rs);
        /*
        shopCd = '';
        rs = ShopInfoUtil.getShopDefInfo(shopCd);
        System.assertEquals(rs.defStayNums, 1, rs);
        System.assertEquals(rs.defCheckInTimeStr, '17:00', rs);
        System.assertEquals(rs.defCheckOtTimeStr, '06:00', rs);
        System.assertEquals(rs.defDayUseCheckInTimeStr, CommConst.DEF_DAYUSE_CHECKIN_TIME, rs);
        System.assertEquals(rs.defDayUseCheckOtTimeStr, getTimeStr(CommConst.DEF_DAYUSE_CHECKIN_TIME, CommConst.DEF_DAYUSE_STAY_HOURS), rs);
   		*/
        
    }
    private static String getTimeStr(String timeStr, Integer hours) {
      return (DateTime.newinstance(Date.today(), CommUtils.stringToTime(timeStr)).addHours(hours)).format('HH:mm');
    }
}