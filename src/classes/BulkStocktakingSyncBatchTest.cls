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
private class BulkStocktakingSyncBatchTest {

    static testMethod void myUnitTest() {
    	createBatchDoc();
        ShopInformation__c shop = TestCommon.createShopInfo();
        shop.shopCode__c = '02';
        update shop;
        // TO DO: implement unit test
        BulkStocktakingSyncBatch batch = new BulkStocktakingSyncBatch();
        List<Accountmaster__c> accs = TestCommon.createProductMst(20);
        List<InventoryInfo__c> invens = new  List<InventoryInfo__c>();
        List<ProductStock__c>  prodStocks = new List<ProductStock__c>();
        for (Accountmaster__c acc : accs) {
            acc.ShopInfoRef__c = shop.id;
            invens.add(new InventoryInfo__c(AccountMasterRef__c = acc.id,RealQtyOfStock__c = 5,StockDate__c = Date.today(),ShelfChkFlag__c = true));
            prodStocks.add(new ProductStock__c(ProductRef__c = acc.id));
        }
        update accs;
        insert invens;
        insert prodStocks;
        BulkStocktakingSyncBatch schedult = new BulkStocktakingSyncBatch('02',system.today());
        // 起動ＣＲＯＮを設定する
        Datetime nowTime = system.now().addSeconds(50);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = 'BulkStocktakingSyncBatch_' + nowTime.format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        Test.startTest();
        system.schedule(jobName, sch, schedult);
        Test.stopTest();
    }
    static testMethod void myUnitTest02() {
        createBatchDoc();
        TestCommon.createProductMst(20);
        BulkStocktakingSyncBatch schedult = new BulkStocktakingSyncBatch();
        // 起動ＣＲＯＮを設定する
        Datetime nowTime = system.now().addSeconds(50);
        String timeStr = nowTime.format('yyyyMMddHHmmss');
        String yy = timeStr.substring(0,4);
        String mm = timeStr.substring(4,6);
        String dd = timeStr.substring(6,8);
        String hh = timeStr.substring(8,10);
        String ms = timeStr.substring(10,12);
        String ss = timeStr.substring(12,14);
        String sch = ss + ' ' +
               ms + ' ' +
               hh + ' ' +
               dd + ' ' +
               mm + ' ' +
               ' ? ' + yy;
        String jobName = 'BulkStocktakingSyncBatch_' + nowTime.format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
        Test.startTest();
        system.schedule(jobName, sch, schedult);
        Test.stopTest();
    }
    static testMethod void myUnitTest01() {
        createBatchDoc();
        // TO DO: implement unit test
        TestCommon.createProductMst(20);
        BulkStocktakingSyncBatch batch1 = new BulkStocktakingSyncBatch();
        DataBase.executeBatch(batch1,20);
    }
    static testMethod void myUnitTest03() {
        createBatchDoc();
        ShopInformation__c shop = TestCommon.createShopInfo();
        shop.shopCode__c = '02';
        update shop;
        
        // TO DO: implement unit test
        List<AccountMaster__c> accs = TestCommon.createProductMst(20);
        ProductStockInventoryCtrl ctrl = new ProductStockInventoryCtrl();
        ctrl.initStock();
        String label = ctrl.masterOpts[0].getLabel();
        for (AccountMaster__c acc : accs) {
        	acc.Shelves__c = label;
        	acc.ShopInfoRef__c = shop.id;
        }
        update accs;
        ctrl.changeMaster();
        List<Map<String,object>> stocks = new List<Map<String,object>>{
        	new Map<String,object>{'stockQty' =>2,'groupName' =>label,'accountId' =>accs[0].id,'checkFlag' => true},
        	new Map<String,object>{'stockQty' =>3,'groupName' =>label,'accountId' =>accs[1].id,'checkFlag' => true}
        };
        ProductStockInventoryCtrl.remoteCenter('updateStockData',JSON.serialize(stocks));
        
        BulkStocktakingSyncBatch batch1 = new BulkStocktakingSyncBatch('02',system.today());
        DataBase.executeBatch(batch1,20);
        BulkStocktakingSyncBatch batch2 = new BulkStocktakingSyncBatch('',system.today().addDays(-1));
        DataBase.executeBatch(batch2,20);
    }
    static testMethod void myUnitTest04(){
        
        Test.startTest();
        Set<String> accIds = new Set<String>();
        List<InventoryInfo__c> invens = new List<InventoryInfo__c>();
        List<PurchaseDetail__c> purs = new List<PurchaseDetail__c>();
        List<ProductStock__c> prostocks = new List<ProductStock__c>();
        List<ProductOutStock__c> sobjects = new List<ProductOutStock__c>();
        String queryYmd = system.now().format('yyyyMMdd');
        Purchase__c pur = Testcommon.createPurchase();
        for (AccountMaster__c acc : TestCommon.createProductMst(5)) {
            accIds.add(acc.id);
            invens.add(new InventoryInfo__c(AccountMasterRef__c = acc.id,StockDate__c = system.today()));
            prostocks.add(new ProductStock__c(ProductRef__c = acc.id , InitQtyOfStock__c = 6));
            purs.add(new PurchaseDetail__c(InstockDate__c = queryYmd ,AccountMasterRef__c = acc.id, PurchaseRef__c = pur.id));
            sobjects.add(new ProductOutStock__c(OutStockDate__c = queryYmd , AccountMasterRef__c = acc.id));
        }
        insert invens;
        insert prostocks;
        for (integer i = 0 ; i < prostocks.size(); i++) {
            ProductStock__c pro = prostocks[i];
            sobjects[i].ProductStock__c = pro.id;
            purs[i].ProductStockRef__c = pro.id;
        }
        insert sobjects;
        insert purs;
        BulkStocktakingLinkBatch batch1 = new BulkStocktakingLinkBatch(queryYmd,BulkStocktakingLinkBatch.BATCH_TYPE.INSTOCK);
        batch1.processIdSet = accIds;
        DataBase.executeBatch(batch1,20);
        BulkStocktakingLinkBatch batch2 = new BulkStocktakingLinkBatch(queryYmd,BulkStocktakingLinkBatch.BATCH_TYPE.OUSTOCK);
        batch2.processIdSet = accIds;
        DataBase.executeBatch(batch2,20);
        Test.stopTest();
        
    }
    private static void createBatchDoc(){
        Date todayDt = System.today();
        String dtStr = todayDt.format().subString(5);
        String body = '<?xml version="1.0" encoding="utf-8"?><root>   <INVENTORYSYNC>       <SHOP>          <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください             注意：個別店舗コードを指定する場合、該当店舗の会計商品の「店舗情報」項目を必ず指定してください!!!          -->         <SHOPCODE></SHOPCODE>           <!-- 棚卸し商品対象抽出条件            デフォルト：商品処理種別：通常         -->         <FILTER>ActionType__c IN (\'通常\')</FILTER>          <!-- 棚卸し連携頻度設定              該当頻度設定により、棚卸しデータの実在庫数は商品在庫に反映を行う                そのため、該当指定日前まで棚卸し点検が終わるが必要、どうして間に合わない場合、該当設定を変更してください             -->            <REPEATCONF>                <!-- 頻度単位：YEAR/MONTH/WEEK   ：YEAR:年単位、MONTH:月単位(デフォルト)、WEEK:週単位 -->             ' 
                    + '<REPEATTYPE>MONTH</REPEATTYPE><REPATDETAIL>10,23,26,月末,' + todayDt.day() + '</REPATDETAIL>           </REPEATCONF>       </SHOP>     <SHOP>          <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください             注意：個別店舗コードを指定する場合、該当店舗の会計商品の「店舗情報」項目を必ず指定してください!!!          -->         <SHOPCODE>02</SHOPCODE>         <!-- 棚卸し商品対象抽出条件            デフォルト：商品処理種別：通常         -->         <FILTER>OP__r.name IN (\'料理\')</FILTER>         <!-- 棚卸し連携頻度設定              該当頻度設定により、棚卸しデータの実在庫数は商品在庫に反映を行う                そのため、該当指定日前まで棚卸し点検が終わるが必要、どうして間に合わない場合、該当設定を変更してください             -->            <REPEATCONF>                <!-- 頻度単位：YEAR/MONTH/WEEK   ：YEAR:年単位、MONTH:月単位(デフォルト)、WEEK:週単位 -->             ' 
                    + '<REPEATTYPE>WEEK</REPEATTYPE> <REPATDETAIL>日,水,木,金,火,土,月</REPATDETAIL>           </REPEATCONF>       </SHOP>     <SHOP>          <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください             注意：個別店舗コードを指定する場合、該当店舗の会計商品の「店舗情報」項目を必ず指定してください!!!          -->         <SHOPCODE>03</SHOPCODE>         <BATCHTIME>14:33</BATCHTIME>            <!-- 棚卸し商品対象抽出条件            デフォルト：商品処理種別：通常         -->         <FILTER>CookCount__c = 0</FILTER>           <!-- 棚卸し連携頻度設定              該当頻度設定により、棚卸しデータの実在庫数は商品在庫に反映を行う                そのため、該当指定日前まで棚卸し点検が終わるが必要、どうして間に合わない場合、該当設定を変更してください             -->            <REPEATCONF>                <!-- 頻度単位：YEAR/MONTH/WEEK   ：YEAR:年単位、MONTH:月単位(デフォルト)、WEEK:週単位 -->             '
                    +'<REPEATTYPE>YEAR</REPEATTYPE> <REPATDETAIL>' + dtStr +'</REPATDETAIL>         </REPEATCONF>       </SHOP>    </INVENTORYSYNC></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'BatchRequstConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(body);
        insert item;
    }
}