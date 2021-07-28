public with sharing class CustomButtonRac {

    //売上オブジェクトのカスタムボタンで使用
    private ID WhiteBoardID;//売上日の予約情報

    private Date rsvaccdate;

    public CustomButtonRac(ApexPages.StandardController controller){
        WhiteBoardID = [select Id, name from Report where Name = :CommDefine__c.getOrgDefaults().WhiteBoardReport__c limit 1].Id;

        rsvaccdate = [select Id, Field3__c from RsvAccount__c where Id =: controller.getId() limit 1].Field3__c;
    }

    public PageReference ViewWhiteBoard(){
        String wrsvaccdate = String.valueOf(rsvaccdate.year())+'/'+String.valueOf(rsvaccdate.month())+'/'+String.valueOf(rsvaccdate.day());
        return (new PageReference('/'+String.valueOf(WhiteBoardID)+'?colDt_s='+wrsvaccdate+'&colDt_e='+wrsvaccdate));
    }

}