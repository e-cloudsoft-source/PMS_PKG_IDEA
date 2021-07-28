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
private class ApplicationFormPDFTest {
	@isTest
	static void testCase1() {
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
		List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		AccountMaster__c planProd2 = TestCommon.createPlanProd();
		//　上記プランの関連プラン商品を取得する
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
		Test.startTest();
		// Lead Id 設定する
		Apexpages.currentPage().getParameters().put('id',leadInfo.Id);
		Pagereference pg = ApexPages.currentPage();
		Test.setCurrentPage(pg);
    	ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
    	ApplicationFormPDF ctrl = new ApplicationFormPDF(contrl);
		ctrl.initPdf();
		createDocument();
		//2015/12/09 テスト追加　start
		ApplicationFormPDFSwitch pdfSwitch = new ApplicationFormPDFSwitch(contrl);
		pdfSwitch.redirect();
		ApplicationFormPDFSwitch.getApplicationFormPdfCommentAndRooms(leadInfo.LeadIndexRef__c);
		ApplicationFormPDFSwitch.isHaveAssigedRoom(leadInfo.LeadIndexRef__c);
		//2015/12/09 テスト追加　end
		Test.stopTest();
		System.assert(ctrl.oLeadInf != null);
	}
	// ログインユーザの通貨設定情報のドキュメントを作成する
	private static void createDocument(){
		String fileXml = '<?xml version="1.0" encoding="UTF-8"?><root>		<SHOP>		<SHOPCODE></SHOPCODE>		<HEADER>			<!-- 確認書タイトル漢字名 -->			<TITLE_KANJI>				ご　予　約　確　認　書			</TITLE_KANJI>			<!-- 確認書タイトル英語名 -->			<TILTE_ENGLISH>				JINYA RESERVATION CONFIRMATION			</TILTE_ENGLISH>			<!-- 注釈文言 -->			<!-- 注意：内容は改行をしたい場合、 該当行後ろに文字列「&lt;br/&gt;」を追加する-->			<TITLE_COMMENT>				この度はご予約承り誠にありがとうございます。&lt;br/&gt;				ご予約内容を下記の通り承りました。 ご確認くださいませ。			</TITLE_COMMENT>            <TITLE_LAYOUT>                <LAYOUT>                    <LAYOUT_CODE>5</LAYOUT_CODE>                    <LAYOUT_SHOPNAME>錦  水  館</LAYOUT_SHOPNAME>                    <LAYOUT_POST>〒739-0558</LAYOUT_POST>                    <LAYOUT_ADD>日本橋浜町２－２３－５</LAYOUT_ADD>                    <LAYOUT_PHONE>TEL 03-0111-3111</LAYOUT_PHONE>                    <LAYOUT_FREEDIAL>03-0111-3112</LAYOUT_FREEDIAL>                </LAYOUT>                <LAYOUT>                    <LAYOUT_CODE>5</LAYOUT_CODE>                    <LAYOUT_SHOPNAME>錦水別荘</LAYOUT_SHOPNAME>                    <LAYOUT_POST>〒739-0558</LAYOUT_POST>                    <LAYOUT_ADD>日本橋浜町２－２３－５</LAYOUT_ADD>                    <LAYOUT_PHONE>TEL 03-0111-3111</LAYOUT_PHONE>                    <LAYOUT_FREEDIAL>03-0111-3112</LAYOUT_FREEDIAL>                </LAYOUT>            </TITLE_LAYOUT>		</HEADER>		<BODY>			<FIELD_LABEL>				<!-- ご予約名 -->				<LEAD_NAME>ご予約名</LEAD_NAME>				<!-- 発行日(issueDate) -->				<ISSUE_DATE>発行日</ISSUE_DATE>				<!-- ご住所 -->				<ADDRESS>ご住所</ADDRESS>				<!-- 連絡電話番号 -->				<PHONE>連絡電話番号</PHONE>				<!-- 予約番号 -->				<LEAD_NO>予約番号</LEAD_NO>				<!-- ご利用日時 -->				<USED_DATE>ご利用日時</USED_DATE>				<!-- ご宿泊日数/部屋数 -->				<USED_INFO>ご宿泊日数/部屋数</USED_INFO>				<!-- ご宿泊人数 -->				<USED_PAXCOUNT>ご宿泊人数</USED_PAXCOUNT>			</FIELD_LABEL>			<!-- 1ページに最大表示の明細件数 -->			<!-- 注：「0」に設定する場合、予約明細は非表示でPDF出力する,Default:12行 -->			<MAX_ROWS>8</MAX_ROWS>			<!--画面の部屋番号セクションに最大表示できる部屋数  -->			<MAX_SHOWROOMS>23</MAX_SHOWROOMS>			<!-- 入湯税関1連の会計商品コード、会計商品コードを定義なかっかの場合、明細情報のSectionに、入湯税列はPDFに非表示する -->			<BATHTAX>				<!-- 入湯税の会計商品コード、複数定義可能 -->				<PRODCODE>5041</PRODCODE>				<PRODCODE>5941</PRODCODE>			</BATHTAX>			<!-- キャンセル料金ルール説明文 -->			<!-- 注意：キャンセル内容は改行をしたい場合、 該当行後ろに文字列「&lt;br/&gt;」を追加するが必要-->			<CANCEL_RULE>				キャンセルされる場合&lt;br/&gt;				規定により宿泊料金に対し前日20%・当日80%・不泊100%のキャンセル料を申し受けます。			</CANCEL_RULE>			<!-- コメント欄Default情報 -->			<COMMENT></COMMENT>		</BODY>		<FOOTER>		</FOOTER>	</SHOP></root>';
		// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ApplicationFormPdfConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(fileXml);
    	insert item;
	}
}