@isTest
private class BillSimpleHelpTest {
    static testMethod void case01() {
        Document BillSimpleHelpConfig = new Document();
        BillSimpleHelpConfig.Name = 'BillSimpleHelpConfig';
        BillSimpleHelpConfig.DeveloperName = BillSimpleHelpConfig.Name;
        BillSimpleHelpConfig.FolderId = UserInfo.getUserId();
        BillSimpleHelpConfig.Body = Blob.valueOf(getCsvSetupConfig());
        insert BillSimpleHelpConfig;

        Date dt = Date.today();
        String bShopCode = 'T001';
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        List<Lead__c> leadLst = TestCommon.createLead(dt, 3, 3);
        List<AccountMaster__c> amLst = TestCommon.createProductMst(100);
        List<AccountAcount__c> aaLst = new List<AccountAcount__c>();
        List<TTend__c> ttLst = new List<TTend__c>();
        List<Id> ttId = new List<Id>();
        for (Lead__c ls:leadLst ) {
            AccountAcount__c aa = TestCommon.createAccountAcount(rsv.Id, ls.Id);
            TTend__c tt = TestCommon.createTTend(rsv.Id, aa.id);
            aaLst.add(aa);
            ttLst.add(tt);
            ttId.add(tt.Id);
        }
        Test.startTest();
        BillSimpleHelp bsh = new BillSimpleHelp(bShopCode);
        BillSimpleHelp.autoCalTTendInfo(ttId);
        Map<String, AccountMaster__c> map1 = bsh.getMediaLabToAccMstMap();
        Map<String, String> map2 = bsh.getPaymentTypeToMediaLabMap();

        Test.stopTest();
        
        System.assert(!BillSimpleHelp.isRefundItem(''));
        System.assert(BillSimpleHelp.getRefundItemStr()!=null);

    }
    static testMethod void case02() {
        Document BillSimpleHelpConfig = new Document();
        BillSimpleHelpConfig.Name = 'BillSimpleHelpConfig';
        BillSimpleHelpConfig.DeveloperName = BillSimpleHelpConfig.Name;
        BillSimpleHelpConfig.FolderId = UserInfo.getUserId();
        BillSimpleHelpConfig.Body = Blob.valueOf(getCsvSetupConfig());
        insert BillSimpleHelpConfig;
        
        System.assert(!BillSimpleHelp.isRefundItem('A'));
        String[] a = BillSimpleHelp.getRefundItemStr();
        System.assertEquals(BillSimpleHelp.getMediaCodeByLeadMediaType('カード')[0], CommConst.MEDIA_TYPE_CD_02);
        System.assertEquals(BillSimpleHelp.getMediaCodeByLeadMediaType('売掛')[0], CommConst.MEDIA_TYPE_CD_03);
        System.assertEquals(BillSimpleHelp.getMediaCodeByLeadMediaType('クーポン')[0], CommConst.MEDIA_TYPE_CD_11);
        System.assertEquals(BillSimpleHelp.getMediaCodeByLeadMediaType('そのた')[0], CommConst.MEDIA_TYPE_CD_01);

        // 予約情報の自動チェックインの支払作成
        
        
    } 
    
    static testMethod void autoCalTTendInfo() {
    	// DOC INIT 
    	String gShopCode = '';
		
		CommDefine__c condef = TestCommon.createCommDefine();
		condef.AccountPaymentIsAutoGenFlg__c = true;
		update condef;
		
		TestCommon.createBillSimplePaymentConfigDoc();
		TestCommon.createBillSimpleHelpConfigDoc();
     	//getCsvSetupConfig1();
    	Date tday = Date.today();
    	// お客様作成
    	Contact cont = TestCommon.createContact();
    	// 取引先作成
    	//Account acc = TestCommon.createNormalAccount();
        // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
  		// 予約作成
		List<Lead__c> leads = TestCommon.createLead(tday,1,1,cont.Id);
		lead__c lead = leads[0];
        // 予約情報のステータス：チェックインに変更する
        // Lead設定する
        ApexPages.StandardController contrl = new ApexPages.StandardController(lead);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        Integer isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
        	if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 1);
		Test.startTest();
        BookingEstimateItemSetup.BookEstItem item2 = queryLst[1];
        item2.sobj.refAccountMaster__c = productLst[1].Id;
        item2.productNm = productLst[1].Name;
        item2.prodNums = '4';
        item2.sobj.UnitPrice__c = 5000;
        item2.sobj.ActionType__c = '通常';
        item2.sobj.UseDate__c = system.today();
        ctrl.upsertData();
        queryLst = ctrl.oBookEstLst;
        isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
            if (item.isValidata) isValidataRecs++;
        }
        // 予約情報のステータス：チェックインに変更する
        lead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update lead;
        // 会計支払商品を作成、関連の手数料情報を定義する
 		List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c,Relreserve__r.Relcontact__r.AccountId,Relreserve__r.Relcontact__c,Relreserve__r.SalesOfficeInfoRef__c from AccountAcount__c where Relreserve__c = :lead.Id];
        AccountAcount__c accObj = accObjLst[0];
        
        BillSimpleHelp.autoCalTTendInfo(new list<id>{ accObj.Id});
        CustomBathTaxAutoSetCtrl bathCtrl = new CustomBathTaxAutoSetCtrl();
        String modeStr = bathCtrl.bTaxSetMode;
        boolean isTaxFlg = bathCtrl.isBTaxSetFlg;
        Test.stopTest();
    }
    private static String getCsvSetupConfig() {
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP>'
                    + '</root>';
        return csv;
    }
}