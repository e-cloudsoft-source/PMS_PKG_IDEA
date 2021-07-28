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
private class ApplicationFormPDFExt1Test {


    static testMethod void myUnitTest() {
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	CommDefine__c comdef = TestCommon.createCommDefine();
    	comdef.ApplicationFormPDFSwitchCode__c = '2';
    	comdef.ReducedTaxRateFlg__c = true;
    	comdef.PDFPlanBrkIsShowFlg__c = true;
    	update comdef;
    	// 2019/07/30 軽減税率機能対応 WGCH END
		Date dt = Date.today();
        Room__c guestRoom = TestCommon.createRooms();
        // 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Room__c where UseOfRoom__c = '客室'].size(), 1);
		// 2015/12/01 Assert END
        Lead__c normalLead = TestCommon.createBookingLead(dt, guestRoom.TypeRoomRef__c, 0);
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        TestCommon.createBookEstItems(normalLead, productLst);
        String idxName = [select LeadIndexRef__r.Name from Lead__c where id = :normalLead.Id].LeadIndexRef__r.Name;
        List<LeadIndex__c> leadIdxLst = [select id from LeadIndex__c where name = :idxName];

        ShopInformation__c tempShop = TestCommon.createShopInfo();
        ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = tempShop.Id;
        update tempShopLogo;
        System.debug(LoggingLevel.INFO, 'tempShopLogo:::' + tempShopLogo);

		Test.startTest();

		Apexpages.currentPage().getParameters().put('id',normalLead.Id);
		Pagereference pg = ApexPages.currentPage();
		Test.setCurrentPage(pg);

		ApexPages.StandardController contrl = new ApexPages.StandardController(leadIdxLst[0]);

		insertDoc();
		User currUser = [select id, ShopCode__c from user where id = :UserInfo.getUserId()];
    	currUser.ShopCode__c = tempShop.ShopCode__c;
    	update currUser;
    	system.runAs(currUser) {
			ApplicationFormPDFExt1 newPdf = new ApplicationFormPDFExt1(contrl);

			newPdf.initPdf();
		}

		Test.stopTest();
	}
	
	static testMethod void AppFormPdfSwithTest() {
		CommDefine__c comdef = TestCommon.createCommDefine();
		comdef.ApplicationFormPDFSwitchCode__c = '2';
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		comdef.ReducedTaxRateFlg__c = true;
		comdef.PDFPlanBrkIsShowFlg__c = true;
		update comdef;
		// 2019/07/30 軽減税率機能対応 WGCH END
		insertDoc();
   		List<Lead__c> testLeads = TestCommon.createLead(Date.today(), 1,  1);

		String common = ApplicationFormPDFSwitch.getApplicationFormPdfComment();
		System.assertEquals(common, 'ABC');
		String commonRooms = ApplicationFormPDFSwitch.getApplicationFormPdfCommentAndRooms(testLeads[0].LeadIndexRef__c);
		String[] arr = commonRooms.split(':');
		System.assertEquals(Integer.valueOf(arr[1]), 1);
		
        Apexpages.currentPage().getParameters().put('lc','4');
        Apexpages.currentPage().getParameters().put('psd','20151001');
        Apexpages.currentPage().getParameters().put('ped','20151003');
        ApexPages.StandardController contr2 = new ApexPages.StandardController(testLeads[0]);
    	ApplicationFormPDFSwitch switchCtrl = new ApplicationFormPDFSwitch(contr2);
    	switchCtrl.redirect();
	}

    static testMethod void AppFormCustomPdfTest() {
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.ApplicationFormPDFSwitchCode__c = '6';
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        comdef.ReducedTaxRateFlg__c = true;
        comdef.PDFPlanBrkIsShowFlg__c = true;
        update comdef;
        // 2019/07/30 軽減税率機能対応 WGCH END
        insertDoc();
        List<Lead__c> testLeads = TestCommon.createLead(Date.today(), 1,  1);
        ShopInformation__c tempShop = TestCommon.createShopInfo();
        ReportLogo__c tempShopLogo = TestCommon.createRepLogo();
        tempShopLogo.ShopInfoRef__c = tempShop.Id;
        update tempShopLogo;

        String common = ApplicationFormPDFSwitch.getApplicationFormPdfComment();
        System.assertEquals(common, 'ABC');
        String commonRooms = ApplicationFormPDFSwitch.getApplicationFormPdfCommentAndRooms(testLeads[0].LeadIndexRef__c);
        String[] arr = commonRooms.split(':');
        System.assertEquals(Integer.valueOf(arr[1]), 1);
        
        Apexpages.currentPage().getParameters().put('id',testLeads[0].id);
        Apexpages.currentPage().getParameters().put('lc','6');
        Apexpages.currentPage().getParameters().put('psd','20151001');
        Apexpages.currentPage().getParameters().put('ped','20151003');
        Apexpages.currentPage().getParameters().put('shopcd',tempShop.ShopCode__c);
        
        (new ApplicationFormPDFExt1()).getLeadindexByLeads(testLeads[0].id,tempShop.ShopCode__c);

        ApexPages.StandardController contr2 = new ApexPages.StandardController(testLeads[0]);
        ApplicationFormPDFSwitch switchCtrl = new ApplicationFormPDFSwitch(contr2);
        switchCtrl.redirect();
        ApplicationFormPDFExt1 newPdf = new ApplicationFormPDFExt1(contr2);
        newPdf.initPdf();
    }
	private static void insertDoc() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'ApplicationFormPdfConfig';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	ApplicationFormPdfConfig.Body = Blob.valueOf(getCsvSetupConfig());
    	insert ApplicationFormPdfConfig;	
	}
	private static String getCsvSetupConfig() {
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;
        String customHtml = '<RESVCARD><PAGESIZE VERTICAL="true">A4</PAGESIZE><BODY><PAGESIZE MARGINVERTICAL="80px" MARGINHORIZONTAL="70px">A4</PAGESIZE><TABLE style="width: 100%; border-spacing: 0px; margin-top: 9px;">  <ROW>    <COL style="text-align: center;line-height: 90%;font-size: 16px;">ご　予　約　確　認　書    </COL>  </ROW>  <ROW>    <COL style="text-align: center;margin-top: 6px;font-size: 12px;">RESERVATION CONFIRMATION    </COL>  </ROW></TABLE><TABLE style="width:100%; font-size: 12px; margin-top: 10px;">  <ROW>    <COL style="text-align: center;" >この度はご予約承り誠にありがとうございます。ご予約内容を下記の通り承りました。ご確認くださいませ。    </COL>  </ROW></TABLE><ROW STYLE="text-align:center;"></ROW><TABLE style="border: 1px solid #000;font-size: 1.1em;TABLE-layout: fixed; margin-top: 10px">  <ROW>    <COL style="font-size: 16pt;width:12px;">◆    </COL>    <COL style="font-size: 14px;width: 124px;">ご予約名    </COL>    <COL style="font-size: 14pt">$$_Name_$$</COL>    <COL style="font-size: 14px;width: 60px;">$$_Honorific_$$</COL>    <COL width="60px"> </COL>    <COL style="font-size: 14px;width: 60px;">発行日</COL>    <COL style="text-align: center;width: 150px;">$$_Field372__c_$$</COL>    <COL width="40px"> </COL>  </ROW></TABLE><TABLE style="border: 1px solid #000;font-size: 1.1em;TABLE-layout: fixed;margin-top: 6px;">  <ROW>    <COL style="font-size: 16pt;width:12px;">◆</COL>    <COL style="font-size: 14px;width: 110px">ご住所</COL>    <COL style="font-size: 14px;width: 24px">〒</COL>    <COL colspan="5" >$$_Relcontact__r.MailingPostalCode_$$ </COL>  </ROW>  <ROW>    <COL colspan="3"></COL>    <COL colspan="5">$$_Relcontact__r.MailingCountry_$$ $$_Relcontact__r.MailingCity_$$ $$_Relcontact__r.MailingState_$$ $$_Relcontact__r.MailingStreet_$$</COL>  </ROW></TABLE><TABLE style="border: 1px solid #000;border-top:none;TABLE-layout: fixed;border-spacing:0;">  <ROW>    <COL style="font-size: 16pt;width:12px;">◆    </COL>    <COL style="font-size: 14px;">連絡電話番号    </COL>    <COL>$$_Relcontact__r.Phone_$$</COL>    <COL style="width:100px;"></COL>    <COL style="border-left: 1px solid #000;font-size: 16pt;width:12px;">◆    </COL>    <COL  style="font-size: 14px;">予約番号    </COL>    <COL >$$_LeadIndexRef__r.Name_$$</COL>    <COL></COL>  </ROW></TABLE><TABLE style="border: 1px solid #000;font-size: 1.1em;TABLE-layout: fixed;margin-top: 6px;">  <ROW>    <COL style="border-bottom:1px solid #000;" ><TABLE style="TABLE-layout: fixed;"><ROW><COL style="font-size: 16pt;width: 12px;">◆</COL><COL style="font-size: 14px;width: 120px;">ご利用日時</COL><COL style="width:100px;"></COL><COL style="text-align: center;font-size: 1.6em;font-weight: bold;width:100px;">  $$_LeadIndexRef__r.EntryDate__c_$$</COL><COL style="text-align: center;font-size: 1.4em;width:100px">  から</COL><COL style="text-align: left;font-weight: bold;font-size: 1.6em;">  $$_LeadIndexRef__r.DepartureDate__c_$$ </COL></ROW></TABLE>    </COL>  </ROW>  <ROW>    <COL style="border-bottom:1px solid #000;" ><TABLE style="TABLE-layout: fixed;"><ROW><COL style="font-size: 16pt;width: 12px;">  ◆</COL><COL style="font-size: 14px;width: 130px;">  ご宿泊日数/部屋数</COL><COL style="width:150px;"></COL><COL style="text-align: right;font-size: 1.6em; font-weight: bold;width:80px;">  $$_NightNumber_$$</COL><COL style="text-align: center;font-size: 1.4em;width:80px;">泊</COL><COL style="font-size: 1.6em; font-weight: bold;width:50px;">$$_RoomNumber_$$</COL><COL style="text-align: left;font-size: 1.4em">部屋</COL></ROW></TABLE>    </COL>  </ROW>  <ROW>    <COL ><TABLE style="TABLE-layout: fixed;"><ROW><COL style="font-size: 16pt;width: 12px;">  ◆</COL><COL style="font-size: 14px;width: 130px;">  ご宿泊人数</COL><COL style="width: 200px"></COL><COL style="font-weight: bold;font-size: 1.6em;border-bottom:1px solid #000;text-align: center;">  $$_AdultNumber_$$</COL><COL style="font-size: 1.4em;border-bottom:1px solid #000;text-align: center;">  名様</COL><COL style="width: 200px"></COL></ROW><ROW style="vertical-align: bottom;"><COL colspan="2" style="font-size: 14px;width: 140px;text-align: right;padding-right: 10px">  内訳:</COL><COL style="text-align: center;" colspan="4">  <TABLE>    <ROW><COL>(  大人 : 男性</COL><COL style="margin-left: 30px;margin-right: 40px; font-weight: bold;font-size: 1.6em">$$_Mans__c_$$</COL><COL>大人 : 女性</COL><COL style="margin-left: 40px;margin-right: 40px; font-weight: bold;font-size: 1.6em">$$_Femails__c_$$</COL><COL>子供</COL><COL style="margin-left: 40px;margin-right: 30px; font-weight: bold;font-size: 1.6em">$$_ChildNumber_$$</COL><COL>)</COL>    </ROW>  </TABLE></COL></ROW></TABLE>    </COL>  </ROW></TABLE><TABLE style="border: 1px solid #000;font-size: 1.1em;TABLE-layout: fixed;margin-top: 6px;">  <ROW>    <COL style="font-size:16pt;width: 12px;">◆    </COL>    <COL style="border-right:1px solid #000;width: 104px;">部屋タイプ    </COL>    <COL style="width:40px;text-align:center;border-right:1px solid #000;">$$_RoomNumber_$$室    </COL>    <COL style="width:40px;text-align:center;border-right:1px solid #000;">内 訳    </COL>    <COL style="width:150px;text-align:left;overflow: hidden;border-right:1px dotted #000;" ><span style="margin-left:2px;">XXXXXX</span>    </COL>    <COL style="width:30px;text-align:center;border-right:1px solid #000;"><span>XXXXXX</span>    </COL>    <COL style="width:150px;text-align:left;overflow: hidden;border-right:1px dotted #000;"><span style="margin-left:2px;">XXXXXX</span>    </COL>    <COL style="width:30px;text-align:center;"><span>XXXXXX</span>    </COL>  </ROW></TABLE><ROW STYLE="height:10px;"/><TABLE STYLE="border:none;">  <ROW>    <COL STYLE="width:70px;border:none;font-size:14px;">◆予約詳細</COL>    <COL STYLE="border:none;"><ESTIMATETABLE ROWNUM="10" COLGROUP="70,90,,20,100"></ESTIMATETABLE>    </COL>  </ROW></TABLE><ROW STYLE="height:10px;"/><TABLE STYLE="border: 1px solid #000;font-size: 1.1em;margin-left:72px;width:690px;">  <ROW>    <COL STYLE="border-right:none;width:80px;vertical-align: top;font-size:14px;">コメント欄 </COL>    <COL STYLE="border-left:none;height: 76px;vertical-align: top;"><COMMENT STYLE="width:100%;"></COMMENT>    </COL>  </ROW></TABLE><TABLE style="margin-top: 6px">  <ROW>    <COL STYLE="font-size: 10pt;">キャンセルされる場合規定により宿泊料金に対し前日20%・当日80%・不泊100%のキャンセル料を申し受けます。    </COL>  </ROW></TABLE><TABLE style="margin-top: 10px;">  <ROW>  <COL style="width: 100px;height:75px;display: inline-block;vertical-align: bottom;">    XXXXXXX  </COL>  <COL style="vertical-align: top;">    <TABLE style="font-size: 10pt"><ROW style="height: 22px;"><COL>$$_ShopName_$$</COL></ROW>    </TABLE>    <TABLE><ROW><COL> $$_ShopPostNo_$$  $$_ShopAddress_$$ </COL></ROW>    </TABLE>    <TABLE><ROW style="height: 22px;"><COL>tel.$$_ShopPhone_$$ fax. $$_ShopFax_$$</COL></ROW>    </TABLE>    <TABLE><ROW style="height: 22px;"><COL>email:$$_ShopEmail_$$  $$_ShopWebSite_$$</COL></ROW>    </TABLE>  </COL>  </ROW></TABLE></BODY>    </RESVCARD>';
    	csv = '<root><SHOP><SHOPCODE></SHOPCODE><HEADER><TITLE_KANJI>ご　予　約　確　認　書</TITLE_KANJI><TILTE_ENGLISH>JINYA RESERVATION CONFIRMATION</TILTE_ENGLISH></HEADER><BODY><FIELD_LABEL><LEAD_NAME>ご予約名</LEAD_NAME><ISSUE_DATE>発行日</ISSUE_DATE></FIELD_LABEL><MAX_ROWS>12</MAX_ROWS><MAX_SHOWROOMS>23</MAX_SHOWROOMS><BATHTAX><PRODCODE>8100</PRODCODE></BATHTAX><CANCEL_RULE>キャンセルされる場合&lt;br/&gt;規定により宿泊料金に対し前日20%・当日80%・不泊100%のキャンセル料を申し受けます。</CANCEL_RULE><COMMENT>ABC</COMMENT></BODY><FOOTER></FOOTER>'
    										+ customHtml
                                            + '</SHOP>'
                                            + '</root>';
    	return csv;
    	

        
    }
}