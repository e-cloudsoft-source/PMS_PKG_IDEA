public with sharing class AppMenu {

    public AppMenu() {
    	String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
    	for (RecordType s : [select id,DeveloperName from RecordType where SobjectType = :leadLocalName]) {
    		if (s.DeveloperName == LeadRsType1) leadRcType1 = s.Id;
    		else if (s.DeveloperName == LeadRsType2) leadRcType2 = s.Id;
    		else if (s.DeveloperName == LeadRsType3) leadRcType3 = s.Id;
    		else if (s.DeveloperName == LeadRsType4) leadRcType4 = s.Id;
    	}
    }
    // ケータリング/基本/宴会/宿泊
    private final String LeadRsType1 = 'CateringRecType';
    private final String LeadRsType2 = 'BaseRecType';
    private final String LeadRsType3 = 'EnkaiRecType';
    private final String LeadRsType4 = 'BookingRecType';
    // 予約のレコードタイプ取得、設定を行う
    public String leadRcType1{get;private set;}
    public String leadRcType2{get;private set;}
    public String leadRcType3{get;private set;}
    public String leadRcType4{get;private set;}
    // 2016/10/03 権限関連のチェック情報を追加
    public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateable(Lead__c.sObjectType);}}//予約修正権限あり、なし
    public boolean isCanUpdateAcct{get{return CommSecurityUtils.isCanUpdateable(AccountAcount__c.sObjectType);}}//会計修正権限あり、なし
    public boolean isCanUpdateRsv{get{return CommSecurityUtils.isCanUpdateable(RsvAccount__c.sObjectType);}}//売上修正権限あり、なし
    public boolean isCanUpdateRackRate{get{return CommSecurityUtils.isCanUpdateable(RackRateTable__c.sObjectType);}}//ラックレート修正権限あり、なし
    public boolean isCanUpdateRealAgt{get{return CommSecurityUtils.isCanUpdateable(RealAGT__c.sObjectType);}}//リアルAGT修正権限あり、なし
    public boolean isCanUpdatePur{get{return CommSecurityUtils.isCanUpdateable(Purchase__c.sObjectType);}}//仕入修正権限あり、なし
/**
*2015-11-18 
*テストクラスAppMenuTestに移行する	    
	@isTest
	static void testAppMenu() {
  		AppMenu menu = new AppMenu();
  		System.assertNotEquals(menu.leadRcType1, null);
  		System.assertNotEquals(menu.leadRcType2, null);
  		System.assertNotEquals(menu.leadRcType3, null);
  		System.assertNotEquals(menu.leadRcType4, null);
	}
*/
}