@isTest
private class IOTInformationSyncTest {
  static testMethod void case01() {
		// Chatter Group
		List<CollaborationGroup> groups = TestCommon.createGroups(1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ChatterGroupName__c = '6:'+groups[0].name;
    	update comDef; 
    	 
    	List<Call_information__c> callInfo = new List<Call_information__c>();
    	IOTInformationSync.IOTInformation call = new IOTInformationSync.IOTInformation();
		call.sno     = '40';
		call.nam     = 'WaterTemperature';
		call.dt1     ='Yama';
		call.lno     = '00';
		call.cdt     = '20161010';
		call.ctm     = '093152';
		call.rsnp	 = true;
		call.rsncode = 'xx';
		call.dcd1	 = true;
		call.dt0 	 = 'Low';
		call.dno 	 = '12';
		call.dt4 	 = 'zz';
		

        IOTInformationSync.IOTInformationSyncResult rs  = IOTInformationSync.createCallInformation(call);
		System.assert(rs.isSuccess);
		
		call.sno     = '100';
		call.nam     = 'Persons';
		call.dt1     ='Yamakura';
		call.cdt     = '20161110';
		call.ctm     = '093152';
		rs  = IOTInformationSync.createCallInformation(call);
		System.assert(rs.isSuccess);
  }
  
  static testMethod void case02() {
		// Chatter Group
		List<CollaborationGroup> groups = TestCommon.createGroups(1);
    	CommDefine__c comDef = TestCommon.createCommDefine();
    	comDef.ChatterGroupName__c = '6:'+groups[0].name;
    	comDef.IotMessageJoinFlg__c = true;
    	update comDef; 
    	 
    	List<Call_information__c> callInfo = new List<Call_information__c>();
    	IOTInformationSync.IOTInformation call = new IOTInformationSync.IOTInformation();
		call.sno     = '40';
		call.nam     = 'WaterTemperature';
		call.dt1     ='Yama';
		call.lno     = '00';
		call.cdt     = '20161010';
		call.ctm     = '093152';
		call.rsnp	 = true;
		call.rsncode = 'xx';
		call.dcd1	 = true;
		call.dt0 	 = 'Low';
		call.dno 	 = '12';
		call.dt4 	 = 'zz';
		

        IOTInformationSync.IOTInformationSyncResult rs  = IOTInformationSync.createCallInformation(call);
		System.assert(rs.isSuccess);
		
		call.sno     = '100';
		call.nam     = 'Persons';
		call.dt1     ='Yamakura';
		call.cdt     = '20161110';
		call.ctm     = '093152';
		rs  = IOTInformationSync.createCallInformation(call);
		System.assert(rs.isSuccess);
  }
  static testMethod void case03() {
  		//List<CollaborationGroup> groups = TestCommon.createGroups(1);
  		CommDefine__c def = TestCommon.createCommDefine();
  		//def.ChatterGroupName__c = '6:'+groups[0].name;
  		def.IotMessageJoinFlg__c = true;
  		update def;
    	List<Call_information__c> callInfo = new List<Call_information__c>();
    	IOTInformationSync.IOTInformation call = new IOTInformationSync.IOTInformation();
		call.sno     = '40';
		call.nam     = 'WaterTemperature';
		call.dt1     ='Yama';
		call.lno     = '00';
		call.cdt     = '20161010';
		call.ctm     = '093152';
		call.rsnp	 = true;
		call.rsncode = 'xx';
		call.dcd1	 = true;
		call.dt0 	 = 'Low';
		call.dno 	 = '12';
		call.dt4 	 = 'zz';
		
        IOTInformationSync.IOTInformationSyncResult rs  = IOTInformationSync.createCallInformation(call);
		System.assert(!rs.isSuccess);
  }
}