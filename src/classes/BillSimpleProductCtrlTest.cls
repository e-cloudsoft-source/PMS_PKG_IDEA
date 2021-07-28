@isTest
private class BillSimpleProductCtrlTest {
	static testMethod void case01() {
		Document BillProductMenuConfig = new Document();
		BillProductMenuConfig.Name = 'BillSimpleProductConfig';
		BillProductMenuConfig.DeveloperName = BillProductMenuConfig.Name;
    	BillProductMenuConfig.FolderId = UserInfo.getUserId();
    	BillProductMenuConfig.Body = Blob.valueOf(getCsvSetupConfig());
    	insert BillProductMenuConfig;
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'BillSimpleProductConfig'].size(), 1);
		// 2015/12/01 Assert END

		Test.startTest();
		BillSimpleProductCtrl pct = new BillSimpleProductCtrl();
		String stx = pct.getInitXmlDefineInfo();
		Test.stopTest();
	}

	private static String getCsvSetupConfig() {
    	String csv = '<root><SHOP><SHOPCODE></SHOPCODE><TABLEWIDTH>100%</TABLEWIDTH><TABLEHEIGHT>240px</TABLEHEIGHT><TABGROUP><TABLABEL>A1_料理</TABLABEL><LAYOUT><BTNWORDLEN>9</BTNWORDLEN><BTNSTYLE>width:115px;height:30px</BTNSTYLE></LAYOUT><PRODUCT><CODE>0001</CODE><NAME>みえて</NAME></PRODUCT><PRODUCT><CODE>0002</CODE><NAME>検討中</NAME></PRODUCT><PRODUCT><CODE>1025</CODE><NAME>婚礼カスタマイズ会席</NAME></PRODUCT></TABGROUP><TABGROUP><TABLABEL>B1_ドリンク</TABLABEL><LAYOUT><BTNWORDLEN>9</BTNWORDLEN>	ボタンに最大表示文字数<BTNSTYLE>width:115px;height:30px</BTNSTYLE> ボタンに最大表示文字数</LAYOUT><PRODUCT><CODE>20164</CODE><NAME>菊勇 300ml</NAME></PRODUCT><PRODUCT><CODE>20163</CODE><NAME>菊勇 150ml</NAME></PRODUCT><PRODUCT><CODE>20380</CODE><NAME>バルディピエソ ブリュット(スパークリング)</NAME></PRODUCT></TABGROUP></SHOP>'
					+ '</root>';
    	return csv;
	}
	
}