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
private class PurchaseManagentBankCsvProcessTest {
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        
        // 仕入[Purchase__c][仕入先]
        RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		Account travel = new Account(
    		Name = '旅行会社_' + CommUtils.getRandom(10),
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
    	insert travel;
        ShopInformation__c shop = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shop;
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType  = :shopAccLocalName];
    	list<ShopAccountInfo__c> accInfLst = createShopAccount(shop,travel,rts);
    	String shopKouza = [select name from ShopAccountInfo__c where id = :accInfLst[1].Id].name;
    	createConfigDoc(shopKouza);
    	
    	List<Purchase__c> ps = new List<Purchase__c>();
    	for(integer i = 0 ; i < 1 ; i++){
    		Double status_idx = Math.random() * 1;
    		Double kamoku_idx = Math.random() * 4;
    		decimal incTax = Math.random() * 10000.9;
    		Purchase__c p = new Purchase__c(
    							KamokuLst__c = '買掛（月末振込）',
    							DenpyoukeiIncTax__c = incTax * 1.08,
    							Denpyoukei__c  = incTax,
    							Purchasesource__c = travel.id,
    							JinyaRevenue__c = rsv.id,
    							ShopInfoRef__c = shop.id
    						);
    		ps.add(p);
    	}
    	insert ps;
    	
    	//Purchase__c item = new Purchase__c();
    	//item.JinyaRevenue__c = rsv.id;
    	//item.Denpyoukei__c = 12000;
    	//insert item;
    	//insert travel;
    	//insert shop;

		Date stDate=rsv.Salesday__c;
   		Date edDate=rsv.Salesday__c;
   		AccountingSyncBatchHelp config=new AccountingSyncBatchHelp(shop.ShopCode__c);
        PurchaseManagentBankCsvProcess purProcess = new  PurchaseManagentBankCsvProcess(new List<Id>{travel.id},shop.ShopCode__c,stDate,edDate,edDate,config,false,null);
        purProcess.generalBankImportCsv(true);
        purProcess.generalBankImportCsvEnd(0,10);
        
    }
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test

        // 仕入[Purchase__c][仕入先]
		RsvAccount__c rsv = TestCommon.createRsvAccount();
        rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		Account travel = new Account(
    		Name = '旅行会社_' + CommUtils.getRandom(10),
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
    	insert travel;
        ShopInformation__c shop = new ShopInformation__c(
    		Name='東京都新宿区２号店'
    		,Fax__c = '03-1111-2222'
    		,Seq__c = Integer.valueOf(CommUtils.getRandom(8))
    		,WebSite__c = 'http://www.branch002.softpark.com'
    		,Email__c = 'east.baranch0002@softpark.com'
    		,Address__c = '東京都新宿区１番地２３手目４０６号'
    		,ShopCode__c = '02'
    		,Phone__c = '03-0222-11111'
    		,Post__c = '19100011'
    		,TierDefault__c = 'Tier1'
    		,FacilityCode__c = CommUtils.getRandom(4)
    	);
    	insert shop;
		String shopAccLocalName = ShopAccountInfo__c.sObjectType.getDescribe().getName();
        List<RecordType> rts = [SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType  = :shopAccLocalName];
    	list<ShopAccountInfo__c> accInfLst = createShopAccount(shop,travel,rts);
    	accInfLst[0].BankNumber__c = '4';
    	accInfLst[1].BankNumber__c = '4';
    	accInfLst[0].BankBranchNumber__c = '2';
    	accInfLst[1].BankBranchNumber__c = '2';
    	accInfLst[0].TransferChargeKbn__c = '自社負担';
    	accInfLst[1].TransferChargeKbn__c = '自社負担';
    	accInfLst[0].DepositsType__c = '貯蓄';
    	accInfLst[1].DepositsType__c = 'xx';
    	update accInfLst;
    	String shopKouza = [select name from ShopAccountInfo__c where id = :accInfLst[1].Id].name;
    	createConfigDoc(shopKouza);
    	
    	List<Purchase__c> ps = new List<Purchase__c>();
    	for(integer i = 0 ; i < 1 ; i++){
    		Double status_idx = Math.random() * 1;
    		Double kamoku_idx = Math.random() * 4;
    		decimal incTax = Math.random() * 10000.9;
    		Purchase__c p = new Purchase__c(
    							KamokuLst__c = '買掛（月末振込）',
    							DenpyoukeiIncTax__c = incTax * 1.08,
    							Denpyoukei__c  = incTax,
    							Purchasesource__c = travel.id,
    							JinyaRevenue__c = rsv.id,
    							ShopInfoRef__c = shop.id
    						);
    		ps.add(p);
    	}
    	insert ps;
		Date stDate=rsv.Salesday__c;
   		Date edDate=rsv.Salesday__c;
   		AccountingSyncBatchHelp config=new AccountingSyncBatchHelp(shop.ShopCode__c);
        PurchaseManagentBankCsvProcess purProcess = new  PurchaseManagentBankCsvProcess(new List<Id>{travel.id},shop.ShopCode__c,stDate,edDate,edDate,config,true,null);
        purProcess.generalBankImportCsv(true);
        purProcess.generalBankImportCsvEnd(0,10);
    }
    static testMethod void myUnitTest3() {
        // TO DO: implement unit test
		createConfigDoc();
        // 仕入[Purchase__c][仕入先]
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		rsv = [select Salesday__c from RsvAccount__c where id = :rsv.id];
		RecordType rt = [SELECT Id,Name FROM RecordType LIMIT 1];
		Account travel = TestCommon.createTravelCompany();
		ShopInformation__c shop = TestCommon.createShopInfo();
		
		AccountingSyncBatchHelp config=new AccountingSyncBatchHelp(shop.ShopCode__c);
		//system.debug(logginglevel.info,'<<====::::222::::====>>'+ [select AccountRef__c,Name,BankNumber__c,BankName__c,BankAccountNo__c,BankBranchNumber__c,BankBranchName__c,BankNameKana__c,BankBranchNameKana__c,RequestUserName__c,RequestUserCode__c,DepositsType__c from ShopAccountInfo__c]);
   		Date stDate=rsv.Salesday__c;
   		Date edDate=rsv.Salesday__c;
        PurchaseManagentBankCsvProcess purProcess = new  PurchaseManagentBankCsvProcess(new List<Id>{travel.id},shop.ShopCode__c,stDate,edDate,edDate,config,false,null);
        purProcess.generalBankImportCsv(true);
        purProcess.generalBankImportCsvEnd(0,10);
    }
	private static void createConfigDoc() {
    	createConfigDoc(null);
    }
	private static void createConfigDoc(String kouzaSeq) {
    	kouzaSeq = CommUtils.nullToBlank(kouzaSeq);
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 -->    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <ROUND_TYPE>1</ROUND_TYPE><!-- 手数料の端数処理区分 0:切り捨て / 1:四捨五入 / 2:切り上げ -->        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE><SAME_BANK><!-- 同銀行 --><SAME_BRANCH><!-- 同支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>0</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>0</RATE></RANK_LEVEL></SAME_BRANCH><DIFF_BRANCH><!-- 別支店 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>108</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>324</RATE></RANK_LEVEL></DIFF_BRANCH></SAME_BANK><DIFF_BANK><!-- 別銀行 --><RANK_LEVEL><MIN_VAL>0</MIN_VAL><MAX_VAL>9999</MAX_VAL><RATE>324</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>10000</MIN_VAL><MAX_VAL>29999</MAX_VAL><RATE>432</RATE></RANK_LEVEL><RANK_LEVEL><MIN_VAL>30000</MIN_VAL><RATE>648</RATE></RANK_LEVEL></DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        <PUR_SETTLEMENT><!-- 買掛決済バッチ -->        <KOUZA_SEQ>$$_KOUZA_SEQ_$$</KOUZA_SEQ><!-- 店舗口座情報#SEQ値 -->        <DESCRIPT>仕入支払口座</DESCRIPT>        <TRANS_TYPE>21</TRANS_TYPE><!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        </PUR_SETTLEMENT>        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        <DATA_KBN>1</DATA_KBN><!-- レコード種別:1:ヘッダレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_種別コード_$$$$_コード区分_$$$$_委託者コード_$$$$_委託者名_$$$$_取組日_$$$$_仕向金融機関番号_$$$$_仕向金融機関名_$$$$_仕向支店番号_$$$$_仕向支店名_$$$$_預金種目(依頼人)_$$$$_口座番号(依頼人)_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_HEADER><BANK_TELEGRAM_DETAIL><DATA_KBN>2</DATA_KBN><!-- レコード種別:2:データレコード --><IS_EDI>FALSE</IS_EDI><!-- EDI情報を使う --><IS_PLUSFORMAT>TRUE</IS_PLUSFORMAT><!-- $$_支払金額_$$,$$_先方負担手数料_$$,$$_振込手数料_$$追加情報を出力するがどうか --><!-- $$_識別表示_$$はYの場合、$$_顧客コード1_$$,$$_顧客コード2_$$全部長さ０空白文字を差し替え、$$_EDI情報_$$を設定する、 $$_識別表示_$$はY以外の場合、$$_顧客コード1_$$,$$_顧客コード2_$$は別々１０桁まで設定する、$$_EDI情報_$$は長さ０の空白文字を差し替え --><MESSAGE_LAYOUT>$$_データ区分_$$$$_被仕向金融機関番号_$$$$_被仕向金融機関名_$$$$_被仕向支店番号_$$$$_被仕向支店名_$$$$_手形交換所番号_$$$$_預金種目_$$$$_口座番号_$$$$_受取人名_$$$$_振込金額_$$$$_新規コード_$$$$_顧客コード1_$$$$_顧客コード2_$$$$_EDI情報_$$$$_振込区分_$$$$_識別表示_$$$$_ダミー_$$$$_支払金額_$$$$_先方負担手数料_$$$$_振込手数料_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_DETAIL><BANK_TELEGRAM_TRAILER><DATA_KBN>8</DATA_KBN><!-- レコード種別:8:トレーラレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_合計件数_$$$$_合計金額_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_TRAILER><BANK_TELEGRAM_END><DATA_KBN>9</DATA_KBN><!-- レコード種別:9:エンドレコード --><MESSAGE_LAYOUT>$$_データ区分_$$$$_ダミー_$$</MESSAGE_LAYOUT></BANK_TELEGRAM_END><!-- エージェント販売手数料計算関連 --><AGT_SALESRATE><I_TYPENAME>販売手数料</I_TYPENAME><!-- 種別 --><O_KAMOKU>買掛（月末振込）</O_KAMOKU><!-- 科目 --></AGT_SALESRATE><!-- カード販売手数料計算関連 --><CARD_SALESRATE><I_TYPENAME>支払手数料</I_TYPENAME><O_KAMOKU>買掛（月末振込）</O_KAMOKU></CARD_SALESRATE>    </SHOP></root>';
    	configXml = configXml.replace('$$_KOUZA_SEQ_$$',kouzaSeq);
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;   	
    }
    // [取引先口座情報][店舗口座情報]
    private static list<ShopAccountInfo__c> createShopAccount(ShopInformation__c shop,account acc,List<RecordType> recs) {
		List<ShopAccountInfo__c> saLst = new List<ShopAccountInfo__c>();
		Id shopRecId = null;
		Id AccRecId = null;
		for (RecordType rec : recs) {
			if (rec.DeveloperName == 'CompanyRecordType') shopRecId = rec.Id;
			else if (rec.DeveloperName == 'CustomerRecordType') AccRecId = rec.id;
		}
		ShopAccountInfo__c accKouza = new ShopAccountInfo__c(
			AccountRef__c = acc.id,
			BankNumber__c = CommUtils.getRandom(4),
			BankName__c = '住友銀行' + CommUtils.getRandom(6),
			BankAccountNo__c = CommUtils.getRandom(5),
			BankBranchNumber__c = CommUtils.getRandom(3),         
			BankBranchName__c = '目黒支店' + CommUtils.getRandom(6),
			BankNameKana__c = '来ぃう' + CommUtils.getRandom(3),
			BankBranchNameKana__c = '刈れ' + CommUtils.getRandom(3),
			RequestUserName__c = 'ｶﾏﾙｷ' + CommUtils.getRandom(7),
			AccountTypeLst__c  = '買掛支払',
			DepositsType__c = '普通' ,
			TransferChargeKbn__c = '先方負担',
			RecordTypeId = AccRecId
		);	
		ShopAccountInfo__c ShhopKouza = new ShopAccountInfo__c(
			ShopInfoRef__c = shop.id,
			BankNumber__c = CommUtils.getRandom(4),
			BankName__c = '住友銀行' + CommUtils.getRandom(6),
			BankAccountNo__c = CommUtils.getRandom(5),
			BankBranchNumber__c = CommUtils.getRandom(3),         
			BankBranchName__c = '目黒支店' + CommUtils.getRandom(6),
			BankNameKana__c = '来ぃう' + CommUtils.getRandom(3),
			BankBranchNameKana__c = '刈れ' + CommUtils.getRandom(3),
			RequestUserName__c = 'ｶﾏﾙｷ' + CommUtils.getRandom(7),
			DepositsType__c = '当座' ,
			TransferChargeKbn__c = '先方負担',
			RecordTypeId = shopRecId
		);
		saLst.add(accKouza);
		saLst.add(ShhopKouza);
		insert saLst;
		return saLst;
	}
}