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
private class PurchaseManagentInputTest {

    static testMethod void myUnitTest() {
    	createConfigDoc();
    	getCsvSetupConfig1();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
		// 2015/12/01 Assert END
    	String[] status = new String[]{'申請','処理済'};
    	String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
    	String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
     	List<Purchase__c> ps = new List<Purchase__c>();
     	RsvAccount__c item = new RsvAccount__c();
    	item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
    	//'20151113'
    	insert item;
     	Account guest = new Account(
    		Name = '旅行会社_' ,
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		RoundType__c = '1',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
     	insert guest;
     	Account guest1 = new Account(
    		Name = '旅行会社_' ,
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		RoundType__c = '1',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
     	insert guest1;
     	ShopInformation__c shop = TestCommon.createShopInfo();
    	for(integer i = 0 ; i < 10 ; i++){
    		Double status_idx = Math.random() * 1;
    		Double kamoku_idx = Math.random() * 4;
    		decimal incTax = Math.random() * 10000.9;
    		Purchase__c p = new Purchase__c(
    							StatusLst__c = status[Integer.valueOf(status_idx)],
    							KamokuLst__c = kamokus[Integer.valueOf(kamoku_idx)],
    							DenpyoukeiIncTax__c = incTax * 1.08,
    							Denpyoukei__c  = incTax,
    							Purchasesource__c = guest.id,
    							JinyaRevenue__c = item.id,
    							PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
    							ShopInfoRef__c = shop.id
    						);
    		ps.add(p);
    	}
    	insert ps;
    	 // 予定表情報のＪＳＯＮを作成する
        String purString = JSON.serialize(ps[0]);

		Cookie purchaseCookieShopInfo = new Cookie('_PurchaseManageInput_cookie_purchase', purString , null, -1, true);
		Cookie purchaseCookieMemoInfo = new Cookie('_PurchaseManageInput_cookie_purchase_memo', '333333333' , null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{purchaseCookieShopInfo,purchaseCookieMemoInfo});
        // TO DO: implement unit test
        PurchaseManagentInput input = new PurchaseManagentInput();
        input.currentShopCode = shop.ShopCode__c;
        input.init();
        Purchase__c p = new Purchase__c(
							StatusLst__c = status[1],
							KamokuLst__c = kamokus[1],
							DenpyoukeiIncTax__c = 5000,
							Denpyoukei__c  = 5000/1.08,
							Purchasesource__c = guest.id,
							JinyaRevenue__c = item.id,
							PurchaseType__c = purType[3]
						);
        PurchaseManagentInput.ItemInfo a = input.inpData;
        Purchase__c purchase = a.pur;
        purchase.StatusLst__c = status[1];
		purchase.KamokuLst__c = kamokus[1];
		purchase.DenpyoukeiIncTax__c = 5000;
		purchase.Denpyoukei__c  = 5000/1.08;
		purchase.Purchasesource__c = guest.id;
		purchase.JinyaRevenue__c = item.id;
		purchase.PurchaseType__c = purType[3];
		input.inpData.salesDt = System.today();
		a.salesDt = System.today();
		a.shopCode = shop.ShopCode__c;
		input.editRowIdx = 0;
        input.dataUpsert();
        a.pur.Purchasesource__c = guest.id;
        a.purchasesourceName = guest.Name;
       	//input.refreshBranShop();
       	input.dataUpsert();
       	input.editRowIdx = 1;
       	input.dataUpsert();
       	input.dataSearch();
       	input.deleteRowIdxs = '1,2';
       	input.historyEdit();
       //	input.dataRollBack();
       	input.deleteData();
       	input.firstPage();
       	input.previousPage();
       	input.nextPage();

       	input.lastPage();
//       	input.chgPageSize();
       	PurchaseManagentInput.getAccount(guest.id,guest.Name);
       	PurchaseManagentInput.getAccount(null,guest.Name);
       	//input.batchExceute();
       	// number数据类型   => 过滤条件 => [查询值==输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','EQ'});
       	input.filterDataSerch();
       	// number数据类型   => 过滤条件 => [查询值!=输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','NEQ'});
       	input.filterDataSerch();
       	// number数据类型   => 过滤条件 => [查询值>=输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','GTE'});
       	input.filterDataSerch();
       	// number数据类型   => 过滤条件 => [查询值> 输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','GT'});
       	input.filterDataSerch();
       	// number数据类型   => 过滤条件 => [查询值<=输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','LTE'});
       	input.filterDataSerch();
       	// number数据类型   => 过滤条件 => [查询值< 输入值]
       	input.filter.filterDataJson = getFilterDataJson(new list<String>{'1','LT'});
       	input.filterDataSerch();
    }
    static testMethod void myUnitTest1() {
    	createConfigDoc();
    	getCsvSetupConfig1();
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
		// 2015/12/01 Assert END
    	String[] status = new String[]{'申請','処理済'};
    	String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
    	String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
     	List<Purchase__c> ps = new List<Purchase__c>();
     	RsvAccount__c item = new RsvAccount__c();
    	item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
    	//'20151113'
    	insert item;
     	Account guest = TestCommon.createTravelCompany() ;
     	guest.RoundType__c = '1';
     	update guest;
     	ShopInformation__c shop = TestCommon.createShopInfo();
    	for(integer i = 0 ; i < 1 ; i++){
    		decimal incTax = Math.random() * 10000.9;
    		Purchase__c p = new Purchase__c(
    							StatusLst__c = status[0],
    							KamokuLst__c = kamokus[1],
    							DenpyoukeiIncTax__c = incTax * 1.08,
    							Denpyoukei__c  = incTax,
    							Purchasesource__c = guest.id,
    							JinyaRevenue__c = item.id,
    							PurchaseType__c = purType[2],
    							ShopInfoRef__c = shop.id
    						);
    		ps.add(p);
    	}
    	insert ps;
    	update ps[0];
    	 // 予定表情報のＪＳＯＮを作成する
        String purString = JSON.serialize(ps[0]);

		Cookie purchaseCookieShopInfo = new Cookie('_PurchaseManageInput_cookie_purchase', purString , null, -1, true);
		Cookie purchaseCookieMemoInfo = new Cookie('_PurchaseManageInput_cookie_purchase_memo', '333333333' , null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{purchaseCookieShopInfo,purchaseCookieMemoInfo});
        // TO DO: implement unit test
        PurchaseManagentInput input = new PurchaseManagentInput();
        input.currentShopCode = shop.ShopCode__c;
        input.init();
        Purchase__c p = new Purchase__c(
							StatusLst__c = status[1],
							KamokuLst__c = kamokus[1],
							DenpyoukeiIncTax__c = 5000,
							Denpyoukei__c  = 5000/1.08,
							Purchasesource__c = guest.id,
							JinyaRevenue__c = item.id,
							PurchaseType__c = purType[3]
						);
        PurchaseManagentInput.ItemInfo a = input.inpData;
        Purchase__c purchase = a.pur;
        purchase.StatusLst__c = status[1];
		purchase.KamokuLst__c = kamokus[1];
		purchase.DenpyoukeiIncTax__c = 5000;
		purchase.Denpyoukei__c  = 5000/1.08;
		purchase.Purchasesource__c = guest.id;
		purchase.JinyaRevenue__c = item.id;
		purchase.PurchaseType__c = purType[3];
		a.salesDt = System.today();
		a.shopCode = shop.ShopCode__c;
		input.editRowIdx = 0;
        a.pur.Purchasesource__c = guest.id;
        a.purchasesourceName = guest.Name;
        input.dataUpsert();
       	input.editRowIdx = 1;
       	input.deleteRowIdxs = '1,2';
       	input.batchExceute();
       	input.init();
       	Purchase__c inputPur = new Purchase__c(
							StatusLst__c = status[1],
							KamokuLst__c = kamokus[1],
							DenpyoukeiIncTax__c = 5000,
							Purchasesource__c = guest.id,
							JinyaRevenue__c = item.id,
							PurchaseType__c = purType[3]
						);
		insert inputPur;
		inputPur.DenpyoukeiIncTax__c = 0;
		inputPur.Denpyoukei__c = 600;
		update inputPur;

		PurchaseManagentInput.getProductViewInfo();
		TestCommon.createOrderConfigXml();
		input.initDevice();
		input.getPicklistLst('name');
		PurchaseManagentInput.savePrintLodToDb('123');
		PurchaseManagentInput.getProductItemInfo('002');
    }
    static testMethod void sf1Test() {
    	createConfigDoc();
    	getCsvSetupConfig1();
        // TO DO: implement unit test
        String[] status = new String[]{'申請','処理済'};
    	String[] kamokus = new String[]{'現金','買掛（月末振込）','買掛（都度振込）','事前振込','クレジットカード'};
    	String[] purType = new String[]{'材料仕入','売店仕入','飲料仕入','室料経費','ブライダル仕入'};
     	List<Purchase__c> ps = new List<Purchase__c>();
     	RsvAccount__c item = new RsvAccount__c();
    	item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
    	//'20151113'
    	insert item;
     	Account guest = new Account(
    		Name = '旅行会社_' ,
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		RoundType__c = '1',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
     	insert guest;
     	Account guest1 = new Account(
    		Name = '旅行会社_' ,
    		SalesOfficeCompanyCode__c = CommUtils.getRandom(10),
    		AccountType__c = '旅行会社',
    		ContractStatus__c = '有効',
    		RoundType__c = '1',
    		SalesOfficeCompanyType__c = '旅行会社'
    	);
     	insert guest1;
     	ShopInformation__c shop = TestCommon.createShopInfo();
    	for(integer i = 0 ; i < 10 ; i++){
    		Double status_idx = Math.random() * 1;
    		Double kamoku_idx = Math.random() * 4;
    		decimal incTax = Math.random() * 10000.9;
    		Purchase__c p = new Purchase__c(
    							StatusLst__c = status[Integer.valueOf(status_idx)],
    							KamokuLst__c = kamokus[Integer.valueOf(kamoku_idx)],
    							DenpyoukeiIncTax__c = incTax * 1.08,
    							Denpyoukei__c  = incTax,
    							Purchasesource__c = guest.id,
    							JinyaRevenue__c = item.id,
    							PurchaseType__c = purType[Integer.valueOf(kamoku_idx)],
    							ShopInfoRef__c = shop.id
    						);
    		ps.add(p);
    	}
    	insert ps;
    	
    	//做添付文件
        Attachment a = new Attachment (ParentId = ps[0].Id,
	                                       Body = blob.valueOf(''),
	                                       Name = 'Name001');
	    insert a;
	    
		ApexPages.currentPage().getParameters().put('cid',ps[0].Id);
        ApexPages.StandardController contrl = new ApexPages.StandardController(ps[0]);
        PurchaseManagentInputSf1 purSf1 = new PurchaseManagentInputSf1(contrl);
        purSf1.getPointLen();
        purSf1.getCurrencySybmol();
        purSf1.getNs();
        purSf1.getNumberFormat();
        String vStr = purSf1.viewPrefix;
		purSf1.InitEdit();
		purSf1.InitView();
		
		PurchaseManagentInputSf1.getAccount(guest1.Id);
		PurchaseManagentInputSf1.rsvRetrieve('',new List<String>(),new Map<String, Object>());
		
		PurchaseManagentInputSf1.getAccount('');
		PurchaseManagentInputSf1.rsvRetrieve('',new List<String>(),new Map<String, Object>{'Name'=>'%#&'});

        ApexPages.StandardController contrl1 = new ApexPages.StandardController(ps[0]);
        PurchaseManagentInputSf1 purSf11 = new PurchaseManagentInputSf1(contrl1);
        
		purSf11.InitEdit();
		purSf11.InitView();
    }

    private static void createConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 -->    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>  <FILTERBUTTON>        	<BUTTON>        		<LABEL>事前振込出力</LABEL>        		<!-- default cookie equal label name -->        		<COOKIE></COOKIE>        		<FILTER>KamokuLst__c in (\'買掛（都度振込）\') </FILTER>        	</BUTTON>        	<BUTTON>        		<LABEL>都度振込出力</LABEL>        		<!-- default cookie equal label name -->        		<COOKIE></COOKIE>        		<FILTER>KamokuLst__c in (\'買掛（月末振込）\') </FILTER>        	</BUTTON>        	<BUTTON>        		<LABEL>月末振込出力</LABEL>        		<FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        	</BUTTON>        </FILTERBUTTON>      <!-- リクエストバッチ待ち時間の定義(秒数) 0の場合、待ちなし、１０秒後スケジュールを起動する -->        <REQBAT_WAIT_TIME>0</REQBAT_WAIT_TIME>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE>01</SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
     private static void getCsvSetupConfig1() {
		List<KanjoKamoku__c> kkan = TestCommon.createKanjoKanmoku(2);
	    kkan[0].DebitTaxKbn__c = '非課税';
		kkan[1].DebitTaxKbn__c = '課税';
		update kkan;
        String xml = 
        '<?xml version="1.0" encoding="UTF-8"?>'+
        '<root>'+
        '<SHOP>'+
        '<SHOPCODE></SHOPCODE>'+
        '<PURCHASE><P_TYPE NOTAXKBN_KEY="NOTAX"><CONVERT><TYPENAME>材料仕入</TYPENAME>  <KANJOCODE>'+kkan[0].Kanjocode__c+'</KANJOCODE></CONVERT>'+
	 	'<CONVERT><TYPENAME>売店仕入</TYPENAME>  <KANJOCODE>'+kkan[1].Kanjocode__c+'</KANJOCODE>  </CONVERT></P_TYPE>'+
	 	'<P_KAMOKU> <CONVERT><TYPENAME>現金</TYPENAME><KANJOCODE>2</KANJOCODE></CONVERT><CONVERT><TYPENAME>買掛（月末振込）</TYPENAME><KANJOCODE>212</KANJOCODE></CONVERT> </P_KAMOKU></PURCHASE>'+
        '</SHOP>'+
        '</root>';
        Document doc = new Document();
        doc.Name = 'SyncFieldConvertConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(xml);
        insert doc;
        
    }
    // 做FilterDataJson
    private static String getFilterDataJson(List<String> typeLst) {
    	Map<String,list<String>> filterMap = new Map<String,list<String>>{ 
       		 									'PurchaseType__c' => typeLst,
       		 									'KamokuLst__c' => typeLst,
       		 									'Field1__c' => new List<String>{'2017/01/01'},
       		 									'Purchasesource__r.Name' => typeLst,
       		 									'Denpyoukei__c' => typeLst,
       		 									'DenpyoukeiIncTax__c' => typeLst};
       	return JSON.serialize(filterMap);
    }
}