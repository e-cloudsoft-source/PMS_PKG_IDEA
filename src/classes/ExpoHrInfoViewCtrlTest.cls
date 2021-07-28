@isTest
private class ExpoHrInfoViewCtrlTest {
	
	@isTest static void test_method_one() {
		createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ExpoHrInfoEditCtrl editCtrl = new ExpoHrInfoEditCtrl();
        String expoOrgInfoId = expoOrgs[0].id;
        editCtrl.initAct();
        ExpoHrInfoEditCtrl.getRefDs('ExpoHrInfo__c',expoOrgInfoId);
        Map<String,Object> res = new Map<String,Object>{
        	'expooaskilllst__c' => new List<String>{'SA02','','MPLST'},
        	'expoothlangskilllst__c' => new List<String>{'SC02','','MPLST'},
        	'expohrotherlst__c' =>new List<String>{'SF02','','MPLST'},
        	'expolicskilllst__c' => new List<String>{'SE02','','MPLST'},
        	'expoaccskilllst__c' => new List<String>{'SD01','','MPLST'}
        };
        ExpoHrInfoEditCtrl.saveInfo('',JSON.serialize(res),expoOrgInfoId);
		// Implement test code
		ExpoHrInfoViewCtrl ctrl = new ExpoHrInfoViewCtrl();
		ctrl.initAct();
		ExpoHrInfoViewCtrl.getModel(shop.ShopCode__c , expoOrgInfoId);
	}
	@isTest static void test_method_two() {
		ExpoCommonTest.createDoc();
        List<ExpoOrgInfo__c> expoOrgs = ExpoCommonTest.generateExpoOrgInfo(1);
        ShopInformation__c shop = TestCommon.createShopInfo();
        ExpoUser__c user = ExpoCommonTest.createExpoUser(shop,expoOrgs[0]);
        String sid = ExpoCommonTest.userLogin(user).getParameters().get('sid');
        ApexPages.currentPage().getParameters().put('sid', sid);
        ApexPages.currentPage().getParameters().put('Id',shop.id);
        ExpoHrInfoEditCtrl editCtrl = new ExpoHrInfoEditCtrl();
        String expoOrgInfoId = expoOrgs[0].id;
        editCtrl.initAct();
        ExpoHrInfoEditCtrl.getRefDs('ExpoHrInfo__c',expoOrgInfoId);
        Map<String,Object> res = new Map<String,Object>{
        	'expooaskilllst__c' => new List<String>{'SA02','','MPLST'},
        	'expoothlangskilllst__c' => new List<String>{'SC02','','MPLST'},
        	'expohrotherlst__c' =>new List<String>{'SF02','','MPLST'},
        	'expolicskilllst__c' => new List<String>{'SE02','','MPLST'},
        	'expoaccskilllst__c' => new List<String>{'SD01','','MPLST'}
        };
        ExpoHrInfoEditCtrl.saveInfo('',JSON.serialize(res),expoOrgInfoId);
		// Implement test code
		ExpoHrInfoViewCtrl ctrl = new ExpoHrInfoViewCtrl();
		ctrl.initAct();
		ExpoHrInfoViewCtrl.getModel(shop.ShopCode__c , expoOrgInfoId);
	}
	public static void createDoc(){
    	String body = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><ACCMASTERFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="1">Name,$_BLANK_$,Field5__c,Field7__c,jmstRef__c:消費税,ServiceRate__c,Field12__c,Field2__c</SECTION><SECTION TITLE="EXPO基本情報" COLNUM="1">Category__c,CategorySub__c</SECTION></FIELDS><REQUIREDFIELDS>Name,Field5__c</REQUIREDFIELDS><TEXTAREAIMG>BigImage__c</TEXTAREAIMG><HEIGHT>35px</HEIGHT></ACCMASTERFIELDS><SHOPINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,WebSite__c:,WebSite__c:222,AccountServiceChargeNoTaxFlg__c,$_blank_$,PayeeAcount__c,ShopCode__c,ExpoOrgInfoRef__c,Fax__c,Seq__c,RoomScheduleTimerMinute__c,Email__c,Phone__c,ShopCode1__c</SECTION></FIELDS><REQUIREDFIELDS>Fax__c</REQUIREDFIELDS><HEIGH>150px</HEIGH></SHOPINFOFIELDS><USERINFOFIELDS><FIELDS><SECTION TITLE="" ROW=""></SECTION><SECTION TITLE="情報" COLNUM="2">Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:組織名,Phone__c:電話,ShopCode__c:組織店舗</SECTION></FIELDS><WIDTHFIELDS>Name:50px</WIDTHFIELDS><REQUIREDFIELDS>ShopCode__c,Fax__c</REQUIREDFIELDS><HEIGHT>50px</HEIGHT></USERINFOFIELDS><ORGINFOFIELDS><FIELDS><SECTION TITLE="情報" COLNUM="2">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c,ContactRef__c</SECTION><SECTION TITLE="情報3" COLNUM="1">Name,Phone__c,Fax__c,PostNo__c,State__c,City__c,Street__c,Phone__c,WebSiteUrl__c</SECTION></FIELDS><REQUIREDFIELDS></REQUIREDFIELDS><WIDTHFIELDS>iD:1000PX</WIDTHFIELDS><HEIGHT>100px</HEIGHT></ORGINFOFIELDS><USERLISTFIELDS>Name:氏名,UserName__c:ユーザ名,Email__c:メール,ExpoOrgInfoRef__c:Expo組織情報</USERLISTFIELDS><ORGLISTFIELDS>Name:店舗名,ShopCode__c:店舗コード,ExpoOrgInfoRef__c:abc</ORGLISTFIELDS><HRINFOFIELDS>ExpoOrgInfoRef__r.name:a,Field3__c:b,Name:c,Field5__c:d,Field7__c:e</HRINFOFIELDS></SHOP></root>';
    	// ドキュメントを作成する
    	Document item = new Document();
    	item.Name = 'ExpoServiceConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(body);
    	insert item;
    }
	
}