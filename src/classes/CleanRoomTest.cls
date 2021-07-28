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
private class CleanRoomTest {

    static testMethod void myUnitTest() {
    	Date todayDt = System.today();
    	List<Lead__c> leads = TestCommon.createLead(todayDt,3,2);
    	String roomId = leads[0].Rroom__c;
    	RoomsStatus__c rs = new RoomsStatus__c(roomRef__c = roomId,
    											Status__c = CommConst.ROOM_ST_TYPE_CLS,
    											Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN,
    											StatusBeginDate__c = todayDt,
    											StatusEndDate__c = todayDt);
        // TO DO: implement unit test
        CleanRoomCtrl ctrl = new CleanRoomCtrl();
        ctrl.init();
        Map<String,object> reqMap = new  Map<String,object>{'roomids' => new List<String>{roomId},'status'=>'清掃中'};
        CleanRoomCtrl.remoteQueryInfo('upsertCleanDetail',JSON.serialize(reqMap));
        reqMap = new  Map<String,object>{'spcd' => '','cleanOver'=>true};
        CleanRoomCtrl.remoteQueryInfo('saveCookieSetinfo',JSON.serialize(reqMap));
        reqMap = new  Map<String,object>{'roomids' => new List<String>{roomId}};
        CleanRoomCtrl.remoteQueryInfo('refreshCleanDetail',JSON.serialize(reqMap));
    }
    static testMethod void myUniteTest01(){
    	createDocument();
    	Date todayDt = System.today();
    	List<Lead__c> leads = TestCommon.createLead(todayDt,3,2);
    	String roomId = leads[0].Rroom__c;
    	RoomsStatus__c rs = new RoomsStatus__c(roomRef__c = roomId,
    											Status__c = CommConst.ROOM_ST_TYPE_CLS,
    											Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN,
    											StatusBeginDate__c = todayDt,
    											StatusEndDate__c = todayDt);
        // TO DO: implement unit test
        CleanRoomCtrl ctrl = new CleanRoomCtrl();
         Map<String,object> reqMap = new  Map<String,object>{'roomids' => new List<String>{roomId},'status'=>'インスペ完'};
        CleanRoomCtrl.remoteQueryInfo('upsertCleanDetail',JSON.serialize(reqMap));
    }
    // 2019/04/15 BY zyz BEGIN
    static testMethod void myUniteTest02(){
    	createDocument();
        CommDefine__c def = TestCommon.createCommDefine();
   		def.IsNoCleanKeepFlag__c = true;
    	update def;
    	
    	Date todayDt = System.today();
    	List<Lead__c> leads = TestCommon.createLead(todayDt,3,2);
    	String roomId = leads[0].Rroom__c;
    	RoomsStatus__c rs = new RoomsStatus__c(roomRef__c = roomId,
    											Status__c = CommConst.ROOM_ST_TYPE_CLS,
    											Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN,
    											StatusBeginDate__c = todayDt,
    											StatusEndDate__c = todayDt);
    	insert rs;
        // TO DO: implement unit test
        CleanRoomCtrl ctrl = new CleanRoomCtrl();
        ctrl.gotoDate();
        Map<String,object> reqMap = new  Map<String,object>{'roomids' => new List<String>{roomId},'status'=>'インスペ完'};
        CleanRoomCtrl.remoteQueryInfo('upsertCleanDetail',JSON.serialize(reqMap));
        CleanRoomCtrl.remoteQueryInfo('getChkInfo',JSON.serialize(reqMap));
    }
    // 2019/04/15 BY zyz END
    static void createDocument(){
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><ROOT>    <SHOP>        <SHOPCODE></SHOPCODE>        <COMPLETESTATUS>インスペ完</COMPLETESTATUS>        <COLORCONFIG>        	<STATUS COLOR="pink">未清掃</STATUS>        </COLORCONFIG>        <CHATERCONFIG>        	<STATUS GROUP="TL2WAY連携管理グループ2" MESSAGE="@room @status対応します">未清掃,清掃完了インスペ未完,インスペ中</STATUS>        </CHATERCONFIG><CHECKCONFIG><CHECKLIST><STATUS>インスペ中</STATUS><NEXTSTATUS>インスペ完</NEXTSTATUS><FIELDS>CheckItem1__c,CheckItem2__c,CheckItem3__c,CheckItem4__c,CheckItem5__c</FIELDS></CHECKLIST></CHECKCONFIG></SHOP>    </ROOT>';
    	Document item = new Document();
    	item.Name = 'CleanRoomConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    }
}