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
private class BatchRackRateSetupTest {

    static testMethod void myUnitTest() {
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	List<CollaborationGroup> groups = TestCommon.createGroups(4);
    	comDef.ChatterGroupName__c = '9:'+groups[0].name + ';';
    	update comDef;
    	//groups[0].name = 'TL2WAY連携管理グループ2';
        // TO DO: implement unit test
        List<TypeOfRooms__c> TypeOfRooms1 = TestCommon.createTypeOfRoomByShop(null, 5);
        String tier = 'tier1';
        String peoples = '2';
        Decimal price = 10000;
        Integer days = 5;
        // CREATE RACKRATE
        TestCommon.createRaceRateMst(TypeOfRooms1[0].Id, tier, peoples, price);
        TestCommon.createRaceRateMst(TypeOfRooms1[0].Id, 'Tier3', peoples, price);
        TestCommon.createRaceRateDetail(tier, peoples, days);
        insert new List<RackRateTableDetail__c>{
        								new RackRateTableDetail__c(Tier__c = 'Tier5',PriceSetupDate__c = system.today().addDays(10),
        									RoomTypeRef__c = TypeOfRooms1[1].id,SearchKey__c = '_' + system.today().addDays(10) + '_' + TypeOfRooms1[1].id),
        								new RackRateTableDetail__c(Tier__c = 'Tier1',PriceSetupDate__c = system.today().addDays(5),
        									RoomTypeRef__c = TypeOfRooms1[2].id,SearchKey__c = '_' + system.today().addDays(5) + '_' + TypeOfRooms1[2].id)};
        createConfigDoc();
        TypeOfRooms1[0].Seq__c = 3211;
        TypeOfRooms1[0].MaxRooms__c = 1;
        TypeOfRooms1[1].Seq__c = 70;
        TypeOfRooms1[1].MaxRooms__c = 1;
        TypeOfRooms1[2].Seq__c = 1001;
        TypeOfRooms1[2].MaxRooms__c = 3;
        TypeOfRooms1[3].Seq__c = 3000;
        TypeOfRooms1[3].MaxRooms__c = 3;
        TypeOfRooms1[4].Seq__c = 10105111;
        TypeOfRooms1[4].MaxRooms__c = 5;
        update TypeOfRooms1;
		Test.startTest();
		//Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
    	BatchRackRateSetup m = new BatchRackRateSetup();
		String sch = getScheduleTime();
    	System.schedule('RackRate' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' , sch, m);
        Test.stopTest();
    }
    private static void createConfigDoc() {
        //String configXml = '<?xml version="1.0" encoding="utf-8"?><root>    <COMMON>        <BATCHSIZE>20</BATCHSIZE><!-- バッチサイズ -->        <TARGETMONTH>12</TARGETMONTH><!--処理対象期間（月) -->    </COMMON>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <Rule>            <RuleItem>                <RoomTypeSeq>3211,70</RoomTypeSeq>                <RemainedMinRooms>1</RemainedMinRooms>                <RemainedMaxRooms>1</RemainedMaxRooms>                <RemainedMinDays>10</RemainedMinDays>                <RemainedMaxDays>10</RemainedMaxDays>                <Tier>Tier2</Tier>            </RuleItem>           <RuleItem> <RoomTypeSeq>1001</RoomTypeSeq> <RemainedMinRooms>1</RemainedMinRooms><RemainedMaxRooms>20</RemainedMaxRooms> <RemainedMinDays>3</RemainedMinDays> <RemainedMaxDays>5</RemainedMaxDays> <Tier>Tier28</Tier></RuleItem>      </Rule>        <TierColor Color="">            <Tier Key="Tier1,Tier2">red</Tier>            <Tier Key="Tier3,Tier4">blue</Tier>        </TierColor>    </SHOP></root>';
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root>    <COMMON>        <BATCHSIZE>20</BATCHSIZE><!-- バッチサイズ -->        <TARGETMONTH>12</TARGETMONTH><!--処理対象期間（月) -->    </COMMON>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <Rule>        <RuleItem><RoomTypeSeq>3211,70</RoomTypeSeq><RemainedMinRooms>5</RemainedMinRooms><RemainedMaxRooms>10</RemainedMaxRooms><RemainedMinDays>10</RemainedMinDays><RemainedMaxDays>15</RemainedMaxDays><Tier>Tier29</Tier></RuleItem><RuleItem><RoomTypeSeq>10105111,10106222</RoomTypeSeq><RemainedMinRooms>5</RemainedMinRooms><RemainedMaxRooms>10</RemainedMaxRooms><RemainedMinDays></RemainedMinDays><RemainedMaxDays></RemainedMaxDays><Tier>Tier30</Tier></RuleItem> <RuleItem><RoomTypeSeq>1001,3000</RoomTypeSeq><RemainedMinRooms>1</RemainedMinRooms><RemainedMaxRooms>20</RemainedMaxRooms><RemainedMinDays>3</RemainedMinDays><RemainedMaxDays>5</RemainedMaxDays><Tier>Tier28</Tier></RuleItem>     </Rule>        <TierColor Color="">            <Tier Key="Tier1,Tier2">red</Tier>            <Tier Key="Tier3,Tier4">blue</Tier>        </TierColor>    </SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'TierAutoSetupConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
	}
	
	private static String getScheduleTime() {
    	DateTime nowTime = DateTime.now().addSeconds(10);
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
		       ms + ' ' +
		       hh + ' ' +
		       dd + ' ' +
		       mm + ' ' +
		       ' ? ' + yy;
		return sch;
    }
}