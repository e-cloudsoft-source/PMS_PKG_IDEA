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
private class ExpoAreaMstSettingCtrlTest {

    static testMethod void myUnitTest() {
        // 商品作成
        List<AccountMaster__c> accMstLst = TestCommon.createFullProductMst(1);
        Id accMstId = accMstLst[0].Id;
        // Data Create
        createMstData(accMstId);
        // 明細呼び出しする
        ApexPages.StandardController contrl = new ApexPages.StandardController(accMstLst[0]);
        ExpoAreaMstSettingCtrl ctrl = new ExpoAreaMstSettingCtrl(contrl);
		ctrl.init();
		ctrl.queryExpoAreaMstData();
		//
		list<String> accIdlst = new list<String>();
		accIdlst.add(accMstId);
		ExpoAccountMasterUndeleteCtrl ctrl1 = new ExpoAccountMasterUndeleteCtrl();
		delete accMstLst[0];
		ctrl1.init();
		ctrl1.initAct();
		ExpoAccountMasterUndeleteCtrl.recovery(accIdlst);
    }
    // 
    
    private static void createMstData(String accMstId) {
    	String[] s = new String[]{
    		'A,01,010006, , ',
    		'A,01,011002,札幌市, ',
    		'A,01,011025,函館市, ',
    		'B,02,022012,青森市, ',
    		'B,02,022021,弘前市, ',
    		'C,13,131016,千代田区,23区',
    		'C,13,131024,中央区,23区',
    		'C,13,132012,八王子市, '
    	};
    	
    	list<ExpoAreaMst__c> inslst = new list<ExpoAreaMst__c>();
    	map<String, Set<String>> wkSelectCityCdMap = new map<String, Set<String>>();
    	for (String a : s) {
    		String[] csvArr = a.split(',');
			ExpoAreaMst__c mst = new ExpoAreaMst__c(
				AreaLst__c = CommUtils.nullToBlank(csvArr[0]),
				StateLst__c = CommUtils.nullToBlank(csvArr[1]),
				CityCode__c = CommUtils.nullToBlank(csvArr[2]),
				City__c = CommUtils.nullToBlank(csvArr[3]),
				CityAll__c = CommUtils.nullToBlank(csvArr[4])
			);
			// KEYを設定する
			mst.Name = mst.AreaLst__c + '_' + mst.StateLst__c + '_' + mst.CityCode__c;
			String selectCityStr = mst.AreaLst__c + '_' + mst.StateLst__c;
			
			if(!wkSelectCityCdMap.containsKey(selectCityStr)) wkSelectCityCdMap.put(selectCityStr, new Set<String>());
			wkSelectCityCdMap.get(selectCityStr).add(mst.CityCode__c);
			
    		inslst.add(mst);
    	}
    	insert inslst;
    	
    	ExpoAreaMstSettingCtrl.updateAreaToAccMst(JSON.serialize(wkSelectCityCdMap), accMstId, 'true');
    	ExpoAreaMstSettingCtrl.updateAreaToAccMst(JSON.serialize(wkSelectCityCdMap), accMstId, 'false');
    	ExpoAreaMstSettingCtrl.updateAreaToAccMst(JSON.serialize(new map<String, Set<String>>()), accMstId, 'false');
    }
}