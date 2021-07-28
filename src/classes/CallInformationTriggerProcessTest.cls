@isTest(seeAllData=false)
private class CallInformationTriggerProcessTest {
	static testMethod void case01() {
		// お客様情報を作成する
		Contact  con = TestCommon.createContact();
		con.Katakana__c = 'X33335 BWM RED';
		update con;
		
		
		
		List<CollaborationGroup> groups = TestCommon.createGroups(3);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ChatterGroupName__c = '1:' + groups[0].name+','+groups[1].name+';2:'+groups[2].name;
    	comDef.CTICarAPIName__c = 'Katakana__c';
    	comDef.ResCarNoRef__c = '00Nd00000051L7k';
    	update comDef;

		List<Call_information__c> callInfo = new List<Call_information__c>();
    	String picData = '/9j/4AAQSkZJRgABAQEAYABgAAD/4QA6RXhpZgAATU0AKgAAAAgAA1EQAAEAAAABAQAAAFERAAQAAAABAAAAAFESAAQAAAABAAAA'
							+ 'AAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/'
							+ '2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCABB'
							+ 'AK8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIh'
							+ 'MUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1'
							+ 'dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3'
							+ '+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMi'
							+ 'MoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE'
							+ 'hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMB'
							+ 'AAIRAxEAPwD9/KCcCivh7/gs1+1vqHwr8E6b8O/D91JZ6l4rge51SeJtskViGKCNT1HmuHBI/hjYdGr1sjyetmmNhgqG8uvRJat/'
							+ 'JffsfP8AFHEWHyPLKuZ4nWMFolvJvRJer69Fd9Dsv2iv+Cv3wz+COtXGkaOl7431a1YpN/ZrqllEw6qZ2yGP/XNXHXkEYryzw1/w'
							+ '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'
							+ 'QAUUUUAFFFFABRRRQB//9k=';

		CallInformationSync.CallInformation call = new CallInformationSync.CallInformation();
		call.sno     = 'CAR&X33335&BWM&RED&' + picData;
		call.nam     = 'テスト部署';
		call.lno     = '00';
		call.cdt     = '20151010';
		call.ctm     = '172603';
		
		Test.startTest();
		CallInformationSync.CallInformationSyncResult rs  = CallInformationSync.createCallInformation(call);
        
        Call_Information__c callInfoRs = [ select Contact__c from Call_Information__c where id = :rs.sfdcId];
        callInfoRs.Contact__c = con.Id;
        update callInfoRs;
        Test.stopTest();
        
        List<FeedItem> feeds = [select id from FeedItem];
        System.assertEquals(feeds.size(),1);
	}

}