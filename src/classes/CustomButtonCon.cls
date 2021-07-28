public with sharing class CustomButtonCon {

    //予約オブジェクトのカスタムボタンで使用
    private ID RmAssNoonID;//客室割当状況 - 昼と夕
    private ID ScheduleID;//炭酸泉エステ時間割予約表

    private Date rsvdate;

    public CustomButtonCon(ApexPages.StandardController controller){
        RmAssNoonID = [select Id, name from Report where Name = :CommDefine__c.getOrgDefaults().Tier4Report__c limit 1].Id;
        ScheduleID = [select Id, name from Report where Name = :CommDefine__c.getOrgDefaults().CustomTimeReport__c limit 1].Id;

        rsvdate = [select Id, ReservedDate821__c from Lead__c where Id =: controller.getId() limit 1].ReservedDate821__c;
    }

    public PageReference ViewRmAssNoon(){
        //String wdate = String.valueOf(rsvdate.year())+'/'+String.valueOf(rsvdate.month())+'/'+String.valueOf(rsvdate.day());
        String wdate = DateTime.newinstance(rsvdate.year(),rsvdate.month(),rsvdate.day()).format(CommBaseCtrl.getDateFormat());
        return (new PageReference('/'+String.valueOf(RmAssNoonID)+'?colDt_s='+wdate+'&colDt_e='+wdate));
    }

    public PageReference ViewSchedule(){
        //String wdate = String.valueOf(rsvdate.year())+'/'+String.valueOf(rsvdate.month())+'/'+String.valueOf(rsvdate.day());
        String wdate = DateTime.newinstance(rsvdate.year(),rsvdate.month(),rsvdate.day()).format(CommBaseCtrl.getDateFormat());
        return (new PageReference('/'+String.valueOf(ScheduleID)+'?colDt_s='+wdate+'&colDt_e='+wdate));
    }

}