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
private class RoomStatusManagerTest {
    static testMethod void myUnitTest() {
        TestCommon.createTl2WayConfigDoc();
        Room__c room = TestCommon.createRooms();
        createConfigDoc();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Room__c].size(), 1);
		// 2015/12/01 Assert END
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 予約
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.roomType = room.TypeRoomRef__c;
        ctl.staysNums = 1;
        ctl.newLead.StayPersons__c = 2;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 1;
        ctl.newLead.ExtraBedChk__c = true;
        // 予約作成
        ctl.bookingCreate();
        
        List<Lead__c> leads = [select id, Rroom__c, Field298__c from lead__c limit 10];
        for (Lead__c lead : leads) {
        	lead.Rroom__c = room.Id;
        }
        update leads;
        
        Date day = Date.today();
		RoomStatusManager manager = new RoomStatusManager();
		manager.createNoCleanRooms(day,leads );
		manager.createNoCleanRooms(leads );
		manager.queryBadRoomSet(Date.today(), Date.today());
		Map<Id, String> maps = manager.getCleanStatusRooms(day);
		
		Set<Id> roomIdset = new Set<Id>();
		roomIdset.add(room.Id);
		manager.upClearnStatus(day, roomIdset);
	}
    static testMethod void myUnitTest01() {
        TestCommon.createTl2WayConfigDoc();
        Room__c room = TestCommon.createRooms();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Room__c].size(), 1);
        
        //清掃管理データ自動作成_
        RoomsStatus__c roomsStatus = new RoomsStatus__c( Name = 'statusName',
                         RoomRef__c = room.id , Status__c = CommConst.ROOM_ST_TYPE_BED,
                         StatusBeginDate__c = System.today().addDays(-5),StatusEndDate__c = System.today().addDays(1));
        insert roomsStatus;
        RoomStatusManager.updBadRoomStatus(new Set<String>{room.id},new Set<Date>{System.today()});
        System.assertEquals([select Id from RoomsStatus__c].size(), 2);
        RoomStatusManager.updBadRoomStatus(new Set<String>{room.id},new Set<Date>{System.today().addDays(1)});
        System.assertEquals([select Id from RoomsStatus__c].size(), 2);
        System.assertEquals([select Id from RoomsStatus__c where Result__c = :CommConst.ROOM_ST_TYPE_BED_FIN].size(), 1);
        delete [select Id from RoomsStatus__c where Result__c = :CommConst.ROOM_ST_TYPE_BED_FIN];
        RoomStatusManager.updBadRoomStatus(new Set<String>{room.id},new Set<Date>{System.today().addDays(-5)});
        System.assertEquals([select Id from RoomsStatus__c].size(), 1);
        RoomStatusManager.updBadRoomStatus(new Set<String>{room.id},new Set<Date>{System.today().addDays(-4),System.today().addDays(-3),System.today().addDays(-2),System.today().addDays(-1)});
        System.assertEquals([select Id from RoomsStatus__c where Result__c = :CommConst.ROOM_ST_TYPE_BED_FIN].size(), 1);
    }
    static testMethod void myUnitTest02(){
        createCleanDoc();
        CommDefine__c def = TestCommon.createCommDefine();
        Lead__c lead = TestCommon.createLead();
        List<TypeOfRooms__c> typeRooms = [select id,seq__c from TypeOfRooms__c where id = :lead.refTypeOfRooms__c];
        typeRooms[0].seq__c = 123;
        update typeRooms[0];
        def.AutoCancelBadRoom__c = '123:1';
        update def;
        lead.Field298__c = 'チェックイン完';
    	update lead;
        insert new RoomsStatus__c(
        //清掃管理データ自動作成_
            Name = Label.CONST_012_0496 + system.today().format(),
            RoomRef__c = lead.Rroom__c,
            Status__c = CommConst.ROOM_ST_TYPE_CLS,
            StatusBeginDate__c = system.today(),
            StatusEndDate__c = system.today(),
            Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN);
        (new RoomStatusManager()).createNoCleanRooms([select id,checkoutdate__c,Rroom__c from lead__c where id = :lead.id]);
        RoomStatusManager.getCleanStatusLst(system.today(),new Set<String>{lead.rroom__c},new List<String>{'RoomRef__r.name'});
        RoomStatusManager.groupCleanStatusRoomMap(new Set<String>{lead.rroom__c},null);
    }
	private static void createConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="utf-8"?><root>    <COMMON>        <BATCHSIZE>20</BATCHSIZE><!-- バッチサイズ -->        <TARGETMONTH>12</TARGETMONTH><!--処理対象期間（月) -->    </COMMON>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <Rule>            <RuleItem>                <RoomTypeSeq>3211,70</RoomTypeSeq>                <RemainedMinRooms>1</RemainedMinRooms>                <RemainedMaxRooms>1</RemainedMaxRooms>                <RemainedMinDays>10</RemainedMinDays>                <RemainedMaxDays>10</RemainedMaxDays>                <Tier>Tier2</Tier>            </RuleItem>            <RuleItem>                <RoomTypeSeq>B001</RoomTypeSeq>                <RemainedMinRooms>0</RemainedMinRooms>                <RemainedMaxRooms>4</RemainedMaxRooms>                <RemainedMinDays>2</RemainedMinDays>                <RemainedMaxDays>9</RemainedMaxDays>                <Tier>Tier1</Tier>            </RuleItem>        </Rule>        <TierColor Color="">            <Tier Key="Tier1,Tier2">red</Tier>            <Tier Key="Tier3,Tier4">blue</Tier>        </TierColor>    </SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'TierAutoSetupConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
	}
    private static void createCleanDoc(){
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP>	<SHOPCODE></SHOPCODE>	<COMPLETESTATUS>インスペ完</COMPLETESTATUS>	<COLORCONFIG>		<STATUS COLOR="darkcyan">未清掃</STATUS>		<STATUS COLOR="#00ccff">清掃中</STATUS>		<STATUS COLOR="darkgreen">清掃完了インスペ未完</STATUS>		<STATUS COLOR="royalblue">インスペ中</STATUS>		<STATUS COLOR="gray">インスペ完</STATUS>	</COLORCONFIG>		<CHECKCONFIG>		<CHECKLIST>			<STATUS>インスペ中</STATUS>			<NEXTSTATUS>インスペ完</NEXTSTATUS>			<FIELDS>				CheckItem1__c,CheckItem2__c,CheckItem3__c,CheckItem4__c,CheckItem5__c				,CheckItem6__c,CheckItem7__c,CheckItem8__c,CheckItem9__c,CheckItem10__c				,CheckItem11__c,CheckItem12__c,CheckItem13__c,CheckItem14__c,CheckItem15__c				,CheckItem16__c,CheckItem17__c,CheckItem18__c,CheckItem19__c,CheckItem20__c				,CheckItem21__c,CheckItem22__c,CheckItem23__c,CheckItem24__c,CheckItem25__c				,CheckItem26__c,CheckItem27__c,CheckItem28__c,CheckItem29__c,CheckItem30__c				,CheckItem31__c,CheckItem32__c,CheckItem33__c			</FIELDS>		</CHECKLIST>	</CHECKCONFIG></SHOP>  </root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'CleanRoomConfig';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
    }
}