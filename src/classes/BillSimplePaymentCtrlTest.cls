@isTest
private class BillSimplePaymentCtrlTest {
	static testMethod void case01() {
		Document BillPaymentBtnConfigInfo = new Document();
		BillPaymentBtnConfigInfo.Name = 'BillSimplePaymentConfig';
		BillPaymentBtnConfigInfo.DeveloperName = BillPaymentBtnConfigInfo.Name;
    	BillPaymentBtnConfigInfo.FolderId = UserInfo.getUserId();
    	BillPaymentBtnConfigInfo.Body = Blob.valueOf(getCsvSetupConfig());
    	insert BillPaymentBtnConfigInfo;
    	// 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from Document where Name = 'BillSimplePaymentConfig'].size(), 1);
		// 2015/12/01 Assert END

		Test.startTest();
		BillSimplePaymentCtrl pct = new BillSimplePaymentCtrl();
		String stx = pct.getInitXmlDefineInfo();
		pct.getLayoutTagInfo('');
		Test.stopTest();
	}

	private static String getCsvSetupConfig() {
    	String csv = '<root><SHOP><SHOPCODE></SHOPCODE><LAYOUT><MAXCOLS>3</MAXCOLS><BTNSTYLE>width:125px;height:30px;</BTNSTYLE><TABLEWIDTH>450</TABLEWIDTH><TABLEHEIGHT>260</TABLEHEIGHT></LAYOUT><BUTTONTAB><TABLABEL>メディア</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>現金</LABEL><PRODCODE>87001</PRODCODE><ICONURL>/resource/AppImages/payicon/Cash.png</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>カード</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>VISA</LABEL><PRODCODE>85201</PRODCODE><ICONURL>/resource/simplepayimg/card/visa.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>MASTER</LABEL><PRODCODE>85301</PRODCODE><ICONURL>/resource/simplepayimg/card/mc.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>JCB</LABEL><PRODCODE>85401</PRODCODE><ICONURL>/resource/simplepayimg/card/jcb.jpg</ICONURL></BUTTON></BUTTONTAB><BUTTONTAB><TABLABEL>クーポン</TABLABEL><BUTTON ISBLANK="FALSE"><LABEL>楽天ポイント</LABEL><PRODCODE>85601</PRODCODE><ICONURL>/resource/simplepayimg/coupon/rt.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>一休ポイント</LABEL><PRODCODE>85602</PRODCODE><ICONURL>/resource/simplepayimg/coupon/1x.jpg</ICONURL></BUTTON><BUTTON ISBLANK="FALSE"><LABEL>じゃらんポイント</LABEL><PRODCODE>85603</PRODCODE><ICONURL>/resource/simplepayimg/coupon/jal.jpg</ICONURL></BUTTON></BUTTONTAB></SHOP>'
					+ '</root>';
    	return csv;
	}
}