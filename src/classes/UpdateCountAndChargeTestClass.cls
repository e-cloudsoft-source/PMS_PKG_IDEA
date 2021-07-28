@IsTest 
private class UpdateCountAndChargeTestClass
{
    static Testmethod void Test()
    {
    	TestCommon.createCommDefine();
        Contact c=new Contact(LastName='Sample');
        insert c;
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Contact where LastName = 'Sample'].size(), 1);
        // 2015/12/01 Assert END
        ps__RsvAccount__c Rs=new ps__RsvAccount__c(Name='Sample');
        insert Rs;
        ps__AccountAcount__c ac=new ps__AccountAcount__c(ps__Field114__c='120',ps__frs__c=Rs.id,ps__relaccount__c=c.id);
        insert Ac;
        ps__Room__c room=new ps__Room__c(Name='Sample Room',ps__CapacityHaku__c=5,ps__Capacity__c=5,ps__heyadashiryou__c=1000,ps__heyadashiryouryou__c=2000);
        insert room;
        Ps__Lead__c ld=new Ps__Lead__c(Name='Sample',ps__Relcontact__c=c.id,ps__ReservedDate__c=datetime.now(),ps__Field4__c='11:00',ps__Field3__c='20:00',ps__Field2__c='phone',ps__Rroom__c=Room.id);
        insert ld;
        c.Lastname='Sample 1';
        delete ld;
        delete Ac;     
        System.debug(c != null);
    }
}