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
private class LeadTriggerProcessTest {

	// 標準画面から作成したの予約データに対して、予約データの到着日、出発日を変更する場合、関連の予約INDEXも自動連動変更を行う
	static testMethod void tranCase_1_1() {
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	Lead__c newLeadInfo = [select SfRegisteredFlg__c, LeadIndexRef__c from lead__c where Id =: leadInfo.Id];
    	System.assert(newLeadInfo.SfRegisteredFlg__c);
    	// 予約の日付を更新を行う
    	leadInfo.EntryTime__c = leadInfo.EntryTime__c.addDays(3);
    	leadInfo.Departure__c = leadInfo.Departure__c.addDays(3);
    	leadInfo.field4__c = '05:00';
    	leadInfo.field3__c = '23:00';
    	update leadInfo;
    	
    	LeadIndex__c leadIdx = [select EntryDate__c, EntryTime__c,DepartureDate__c,DepartureTime__c from LeadIndex__c where id = :newLeadInfo.LeadIndexRef__c ];
    	System.assertEquals(leadInfo.EntryTime__c.date(), leadIdx.EntryDate__c);
    	System.assertEquals(leadInfo.Departure__c.date(), leadIdx.DepartureDate__c);
    	//System.assertEquals(leadInfo.field4__c, leadIdx.EntryTime__c);
    	//System.assertEquals(leadInfo.field3__c, leadIdx.DepartureTime__c);
	}
	// 予約データのステータスを変更する場合、期間対応を行う
    static testMethod void tranCase_1_2() {
    	TestCommon.createTl2WayConfigDoc();
    	createConfigDoc();
    	TypeOfRooms__c roomType = TestCommon.createTypeOfRoom();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 予約
        ctl.contactName = 'GUESTNAME' + CommUtils.getRandom(10);
        ctl.newContact.Katakana__c = CommUtils.getRandom(10);
        ctl.newLead.name = 'LEADNAME' + CommUtils.getRandom(10);
        ctl.newLead.Field2__c = 'テストセル';
        ctl.roomType = roomType.Id;
        ctl.staysNums = 2;
        ctl.newLead.StayPersons__c = 2;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 1;
        ctl.newLead.ExtraBedChk__c = true;
        // 予約作成
        ctl.bookingCreate();
        
System.assertEquals(ApexPages.hasMessages(),false, ApexPages.getMessages());
//System.debug(LoggingLevel.ERROR,[select EntryDate__c, EntryTime__c,Nights__c, DepartureDate__c,DepartureTime__c,ParentLeadIndxRef__c from LeadIndex__c]);
		test.startTest();
		// 予約データの中に、１件データはキャンセル処理を行う
		LeadIndex__c baseIdx = [select EntryDate__c, EntryTime__c,Nights__c, DepartureDate__c,DepartureTime__c from LeadIndex__c where ParentLeadIndxRef__c = null  limit 1 ];
		LeadIndex__c subIdx =  [select EntryDate__c, EntryTime__c,Nights__c, DepartureDate__c,DepartureTime__c from LeadIndex__c where ParentLeadIndxRef__c != null  limit 1 ];
		
		System.assertEquals(baseIdx.EntryDate__c, Date.today());		
		System.assertEquals(baseIdx.Nights__c, ctl.staysNums);
		// 一件データキャンセル更新を行う
		Lead__c cancelLead = [select id, ReservedStatus__c from lead__c limit 1];
		cancelLead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
		update cancelLead;
		
		baseIdx = [select EntryDate__c, EntryTime__c,Nights__c, DepartureDate__c,DepartureTime__c from LeadIndex__c where ParentLeadIndxRef__c = null  limit 1 ];
		subIdx =  [select EntryDate__c, EntryTime__c,Nights__c, DepartureDate__c,DepartureTime__c from LeadIndex__c where ParentLeadIndxRef__c != null  limit 1 ];
		System.assertEquals(baseIdx.Nights__c, ctl.staysNums-1);
		System.assertEquals(subIdx.Nights__c, ctl.staysNums-1);
		
		test.stopTest();
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
}