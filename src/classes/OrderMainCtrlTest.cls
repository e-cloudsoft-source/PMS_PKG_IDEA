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
private class OrderMainCtrlTest {

    static testMethod void myUnitTest() {
        User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
    	insertDom();
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		seq__c = 101001,
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = TestCommon.createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		Datetime startDt = system.now();
		Lead__c lead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
    	   name = '予約単体テスト_宴会場' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDt,
    	   Field4__c = '00:00',
    	   Departure__c = startDt.addDays(1),
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = item.id);
    	insert lead;
    	lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	//TestCommon.createAccountAcount();
    	
    	List<AccountMaster__c> accs = insertProd(new List<String>{'0000000112506','0000000112104','0000000121103'},new List<String>{'SF)かに丼','SF)幼児朝食','EF)宴会料理（０３０）'});
        // TO DO: implement unit test
        OrderMainCtrl o = new OrderMainCtrl();
        o.initAction();
        o.changeEnLanguage();
        o.changeJpLanguage();
        o.localIp = '192.168.10.104';
        o.initFun();
        String orderMessage = accs[0].id + ':1,' + accs[1].id + ':1' ;
        //OrderMainCtrl.ProcessResult r = OrderMainCtrl.processOrder( orderMessage,String.valueOf(item.id),'',o.localIp);
    	//List<Tran1__c> transLst = [select id,Field21__c from Tran1__c];
    	//System.assertEquals(transLst.size(),r.prodObj.size());
    	//OrderMainCtrl.cancelTran(String.valueOf(transLst[0].id));
    	//OrderMainCtrl.getBeginStmp(String.valueOf(item.id),'');
    }
    static testMethod void myUnitTest001() {
     	User loginUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        loginUser.ShopCode__c = null;
        update loginUser;
        
    	insertDom();
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		seq__c = 101001,
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = TestCommon.createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		Datetime startDt = system.now();
		Lead__c lead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
    	   name = '予約単体テスト_宴会場' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDt,
    	   Field4__c = '00:00',
    	   Departure__c = startDt.addDays(1),
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = item.id);
    	insert lead;
    	lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	//TestCommon.createAccountAcount();
    	
    	List<AccountMaster__c> accs = insertProd(new List<String>{'0000000112506','0000000112104','0000000121103'},new List<String>{'SF)かに丼','SF)幼児朝食','EF)宴会料理（０３０）'});
        // TO DO: implement unit test
        OrderMainCtrl o = new OrderMainCtrl();
        o.initAction();
        o.initFun();
        o.changelayout();
        //o.
        o.changeCurrentRoom();
        o.oShopCode = '02';
        o.chgShopCodeFun();
        String accId = '';
        for (List<Id> roomIds : o.floatRoomLst.getRoomIds()) {
        	for (Id roomId : roomIds) {
	        	if ( o.mainRoomMap.containsKey(roomId) ) {
	        		accId = o.mainRoomMap.get(roomId).accId;
	        		break;
	        	}
        	}
        }
       	Map<String,Object> oMap = new Map<String,Object>{'accId'=>accId };
        o.reqJson = JSON.serialize(new List<Object>{oMap});
        o.accountDomain();
        oMap = new Map<String,Object>{'accId'=>accId };
        // 带商品保存
        List<Map<String,Object>> prodInfo = new List<Map<String,Object>>();
       	for (AccountMaster__c acc : accs) {
       		prodInfo.add(
       			new Map<String,Object>{'qty'=>2,'prodId'=>acc.id,'pos'=>'POS02'}
       		);
       	}
       	oMap.put('prods',prodInfo);
       	oMap.put('sequene','2');
       	oMap.put('leadId',lead.id);
        o.reqJson = JSON.serialize(oMap);
        o.localIp = '192.168.1.101';
        o.roomId = item.id;
        o.processOrderDomain();
        oMap = new Map<String,Object>();
        oMap.put('accId',accId);
        o.reqJson = JSON.serialize(oMap);
        OrderMainCtrl.getTransDetail(o.reqJson);
    }
    @isTest(SeeAllData=true)
    static void remoteTest001() {
     	OrderMainCtrl.savePrintLodToDb('test');
     	Map<String,String> jsonRequst = new Map<String,String>{
     		'queryDate' => system.today().format(),
     		'localIp' => '192.168.1.101',
     		'processType' =>'mitumori'
     	};
     	String curJson = JSON.serialize(jsonRequst);
     	insertDom();
     	OrderMainCtrl.ProcessResult result = OrderMainCtrl.getOneDayCook(curJson);
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		seq__c = 101001,
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = TestCommon.createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		Datetime startDt = system.now();
		Lead__c lead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
    	   name = '予約単体テスト_宴会場' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDt,
    	   Field4__c = '00:00',
    	   Departure__c = startDt.addDays(1),
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = item.id);
    	insert lead;
    	OrderServiceHelp.getAllCustomMap(new List<Id>{lead.id},'abc:field310__c',true);
        OrderServiceHelp.CustomInfo info = new OrderServiceHelp.CustomInfo();
    }
    static testMethod void remoteTest002(){
    	insertDom();
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		seq__c = 101001,
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = TestCommon.createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		Datetime startDt = system.now();
		Lead__c lead = new Lead__c(
    	   RecordTypeId = CommLogicProcess.getLeadEnkaiRecType(),
    	   name = '予約単体テスト_宴会場' + System.now(), // 予約名
    	   Relcontact__c = TestCommon.createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDt,
    	   Field4__c = startDt.format('HH:mm'),
    	   Departure__c = startDt.addDays(1),
    	   Field3__c = '16:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   comment3__c ='アレルギー:なし\\n',
    	   Rroom__c = item.id);
    	insert lead;
    	lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
    	List<AccountMaster__c> accs = insertProd(new List<String>{'0000000112506','0000000112104','0000000121103'},new List<String>{'SF)かに丼','SF)幼児朝食','EF)宴会料理（０３０）'});
    	String orderMessage = '';
        for (AccountMaster__c acc : accs) {
        	orderMessage += acc.id + ':1,' ;
       	}
        OrderMainCtrl.ProcessResult res = OrderMainCtrl.processOrder(orderMessage,CommUtils.nullToBlank(item.id),'','192.168.10.104','',true);
		List<Tran1__c> tranLst = [select id,Field21__c from Tran1__c];
		List<OrderEntryInfo__c> infos = [select id from OrderEntryInfo__c ];
		String orderId = infos.isEmpty() ? '' : infos[0].id;
       if (!tranLst.isEmpty()) String tranId = OrderMainCtrl.cancelTran(tranLst[0].id,JSON.serialize(new Map<String,String>{'spcd' => '','orderId'=>orderId}));
        res = OrderMainCtrl.getBeginStmp('',null);
	}
	
    static testMethod void remoteTest003(){
    	insertDom();
    	Room__c item = new Room__c(
    		Name = '部屋テスト' + CommUtils.getRandom(6),
    		CapacityHaku__c = 4,
    		Capacity__c = 2,
    		Area__c = '本館',
    		Floor__c = '1F',
    		UseOfRoom__c = '客室',
    		seq__c = 101001,
    		heyadashiryouryou__c = 40000,
    		TypeRoomRef__c = TestCommon.createTypeOfRoom().Id,
    		heyadashiryou__c = 25000);
		insert item;
		Datetime startDt = system.now();
		
		Map<String,Object> o = new Map<String,Object>{'queryDate'=>startDt.format(),'shopCd'=>'','accFlg'=>true,'orderSort'=>'','order'=>''};
		OrderMainCtrl.remoteCenter('printHistory',JSON.serialize(o));
		OrderMainCtrl.remoteCenter('rePrintOrder',JSON.serialize(o));
		o.put('orderIds' ,new List<String>{item.id});
		OrderMainCtrl.remoteCenter('createLeadByRooms',JSON.serialize(o));
		OrderMainCtrl orderMain = new OrderMainCtrl();
        orderMain.initAction();
	}
	static testMethod void remoteTest004(){
		insertDom();
		TypeOfRooms__c typeRoom = TestCommon.createTypeOfRoom();
		List<Room__c> rooms = TestCommon.createRooms(2,typeRoom.id);
		Datetime startDt = system.now();
		Map<String,Object> o = new Map<String,Object>{'queryDate'=>startDt.date().format(),'shopCd'=>'','localIp' => '192.168.10.104'};
		o.put('orderIds' ,new List<String>{rooms[0].id});
		OrderMainCtrl.remoteCenter('createLeadByRooms',JSON.serialize(o));
		Object obj = OrderMainCtrl.remoteCenter('getCuurentLeads',JSON.serialize(o));
		List<Map<String,object>> objs = (List<Map<String,object>>)obj;
		o.put('leadId' ,objs[0].get('id'));
		o.put('orderIds' ,new List<String>{rooms[1].id});
		OrderMainCtrl.remoteCenter('createLeadByRooms',JSON.serialize(o));
	}
    private static List<AccountMaster__c> insertProd(List<String> prodLst,List<String> nameLst){
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	for (integer i = 0 ; i < prodLst.size() ; i++){
    		AccountMaster__c item = new AccountMaster__c(
	           Name = nameLst[i],
	           jmstRef__c = taxMst.Id,
	           StsTaxfee__c = '0',
	           Field3__c = prodLst[i],         // 商品コード
			   Field5__c = 1050,
			   Field7__c = 500,
	           ServiceRate__c = 10,
	           SpecialTax__c = 100
	        );
	        insLst.add(item);
    	}
        insert insLst;
        return insLst;
    }
    private static void insertDom(){
    	/*
    	String domString = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>	<CAMPAIGN> <URL>http://www.jinya-inn.com/databox/data.php/topics_furusto_bridal_ja/code</URL> <MESSAGE> 本格的な和婚や、心のこもった家族婚の結婚式を挙げたいカップルにご好評いただいている陣屋の結婚式 陣屋では結婚式でも「ふるさと納税」をご利用いただけます。 うまく組み合わせていただければ、実質2,000円で結婚式ができる陣屋のふるさと納税の活用術をご紹介します。 お嬢様、お孫様へのプレゼントにも最適です。 </MESSAGE> <IMGNAME>WorkFileForCampaign</IMGNAME> </CAMPAIGN>	<!-- 店舗コード -->		<LOGOIMG>https://c.cs31.content.force.com/servlet/rtaImage?eid=a0Tp0000000YzX7&feoid=00Np0000000hzrc&refid=0EMp00000004IGZ		</LOGOIMG>		<PRINTCONFIG><PRINT>localhost</PRINT><PRINTPORT>9999</PRINTPORT><STATUS>localhost</STATUS><STATUSPORT>9999</STATUSPORT>	<LAYOUT> <ORDER>table_reciept2</ORDER>	 <ACCOUNT>retail_reciept2</ACCOUNT> <SIMPLEACCOUNT>retail_reciept2</SIMPLEACCOUNT> <DOOROPENSEQ>kick_drawer</DOOROPENSEQ> </LAYOUT>	</PRINTCONFIG>		<LAYOUT><MAXCOLS>3</MAXCOLS>	<!-- 最大列数 --><BTNSTYLE>width:124px;height:30px;</BTNSTYLE><TABLEWIDTH>420</TABLEWIDTH><TABLEHEIGHT>280</TABLEHEIGHT>		</LAYOUT>		<DEVICECONFIG><DEVICE>	<LOCAL>192.168.10.104</LOCAL>	<ROOMSEQ>101001</ROOMSEQ></DEVICE><DEVICE>	<LOCAL>192.168.1.101</LOCAL>	<ROOMSEQ>1318</ROOMSEQ></DEVICE>		</DEVICECONFIG>		<BUTTONTAB><TABLABEL>●会席料理</TABLABEL><PRODUCT ISBLANK="FALSE">	<LABEL>SF)かに丼</LABEL>	<PRODCODE>0000000112506</PRODCODE>	<ICONURL></ICONURL>	</PRODUCT>		    <PRODUCT ISBLANK="FALSE">		<LABEL>SF)幼児朝食</LABEL>		<PRODCODE>0000000112104</PRODCODE>		<ICONURL>/resource/OrderLib/images/75/shake.jpg</ICONURL></PRODUCT><PRODUCT ISBLANK="FALSE">		<LABEL>EF)宴会料理（０３０）</LABEL>		<PRODCODE>0000000121103</PRODCODE>		<ICONURL>/resource/OrderLib/images/75/miso-soup.jpg</ICONURL></PRODUCT>		</BUTTONTAB>	</SHOP></root>';
    	Document item = new Document();
    	item.Name = 'OrderProductConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;*/
    	TestCommon.createOrderConfigXml(); 
    }
}