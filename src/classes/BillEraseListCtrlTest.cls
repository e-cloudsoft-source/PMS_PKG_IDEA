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
private class BillEraseListCtrlTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
		CommDefine__c newDef = new CommDefine__c(
			BillEraseMediaTypeCode__c = '02,03'
		);	
		insert newDef;
        // 2019/11/30 BY zyz BEGIN
        getCsvSetupConfig();
        // 2019/11/30 BY zyz END
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        ExchangeRate__c rate = TestCommon.createExchangeRate();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        BookingEstimateItem__c bookingItem = TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMst.PaymentType__c = '売掛金';  // XMLの定義と合わせるが必要です
        update accMst;
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
        Test.startTest();
    	DateTime preMonthDate = Date.today().addMonths(-1);
    	String dtStr = DateTime.newInstance(preMonthDate.Year(),preMonthDate.month(),preMonthDate.day()).format('yyyyMMdd');
        list<RsvAccount__c> rsv = [select Id,Name from RsvAccount__c where Name =: dtStr]; 
        if(rsv.isEmpty()) rsv.add(new RsvAccount__c(Name=dtStr));
    	upsert rsv;
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
        AccountAcount__c accObj = accObjLst[0];
        TTend__c ttitem = TestCommon.createTTend(rsv[0].Id, accObj.Id); 
        ttitem.field2__c = '03'; 
        ttitem.field3__c = '掛計';
        ttitem.RowNo__c  = 44;  // メディア種別,メディア名称
        ttitem.Field20__c = '1000';// 単価,枚数,支払金額 
        update ttitem;
        map<String,String> diffmap = new map<String,String>{ ttitem.id=>'2019/04/24 16:39'};
        map<String,String> flgmap = new map<String,String>{ ttitem.id=>'true'};
        map<String,String> RepMap = new map<String,String>{ ttitem.id=>'2019/04/24'};
        list<id> ttidlst= new list<id>{ttitem.id};
        Map<String,object> req = new Map<String,object>{'ttends'=>ttidlst,'bdt'=>'2019/04/20','edt'=>'2019/04/24','bcheck'=>'true','diffFlgMap'=>flgmap,
                                                            'diffTTendMap'=>diffmap,'tspcd'=>'','diffRepMap'=>RepMap,
                                                                    'diffPayMap' => new Map<String,String>{ttitem.id=>'123'},'diffComMap'=> new Map<String,String>{ttitem.id=>'666'}};
        
        BillEraseListCtrl ctrl = new BillEraseListCtrl();
        ctrl.saveValStr = JSON.serialize(req);
        ctrl.getTTend();
        ctrl.saveTTend();
        Test.stopTest();    
    }
    // 2019/11/30 BY zyz BEGIN
    private static void getCsvSetupConfig() {
    String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><FILTERABLE>true</FILTERABLE><FIELDS><SECTION COLNUM="2">Field66__c,Field70__c,$_blank_$,relaccount__r.Phone</SECTION></FIELDS><REQUIREDFIELDS>Field137__c,AccountLanguage__c,relaccount__r.phone,TaxRate__c</REQUIREDFIELDS><LABEL>Field66__c:男性</LABEL><STYLECLASS>Field137__c:k-textbox</STYLECLASS><EXUTEFIELD>relaccount__r.gender__c</EXUTEFIELD><COLNUMSIZE>Relcontact__c:180px,Name:180px,Field137__c:150px</COLNUMSIZE></SHOP><SHOP><SHOPCODE>02</SHOPCODE><FILTERABLE>false</FILTERABLE><FIELDS><SECTION COLNUM="2"></SECTION></FIELDS></SHOP></root>';
    Document doc = new Document();
    doc.Name = 'BillSimpleInputField';
    doc.DeveloperName = doc.Name;
    doc.FolderId = UserInfo.getUserId();
    doc.Body = Blob.valueOf(csv);
    insert doc;
    }
    // 2019/11/30 BY zyz END
}