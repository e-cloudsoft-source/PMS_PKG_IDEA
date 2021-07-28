/**
* 予約確認書切替コントロール
* 2015/11/05 予約確認書レイアウト５を追加する
**/
global with sharing class ApplicationFormPDFSwitch {
	
	private static final String LAYOUT_CODE = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ApplicationFormPDFSwitchCode__c);
	
	public ApplicationFormPDFSwitch(ApexPages.StandardController controller){
		paramMap = ApexPages.currentPage().getParameters();
	}

	// ログインユーザの通貨設定情報
	webservice static String getApplicationFormPdfComment() {
		// 店舗コード
		String shopCode = UserUtil.CurrentUser.ShopCode__c;
		// コメント欄情報を取得する
		String xmlConfigName = 'ApplicationFormPdfConfig';
		ApplicationFormPDFExt1.XmlConfigInfo oXmlInfo = new ApplicationFormPDFExt1.XmlConfigInfo(CommXmlUtils.parseXmlDoc(xmlConfigName, shopCode));
		return  oXmlInfo.bComment;
	}
	webservice static String getApplicationFormPdfCommentAndRooms(String leadIndex) {
		return getApplicationFormPdfComment() + ':' + isHaveAssigedRoom(leadIndex);
	}
	// 指定の予約インデックスのIDにより、部屋アサインされている予約が存在チェツクを行う
	webservice static integer isHaveAssigedRoom(String leadIndex) {
		// 2015/12/09 錦水館機能対応 BEGIN
		if (LAYOUT_CODE == '5') return 0;
		// 2015/12/09 錦水館機能対応 END
		List<Lead__c> leads = [
						select id from lead__c 
						where Rroom__c != null 
							And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
							And LeadIndexRef__c = :leadIndex
						limit 1];
		return leads.size();
	}
	private final Map<String,String> paramMap;
	private static final Map<String, String> pageMap;
	static {
		pageMap = new Map<String,String>{
			// 2021/07/30 #JP10785 by zy BEGIN
			// 予約確認書のカスタマイズ
			'6'=>'ApplicationFormPDF_6',
			// 2021/07/30 #JP10785 by zy END
			// 新レイアウト（A4）[錦水館]
			'5'=>'ApplicationFormPDF_5',
			// 新レイアウト（A4）[入寮確認書]
			'4'=>'ApplicationFormPDF_4',
			// 新レイアウト（B5）
			//'3'=>'ApplicationFormPDF_3',
			// 新レイアウト（A4）
			'2'=>'ApplicationFormPDF_2',
			// JINYA会社DefaultPDF専用ページ
			'1'=>'ApplicationFormPDF'};
	}
	
	// ページ遷移制御処理
	public PageReference redirect() {
		// 予約確認書レイアウトコード
		PageReference customPage = new PageReference( pageMap.get(LAYOUT_CODE) == null ? '/apex/ApplicationFormPDF_2' : '/apex/' + pageMap.get(LAYOUT_CODE) );
		paramMap.put('lc',LAYOUT_CODE);
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);
		return customPage;
	}
}