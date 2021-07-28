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
private class WS_ExpoEngineServiceTest {

    static testMethod void getmasterinfoTest() {
        Test.startTest();
        // 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        Test.stopTest();
        WS_ExpoEngineService.log = new CommLogUtils('WS_ExpoEngineService,',true);
        WS_ExpoEngineService.BAT_SIZE = 2;
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category>食料</Category><CategorySub>完成品</CategorySub><PriceDurationFrom>0</PriceDurationFrom><PriceDurationTo>999999999</PriceDurationTo><DisplayDurationFrom>20170101</DisplayDurationFrom><DisplayDurationTo>29991212</DisplayDurationTo></ExtractionCondition></GetMasterInfoRQ>';
        String rs = WS_ExpoEngineService.getmasterinfo(reqXml);
        System.assert(rs.contains('<IsSuccess>true</IsSuccess>'),rs);
        String jobId = rs.substringBetween('<JobId>','</JobId>');
        String prdcd = rs.substringBetween('<NextPageProductCodes>','</NextPageProductCodes>');
        String reqXml2 = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><JobId>$_JOBID_$</JobId><ProductCodes>$_PRODUCTCODES_$</ProductCodes></ExtractionCondition></GetMasterInfoRQ>';
        reqXml2 = reqXml2.replace('$_JOBID_$',jobId);
        reqXml2 = reqXml2.replace('$_PRODUCTCODES_$',prdcd);
        rs = WS_ExpoEngineService.getmasterinfo(reqXml2);
        System.assert(rs.contains('<IsSuccess>true</IsSuccess>'),rs);
        
        String userId = UserInfo.getUserId();
        String orgId = userInfo.getOrganizationId();
        String reqKey = orgId + '-' + userId;
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>2</minorno></CommonRequest><ExtractionCondition><UserId>$_REQKEY_$</UserId></ExtractionCondition></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_REQKEY_$',reqKey);
        rs = WS_ExpoEngineService.getmasterinfo(reqXml);
        System.assert(rs.contains('<IsSuccess>true</IsSuccess>'));
        /*
        reqXml = '<GetRoomTypeListRQ><CommonRequest><ShopCode></ShopCode></CommonRequest><RoomTypeInfo><DataType>0</DataType></RoomTypeInfo></GetRoomTypeListRQ>';
        rs = WS_BookingEngineService.getroomtypelistService(reqXml);
        System.assert(rs.contains('<IsSuccess>true</IsSuccess>'));
        reqXml = '<GetRoomTypeListRQ><CommonRequest><ShopCode></ShopCode></CommonRequest><RoomTypeInfo><DataType>2</DataType></RoomTypeInfo></GetRoomTypeListRQ>';
        rs = WS_BookingEngineService.getroomtypelistService(reqXml);
        System.assert(rs.contains('<IsSuccess>false</IsSuccess>'));*/
        
    }
    static testMethod void doPostTest() {
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getmasterinfo';  
        req.requestBody = Blob.valueOf('<?xml version="1.0" encoding="UTF-8"?>');
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	req.requestURI = '/services/apexrest/exposervice/V1/getmasterinfo';  
    	WS_ExpoEngineService.doPost();
    	req.requestURI = '/services/apexrest/pmsservice/V1/orderinfo';  
    	WS_ExpoEngineService.doPost();
    }
    
    static testMethod void getMasterinfoTest001() {
    	// 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(101);
        String prods = '';
        for (AccountMaster__c acc : productLst) {
        	acc.DisplayDate__c =Date.today();
        	acc.Category__c = '人材';
        	prods += '-' + acc.id + ',';
        }
        update productLst;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getmasterinfo'; 
        //不指定抽出条件 
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category></Category><CategorySub></CategorySub><PriceDurationFrom></PriceDurationFrom><PriceDurationTo></PriceDurationTo><DisplayDurationFrom></DisplayDurationFrom><DisplayDurationTo>'+ system.today().format() +'</DisplayDurationTo><ProductCodes>' + prods + '</ProductCodes><JobId></JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	//指定抽出条件 Category:人材
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category>人材</Category><CategorySub></CategorySub><PriceDurationFrom></PriceDurationFrom><PriceDurationTo></PriceDurationTo><DisplayDurationFrom></DisplayDurationFrom><DisplayDurationTo></DisplayDurationTo><ProductCodes></ProductCodes><JobId></JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
        WS_ExpoEngineService.doPost();
        String userId = UserInfo.getUserId();
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>2</minorno></CommonRequest><ExtractionCondition><UserId>$_USERID_$</UserId></ExtractionCondition></GetMasterInfoRQ>';
    	reqXml = reqXml.replace('$_USERID_$',userId);
    	req.requestBody = Blob.valueOf(reqXml);
        WS_ExpoEngineService.doPost();
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>3</minorno></CommonRequest><ExtractionCondition><UserId>$_USERID_$</UserId><ProductCode>00D10000000Abcd-'+productLst[0].Field3__c+'</ProductCode></ExtractionCondition></GetMasterInfoRQ>';
    	reqXml = reqXml.replace('$_USERID_$',userId);
    	req.requestBody = Blob.valueOf(reqXml);
        WS_ExpoEngineService.doPost();
    }
    
    static testMethod void getMasterPropTest() {
        //サブ商品と属性関連情報作成する
        createMasterProp(3);
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getmasterinfo'; 
    	//不指定抽出条件
    	String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category></Category><CategorySub></CategorySub><PriceDurationFrom></PriceDurationFrom><PriceDurationTo></PriceDurationTo><DisplayDurationFrom></DisplayDurationFrom><DisplayDurationTo></DisplayDurationTo><ProductCodes></ProductCodes><JobId></JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	//指定抽出条件 Category:人材
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category>人材</Category><CategorySub></CategorySub><PriceDurationFrom></PriceDurationFrom><PriceDurationTo></PriceDurationTo><DisplayDurationFrom></DisplayDurationFrom><DisplayDurationTo></DisplayDurationTo><ProductCodes></ProductCodes><JobId>1</JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	String userId = UserInfo.getUserId();
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>2</minorno></CommonRequest><ExtractionCondition><UserId>$_USERID_$</UserId></ExtractionCondition></GetMasterInfoRQ>';
    	reqXml = reqXml.replace('$_USERID_$',userId);
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    
    static testMethod void getMasterChargeTest() {
        //商品手数料情報作成する
        createMasterCharge(3);
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getmasterinfo'; 
    	//不指定抽出条件
    	String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category></Category><CategorySub>1</CategorySub><PriceDurationFrom>2</PriceDurationFrom><PriceDurationTo></PriceDurationTo><DisplayDurationFrom>1</DisplayDurationFrom><DisplayDurationTo>2</DisplayDurationTo><ProductCodes></ProductCodes><JobId></JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	//指定抽出条件 Category:人材
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><Category>人材</Category><CategorySub></CategorySub><PriceDurationFrom></PriceDurationFrom><PriceDurationTo>12</PriceDurationTo><DisplayDurationFrom></DisplayDurationFrom><DisplayDurationTo></DisplayDurationTo><ProductCodes></ProductCodes><JobId></JobId></ExtractionCondition></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	String userId = UserInfo.getUserId();
        reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>2</minorno></CommonRequest><ExtractionCondition><UserId>$_USERID_$</UserId></ExtractionCondition></GetMasterInfoRQ>';
    	reqXml = reqXml.replace('$_USERID_$',userId);
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>2</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    
    
    static testMethod void getorderinfoTest() {
        //店铺作成
        ShopInformation__c shop = TestCommon.createShopInfo();
        shop.ShopCode__c = '01';
        update shop;
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.StockSyncIsActiveFlg__c = true;
        update comDef;
        // 商品情報を作成する
        //List<AccountMaster__c> productLst = TestCommon.createProductMst(101); 
        List<AccountMasterProp__c> props = createMasterProp(1);
        List<AccountMaster__c> productLst = [select Name ,jmstRef__c,StsTaxfee__c ,Field3__c ,Field5__c,ServiceRate__c,SpecialTax__c,DisplayDate__c  from AccountMaster__c];
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/orderinfo'; 
        //一个order一个明细
        String reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>1</minorno></CommonRequest><OrderInfoList><UserId>00510000003t7b8</UserId><OrderAmountIncTax>41432</OrderAmountIncTax><OrderNo>003</OrderNo><OrderSetInfo><ShopCode>01</ShopCode><ShopName>東京都千代田区1号店</ShopName><OrganizationId>00D10000000Abcd</OrganizationId><SetDeliveryCharge>432</SetDeliveryCharge><SetDeliveryDate>20170923</SetDeliveryDate><SetDeliveryTime>午前中/12:00〜14:00</SetDeliveryTime><SetDeliveryType>宅配便</SetDeliveryType><SetDeliveryAddress>神奈川県秦野市鶴巻北2-8-99</SetDeliveryAddress><SetOrderTitle>サンプル株式会社</SetOrderTitle><SetAmountTax>432</SetAmountTax><SetAmount>41432</SetAmount><PayType>カード</PayType><PayDetail>6412-1211-2113-4412</PayDetail><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[0].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderSetInfoItem></OrderSetInfo></OrderInfoList></OrderInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
        //2个order、每个order2个明细
        reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>1</minorno></CommonRequest><OrderInfoList><UserId>00510000003t7b8</UserId><OrderAmountIncTax>41432</OrderAmountIncTax><OrderNo>003</OrderNo><OrderSetInfo><ShopCode>01</ShopCode><ShopName>東京都千代田区1号店</ShopName><OrganizationId>00D10000000Abcd</OrganizationId><SetDeliveryCharge>432</SetDeliveryCharge><SetDeliveryDate>20170923</SetDeliveryDate><SetDeliveryTime>午前中/12:00〜14:00</SetDeliveryTime><SetDeliveryType>宅配便</SetDeliveryType><SetDeliveryAddress>神奈川県秦野市鶴巻北2-8-99</SetDeliveryAddress><SetOrderTitle>サンプル株式会社</SetOrderTitle><SetAmountTax>432</SetAmountTax><SetAmount>41432</SetAmount><PayType>カード</PayType><PayDetail>6412-1211-2113-4412</PayDetail><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[0].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderSetInfoItem><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[1].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>個</StockUnit><Qty>2</Qty><PriceNoTax>30000</PriceNoTax><Charge>2200</Charge><StaffPriceFlg>3</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>2</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderSetInfoItem></OrderSetInfo><OrderSetInfo><ShopCode>0002</ShopCode><ShopName>株式会社陣屋1</ShopName><OrganizationId>00D10000000Abcd</OrganizationId><SetDeliveryCharge>4321</SetDeliveryCharge><SetDeliveryDate>20170921</SetDeliveryDate><SetDeliveryTime>午前中/12:00〜14:00</SetDeliveryTime><SetDeliveryType>宅配便</SetDeliveryType><SetDeliveryAddress>神奈川県秦野市鶴巻北2-8-99</SetDeliveryAddress><SetOrderTitle>サンプル株式会社</SetOrderTitle><SetAmountTax>432</SetAmountTax><SetAmount>41432</SetAmount><PayType>カード</PayType><PayDetail>6412-1211-2113-4412</PayDetail><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[2].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderSetInfoItem><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[2].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>枚</StockUnit><Qty>3</Qty><PriceNoTax>10000</PriceNoTax><Charge>2100</Charge><StaffPriceFlg>3</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>2</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderSetInfoItem></OrderSetInfo></OrderInfoList></OrderInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
        //只有必填项
        reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>1</minorno></CommonRequest><OrderInfoList><UserId>00510000003t7b8</UserId><OrderAmountIncTax>41432</OrderAmountIncTax><OrderNo>003</OrderNo><OrderSetInfo><ShopCode>01</ShopCode><ShopName>東京都千代田区1号店</ShopName><OrganizationId>00D10000000Abcd</OrganizationId><SetDeliveryCharge>432</SetDeliveryCharge><SetDeliveryDate>20170923</SetDeliveryDate><SetDeliveryTime></SetDeliveryTime><SetDeliveryType>宅配便</SetDeliveryType><SetDeliveryAddress></SetDeliveryAddress><SetOrderTitle></SetOrderTitle><SetAmountTax>432</SetAmountTax><SetAmount>41432</SetAmount><PayType>カード</PayType><PayDetail>6412-1211-2113-4412</PayDetail><OrderSetInfoItem><ProductCode>00D10000000Abcd-'+productLst[3].Field3__c+'</ProductCode><ProductSubCode></ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge></Charge><StaffPriceFlg></StaffPriceFlg><RepeaterFlg></RepeaterFlg><RepeaterPayType></RepeaterPayType><WorkContractStartDate></WorkContractStartDate><WorkContractFilter></WorkContractFilter><WorkContractRange></WorkContractRange><WorkContractTerm></WorkContractTerm><Amount></Amount></OrderSetInfoItem></OrderSetInfo></OrderInfoList></OrderInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
        //1个注文見積情報
        reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>10</minorno></CommonRequest><ExtractionCondition><DestinationState>1</DestinationState></ExtractionCondition><OrderEstInfo><ProductCode>-'+productLst[0].field3__c+'</ProductCode><ProductSubCode>' + props[0].id + '</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><DeliveryType>宅配便</DeliveryType><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderEstInfo></OrderInfoRQ>';
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	//2个注文見積情報
    	reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>10</minorno></CommonRequest><OrderEstInfo><ProductCode>'+productLst[0].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><DeliveryType>宅配便</DeliveryType><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderEstInfo><OrderEstInfo><ProductCode>'+productLst[1].Field3__c+'</ProductCode><ProductSubCode>0002</ProductSubCode><StockUnit>枚</StockUnit><Qty>3</Qty><PriceNoTax>10000</PriceNoTax><Charge>2100</Charge><DeliveryType>取りに行く</DeliveryType><StaffPriceFlg>3</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>2</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>32000</Amount></OrderEstInfo></OrderInfoRQ>';
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	//只有必填项
    	reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>10</minorno></CommonRequest><OrderEstInfo><ProductCode>'+productLst[0].Field3__c+'</ProductCode><ProductSubCode></ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge></Charge><DeliveryType>宅配便</DeliveryType><StaffPriceFlg></StaffPriceFlg><RepeaterFlg></RepeaterFlg><RepeaterPayType></RepeaterPayType><WorkContractStartDate></WorkContractStartDate><WorkContractFilter></WorkContractFilter><WorkContractRange></WorkContractRange><WorkContractTerm></WorkContractTerm><Amount></Amount></OrderEstInfo></OrderInfoRQ>';
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	List<Order__c> orders = [select Id,OrderStatus__c,OrderNo__c from Order__c];
    	//2个order、每个order一个明细
        reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>3</minorno></CommonRequest><OrderInfo> <OrderNo>' + orders[0].OrderNo__c + '</OrderNo> <Memo>製品は良くない</Memo> </OrderInfo></OrderInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	// SUB機能確認[5.4.注文履歴取得]
    	String userId = UserInfo.getUserId();
    	reqXml = '<OrderInfoRQ><CommonRequest><majorno>3</majorno><minorno>4</minorno></CommonRequest><ExtractionCondition><UserId>$_USERID_$</UserId></ExtractionCondition><OrderEstInfo><ProductCode>'+productLst[0].Field3__c+'</ProductCode><ProductSubCode>0001</ProductSubCode><StockUnit>瓶</StockUnit><Qty>1</Qty><PriceNoTax>40000</PriceNoTax><Charge>1200</Charge><DeliveryType>宅配便</DeliveryType><StaffPriceFlg>2</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>1</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>41000</Amount></OrderEstInfo><OrderEstInfo><ProductCode>'+productLst[1].Field3__c+'</ProductCode><ProductSubCode>0002</ProductSubCode><StockUnit>枚</StockUnit><Qty>3</Qty><PriceNoTax>10000</PriceNoTax><Charge>2100</Charge><DeliveryType>取りに行く</DeliveryType><StaffPriceFlg>3</StaffPriceFlg><RepeaterFlg>1</RepeaterFlg><RepeaterPayType>2</RepeaterPayType><WorkContractStartDate>20180101</WorkContractStartDate><WorkContractFilter>20170501,08:30-17:30</WorkContractFilter><WorkContractRange>20180101-20180315</WorkContractRange><WorkContractTerm>2</WorkContractTerm><Amount>32000</Amount></OrderEstInfo></OrderInfoRQ>';
    	reqXml = reqXml.replace('$_USERID_$',userId);
    	req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>3</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>4</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>10</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    
    public static List<AccountMasterProp__c> createMasterProp(Integer intNum) {
    	// 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[0].DisplayDate__c =Date.today();
        productLst[1].DisplayDate__c =Date.today();
        productLst[2].DisplayDate__c =Date.today();
        productLst[3].DisplayDate__c =Date.today();
        productLst[4].DisplayDate__c =Date.today();
        update productLst;
    	//サブ商品と属性関連情報作成する
    	List<AccountMasterProp__c> masterPropLst = new List<AccountMasterProp__c>();
        for (Integer i =0; i < intNum; i++) {
	        AccountMasterProp__c masterProp = new AccountMasterProp__c(
	            Field5__c = 1000,
	           AccountMasterRef__c = productLst[0].Id
	        );
        	masterPropLst.add(masterProp);
        }
        insert masterPropLst;
        return masterPropLst;
    }
    
    
    public static List<AccountMasterCharge__c> createMasterCharge(Integer intNum) {
    	// 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[0].DisplayDate__c =Date.today();
        productLst[1].DisplayDate__c =Date.today();
        productLst[2].DisplayDate__c =Date.today();
        productLst[3].DisplayDate__c =Date.today();
        productLst[4].DisplayDate__c =Date.today();
        update productLst;
    	//商品手数料情報作成する
    	List<AccountMasterCharge__c>  masterChargeLst = new List<AccountMasterCharge__c>();
        for (Integer i =0; i < intNum; i++) {
	        AccountMasterCharge__c masterCharge = new AccountMasterCharge__c(
	           MemberType__c = '3',
	           AccountMasterRef__c = productLst[0].Id,
	           Charge__c = 2
	        );
        	masterChargeLst.add(masterCharge);
        }
        insert masterChargeLst;
        return masterChargeLst;
    }
    static testMethod void getproductstocklistTest() {
        // 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getproductstocklist'; 
        //不指定抽出条件 
        String orgId = userInfo.getOrganizationId();
        String reqKey = '';
        for(AccountMaster__c accMaster : prods){
        	 reqKey += orgId + '-' + accMaster.nextitemcode__c;
        }
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>2</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><JobId></JobId><ProductCodes>$_PRODUCTCODES_$</ProductCodes></ExtractionCondition></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_PRODUCTCODES_$',reqKey);
        
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>2</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    static testMethod void orderinfoTest() {
    	// 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/orderinfo'; 
        //不指定抽出条件 
        String userId = UserInfo.getUserId();
        String orgId = userInfo.getOrganizationId();
        String reqKey = orgId + '-' + userId;
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>9</minorno></CommonRequest><ExtractionCondition><UserId>$_REQKEY_$</UserId></ExtractionCondition></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_REQKEY_$',reqKey);
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>3</majorno><minorno>9</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    static testMethod void getlinkproductlist() {
    	// 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/getlinkproductlist'; 
        
    	String userId = UserInfo.getUserId();
    	
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>4</majorno><minorno>1</minorno></CommonRequest><ExtractionCondition><UserId>$_REQKEY_$</UserId><ProductCodes>$_PRODUCTCODES_$</ProductCodes></ExtractionCondition></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_REQKEY_$', userId);
    	req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>4</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    static testMethod void notifyinfoTest() {
    	// 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/notifyinfo'; 
        
    	String userId = UserInfo.getUserId();
    	
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>5</majorno><minorno>1</minorno></CommonRequest><NotifyInfo><NofityTitle>NofityTitle</NofityTitle><NofityContent>NofityContent</NofityContent><NofityDateTime>20171022101214</NofityDateTime><NotifyTargetUserId>$_REQKEY_$</NotifyTargetUserId><IsNotifyAll>0</IsNotifyAll></NotifyInfo></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_REQKEY_$', userId);
    	req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>5</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    static testMethod void caseinfoTest() {
    	// 商品コード一覧をテストする
        List<AccountMaster__c> prods = TestCommon.createFullProductMst(6);
        for (AccountMaster__c acc : prods) {
            acc.DisplayDate__c = Date.today();
            acc.DeliveryType__c = '宅配便,代引';
            acc.ExpoWorkerRef__c = UserInfo.getUserId();
            acc.WorkContractStartDt__c = Date.today();
            acc.WorkContractStartEt__c = acc.WorkContractStartDt__c.addDays(30);
            acc.WorkUnitPriceType__c = '日';
            acc.Category__c = '食料';
            acc.CategorySub__c = '完成品';
        }
        update prods;
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/exposervice/V1/caseinfo'; 
        
    	String userId = UserInfo.getUserId();
        String orgId = userInfo.getOrganizationId();
        String reqKey = orgId + '-' + userId;
        String PRODUCTCODES = '';
        for(AccountMaster__c accMaster : prods){
        	 PRODUCTCODES += orgId + '-' + accMaster.nextitemcode__c;
        }
        String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>6</majorno><minorno>1</minorno></CommonRequest><CaseInfo><CaseTitle>納品の確認</CaseTitle><ProductCode>$_PRODUCTCODES_$</ProductCode><CaseContent>CaseContent</CaseContent><CaseDateTime>20171022101214</CaseDateTime><CaseOwnerUserId>$_CaseOwnerUserId_$</CaseOwnerUserId><OrderNo>STM_20171112_00000101</OrderNo><CaseNo>CAS-20171112-00000001</CaseNo></CaseInfo></GetMasterInfoRQ>';
        reqXml = reqXml.replace('$_CaseOwnerUserId_$', reqKey);
        reqXml = reqXml.replace('$_PRODUCTCODES_$', PRODUCTCODES);
    	req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>6</majorno><minorno>1</minorno></CommonRequest></GetMasterInfoRQ>';
        req.requestBody = Blob.valueOf(reqXml);
    	WS_ExpoEngineService.doPost();
    }
    
    // 2019/04/12 analytics テスト　
    static testMethod void analyticsTest() {
    	// 予約と会計作成を行う
    	TestCommon.createBillSimpleHelpConfigDoc();
    	TestCommon.createBillSimplePaymentConfigDoc();
    	TestCommon.createDeviceConfigXml();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
        // 2015/12/01 Assert END
        Contact guest = TestCommon.createContact();
        // 予約情報を作成する
        List<Lead__c> leadInfos = TestCommon.createLead(Date.today(), 1, 3, guest.Id);
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(4);
        // 見積明細を作成する
        AccountMaster__c accMstRoom = productLst[0];
        accMstRoom.ActionType__c = CommConst.PROD_ACTION_TYPE_RP;//室料
        update accMstRoom;
        TestCommon.createBookEstItem(leadInfos[0], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[1], productLst[0]);
        TestCommon.createBookEstItem(leadInfos[2], productLst[0]);
        // 商品２は前受付金に変更を行う
        AccountMaster__c accMst = productLst[1];
        accMst.ActionType__c = CommConst.PROD_ACTION_TYPE_AR;
        accMst.PaymentType__c = 'カード';  // XMLの定義と合わせるが必要です
        update accMst;
        AccountMaster__c accMstPay = productLst[3];
        accMstPay.ActionType__c = CommConst.PROD_ACTION_TYPE_PY;
        accMstPay.PaymentType__c = '現金';    // XMLの定義と合わせるが必要です
        update accMstPay;
        
        Test.startTest();
        TestCommon.createBookEstItem(leadInfos[0], productLst[1]);
        // 予約情報のステータス：チェックインに変更する
        leadInfos[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
        update leadInfos[0];
        
        
        // 会計画面に動作確認を行う
        List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfos[0].Id];
        AccountAcount__c accObj = accObjLst[0];

        ApexPages.StandardController contrl = new ApexPages.StandardController(accObj);
        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
        ctrl.initAction();
        ctrl.upsertData();
        
    	String begDt = system.now().format('yyyyMMdd');
    	String endDt = system.now().addDays(100).format('yyyyMMdd');
    	String reqXml = '<AnalyticsRQ><CommonRequest><majorno>8</majorno><minorno>1</minorno></CommonRequest>'+
        				'<ExtractionCondition><ArrivalDateFrom>'+begDt+'</ArrivalDateFrom><ArrivalDateTo>'+endDt+'</ArrivalDateTo></ExtractionCondition></AnalyticsRQ>';
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = ' /services/apexrest/exposervice/V1/analytics'; 

        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
        
        Test.stopTest();
    }
    
    static testMethod void shopInfoTest() {
        ReportLogo__c rep = TestCommon.createRepLogo();
        ShopInformation__c shop = TestCommon.createShopInfo();
        rep.ShopInfoRef__c = shop.Id;
        update rep;
    	String reqXml = '<GetMasterInfoRQ><CommonRequest><majorno>1</majorno><minorno>4</minorno></CommonRequest>'+
        				'<ExtractionCondition><OrganizationId>'+UserInfo.getOrganizationId()+'</OrganizationId><ShopCodes>'+shop.ShopCode__c+'</ShopCodes></ExtractionCondition></GetMasterInfoRQ>';
        RestRequest req = new RestRequest(); 
    	RestResponse res = new RestResponse();
        req.requestURI = ' /services/apexrest/exposervice/V1/getmasterinfo'; 
        req.requestBody = Blob.valueOf(reqXml);
    	req.httpMethod = 'POST';  
        RestContext.request = req;
    	RestContext.response = res;
    	WS_ExpoEngineService.doPost();
    	String rsXml = res.responseBody.tostring();
    	System.assert(!CommUtils.isBlank(rsXml));
    	// 取得結果を確認する
    	String emailStr = rsXml.substringBetween('<ShopMail>','</ShopMail>');
    	String phoneStr = rsXml.substringBetween('<ShopPhone>','</ShopPhone>');
    	System.assert(!CommUtils.isBlank(emailStr));
    	System.assert(!CommUtils.isBlank(phoneStr));
    }
}