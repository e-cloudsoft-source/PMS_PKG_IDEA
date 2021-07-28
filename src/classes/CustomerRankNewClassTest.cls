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
@isTest(seeAlldata=true)
private class CustomerRankNewClassTest {

    @Istest(seeAlldata=true) 
    static void TestCustomerRank()
    {
        Contact con=[select id from contact limit 1];
        CustomerRankNewClass  CRS=new CustomerRankNewClass (new apexpages.standardcontroller(con));
        CustomerRankNewClass CR=new CustomerRankNewClass();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        CR.getFromDate();
        CR.getToDate();
        CR.ShowPDF();
        CR.getGraphValues();
        CR.getRowSize();
        CR.getConRec();
        CR.getConRec1();
        CR.getConRec2();
        CR.getSearchResults();
        CR.getShowResult();
        CR.getshowRadio();
        CR.CancelRank();
        CR.SaveRecords();
        CR.getDispPopUp();
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();        
        CR.Condition1='Equal To';
        CR.UsageCountSel=20;
        CR.condition3='And';
        CR.Condition2='Greater than';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.Condition1='Equal To';
        CR.UsageCountSel=20;
        CR.condition3='--None--';        
        CR.SearchRecords();
        CR.QueryRecords();
        System.assert(CR != null);
    }
}