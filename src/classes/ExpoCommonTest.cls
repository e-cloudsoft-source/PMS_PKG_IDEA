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
public class ExpoCommonTest {
	
	public static PageReference userLogin(ExpoUser__c user){
    	ExpoLoginCtrl ctrl = new ExpoLoginCtrl();
    	ctrl.username = user.UserName__c;
    	ctrl.password = user.PassWord__c;
    	return ctrl.actionLogin();
    }
    
    public static ExpoUser__c createExpoUser(ShopInformation__c shop,ExpoOrgInfo__c expoInfo){
    	ExpoUser__c expoUserItem = new ExpoUser__c();
    	shop.ExpoOrgInfoRef__c =expoInfo.id;
    	update shop;
		// 氏名
		expoUserItem.Name = 'test001';
		// ユーザ名
		expoUserItem.UserName__c = 'text001';
		// PassWord
		expoUserItem.PassWord__c = 'abc';
		// メール
		expoUserItem.Email__c = '123@abc.com';
		// 組織
		expoUserItem.ExpoOrgInfoRef__c = expoInfo.id;
		// 店舗情報
		expoUserItem.ShopCode__c = shop.ShopCode__c;
		expoUserItem.IsActive__c = true;
		expoUserItem.ActivationFlg__c = true;
		insert expoUserItem;
		return expoUserItem;
    }
    public static ExpoOrgInfo__c[] generateExpoOrgInfo(Integer n) {
    	List<ExpoOrgInfo__c> sobjs = new List<ExpoOrgInfo__c>();
    	Integer i = n;
    	while(i-- > 0){
	    	ExpoOrgInfo__c newOrg = new ExpoOrgInfo__c(
	    		Name = CommUtils.getRandom(10)
	    	);
			sobjs.add(newOrg);
    	}
    	upsert sobjs;
    	return sobjs;
    }
    public static void createEmptyDoc(){
    	String body = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE>		</SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ExpoServiceConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(body);
    	insert item;
    }
    public static void createDoc(){
    	String body = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCMASTERFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="1">Name,$_BLANK_$,Field5__c,Field7__c,jmstRef__c:消費税,ServiceRate__c,Field12__c,Field2__c</SECTION><SECTION TITLE="EXPO基本情報" COLNUM="1">Category__c,CategorySub__c</SECTION></FIELDS><REQUIREDFIELDS>Name,Field5__c</REQUIREDFIELDS><TEXTAREAIMG>BigImage__c</TEXTAREAIMG><HEIGHT>35px</HEIGHT></ACCMASTERFIELDS><SHOPINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,WebSite__c:,WebSite__c:222,AccountServiceChargeNoTaxFlg__c,$_blank_$,PayeeAcount__c,ShopCode__c,ExpoOrgInfoRef__c,Fax__c,Seq__c,RoomScheduleTimerMinute__c,Email__c,Phone__c,ShopCode1__c</SECTION></FIELDS><REQUIREDFIELDS>Fax__c</REQUIREDFIELDS><HEIGH>150px</HEIGH></SHOPINFOFIELDS><USERINFOFIELDS><FIELDS><SECTION TITLE="" ROW=""></SECTION><SECTION TITLE="情報" COLNUM="2">Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:組織名,Phone__c:電話,ShopCode__c:組織店舗</SECTION></FIELDS><WIDTHFIELDS>Name:50px</WIDTHFIELDS><REQUIREDFIELDS>ShopCode__c,Fax__c</REQUIREDFIELDS><HEIGHT>50px</HEIGHT></USERINFOFIELDS><ORGINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c,ContactRef__c</SECTION><SECTION TITLE="情報3" COLNUM="1">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c</SECTION></FIELDS><REQUIREDFIELDS></REQUIREDFIELDS><WIDTHFIELDS>iD:1000PX</WIDTHFIELDS><HEIGHT>100px</HEIGHT></ORGINFOFIELDS><USERLISTFIELDS>Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:Expo組織情報</USERLISTFIELDS><ORGLISTFIELDS>Name:店舗名,ShopCode__c:店舗コード,ExpoOrgInfoRef__c:abc</ORGLISTFIELDS><ACCLISTFIRLDS>Field3__c,Name,Field5__c,Field7__c</ACCLISTFIRLDS></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ExpoServiceConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(body);
    	insert item;
    }
}