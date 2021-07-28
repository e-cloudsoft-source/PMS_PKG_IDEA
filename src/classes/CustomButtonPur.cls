public with sharing class CustomButtonPur {

    //仕入オブジェクトのカスタムボタンで使用
    private ID CostID;//今月の原価率[調理]
    private ID PurchaseID;//現在の仕入高[調理]
    private Date purchasedate;
    //Add by jiashixin 20131015 begin
    private String colDt_s = '';
    private String colDt_e = '';
    //Add by jiashixin 20131015 end

    public CustomButtonPur(ApexPages.StandardController controller){
        CostID = [select Id, name from Report where Name = :CommDefine__c.getOrgDefaults().A1CookingReport__c limit 1].Id;
        PurchaseID = [select Id, name from Report where Name = :CommDefine__c.getOrgDefaults().PurchaseReport__c limit 1].Id;
        purchasedate = [select Id, Field1__c from Purchase__c where Id =: controller.getId() limit 1].Field1__c;
        //Add by jiashixin 20131015 begin
        //get the first and last day of the current month
        Date firstDayOfMonth = purchasedate.toStartOfMonth();
        colDt_s = String.valueOf(firstDayOfMonth.year())+'/'+String.valueOf(firstDayOfMonth.month())+'/'+String.valueOf(firstDayOfMonth.day());
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        colDt_e = String.valueOf(lastDayOfMonth.year())+'/'+String.valueOf(lastDayOfMonth.month())+'/'+String.valueOf(lastDayOfMonth.day());
        //Add by jiashixin 20131015 end
    }

    public PageReference ViewCost(){
        //update by jiashixin 20131015 begin
        //String wpurchasedate = String.valueOf(purchasedate.year())+'/'+String.valueOf(purchasedate.month())+'/'+String.valueOf(purchasedate.day());
        return (new PageReference('/'+String.valueOf(CostID)+'?colDt_q=custom&colDt_s='+colDt_s+'&colDt_e='+colDt_e));
        //update by jiashixin 20131015 end
    }

    public PageReference ViewPurchase(){
        //update by jiashixin 20131015 begin
        //String wpurchasedate = String.valueOf(purchasedate.year())+'/'+String.valueOf(purchasedate.month())+'/'+String.valueOf(purchasedate.day());
        return (new PageReference('/'+String.valueOf(PurchaseID)+'?colDt_q=custom&colDt_s='+colDt_s+'&colDt_e='+colDt_e));
        //update by jiashixin 20131015 end
    }

}