/****************
* 給与明細関連のテストクラス
*****************/
@isTest(SeeAllData=false)
private class SalaryProcessTest {

    static testMethod void myUnitTest() {
    	//Profile pf_sy = [SELECT ID FROM Profile WHERE Name = 'システム管理者' Limit 1];
    	User userItem = new User();
        userItem.alias               = 'standt';
        userItem.email               = 'testUser_sy@test.com'; 
        userItem.emailencodingkey    = 'UTF-8';
        userItem.profileid           = UserInfo.getProfileId();//pf_sy.Id; 
        userItem.timezonesidkey      = 'Asia/Tokyo';
        userItem.username            = 'testUser_sy@test.com';
        userItem.lastname            = 'testUser_sy';
        userItem.languagelocalekey   = 'ja'; 
        userItem.localesidkey        = 'ja_JP';
        insert userItem;
        // 2015/12/01 Assert BEGIN
		System.assertEquals([select Id from User where email = 'testUser_sy@test.com'].size(), 1);
		// 2015/12/01 Assert END

        // 終業規則設定
        WorkTimeDefine__c wt = TestCommon.createWorkTimeDefine(null);
        
        System.runAs(userItem){
        	//ドキュメント
        	Document dummyDocument = new Document();
	        dummyDocument.name = 'AccessSalaryUserXml';
	        dummyDocument.DeveloperName = 'AccessSalaryUserXml';
	        dummyDocument.body = Blob.valueOf('<?xml version="1.0" encoding="UTF-8"?><root><ACCESSUSER><USERNAME>testUser_sy@test.com</USERNAME></ACCESSUSER></root>');
	        dummyDocument.AuthorId = UserInfo.getUserId();
			dummyDocument.FolderId = UserInfo.getUserId();
	        insert dummyDocument;
	        
        	SalaryProcessCTRL salaryProcessItem = new SalaryProcessCTRL();
	        
	        Date firstDayOfMonth = System.now().date().toStartOfMonth();
	        //開始日付
	        salaryProcessItem.timeManagementStart.WorkDay__c = firstDayOfMonth;
	        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
	        //終了日付
	        salaryProcessItem.timeManagementEnd.WorkDay__c = lastDayOfMonth;
	        //氏名
	        salaryProcessItem.selectedUserName = UserInfo.getUserId();
	        //勤怠情報
	        DateTime beforeDt = System.now().addDays(-1);
			Date beforeDay = beforeDt.date();
	        TimeManagement__c beforeItem = new TimeManagement__c(
			    Status__c = System.Label.MSG_1019,
				WorkDay__c = beforeDay,
				WorkerRef__c = UserInfo.getUserId(),
				WorkerName__c = UserInfo.getName(),
				WorkBeginTime__c = System.now().addDays(-1),
				OutingTime__c = System.now().addDays(-1),
				OutingTime2__c = System.now().addDays(-1), 
				OutingTime3__c = System.now().addDays(-1) 
			);
			insert beforeItem;
			
	        salaryProcessItem.SalaryCalculation();
	        
	        salaryProcessItem.SalaryItemInfo.BaseSalary = 'test';
	        salaryProcessItem.SalaryCalculation();
	        
	        salaryProcessItem.printFromPDF();
	        salaryProcessItem.DepartmentChanged();
			String s1 = salaryProcessItem.startTimeOfMaster + salaryProcessItem.endTimeOfMaster + salaryProcessItem.restTimeOfMaster;
	        SalaryPdfCTRL salaryPDFItem = new SalaryPdfCTRL();
        }
    }
}