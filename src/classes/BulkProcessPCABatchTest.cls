@isTest
private class BulkProcessPCABatchTest {

    static testMethod void case01(){
        Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END

        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.SchedulePcaDeviationDays__c = 0;
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        update comDef;
		
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch();
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);

        Test.stopTest();

    }
    // パラメータなし
    static testMethod void case02(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;

        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',Date.today(),null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
        System.assert(rsAtt.isEmpty(), rsAtt);
    }
    // パラメータ:1
    static testMethod void case03(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '1';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;
        
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',Date.today(),null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
        System.assert(rsAtt.isEmpty(), rsAtt);
    }
    // パラメータ:2
    static testMethod void case04(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '2';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;
        
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',date.today(),null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }

    // パラメータ:3
    static testMethod void case05(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '3';
        comDef.SchedulePcaDeviationDays__c = 0;
        update comDef;
        
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',date.today(),null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_PCA);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }
    static testMethod void case06(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createSimpleRsvAccount();
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '2';
        comDef.SchedulePcaDeviationDays__c = 1;
        update comDef;

        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
         
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',date.today(),null,null,BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }

    // 期間指定のスケジュールを起動確認のケース
    static testMethod void case07(){
    	Document doc1 = new Document();
        doc1.Name = 'SyncFieldConvertConfig';
        doc1.DeveloperName = doc1.Name;
        doc1.FolderId = UserInfo.getUserId();
        doc1.Body = Blob.valueOf(getCsvSetupConfig());
        insert doc1;
        
        Document doc2 = new Document();
        doc2.Name = 'BillSimpleHelpConfig';
        doc2.DeveloperName = doc2.Name;
        doc2.FolderId = UserInfo.getUserId();
        doc2.Body = Blob.valueOf(getCsvSetupConfig2());
        insert doc2;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'SyncFieldConvertConfig'].size(), 1);
        // 2015/12/01 Assert END
        RsvAccount__c rsv = createSimpleRsvAccount();
        List<CollaborationGroup> groups = TestCommon.createGroups(1);
        CommDefine__c comDef = TestCommon.createCommDefine();
        comDef.ScheduleResultMailAddress__c = '111@aaa.com';
        comDef.SchedulePcaResultSendType__c = '3';
        comDef.SchedulePcaDeviationDays__c = 0;
        comDef.ChatterGroupName__c = '4:'+groups[0].name + ';4,4:';
        update comDef;


        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(1);
        // 見積明細を作成する
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        // 予約情報のステータス：チェックインに変更する
        leadInfo.Field298__c = 'チェックイン完';
        update leadInfo;
          
        Test.startTest();
        BulkProcessPCABatch bppb = new BulkProcessPCABatch('',date.today(),date.today(),new list<string>{'PCABatch'},BulkProcessPCABatch.CSV_OUTPUT_MODE_FREEE);
        DateTime nowTime = DateTime.now().addSeconds(100);
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
        String jobId = system.schedule(jobName, sch, bppb);
        Test.stopTest();
        // パラメータ設定なしの場合、メール送信を行う
        List<Attachment> rsAtt = [select id from attachment where parentId = :rsv.Id];
    }
    // 指定バッチを実施する
    
    private static String getCsvSetupConfig() {
    	String configXml = '<?xml version="1.0" encoding="utf-8"?><root><!-- 概要：銀行振り込み情報作成の関連定義情報 -->    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE></SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- リクエストバッチ待ち時間の定義(秒数) 0の場合、待ちなし、１０秒後スケジュールを起動する -->        <REQBAT_WAIT_TIME>0</REQBAT_WAIT_TIME>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP>    <SHOP>        <!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->        <SHOPCODE>01</SHOPCODE>        <!-- 処理通知先メールアドレス,「,」で複数メールアドレス定義可能（５個まで） -->        <RESULT_MAIL>sankyou.go@m.e-cloudsoft.com,zhouyu@e-cloudsoft.com</RESULT_MAIL>        <!-- 振込決済バッ出力対象の制御条件の定義 -->        <FILTER>KamokuLst__c in (\'買掛（月末振込）\',\'買掛（都度振込）\') </FILTER>        <!-- 仕入入力画面に表示するレポートボタン情報 -->        <BUTTONS>        	<BUTTON>        		<LABEL>レポート1</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート2</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート3</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        	<BUTTON>        		<LABEL>レポート4</LABEL>        		<REP_NAME>$9030 勤怠一覧</REP_NAME>        	</BUTTON>        </BUTTONS>        <!-- 銀行へ通信電文関連定義情報 -->        <!-- 銀行振り込み手数料:必須 -->        <BANK_TRANS_RATE>			<SAME_BANK>							<!-- 同銀行 -->				<SAME_BRANCH>					<!-- 同支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>0</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>0</RATE>					</RANK_LEVEL>				</SAME_BRANCH>				<DIFF_BRANCH>					<!-- 別支店 -->					<RANK_LEVEL>						<MIN_VAL>0</MIN_VAL>						<MAX_VAL>9999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>10000</MIN_VAL>						<MAX_VAL>29999</MAX_VAL>						<RATE>108</RATE>					</RANK_LEVEL>					<RANK_LEVEL>						<MIN_VAL>30000</MIN_VAL>						<RATE>324</RATE>					</RANK_LEVEL>				</DIFF_BRANCH>			</SAME_BANK>			<DIFF_BANK>						<!-- 別銀行 -->				<RANK_LEVEL>					<MIN_VAL>0</MIN_VAL>					<MAX_VAL>9999</MAX_VAL>					<RATE>324</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>10000</MIN_VAL>					<MAX_VAL>29999</MAX_VAL>					<RATE>432</RATE>				</RANK_LEVEL>				<RANK_LEVEL>					<MIN_VAL>30000</MIN_VAL>					<RATE>648</RATE>				</RANK_LEVEL>			</DIFF_BANK>        </BANK_TRANS_RATE>        <!-- 口座情報定義する -->        <BANK_KOZAINFO>        	<!-- 買掛決済処理機能関連の口座情報定義　BEGIN -->        	<PUR_SETTLEMENT>								<!-- 買掛決済バッチ支払口座情報の定義 -->        		<KOUZA_SEQ>2</KOUZA_SEQ>					<!-- 店舗口座情報#SEQ値 -->        		<DESCRIPT>仕入支払口座</DESCRIPT>        		<TRANS_TYPE>21</TRANS_TYPE>					<!-- 業務種別:21:総合 11または71:給与 12または72:賞与 -->        	</PUR_SETTLEMENT>        	        	<PUR_RECIVEACCOUNT>								<!-- 振り込み先の口座情報の定義 -->        		<KOUZA_TYPE>買掛支払</KOUZA_TYPE>        		<DESCRIPT>        		取引先の振込用口座の種別情報、取引先側に複数口座情報を登録される場合、該当種別で、口座情報の「口座種別」と比較用        		一致すると、該当口座情報は買掛決済振り込み先の口座情報で利用する        		</DESCRIPT>        	</PUR_RECIVEACCOUNT>        	        	<!-- 買掛決済処理機能関連の口座情報定義　END -->        </BANK_KOZAINFO>        <BANK_TELEGRAM_HEADER>        	<DATA_KBN>1</DATA_KBN>		<!-- レコード種別:1:ヘッダレコード -->        	<MESSAGE_HEADER>        	データ区分,種別コード,コード区分,会社コード,会社名,振込指定日,仕向銀行番号,仕向銀行名,仕向支店番号,仕向支店名,預金種目,口座番号,ダミー        	</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_種別コード_$$			$$_コード区分_$$			$$_委託者コード_$$			$$_委託者名_$$			$$_取組日_$$			$$_仕向金融機関番号_$$			$$_仕向金融機関名_$$			$$_仕向支店番号_$$			$$_仕向支店名_$$			$$_預金種目(依頼人)_$$			$$_口座番号(依頼人)_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_HEADER>		<BANK_TELEGRAM_DETAIL>			<DATA_KBN>2</DATA_KBN>		<!-- レコード種別:2:データレコード -->			<IS_EDI>FALSE</IS_EDI>			<!-- EDI情報を使う -->			<FURIKOMIKBN>7</FURIKOMIKBN>	<!-- 振込指定区分 -->			<MESSAGE_HEADER>			データ区分,被仕向銀行番号,被仕向銀行名,被仕向支店番号,被仕向支店名,手形交換所番号,預金種目,口座番号,受取人名,振込金額,新規コード,顧客コード1,顧客コード2,振込指定区分,識別表示,ダミー,支払金額,先方負担手数料,振込手数料			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_被仕向金融機関番号_$$			$$_被仕向金融機関名_$$			$$_被仕向支店番号_$$			$$_被仕向支店名_$$			$$_手形交換所番号_$$			$$_預金種目_$$			$$_口座番号_$$			$$_受取人名_$$			$$_振込金額_$$			$$_新規コード_$$			$$_顧客コード1_$$			$$_顧客コード2_$$			$$_EDI情報_$$			$$_振込区分_$$			$$_識別表示_$$			$$_ダミー_$$			$$_支払金額_$$			$$_先方負担手数料_$$			$$_振込手数料_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_DETAIL>		<BANK_TELEGRAM_TRAILER>			<DATA_KBN>8</DATA_KBN>		<!-- レコード種別:8:トレーラレコード -->			<MESSAGE_HEADER>			データ区分,合計件数,合計金額,ダミー			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_合計件数_$$			$$_合計金額_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_TRAILER>		<BANK_TELEGRAM_END>			<DATA_KBN>9</DATA_KBN>		<!-- レコード種別:9:エンドレコード -->			<MESSAGE_HEADER>			データ区分,ダミー 			</MESSAGE_HEADER>			<MESSAGE_LAYOUT>			$$_データ区分_$$			$$_ダミー_$$			</MESSAGE_LAYOUT>		</BANK_TELEGRAM_END>		<!-- エージェント販売手数料計算関連 -->		<AGT_SALESRATE>			<DATA_FILTER></DATA_FILTER>				<!-- 旅行会社の「旅行会社分類」制御が必要場合、タイプを追加する、複数存在すると、「,」定義する -->			<I_TYPENAME>販売手数料</I_TYPENAME>		<!-- 種別 -->			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		<!-- 科目 -->			<CHARGERATE_LOGIC>				<FILTER VALUE="HR(宿泊)" CATAGO="KNT">		 			<LOGIC>{0}</LOGIC>		          	<COONDITION>						ReservedType__c in (\'泊 ２食\',\'泊 朝半\',\'泊 夕半\',\'泊 素\',\'宿泊\')		          	</COONDITION>	          	</FILTER>			</CHARGERATE_LOGIC>		</AGT_SALESRATE>		<!-- カード販売手数料計算関連 -->		<CARD_SALESRATE>			<I_TYPENAME>カード手数料</I_TYPENAME>			<O_KAMOKU>買掛（月末振込）</O_KAMOKU>		</CARD_SALESRATE>    </SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'AccountingSyncBatchConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(configXml);
    	insert item;
    	
        String csv = '<root><SHOP><SHOPCODE></SHOPCODE><PCA><PCA_FIELD><VER>#2</VER><STARTNO>6001</STARTNO><CALCULATIONKBN>0</CALCULATIONKBN><JOURNALKBN>1</JOURNALKBN><MANAGEACCJOUKBN>0</MANAGEACCJOUKBN><DEBDEPARTCODE>180</DEBDEPARTCODE><DEBCONSUMPTAX>0</DEBCONSUMPTAX><CREDEPARTCODE>180</CREDEPARTCODE><CRECONSUMPTAX>0</CRECONSUMPTAX><INPUTPROGRAMKBN>HANYOU</INPUTPROGRAMKBN></PCA_FIELD><PCA_TAX><KANJOCODE>3350</KANJOCODE></PCA_TAX><PCA_ADVPAY_L><KANJOCODE>3241003</KANJOCODE></PCA_ADVPAY_L><PCA_ADVPAY_R><KANJOCODE>3241003</KANJOCODE></PCA_ADVPAY_R></PCA><CASH><CASH_INPUT><CONVERT><KEMOKU>内金</KEMOKU><I_KANJOCODE>1110</I_KANJOCODE><O_KANJOCODE>3241002</O_KANJOCODE></CONVERT><CONVERT><KEMOKU>レンタル料金</KEMOKU><I_KANJOCODE>1110</I_KANJOCODE><O_KANJOCODE>3241</O_KANJOCODE></CONVERT></CASH_INPUT><CASH_OUTPUT><CONVERT><KEMOKU>交通費</KEMOKU><I_KANJOCODE>1841</I_KANJOCODE><O_KANJOCODE>1110</O_KANJOCODE></CONVERT></CASH_OUTPUT></CASH></SHOP>'
                    + '</root>';
        return csv;
    }
    private static String getCsvSetupConfig2() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?>'
                                +'<root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT>'
                                +
                                '</PAYMENT><PAYMEIDA>'
                                    +'<CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>T90001</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>T90002</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>T90003</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>T90004</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>T90005</PRODCODE></CONVERT>'
                                    +'<CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>T90006</PRODCODE></CONVERT>'
                                    +'</PAYMEIDA></SHOP></root>';
		return csv;
    }
    private static RsvAccount__c createSimpleRsvAccount() {
        RsvAccount__c item = new RsvAccount__c();
        item.name = DateTime.now().format('yyyyMMdd');
        upsert item name;
        return item;	
    }
    private static List<RsvAccount__c> createRangeRsvAccount(Date begDt, Date endDt) {
		list<RsvAccount__c> insLst = new list<RsvAccount__c>();
		while (begDt < endDt) {
	        RsvAccount__c item = new RsvAccount__c();
	        item.name = DateTime.newInstance(begDt.year(),begDt.month(),begDt.day()).format('yyyyMMdd');
	        inslst.add(item);
	        begDt = begDt.addDays(1);
		}
		upsert insLst name;
		return insLst;
    }
    private static RsvAccount__c createRsvAccount() {
		RsvAccount__c rsv = createSimpleRsvAccount();
		createAccount();
		return rsv;
    }
    private static void createAccount() {
		// 商品作成する
		List<AccountMaster__c> prodList = TestCommon.createProductMst(1);
		// 
		SimpleAccountsCtrl ctrl = new SimpleAccountsCtrl();
		ctrl.mediaType = ctrl.mediaTypeOptionLst[1].getValue();
		ctrl.otran.Field20__c = '16000';
		ctrl.otran.Field21__c = '2';
		ctrl.otran.Field7__c = prodList[0].Id;
		ctrl.otran.ActionType__c = prodList[0].ActionType__c;
		ctrl.otran.TaxRate__c = prodList[0].TaxRateCal__c;
		ctrl.otran.ServiceRate__c = prodList[0].ServiceRate__c;
		ctrl.otran.SpecialTax__c = 200;
		ctrl.productNm = prodList[0].Name;
		
		ctrl.saveTranToMemory();
		
		ctrl.upsertData();
    }
}