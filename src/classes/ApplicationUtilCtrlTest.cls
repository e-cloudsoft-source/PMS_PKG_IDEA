@isTest(SeeAllData=false)
private class ApplicationUtilCtrlTest {
	// 默認出力
	static testMethod void case01() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按#DP、 コード昇順、商品コード昇順出力
	static testMethod void case02() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'DPChange__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按#GP、 コード昇順、商品コード昇順出力
	static testMethod void case03() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'GPChange__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按会計OP、 コード昇順、商品コード昇順出力
	static testMethod void case04() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'OP__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按リンクＤＰコード、 コード昇順、商品コード昇順出力
	static testMethod void case05() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'Field4__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}

	// 按#DP、 名昇順、商品コード昇順出力
	static testMethod void case06() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'DPChange__c';
		ac.sortTab = 'name';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}

	// 按#GP、 名昇順、商品コード昇順出力
	static testMethod void case07() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'GPChange__c';
		ac.sortTab = 'name';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按会計OP、 名昇順、商品コード昇順出力
	static testMethod void case08() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'OP__c';
		ac.sortTab = 'name';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 按リンクＤＰコード、 名昇順、商品コード昇順出力
	static testMethod void case09() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		// 2015/12/01 Assert BEGIN
		System.assertEquals(productLst.size(), 3);
		// 2015/12/01 Assert END
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'Field4__c';
		ac.sortTab = 'name';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.generalProdcutMenuXml();
		Test.stopTest();
	}
	// 創建BillSimpleProductConfigWork
	/*static testMethod void case10() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'DPChange__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.upsProdcutMenuXml();
		Test.stopTest();
	}*/
	// 更新BillSimpleProductConfigWork
	/*static testMethod void case11() {
		List<AccountMaster__c> productLst = TestCommon.createFullProductMst(3);
		Map<String, String> fnMap = new Map<String, String>();
        for (Folder s:[select Id, Name from Folder] ) {
            fnMap.put(s.Name, s.Id);
        }
		Document BillSimpleProductConfigWork = new Document();
	    BillSimpleProductConfigWork.Name = '会計商品メニュー定義情報';
	    BillSimpleProductConfigWork.DeveloperName = 'BillSimpleProductConfigWork';
	    BillSimpleProductConfigWork.FolderId = fnMap.get('ワーク');
	    // BillSimpleProductConfigWork.Body = Blob.valueOf(generalProdcutMenuXml());
	    BillSimpleProductConfigWork.Type = 'text/xml';
	    insert BillSimpleProductConfigWork;

		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.ApplicationUtil')); 
		ApplicationUtilCtrl ac = new ApplicationUtilCtrl();
		ac.tabName = 'DPChange__c';
		ac.sortTab = 'code';
		ac.sortTabOrder = 'asc';
		ac.sortProd = 'Field3__c';
		ac.sortProdOrder = 'asc';
		ac.upsProdcutMenuXml();
		Test.stopTest();
	}*/
}