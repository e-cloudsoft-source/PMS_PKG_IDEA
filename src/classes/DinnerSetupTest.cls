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
private class DinnerSetupTest {

    static testMethod void myUnitTest() {
    	List<AccountMaster__c> masters = TestCommon.createProductMst(4);
    	AccountMaster__c master = masters[0];
    	List<FoodDetail__c> foods = createFoodDetail(master.id);
        // TO DO: implement unit test
        DinnerSetupCtrl diner = new DinnerSetupCtrl(new ApexPages.StandardController(master));
        diner.initKaiseki();
        Map<String,Object> resMap = new Map<String,Object>();
        resMap.put('spcd','');
        createBillProd();
    	// 会計商品項目更新
        DinnerSetupCtrl.remoteCenter('getProds',JSON.serialize(resMap));
        Map<String,Object> objMap = new Map<String,Object>{
        	'name' => masters[2].name,
	    	'cooktype' => 'お凌ぎ'
        };
        resMap = new Map<String,Object>{'spcd' => '','materials' => '小麦粉;糖類','allergys' => 'えび;そば','pro' => 2.1,'prodid' => master.id,
        								'cooks' => new List<Object>{objMap},'deleteids' => new List<String>{foods[2].id}};
        DinnerSetupCtrl.remoteCenter('updCookDetail',JSON.serialize(resMap));
        Date startDt = system.today();
        Date endDt = startDt.addDays(5);
        Set<String> weekOptsSet = new Set<String>{'Monday','Saturday'};
        DinnerSetupCtrl.remoteCenter('updateOpts',JSON.serialize(new Map<String,Object>{'start' => startDt.format(),'endDt'=> endDt.format(),'opts' =>weekOptsSet,'shops' =>'','prodid' => master.id}));
        diner.initKaiseki();
    }
    static testMethod void myUniteTest01(){
    	List<AccountMaster__c> testLst = TestCommon.createProductMst(50);
    	insertFoods(testLst, 200);
    	Test.startTest();
    	ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(testLst);
    	ctrl.setSelected(testLst);
    	DinnerPDFCtrl fmdc = new DinnerPDFCtrl(ctrl);
    	fmdc.initPdf();
    	Test.stopTest();
    	
    }
    
    static void insertFoods(List<AccountMaster__c> lst, Integer n){
    	List<FoodDetail__c> lst3 = new List<FoodDetail__c>();
    	List<String> lst2 = new List<String>{'先付', 'お凌ぎ', 'お椀', '向付', '焼き物', '炊き合わせ', 'ご飯'};
    	for(Integer i = 0; i < n; i++){
    		lst3.add(new FoodDetail__c(
    			BreakName__c = 'キャンセル料金_'+CommUtils.getRandom(10),
    			DetailType__c = lst2.get(random(lst2.size())),
    			AccountMasterRef__c = lst.get(random(lst.size())).id
    			
    		));	
    	}
    	insert lst3;
    }
    static Integer random(Integer max){
    	return Integer.valueOf(Math.random() * max);
    }
    public static List<FoodDetail__c> createFoodDetail(String accId) {
    	List<String> statusLst = new List<String>{'先付','お凌ぎ','お椀','向付','八寸'};
    	List<FoodDetail__c> foods = new List<FoodDetail__c>();
    	List<AccountMaster__c> masters = TestCommon.createProductMst(5);
    	for (integer i = 0 ; i < statusLst.size() ; i++) {
    		FoodDetail__c food = new FoodDetail__c();
    		String status = statusLst[i];
    		food.AccountMasterRef__c = accId;
    		food.DetailType__c = status;
    		food.BreakName__c = masters[i].name;
    		food.AccountMasterSubRef__c = masters[i].id;
			foods.add(food);
    	}
    	insert foods;
    	return foods;
    }
    private static void createBillProd(){
    	Document BillProductMenuConfig = new Document();
		BillProductMenuConfig.Name = 'BillSimpleProductConfig';
		BillProductMenuConfig.DeveloperName = BillProductMenuConfig.Name;
    	BillProductMenuConfig.FolderId = UserInfo.getUserId();
    	BillProductMenuConfig.Body = Blob.valueOf(getCsvSetupConfig());
    	insert BillProductMenuConfig;
    }
	private static String getCsvSetupConfig() {
    	String csv = '<root><SHOP><SHOPCODE></SHOPCODE><TABLEWIDTH>100%</TABLEWIDTH><TABLEHEIGHT>240px</TABLEHEIGHT><TABGROUP><TABLABEL>A1_料理</TABLABEL><LAYOUT><BTNWORDLEN>9</BTNWORDLEN><BTNSTYLE>width:115px;height:30px</BTNSTYLE></LAYOUT><PRODUCT><CODE>0001</CODE><NAME>みえて</NAME></PRODUCT><PRODUCT><CODE>0002</CODE><NAME>検討中</NAME></PRODUCT><PRODUCT><CODE>1025</CODE><NAME>婚礼カスタマイズ会席</NAME></PRODUCT></TABGROUP><TABGROUP><TABLABEL>B1_ドリンク</TABLABEL><LAYOUT><BTNWORDLEN>9</BTNWORDLEN>	ボタンに最大表示文字数<BTNSTYLE>width:115px;height:30px</BTNSTYLE> ボタンに最大表示文字数</LAYOUT><PRODUCT><CODE>20164</CODE><NAME>菊勇 300ml</NAME></PRODUCT><PRODUCT><CODE>20163</CODE><NAME>菊勇 150ml</NAME></PRODUCT><PRODUCT><CODE>20380</CODE><NAME>バルディピエソ ブリュット(スパークリング)</NAME></PRODUCT></TABGROUP></SHOP>'
					+ '</root>';
    	return csv;
	}
}