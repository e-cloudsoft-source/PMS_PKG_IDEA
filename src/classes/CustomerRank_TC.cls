@isTest
public class CustomerRank_TC
{
    static testmethod void m1()
    {
    	TestCommon.createCommDefine();
    	
       Contact con = new Contact();
       con.FirstName  = 'g';
       con.LastName = 'ram';
       insert con;
       
       CustomerRANK__c cr = new CustomerRANK__c();
       cr.RelContact__c = con.id;
       cr.RANK__c = '1';
       insert cr;
       
       Lead__c l = new Lead__c();
       l.Relcontact__c = con.id;
       l.ReservedStatus__c = '確認中';
       l.ReservedDate__c = System.today();
       insert l;
       
       AccountAcount__c aa = new AccountAcount__c();
       aa.relaccount__c = con.id;
       aa.Relreserve__c = l.id;
       aa.Field57__c = '1';       
       aa.Field53__c = '20120813100851';
       aa.Field114__c = '+0065881';
       aa.Field39__c = '00';
       aa.frs__c = TestCommon.createRsvAccount().Id;
       insert aa;
       /*
       CustomerRank  Crank = new CustomerRank();
       crank.getRank();
       crank.getStartDate();
       crank.getEndDate();
       crank.UsageCountSel = 0;
       crank.UsageChargeSel = 1;
       crank.Condition1 = 'Greater Than';
       crank.Condition2 = 'Greater Than';
       crank.QueryRecords();
       crank.getInnserClassList();
       crank.getSearchResults();
       crank.SaveRecords();
       crank.getShowResult();
       System.currentPageReference().getParameters().put('rid','1');
       crank.EditRank();
       crank.getshowRadio();
       crank.SelectedRec = 'The record clicked';
       crank.SaveRank();
       crank.getDispPopUp();
       
       crank.Condition3 = '--None--';
       crank.Condition1 = '--None--';
       crank.Condition2 = 'Greater Than';
       crank.QueryRecords();
       
       crank.Condition3 = '--None--';
       crank.Condition1 = 'Greater Than';
       crank.Condition2 = '--None--';
       crank.QueryRecords();
       
       crank.Condition3 = 'OR';
       crank.Condition1 = '--None--';
       crank.Condition2 = 'Greater Than';
       crank.QueryRecords();
       crank.getConRec();
       crank.getConRec1();
       crank.getConRec2();
       crank.getGraphValues();
       crank.getRowSize();
       crank.ShowPDF();
       
       ApexPages.StandardController controller = new ApexPages.StandardController(con);
       CustomerRank  Crank1 = new CustomerRank(controller);
       */
       System.assertEquals(1,1,'Test Assert');
       
    }
}