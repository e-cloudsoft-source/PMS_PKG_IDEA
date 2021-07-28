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
@isTest(SeeAllData=false)
private class CommUtilsTest {

	static testMethod void validateMstData() {
		// 消費税マスタ定義のチェツク
		try {
			CommUtils.getTaxRate(Date.today());
		} catch (Exception e) {
			System.assert(true, '消費税マスタデータ設定不正、確認してください。');
		}
	}
	static testMethod void validateSplitMetod() {
		String time1 = '8:30';
		String time2 = '08:30:12';
		String time3 = '8';
		String time4 = '12';
		String time5 = null;
		String[] rs1 = CommUtils.splitTimes(time1);
		String[] rs2 = CommUtils.splitTimes(time2);
		String[] rs3 = CommUtils.splitTimes(time3);
		String[] rs4 = CommUtils.splitTimes(time4);
		String[] rs5 = CommUtils.splitTimes(time5);
		
		System.assertEquals(rs1[0], '8');
		System.assertEquals(rs1[1], '30');

		System.assertEquals(rs2[0], '08');
		System.assertEquals(rs2[1], '30');
		System.assertEquals(rs3[0], '8');
		System.assertEquals(rs3[1], '0');
		System.assertEquals(rs4[0], '12');
		System.assertEquals(rs4[1], '0');
		System.assertEquals(rs5[0], '0');
		System.assertEquals(rs5[1], '0');
	}
	static testMethod void validateKbProcess() {
		CommDefine__c comDef = null;
		List<CommDefine__c> existComDefList = Database.query(CommSqlUtils.generateQueryString('CommDefine__c') + ' limit 1');
		if (existComDefList.isEmpty()) {
			comDef = new CommDefine__c ();
			insert comDef;
		}
		// 区分１
		comDef.UnitPriceDefKb__c = 1;
		update comDef;
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(1050,1, 5, 10);
		System.assertEquals(prodInfo.unitPriceIncTax, 1050);
		System.assertEquals(prodInfo.unitPriceExcTax, 1000);
		System.assertEquals(prodInfo.unitPriceIncService, 105);
		System.assertEquals(prodInfo.unitPriceExcService, 100);
		System.assertEquals(prodInfo.unitPriceTax, 1155);
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 1100);

		System.assertEquals(prodInfo.priceIncTax, 1155);
		System.assertEquals(prodInfo.priceIncTaxNoService, 1050);
		System.assertEquals(prodInfo.priceExcTax, 1100);
		System.assertEquals(prodInfo.priceService, 105);
		System.assertEquals(prodInfo.priceServiceExcTax, 100);
		//System.assertEquals(prodInfo.priceTax, 55);

		User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
		System.runAs ( thisUser ) {
		// 区分２
		comDef.UnitPriceDefKb__c = 2;
		update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(1155,1, 5, 10);
        System.assertEquals(prodInfo.unitPriceIncTax, 1050);
        System.assertEquals(prodInfo.unitPriceExcTax, 1000);
        System.assertEquals(prodInfo.unitPriceIncService, 105);
        System.assertEquals(prodInfo.unitPriceExcService, 100);
        System.assertEquals(prodInfo.unitPriceTax, 1155);
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 1100);
		
		System.assertEquals(prodInfo.priceIncTax, 1155);
		System.assertEquals(prodInfo.priceIncTaxNoService, 1050);
		System.assertEquals(prodInfo.priceExcTax, 1100);
		System.assertEquals(prodInfo.priceService, 105);
		System.assertEquals(prodInfo.priceServiceExcTax, 100);
		//System.assertEquals(prodInfo.priceTax, 55);
		}
		// 区分３
		System.runAs ( thisUser ) {
		comDef.UnitPriceDefKb__c = 3;
		update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(1000,1, 5, 10);
        System.assertEquals(prodInfo.unitPriceIncTax, 1050);
        System.assertEquals(prodInfo.unitPriceExcTax, 1000);
        System.assertEquals(prodInfo.unitPriceIncService, 105);
        System.assertEquals(prodInfo.unitPriceExcService, 100);
        System.assertEquals(prodInfo.unitPriceTax, 1155);
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 1100);
		
		System.assertEquals(prodInfo.priceIncTax, 1155);
		System.assertEquals(prodInfo.priceIncTaxNoService, 1050);
		System.assertEquals(prodInfo.priceExcTax, 1100);
		System.assertEquals(prodInfo.priceService, 105);
		System.assertEquals(prodInfo.priceServiceExcTax, 100);
		//System.assertEquals(prodInfo.priceTax, 55);
		}
		
		Decimal speci1 = prodInfo.specialTaxCal(CommConst.ROOM_TAX_MONEY_LEV1 + 100);
		Decimal speci2 = prodInfo.specialTaxCal(CommConst.ROOM_TAX_MONEY_LEV2 + 100);
	}
	// 
	static testMethod void testUtilsMethod() {
		String nowStr = String.valueOf(System.now());
		Date todayDt = CommUtils.stringGmtToLocalDate(nowStr);
		//System.assertEquals(todayDt, Date.today(), todayDt);
		
		Decimal len1 = 10;
		String lpad = CommUtils.paddingLeftZero(len1, 3);
		System.assertEquals(lpad, '010');
		
		String phone1 = '03-0001-0111';
		String[] phoneArray = CommUtils.splitPhone(phone1);
		System.assertEquals(phoneArray.size(), 3);
		
		String post1 = '126-0011';
		String[] postArray = CommUtils.splitPost(post1);
		System.assertEquals(postArray.size(), 2);
		
		Date dayMonthsDt = Date.newInstance(2014,1,1);
		List<Date> dts = CommUtils.getDaysOfMonth(dayMonthsDt);
		System.assertEquals(dts.size(), 31);
		
		String errMsg = 'FIELD_CUSTOM_VALIDATION_EXCEPTION:FIELDXXXXX: []';
		String errMsgRes = Commutils.getFieldValidationMessage(errMsg);
		System.assertEquals(errMsgRes, 'FIELDXXXXX', errMsgRes);
		
		TestCommon.createTaxMst();
		Set<Date> todaytaxSet = new Set<Date>();
		todaytaxSet.add(date.today());
		Map<Date, Decimal> mapTax = CommUtils.getTaxRateMap(todaytaxSet);

		String s = '1.00';
		System.assertEquals(CommUtils.deleteRightZero(s), '1');
	}
	
	static testMethod void testMetaMethod() {
		//ConvByFielType
		List<String> fields = new List<String>{'Femails__c','Field295__c','BillIssue__c','SearchDate__c'};
		map<String,String> fieldValusMap = new map<String,String>();
		fieldValusMap.put('Femails__c','2');
		fieldValusMap.put('Field295__c','true');
		fieldValusMap.put('BillIssue__c','2015-10-21 08:31:49');
		fieldValusMap.put('SearchDate__c','2015-10-21');
System.debug(logginglevel.info,'fieldValusMap='+fieldValusMap);	
		Map<String, Schema.DescribeFieldResult> finalFieldMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),fieldValusMap.keySet());
System.debug(logginglevel.info,'finalFieldMap='+finalFieldMap);
		for(String fieldName : finalFieldMap.keySet()){
            Schema.DescribeFieldResult describeField = finalFieldMap.get(fieldName);
        	// デイフォル値を自動設定を行う
            Object val = CommUtils.ConvByFielType(fieldValusMap.get(fieldName), describeField.getType());
        }
        System.assert(!finalFieldMap.isEmpty(),finalFieldMap);
	}
	
    static testmethod void testRecordType() {

    	System.assertNotEquals(CommLogicProcess.getLeadCateringRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadBaseRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadEnkaiRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadBookingRecType(), null);
    }
    
	static testmethod void testSplitCsvSimple(){
	String line = 'abc,efg';
	String[] splitted = new CommCsvUtils.CsvReader(line).readLine();
	System.assertEquals(2, splitted.size());

	System.assertEquals('efg', splitted[1]);
	System.assertEquals('abc', splitted[0]);
	}

	static testmethod void testSplitCsvEOL(){
	String line = 'abc,';
	String[] splitted = new CommCsvUtils.CsvReader(line).readLine();
	System.assertEquals(2, splitted.size());

	System.assertEquals('', splitted[1]);
	System.assertEquals('abc', splitted[0]);
	}

	static testmethod void testSplitCsvQuotedSimple(){
	String line = '"abc,def,"';
	String[] splitted = new CommCsvUtils.CsvReader(line).readLine();
	System.assertEquals('abc,def,', splitted[0]);
	}

	static testmethod void testSplitCsvQuoted(){
	String line = '"abc"",def",gh"i,"jk""l",""';
	String[] splitted = new CommCsvUtils.CsvReader(line).readLine();
	System.assertEquals(4, splitted.size());
	System.assertEquals('gh"i', splitted[1]);
	System.assertEquals('abc",def', splitted[0]);
	System.assertEquals('jk"l', splitted[2]);
	System.assertEquals('', splitted[3]);
	}
	static testmethod void testSplitCsvQuoted2(){
	String line = 'AAAA,BBBB,"C"",""""""""EF","ED,""""GFH"';
	String[] splitted = new CommCsvUtils.CsvReader(line).readLine();
	System.assertEquals(4, splitted.size());
	System.assertEquals('AAAA', splitted[0]);
	System.assertEquals('BBBB', splitted[1]);
	System.assertEquals('C",""""EF', splitted[2]);
	System.assertEquals('ED,""GFH', splitted[3]);
	}

	static testmethod void testSplitCsvQuotedWithNewLine(){
	String line = '"abc,def\nBoo\nBoo",Test';
	CommCsvUtils.CsvReader reader = new CommCsvUtils.CsvReader(line);
	String[] splitted = reader.readLine();
	System.assertEquals('abc,def\nBoo\nBoo', splitted[0]);
	System.assertEquals('Test', splitted[1]);
	System.assertEquals(null, reader.readLine());
	}
	static testmethod void testSplitCsvQuotedWithEOT(){
	String line = '"abc,def\nBoo';
	CommCsvUtils.CsvReader reader = new CommCsvUtils.CsvReader(line);
	String[] splitted = reader.readLine();
	System.assertEquals('abc,def\nBoo', splitted[0]);
	System.assertEquals(null, reader.readLine());
	}

	static testmethod void testTabDelim(){
	String line = 'abc\tdef';
	CommCsvUtils.CsvReader reader = new CommCsvUtils.CsvReader(line, '\t');
	String[] splitted = reader.readLine();
	System.assertEquals('abc', splitted[0]);
	}

	static testmethod void testEmptyStrings(){
	String line = ',,,,';
	CommCsvUtils.CsvReader reader = new CommCsvUtils.CsvReader(line);
	String[] splitted = reader.readLine();
	System.assertEquals(5, splitted.size());
	for(String s: splitted){
	System.assertEquals('', s);
	}
	}

	// make sure we still get a result even if the source is empty...
	static testmethod void testEmptyString(){
	String line = '';
	CommCsvUtils.CsvReader reader = new CommCsvUtils.CsvReader(line);
	String[] splitted = reader.readLine();
	System.assertEquals(1, splitted.size());
	System.assertEquals('', splitted[0]);
	}
    testmethod static void Case001 () {
        String text1 = '"AA,""A","BB"",""B","処理内容1の"",,""確認""",処理内容2の確認,"""処理内容3の"",""確認,""",end';
        CommCsvUtils.CSVParser parse = new CommCsvUtils.CSVParser();
        String[] rs = parse.parseLine(text1);
        for (String s: rs) {
            System.debug(s + '\n');
        }
        String text2 = '"AA,""A","BB"",""B","処理内容1の"",,""確認""",処理内容2の確認,"""処理内容3の"",""確認,""",end' + '¥n';
        text2 += '' + '¥n';
        text2 += ',"BB"",""B","処理内容1の"",,""確認""",,"""処理内容3の"",""確認,""",end' + '¥n';
        text2 += '"AA,""A","BB"",""B","処理内容1の"",,""確認""",処理内容2の確認,"""処理内容3の"",""確認,""",end';
        text2 += '11W000008,0,中国　UHV 試験用変圧器,一般顧客向,一般顧客向,中国,"機種：変圧器　製品：　SP：XXXX0　ＮＥＴ：X5XXX　客先は発注見直し検討中（ランク：Ａ→Cへ変更）(10年中計：受注09年、売上10年、SPXX0, NETXX0, 販直X0)",Apr-11,Aug-12,東芝　太郎';
        rs = parse.parseLineMulti(text2);

        String text3 = '"SAB""';
        rs = parse.parseLine(text1);
		System.assert(rs!=null);
    }
    
	static testMethod void getRoleByLoginUser() {
		  Set<Id> userIds = CommRoleUtils.getRoleSubordinateUsers(UserInfo.getUserId());
		  System.assert(userIds!=null);
	}
	
   static testMethod void CommSqlUtilsMyunit() {
		String sql = CommSqlUtils.generateQueryString('Account');
		//CommSqlUtils.generateQueryString('Account',new Set<String>{'Contacts'});
		CommException exc = new CommException('テスト情報');
        System.assert(sql != null);
        // 会計と現金合せ履歴項目確認する
        // 設定情報を取得
		Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.CashVerification__c.fields.getMap();
		Map<String, String> customeFieldMap = new Map<String, String>();
		for(String fieldName : fieldsMap.keySet()) {
 			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			if(sField.isCustom()) {
				if (!sField.isCreateable()) continue;
           		customeFieldMap.put(sField.getLocalName(), sField.getLabel());
			}
		}
		String objectNm = 'CashVerification__c';
		sObject newObj = (sObject)Type.forName(objectNm).newInstance();
		Map<String, String> equMap = CommSqlUtils.getCustomeFieldLst(CashVerification__c.sObjectType, true);
		System.assertEquals(equMap.size(),customeFieldMap.size(),equMap);
		for (String key : customeFieldMap.keySet()) {
			System.assert(equMap.containsKey(key), equMap);
			System.assertEquals(customeFieldMap.get(key), equMap.get(key));
		}
		
		fieldsMap = Schema.SObjectType.AccountAcount__c.fields.getMap();
		customeFieldMap.clear();
		for(String fieldName : fieldsMap.keySet()) {
 			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			if(sField.isCustom()) {
				if (!sField.isCreateable()) continue;
           		customeFieldMap.put(sField.getLocalName(), sField.getLabel());
			}
		}
		objectNm = 'AccountAcount__c';
		newObj = (sObject)Type.forName(objectNm).newInstance();
		equMap.clear();
		equMap = CommSqlUtils.getCustomeFieldLst(AccountAcount__c.sObjectType, true);
		System.assertEquals(equMap.size(),customeFieldMap.size(),equMap);
		for (String key : customeFieldMap.keySet()) {
			System.assert(equMap.containsKey(key), equMap);
			System.assertEquals(customeFieldMap.get(key), equMap.get(key));
		}
		// ------ getAllFieldLst ----------
		fieldsMap = Schema.SObjectType.CashVerification__c.fields.getMap();
		customeFieldMap.clear();
		for(String fieldName : fieldsMap.keySet()) {
 			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			//if(sField.isCustom()) {
			if (!sField.isCreateable()) continue;
       		customeFieldMap.put(sField.getLocalName(), sField.getLabel());
			//}
		}
		objectNm = 'CashVerification__c';
		newObj = (sObject)Type.forName(objectNm).newInstance();
		Map<String, Schema.DescribeFieldResult> equMap2 = CommSqlUtils.getAllFieldLst(CashVerification__c.sObjectType, true);
		System.assertEquals(equMap2.size(),customeFieldMap.size(),equMap2);
		for (String key : customeFieldMap.keySet()) {
			System.assert(equMap2.containsKey(key), equMap2);
			System.assertEquals(customeFieldMap.get(key), equMap2.get(key).getLabel());
		}
			
		fieldsMap = Schema.SObjectType.AccountAcount__c.fields.getMap();
		customeFieldMap.clear();
		for(String fieldName : fieldsMap.keySet()) {
 			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			//if(sField.isCustom()) {
			if (!sField.isCreateable()) continue;
       		customeFieldMap.put(sField.getLocalName(), sField.getLabel());
			//}
		}
		objectNm = 'AccountAcount__c';
		newObj = (sObject)Type.forName(objectNm).newInstance();
		equMap2.clear();
		equMap2 = CommSqlUtils.getAllFieldLst(AccountAcount__c.sObjectType, true);
		System.assertEquals(equMap2.size(),customeFieldMap.size(),equMap2);
		for (String key : customeFieldMap.keySet()) {
			System.assert(equMap2.containsKey(key), equMap2);
			System.assertEquals(customeFieldMap.get(key), equMap2.get(key).getLabel());
		}
   }
   
	static testMethod void CommSecurityUtilsSelf() {
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Account.fields.getMap();
		List<String> fields = new List<String>{'Name','ID__c'};
		CommSecurityUtils.isCanCreateable(fields, m);
		CommSecurityUtils.isCanUpdateable(fields, m);
		CommSecurityUtils.isCanAccessible(fields, m);
		CommSecurityUtils.isCanUpsertable(fields, m);
		CommSecurityUtils.isDeleteable(Account.getSObjectType());
		CommSecurityUtils.isCanUpdateable(Account.getSObjectType());
		CommSecurityUtils.isCanUpdateLead();
		System.assert(m!=null);
	}	
	
	static testMethod void ReportTitleCompCtrl_myUnitTest() {

        ReportLogo__c item1 = new ReportLogo__c();
        item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
        item1.ReportLogo__c = 'TEST CONTEXT BODY';
        insert item1;
        
    	User curUser = [select ShopCode__c from User where id =: userInfo.getUserId()];
    	curUser.ShopCode__c = null;
    	update curUser;
    	
    	ReportTitleCompCtrl ctrl = new ReportTitleCompCtrl();
    	System.assert(!ctrl.isBranchShop);
    	ReportLogo__c rep = ctrl.reportInfo;
    }
    static testMethod void addUtilsMethodCase() {
    	String testString = 'abc123';
    	Integer testInteger = 123;
    	String escStr = CommUtils.escStr(testString);
    	System.assertEquals(testString, escStr);
    	// 文字列のバイト数を返す
    	Integer stringBytes = CommUtils.getBytes(testString);
    	String paddingLeftZero = CommUtils.paddingLeftZero(testString,9);
    	System.assertEquals(paddingLeftZero, '000abc123');
    	String deleteRightZero = CommUtils.deleteRightZero(testString,testInteger);

    	Set<String> setString = new Set<String>();
    	setString.add('USD');
    	setString.add('ARS');
    	setString.add('AWG');
    	setString.add('AUD');
    	setString.add('BSD');
    	setString.add('BBD');
    	setString.add('BYR');
    	setString.add('EUR');
    	setString.add('BZD');
    	setString.add('BMD');
    	setString.add('BOB');
    	setString.add('BAM');
    	setString.add('BWP');
    	setString.add('BRL');
    	setString.add('GBP');
    	setString.add('BND');
    	setString.add('CAD');
    	setString.add('KYD');
    	setString.add('CLP');
    	setString.add('CNY');
    	setString.add('COP');
    	setString.add('CRC');
    	setString.add('HRK');
    	setString.add('EUR');
    	setString.add('CZK');
    	setString.add('DKK');
    	setString.add('DOP');
    	setString.add('XCD');
    	setString.add('EGP');
    	setString.add('SVC');
    	setString.add('GBP');
    	setString.add('EEK');
    	setString.add('EUR');
    	setString.add('FKP');
    	setString.add('FJD');
    	setString.add('EUR');
    	setString.add('GHC');
    	setString.add('GIP');
    	setString.add('EUR');
    	setString.add('GTQ');
    	setString.add('GGP');
    	setString.add('GYD');
    	setString.add('EUR');
    	setString.add('HNL');
    	setString.add('HKD');
    	setString.add('HUF');
    	setString.add('ISK');
    	setString.add('IDR');
    	setString.add('EUR');
    	setString.add('IMP');
    	setString.add('EUR');
    	setString.add('JMD');
    	setString.add('JPY');
    	setString.add('JEP');
    	setString.add('LVL');
    	setString.add('LBP');
    	setString.add('LRD');
    	setString.add('CHF');
    	setString.add('LTL');
    	setString.add('EUR');
    	setString.add('MYR');
    	setString.add('EUR');
    	setString.add('MXN');
    	setString.add('MZN');
    	setString.add('NAD');
    	setString.add('ANG');
    	setString.add('EUR');
    	setString.add('NZD');
    	setString.add('NIO');
    	setString.add('NOK');
    	setString.add('PAB');
    	setString.add('PYG');
    	setString.add('PEN');
    	setString.add('PHP');
    	setString.add('PLN');
    	setString.add('RON');
    	setString.add('SHP');
    	setString.add('SGD');
    	setString.add('EUR');
    	setString.add('SBD');
    	setString.add('SOS');
    	setString.add('ZAR');
    	setString.add('EUR');
    	setString.add('SEK');
    	setString.add('CHF');
    	setString.add('SRD');
    	setString.add('SYP');
    	setString.add('TWD');
    	setString.add('TTD');
    	setString.add('TRY');
    	setString.add('TRL');
    	setString.add('TVD');
    	setString.add('GBP');
    	setString.add('USD');
    	setString.add('UYU');
    	setString.add('EUR');
    	setString.add('VEF');
    	setString.add('ZWD');
    	setString.add('KRW');
    	for (String w : setString) {
    		String currencySymbol = CommLocalUtils.getCurrencySymbol(w);
    	}
    }
    // 2016/03/01 マイナス計算と税抜きの端末処理
    // 会計のマイナス金額の計算制御区分はFALSE、会計の税抜金額端数処理区分制御はFALSE
    // 単価定義区分：1,2,3,4 端数処理：0,1,2
    static testMethod void minus_001() {
    	// Default値、会計のマイナス金額の計算制御区分はFALSE、会計の税抜金額端数処理区分制御はFALSE
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	//comDef.AccountMinusCalFlg__c = false;
    	comDef.AccountNoTaxCalFlg__c = false;
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 1;
    	update comDef;
    	// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = ０(切り捨て)
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9260);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10186);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10185); 
		
		// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9260);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10186);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10185); 

		// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9260);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10186);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10185); 	
		
		
		// ************* 単価定義区分２の場合、***********/
    	// 会計商品単価定義区分 = 2(税込:サービス込)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 2;// 2(税込:サービス込)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9091);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8418);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9260);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9091);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8417);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9259);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9091);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8418);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9260);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9090);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8417);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9259);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9092);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8418);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9260);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9090);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8417);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9259);
		
		// ************* 単価定義区分３の場合、***********/
    	// 会計商品単価定義区分 = 3(税抜、サービス料抜き)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 3;// 3(税抜、サービス料抜き)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8239);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8392);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8240);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9064);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8391);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8239);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8392);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8239);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8391);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8240);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9064);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8392);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8239);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8391);
		
		// ************* 単価定義区分4の場合、***********/
    	// 会計商品単価定義区分 = 4(税抜、サビース料込)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 4;// 4(税抜、サビース料込)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9818);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10001);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9819);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10801);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10000);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9818);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10001);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9818);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10000);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9819);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10801);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10001);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9818);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10000);
    }

    // 会計のマイナス金額の計算制御区分はTRUE、会計の税抜金額端数処理区分制御はTRUE
    // 単価定義区分：1,2,3,4 端数処理：0,1,2
    static testMethod void minus_003() {
    	// Default値、会計のマイナス金額の計算制御区分はFALSE、会計の税抜金額端数処理区分制御はFALSE
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	//comDef.AccountMinusCalFlg__c = true;
    	comDef.AccountNoTaxCalFlg__c = true;
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 1;
    	update comDef;
    	// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = ０(切り捨て)
		CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10185);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10185); 
		
		// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10185);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9259);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10185); 

		// 会計商品単価定義区分 = 1(税込、サービス料抜き)　会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, 9260);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10186);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -10000);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9260);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -11000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10186); 	
		
		
		// ************* 単価定義区分２の場合、***********/
    	// 会計商品単価定義区分 = 2(税込:サービス込)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 2;// 2(税込:サービス込)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9090);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8417);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9259);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9090);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8417);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9259);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9091);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8418);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9259);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9091);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8418);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9259);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9092);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 8418);
		// 単価（税込、サービス料込）7653
		System.assertEquals(prodInfo.unitPriceTax, 10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 9260);
		// マイナス処理の場合
		prodInfo.process(-10000,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9092);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -8418);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10000);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -9260);
		
		// ************* 単価定義区分３の場合、***********/
    	// 会計商品単価定義区分 = 3(税抜、サービス料抜き)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 3;// 3(税抜、サービス料抜き)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8239);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8391);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8239);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8391);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8239);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8392);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8239);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9063);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8392);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 8240);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 9064);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 8392);
		// マイナス処理の場合
		prodInfo.process(-7629,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -8240);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -7629);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -9064);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -8392);
		
		// ************* 単価定義区分4の場合、***********/
    	// 会計商品単価定義区分 = 4(税抜、サビース料込)　会計税の端数処理 = ０(切り捨て)
    	comDef.RoundType__c = 0;// (切り捨て)
    	comDef.UnitPriceDefKb__c = 4;// 4(税抜、サビース料込)　
    	update comDef;
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9818);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10000);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9818);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10000);
		
		// 会計税の端数処理 = 1(四捨五入)
    	comDef.RoundType__c = 1;// (四捨五入)
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9818);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10000);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9818);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10800);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10000);

		// 会計税の端数処理 = 2(切上げ)
    	comDef.RoundType__c = 2;
    	update comDef;
		// 確認する
		prodInfo = new CommUtils.ProductInfo();
		prodInfo.process(10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, 9819);
		// 本体単価（税抜）8753
		System.assertEquals(prodInfo.unitPriceExcTax, 9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, 10801);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, 10001);
		// マイナス処理の場合
		prodInfo.process(-10000.1,1, 8, 10);
		// 本体単価（税込）
		System.assertEquals(prodInfo.unitPriceIncTax, -9819);
		// 本体単価（税抜）
		System.assertEquals(prodInfo.unitPriceExcTax, -9091);
		// 単価（税込、サービス料込）
		System.assertEquals(prodInfo.unitPriceTax, -10801);
		// 単価（サービス料込、税抜き）
		System.assertEquals(prodInfo.unitPriceIncServiceExcTax, -10001);
    }
    
    static testMethod void commBaseCtrl_001() {
    	System.assert(CommBaseCtrl.getNumberFormat() != null);
    	System.assert(CommBaseCtrl.getPointLen() != null);
    	System.assert(CommBaseCtrl.getTaxNumberFormat() != null);
    	System.assert(CommBaseCtrl.getTaxPointLen() != null);
    	System.assert(CommBaseCtrl.getCurrencySybmol() != null);
    	System.assert(CommBaseCtrl.getLocalIsJapanese() != null);
    	System.assert(CommBaseCtrl.getUnitPriceDefKbn() != null);
    	System.assert(CommBaseCtrl.getRoundType() != null);
    	System.assert(CommBaseCtrl.getNs() != null);
    }
    static testMethod void CommUtilsIsBirthday_001() {
    	Integer y = 1900;
    	Integer m = 12;
    	Integer d = 10;
    	Boolean v = CommUtils.isBirthday(y,m,d);
    	System.assert(v);
    }
    
    static testMethod void CommRepUtilsCase_001 () {
        String a = 'あああああああああああああああああああああああああああああ';//29
        String[] ret = CommRepUtils.getPdfMaxShowStringNews(a,17,24,true);
        System.assertEquals(ret.size(),2);
        ret = CommRepUtils.getPdfMaxShowStringNews(a,17,29,true);
        System.assertEquals(ret.size(),1);
        ret = CommRepUtils.getPdfMaxShowStringNews(a,17,30,true);
        System.assertEquals(ret.size(),1);
        a = 'あああうううああああ\nああああああああああああああああああ';//31
        ret = CommRepUtils.getPdfMaxShowStringNews(a,3,4,true);
        System.assertEquals(ret.size(),3);
        a = 'あああうううああああ\nああああああああああああああああああ';//31
        ret = CommRepUtils.getPdfMaxShowStringNews(a,1,4,true);
        System.assertEquals(ret[0],'あああう');
        System.assertEquals(ret.size(),1,ret);
        
    }
    static testMethod void CommConvertTimeCase_001 () {
    	Date todayDt = system.today();
    	String todayDtStr = todayDt.format() + ' ';
    	Date tommDt = todayDt.addDays(1);
    	String tomorrowStr = tommDt.format() + ' ';
    	Datetime dt = CommUtils.convertDatetime(todayDt,'9:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), todayDtStr + '09:00');
    	dt = CommUtils.convertDatetime(todayDt,'9:30:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), todayDtStr + '09:30');
    	dt = CommUtils.convertDatetime(todayDt,'09:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), todayDtStr + '09:00');
    	dt = CommUtils.convertDatetime(todayDt,'09:00:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), todayDtStr + '09:00');
    	dt = CommUtils.convertDatetime(todayDt,'24:00:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), tomorrowStr + '00:00');
    	dt = CommUtils.convertDatetime(todayDt,'28:00:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), tomorrowStr + '04:00');
    	dt = CommUtils.convertDatetime(todayDt,'28');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), tomorrowStr + '04:00');
    	dt = CommUtils.convertDatetime(todayDt,'28:00');
    	System.assertEquals(dt.format('yyyy/MM/dd HH:mm'), tomorrowStr + '04:00');
    }
    
    // CommLogUtils テスト補足
    static testmethod void testCommLogCase_001() {
    	CommLogUtils log = new CommLogUtils('CommUtilsTest',true);
    	log.write_method_start('stat-begin');
    	log.write_method_end();
    	log.write_method_end();
    }
    
    // CommStringUtils
    static testmethod void testCommStringUtils() {
    	String a = '今野 蓮';
    	String b = CommStringUtils.convertRomanToKana(a,true);
    	System.assertEquals(a, b, b);

		a = 'yama to';
    	b = CommStringUtils.convertRomanToKana(a,true);
    	System.assertEquals('ヤマ ト', b, b);

		a = 'tanaka sama';
    	b = CommStringUtils.convertRomanToKana(a,true);
    	System.assertEquals('タナカ サマ', b, b);
    	
		a = 'jack moku';
    	b = CommStringUtils.convertRomanToKana(a,true);
    	System.assertEquals(a, b, b);
    }
}