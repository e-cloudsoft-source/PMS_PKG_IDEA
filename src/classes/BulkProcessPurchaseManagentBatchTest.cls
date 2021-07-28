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
private class BulkProcessPurchaseManagentBatchTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
        // 2015/12/01 Assert END
        //連絡結果　予約取り込待ち
        TestCommon.createLeadImportAndWaitImpot();
        RsvAccount__c item = new RsvAccount__c();
    	item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
    	//'20151113'
    	insert item;
    	ShopInformation__c shop = TestCommon.createShopInfo();
        Test.startTest();
    	Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
    	BulkProcessPurchaseManagentBatch batch = new BulkProcessPurchaseManagentBatch (shop.ShopCode__c, Date.today(), null, null);    
		ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
    }
    // 2015/12/30 ADD CASE
	static testMethod void addCase2() {
		// TO DO: implement unit test
		createConfigDoc();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
		// 2015/12/01 Assert END
		//連絡結果　予約取り込待ち
		TestCommon.createLeadImportAndWaitImpot();
		RsvAccount__c item = new RsvAccount__c();
		item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
		//'20151113'
		insert item;
		ShopInformation__c shop = TestCommon.createShopInfo();
		Test.startTest();
		Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
		BulkProcessPurchaseManagentBatch batch = new BulkProcessPurchaseManagentBatch (shop.ShopCode__c, Date.today(), null, null);    
		ID batchprocessid = Database.executeBatch(batch,1);
		Test.stopTest();
	}
    // 2015/12/30 ADD CASE
	static testMethod void addCase3() {
		// TO DO: implement unit test
		createConfigDoc();
		// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'AccountingSyncBatchConfig'].size(), 1);
		// 2015/12/01 Assert END
		//連絡結果　予約取り込待ち
		TestCommon.createLeadImportAndWaitImpot();
		RsvAccount__c item = new RsvAccount__c();
		item.name = Date.today().format().replaceAll('/','').replaceAll('-','');
		//'20151113'
		insert item;
		ShopInformation__c shop = TestCommon.createShopInfo();
		Test.startTest();
		Test.setMock(WebServiceMock.class, new TestCommonMockImpl());
		BulkProcessPurchaseManagentBatch batch = new BulkProcessPurchaseManagentBatch ();
		DateTime nowTime = DateTime.now().addSeconds(10);
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
		String jobName = DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, batch);
		//ID batchprocessid = Database.executeBatch(batch,1);
		Test.stopTest();
	}
     private static void createConfigDoc() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 -->    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- リクエストバッチ待ち時間の定義(秒数) 0の場合、待ちなし、１０秒後スケジュールを起動する -->        <REQBAT_WAIT_TIME>0</REQBAT_WAIT_TIME>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE>01</SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    }
}