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
private class ExpoTest {
    // 店铺编辑
    static testMethod void myExpoShopInfoEdit01Test() {
        // no login
        ExpoShopInfoEditCtrl ctrl = new ExpoShopInfoEditCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ctrl.initAct();
        Object obj = ExpoShopInfoEditCtrl.getRefDs('ExpoOrgInfo__c');
        Map<String,Object> newMap = new Map<String,Object>{ShopInformation__c.Fax__c.getDescribe().getName().toLowerCase() => new List<String>{'1234',shop.Fax__c,'STR'}};
        obj = ExpoShopInfoEditCtrl.saveInfo(shop.id,JSON.serialize(newMap),expoOrgs[0].id);
        // ExpoShopInfoEditCtrl.saveInfo(ctrl.dataId, '{"name":["東京都千代田区2号","東京都千代田区2号店","STR"],"fax__c":["13","133","STR"]}', expoOrgs[0].id);
        ctrl.newLog.Body = Blob.valueOf('123');
        ctrl.saveLogo();
        ctrl.getSpcdLog();
    }
    // 店铺编辑
    static testMethod void myExpoShopInfoEdit02Test(){
        // no login
        ExpoShopInfoEditCtrl ctrl = new ExpoShopInfoEditCtrl();
        // user login
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ExpoCommonTest.createEmptyDoc();
        // 定数設定
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ctrl.initAct();
        ctrl.newLog.Body = Blob.valueOf('123');
        ctrl.saveLogo();
        ctrl.getSpcdLog();
    }
    
    // 店铺一览
    static testMethod void myExpoShopInfoView01Test() {
        // TO DO: implement unit test
        ExpoShopInfoViewCtrl ctrl = new ExpoShopInfoViewCtrl();
        ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ctrl.initAct();
        ExpoShopInfoViewCtrl.getModel(shop.shopcode__c,expoOrgs[0].id);
    }
    // 店铺一览 没有doc
    static testMethod void myExpoShopInfoView02Test() {
        // TO DO: implement unit test
        ExpoShopInfoViewCtrl ctrl = new ExpoShopInfoViewCtrl();
        ctrl.initAct();
        ExpoCommonTest.createEmptyDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ctrl.initAct();
        ExpoShopInfoViewCtrl.getModel(shop.shopcode__c,expoOrgs[0].id);
    }
    
    // 会计商品编集
    static testMethod void myExpoAccountMasterEditTest() {
        // TO DO: implement unit test
        
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        JMST__c taxMst = TestCommon.createTaxMst();
        // 室単料　会計商品
        AccountMaster__c acc = new AccountMaster__c(
            Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME,
            ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
            StsTaxfee__c = '0',
            Field3__c = '100999', // 商品コード
            Field5__c = 1050,
            ServiceRate__c = 10,
            SpecialTax__c = 100,
            ExpoOrgInfoRef__c = org.Id
        );
        insert acc;
        Test.startTest();
        
        ExpoAccountMasterEditCtrl ctrl = new ExpoAccountMasterEditCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id', acc.id);
        ctrl.initAct();
        
        ExpoAccountMasterEditCtrl.getRefDs('JMST__c',expoOrgs[0].Id);
        ExpoAccountMasterEditCtrl.saveInfo(acc.id,'','');
        Test.stopTest();
    }
    // 会计商品一览
    static testMethod void myExpoAccountMasterViewTest() {

        Test.startTest();
        List<AccountMaster__c> productMstList = TestCommon.createProductMst(2);
        ExpoAccountMasterViewCtrl ctrl = new ExpoAccountMasterViewCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ctrl.initAct();
        
        ExpoAccountMasterViewCtrl.getModel('','');
        Test.stopTest();
    }
    // 组织情报编集
    static testMethod void myExpoOrgInfoEditTest() {
        
        Test.startTest();
        ExpoOrgInfoEditCtrl ctrl = new ExpoOrgInfoEditCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoOrgInfoEditCtrl.saveInfo(expoOrgs[0].id,'');
        ExpoOrgInfoEditCtrl.getRefDs('ExpoOrgInfo__c');
        System.assertEquals(CommUtils.nullTOBlank(ctrl.parentDsJson) + CommUtils.nullTOBlank(ctrl.childDsJson),'');
        Test.stopTest();
    }
    // 店铺情报一览
    static testMethod void myExpoShopInfoViewTest() {
        
        Test.startTest();
        ExpoShopInfoViewCtrl ctrl = new ExpoShopInfoViewCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoShopInfoViewCtrl.getModel(user.ShopCode__c,expoOrgs[0].Id);
        Test.stopTest();
    }
    // user编集
    static testMethod void myExpoUserEditTest() {
        
        Test.startTest();
        ExpoUserEditCtrl ctrl = new ExpoUserEditCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoUserEditCtrl.getRefDs('ExpoOrgInfo__c');
        ExpoUserEditCtrl.checkUserName(user.Name);
        ExpoUserEditCtrl.saveInfo(expoOrgs[0].Id,'',expoOrgs[0].Id);
        Test.stopTest();
    }
    // user一览
    static testMethod void myExpoUserViewTest() {
        
        Test.startTest();
        ExpoUserViewCtrl ctrl = new ExpoUserViewCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoUserViewCtrl.getModel(user.ShopCode__c,expoOrgs[0].Id);
        Test.stopTest();
    }
    // パスワードを忘れた
    static testMethod void myExpoForgotpwdTest() {
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Test.startTest();
        createLogoDoc();
        ExpoForgotpwdCtrl ctrl = new ExpoForgotpwdCtrl();
        ctrl.userNameCheck();
        ctrl.updateData();
        ctrl.getLogoUrl();
        Test.stopTest();
    }
    /*
    // header
    static testMethod void myExpoHeaderTest() {
        
        Test.startTest();
        ExpoHeaderCtrl ctrl = new ExpoHeaderCtrl();
        
        //List<ExpoOrgInfo__c> expoOrgs = TestCommon.generateExpoOrgInfo(1);
        //ShopInformation__c shop = TestCommon.createShopInfo();
        //ExpoUser__c user = TestCommon.createExpoUser(shop,expoOrgs[0]);
        //TestCommon.userLogin(user);
        //ExpoSession__c session = ExpoHelperUtil.getSessionByUserId(user.id);
        //ApexPages.currentPage().getParameters().put('sid',session.SessionId__c);
        
        ctrl.removeSessionIdOfCookie();
        ctrl.getSpcdLog();
        
        Test.stopTest();
    }
    */
    // ホーム
    /*
    static testMethod void myExpoHomeTest() {
        //Contact contacts = TestCommon.createContact();
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        // 室単料　会計商品
        AccountMaster__c acc = new AccountMaster__c(
            Name = '1234',
            ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
            StsTaxfee__c = '0',
            Field3__c = '100999', // 商品コード
            Field5__c = 1050,
            ServiceRate__c = 10,
            SpecialTax__c = 100,
            ExpoOrgInfoRef__c = org.Id
        );
        insert acc;
        
        Test.startTest();
        ExpoHomeCtrl ctrl = new ExpoHomeCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c= user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoHomeCtrl.getInfoDs(org.Id);
        Test.stopTest();
    }
    */
    // Search
    /*
    static testMethod void myExpoSearchTest() {
        //Contact contacts = TestCommon.createContact();
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        // 室単料　会計商品
        AccountMaster__c acc = new AccountMaster__c(
            Name = '1234',
            ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
            StsTaxfee__c = '0',
            Field3__c = '100999', // 商品コード
            Field5__c = 1050,
            ServiceRate__c = 10,
            SpecialTax__c = 100,
            IsClosed__c = false,
            ExpoOrgInfoRef__c = org.Id
        );
        insert acc;
        Test.startTest();
        ExpoSearchCtrl ctrl = new ExpoSearchCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c = user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ApexPages.currentPage().getParameters().put('condition',acc.Name);
        ctrl.initAct();
        
        ExpoSearchCtrl.getInfoDs(acc.Name,org.Id);
        ExpoSearchCtrl.getInfoDs(acc.Name,acc.Id);
        Test.stopTest();
    }
    */
    // UIapi
    static testMethod void myExpoUiApiTest() {
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        // 室単料　会計商品
        AccountMaster__c acc = new AccountMaster__c(
            Name = '1234',
            ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
            StsTaxfee__c = '0',
            Field3__c = '100999', // 商品コード
            Field5__c = 1050,
            ServiceRate__c = 10,
            SpecialTax__c = 100,
            ExpoOrgInfoRef__c = org.Id
        );
        insert acc;
        
        Test.startTest();
        ExpoUiApiCtrl ctrl = new ExpoUiApiCtrl();
        PageReference pg = ctrl.initAct();
        ctrl.initOrgInfoAct();
        System.assertNotEquals('',ctrl.orgid + ctrl.suborgId + ctrl.apiEndPoint + ctrl.imgEndPoint + ctrl.domainUrl);
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c = user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        Test.stopTest();
    }
    /*
    // 受注編集
    static testMethod void myExpoOrderEditTest() {
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        
        Test.startTest();
        ExpoOrderEditCtrl ctrl = new ExpoOrderEditCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c = user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;
        List<AccountMaster__c> productMstList = TestCommon.createProductMst(2);
        OrderItem__c orditem = new OrderItem__c(
            AccountMasterRef__c = productMstList[0].Id,
            RefParOrder__c = ord.Id,
            RefSubOrder__c = ord.Id
        );
        insert orditem;
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ApexPages.currentPage().getParameters().put('Id',ord.Id);
        ctrl.initAct();
        
        
        ExpoOrderEditCtrl.saveOrderInfo(ord.Id,'OrderNo__c',System.now()+CommUtils.getRandom(5),'');
        ExpoOrderEditCtrl.saveOrderSubInfo(orditem.Id,'');
        ExpoOrderEditCtrl.saveOrderItemInfo(orditem.Id,'StockUnit__c',System.now()+CommUtils.getRandom(5),'');
        list<object> newLst = new list<object>{
            new map<String,object>{'orderSubNm'=>ord.Name,'orderSubId'=>ord.Id}
        };
        ExpoOrderEditCtrl.getOrderInfo(ord.Id,JSON.serialize(newLst),org.Id);
        Test.stopTest();
    }
    // 受注一览
    static testMethod void myExpoOrderViewTest() {
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;

        Test.startTest();
        ExpoOrderViewCtrl ctrl = new ExpoOrderViewCtrl();
        PageReference pg = ctrl.initAct();
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c = user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        ctrl.initAct();
        
        ExpoOrderViewCtrl.getOrderInfo(org.Id);
        Test.stopTest();
    }
    */
    // 密码激活
    static testMethod void myExpoUserActivationTest(){
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        user.ActivationFlg__c = false;
        user.IsActive__c = true;
        user.TokenId__c = CommUtils.getGUID();
        update user;
        ApexPages.currentPage().getParameters().put('tokenKey',user.TokenId__c);
        ExpoUserActivationCtrl ctrl = new ExpoUserActivationCtrl();
        ctrl.initAct();
        ctrl.updateData();
    }

    // 更改密码 
    /*
    static testMethod void myPwdChangeTest() {
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        Test.startTest();
        ExpoPwdChangeCtrl epcc = new ExpoPwdChangeCtrl();
        epcc.initAct();
        ExpoPwdChangeCtrl.saveInfo(epcc.dataId, '{"password__c":["012345678","","STR"]}');
        Test.stopTest();
    }*/
    
    // ExpoDispatch
    /*
    static testMethod void myExpoDispatchTest(){
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        Test.startTest();
        ExpoDispatchCtrl edc = new ExpoDispatchCtrl();
        edc.cookieVal = '123';
        edc.redirectAct();
        Test.stopTest();
    }*/
    
    //ExpoHeader
    static testMethod void myExpoHeaderTest() {
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid',sid);
        Test.startTest();
        ExpoHeaderCtrl tmp = new ExpoHeaderCtrl();
        tmp.currentUser = user;
        tmp.getSpcdLog();
        String b = tmp.url;
        String a = tmp.currentUserId;
        String c = tmp.currentUserNm;
        tmp.logout();
        Test.stopTest();
    }
    // ExpoNoAuthHelp
    static testMethod void myExpoNoAuthHelpTest() {
        ShopInformation__c shop = TestCommon.createShopInfo();
        Test.startTest();
        createLogoDoc();
        ExpoNoAuthHelp.getReportTitleInfo(shop.ShopCode__c);
        ExpoNoAuthHelp.getLogoUrl();
        Test.stopTest();
    }
    static testMethod void myExpoOrderTest(){
        ExpoOrgInfo__c org = new ExpoOrgInfo__c(
            Name = '組織情報'
        );
        insert org;
        
        Test.startTest();
        CommDefine__c commdef = TestCommon.createCommDefine();
        commdef.StockSyncIsActiveFlg__c = true;
        update commdef;
        ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        Order__c ord = new Order__c(
            OrderUserId__c = user.Id,
            OrderNo__c = System.now()+CommUtils.getRandom(5),
            ExpoOrgInfoRef__c = org.Id
        );
        insert ord;

        List<AccountMaster__c> productMstList = TestCommon.createProductMst(2);
        OrderItem__c orditem = new OrderItem__c(
            AccountMasterRef__c = productMstList[0].Id,
            RefParOrder__c = ord.Id,
            RefSubOrder__c = ord.Id
        );
        insert orditem;
        update orditem;
    }
    public static Document createTl2WayConfigDoc() {
        String configXml = '<?xml version="1.0" encoding="UTF-8"?><root></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'Tl2wayServiceConfigXml';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(configXml);
        insert item;
        return item;
    }
    public static void createLogoDoc(){
        String body = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCMASTERFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="1">Name,$_BLANK_$,Field5__c,Field7__c,jmstRef__c:消費税,ServiceRate__c,Field12__c,Field2__c</SECTION><SECTION TITLE="EXPO基本情報" COLNUM="1">Category__c,CategorySub__c</SECTION></FIELDS><REQUIREDFIELDS>Name,Field5__c</REQUIREDFIELDS><TEXTAREAIMG>BigImage__c</TEXTAREAIMG><HEIGHT>35px</HEIGHT></ACCMASTERFIELDS><SHOPINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,WebSite__c:,WebSite__c:222,AccountServiceChargeNoTaxFlg__c,$_blank_$,PayeeAcount__c,ShopCode__c,ExpoOrgInfoRef__c,Fax__c,Seq__c,RoomScheduleTimerMinute__c,Email__c,Phone__c,ShopCode1__c</SECTION></FIELDS><REQUIREDFIELDS>Fax__c</REQUIREDFIELDS><HEIGH>150px</HEIGH></SHOPINFOFIELDS><USERINFOFIELDS><FIELDS><SECTION TITLE="" ROW=""></SECTION><SECTION TITLE="情報" COLNUM="2">Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:組織名,Phone__c:電話,ShopCode__c:組織店舗</SECTION></FIELDS><WIDTHFIELDS>Name:50px</WIDTHFIELDS><REQUIREDFIELDS>ShopCode__c,Fax__c</REQUIREDFIELDS><HEIGHT>50px</HEIGHT></USERINFOFIELDS><ORGINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c,ContactRef__c</SECTION><SECTION TITLE="情報3" COLNUM="1">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c</SECTION></FIELDS><REQUIREDFIELDS></REQUIREDFIELDS><WIDTHFIELDS>iD:1000PX</WIDTHFIELDS><HEIGHT>100px</HEIGHT></ORGINFOFIELDS><USERLISTFIELDS>Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:Expo組織情報</USERLISTFIELDS><ORGLISTFIELDS>Name:店舗名,ShopCode__c:店舗コード,ExpoOrgInfoRef__c:abc</ORGLISTFIELDS><HRINFOFIELDS>ExpoOrgInfoRef__r.name:a,Field3__c:b,Name:c,Field5__c:d,Field7__c:e</HRINFOFIELDS></SHOP></root>';
        // ドキュメントを作成する
        Document item = new Document();
        item.Name = 'Expologo';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(body);
        insert item;

        // ドキュメントを作成する
        item = new Document();
        item.Name = 'Jinyalogo';
        item.DeveloperName = item.Name;
        item.FolderId = UserInfo.getUserId();
        item.Body = Blob.valueOf(body);
        insert item;
    }
}