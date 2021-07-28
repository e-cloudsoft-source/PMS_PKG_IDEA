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
private class ApprovalTest {
    // 默認出力
    static testMethod void case01() {
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 稟議情報を作成する
        Approvaldocuments__c rat = new Approvaldocuments__c(
            Name = 'App_1',
            DraftUser__c = currUser.Id,
            DraftDt__c = Date.today(),
            Purpose__c = '123'
        );
        insert rat;
        // 稟議明細情報を作成する
        ApprovalItem__c item1 = new ApprovalItem__c(
           Amount__c = 4,
           refApproval__c = rat.id,
           refAccountMaster__c = productLst[0].Id,// 商品名
           UnitPrice__c = 20000,
           UnitPriceTax__c = 20000,
           SpTotal__c = 80000
        );
        insert item1;
        Test.startTest();
        ApexPages.StandardController contrl = new ApexPages.StandardController(rat);
        ApprovalItemCtrl ctrl = new ApprovalItemCtrl(contrl);
        ctrl.upsertData();
        ctrl.addBookingItem();
        // 商品自動取得機能
        ProductItemUtils.ProductItem item = BookingEstimateItemSetup.getProductItemInfo(productLst[0].Field3__c);
        System.assertEquals(item.prodcutName, productLst[0].Name);
        List<ProductItemUtils.ProductItem> items = BookingEstimateItemSetup.getArrayProductItemInfo(productLst[0].Field3__c);
        System.assert(items.size() > 0, items);
        Test.stopTest();
    }
    // PDF
    static testMethod void case02() {
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 稟議情報を作成する
        Approvaldocuments__c rat = new Approvaldocuments__c(
            Name = 'App_2',
            DraftUser__c = currUser.Id,
            DraftDt__c = Date.today(),
            Purpose__c = '123'
        );
        insert rat;
        // 稟議明細情報を作成する
        ApprovalItem__c item1 = new ApprovalItem__c(
           Amount__c = 4,
           refApproval__c = rat.id,
           refAccountMaster__c = productLst[0].Id,// 商品名
           UnitPrice__c = 20000,
           UnitPriceTax__c = 20000,
           SpTotal__c = 80000
        );
        insert item1;

        Test.startTest();
        ApexPages.StandardController contrl = new ApexPages.StandardController(rat);
        Apexpages.currentPage().getParameters().put('Id',rat.Id);

        ApprovalPDFCtrl pdf1 = new ApprovalPDFCtrl(contrl);
        Test.stopTest();
    }
    static testMethod void case03() {
        CommDefine__c def = TestCommon.createCommDefine();
        def.ReducedTaxRateFlg__c = true;
        def.PDFPlanBrkIsShowFlg__c = true;
        update def;
        User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 稟議情報を作成する
        Approvaldocuments__c rat = new Approvaldocuments__c(
            Name = 'App_2',
            DraftUser__c = currUser.Id,
            DraftDt__c = Date.today(),
            Purpose__c = '123'
        );
        insert rat;
        // 稟議明細情報を作成する
        ApprovalItem__c item1 = new ApprovalItem__c(
           Amount__c = 4,
           refApproval__c = rat.id,
           refAccountMaster__c = productLst[0].Id,// 商品名
           UnitPrice__c = 20000,
           UnitPriceTax__c = 20000,
           SpTotal__c = 80000
        );
        insert item1;

        Test.startTest();
        ApexPages.StandardController contrl = new ApexPages.StandardController(rat);
        Apexpages.currentPage().getParameters().put('Id',rat.Id);

        ApprovalPDFCtrl pdf1 = new ApprovalPDFCtrl(contrl);
        Test.stopTest();
    }
}