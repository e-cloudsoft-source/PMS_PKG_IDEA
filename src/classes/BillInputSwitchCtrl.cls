public with sharing class BillInputSwitchCtrl {

	private final Map<String,String> paramMap;
	public static final String BILL_LAYOUT_CODE_1 = '1';
	public static final String BILL_LAYOUT_CODE_2 = '2';
	
	public BillInputSwitchCtrl(ApexPages.StandardController controller){
		paramMap = ApexPages.currentPage().getParameters();
	}
	public Pagereference redirect() {
		String layoutNo = CommDefine__c.getOrgDefaults().BillInputSwitchCode__c;
		PageReference customPage = new PageReference('/apex/BillInput');
		if (layoutNo == BILL_LAYOUT_CODE_2) customPage = new PageReference('/apex/BillSimpleInput');
		customPage.getParameters().putAll(paramMap);
		customPage.setRedirect(true);
		return customPage;
	}
	// 現在は新会計レイアウトに設定する場合
	public static Boolean isNewAccountLayout() {
		return (CommDefine__c.getOrgDefaults().BillInputSwitchCode__c == BILL_LAYOUT_CODE_2);
	}
}