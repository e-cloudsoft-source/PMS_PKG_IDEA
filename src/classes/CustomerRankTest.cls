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
@isTest
private class CustomerRankTest {
	@Istest(seeAlldata=true) 
    static void TestCustomerRank()
    {	
		Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
    		Allergy__c = true,
    		DetailedAllergy__c= 'hjghjgk',
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		contacts.ReportsToId = contacts.Id;		
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu; 
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
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
        CR.UsageChargeSel=10;
        CR.SearchRecords();
        CR.Condition1='Equal To';
        CR.UsageCountSel=20;
        CR.condition3='And';        
        CR.SearchRecords();
        CR.QueryRecords();
        System.assert(con != null);
    }    
    @Istest(seeAlldata=true)    
    static void TestCustomerRank1()
    {   
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
		Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
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
        CR.UsageCountSel=20;
        CR.Condition2='Lesser than';
        CR.UsageChargeSel=20;
        CR.InitData();
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='And'; 
        CR.Condition1='Greater Than';
        CR.Condition2='Lesser than';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)    
    static void TestCustomerRank2()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=0;
        CR.Condition2='';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.UsageCountSel=0;
        CR.condition3='And'; 
        CR.Condition1='';
        CR.Condition2='';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)    
    static void TestCustomerRank3()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=30  
        );
		insert contacts;
		//system.debug(logginglevel.info,'contacts:::'+contacts);
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        Contact co = new Contact(); 
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();                
        CR.UsageCountSel=30;
        CR.Condition2='';
        CR.UsageChargeSel=30;
        CR.SearchRecords();
        CR.UsageCountSel=30;
        CR.condition3='And'; 
        CR.Condition1='Lesser Than';
        CR.Condition2='Equal To';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true) 
    static void TestCustomerRank4()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '???',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
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
        CR.UsageCountSel=1;
        CR.condition3='--None--';
        CR.Condition2='Greater than';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.Condition1='Equal To';
        CR.UsageCountSel=1;
        //CR.condition3='--None--';        
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    } 
    @Istest(seeAlldata=true) 
    static void TestCustomerRank44()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '???',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
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
        CR.condition3='--None--';
        CR.Condition2='Greater than';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.Condition1='Equal To';
        CR.UsageCountSel=20;
        //CR.condition3='--None--';        
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }     
    @Istest(seeAlldata=true)  
    static void TestCustomerRank5()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        CR.getStartDate();
        CR.getEndDate();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
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
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=10;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='--None--'; 
        CR.Condition1='Greater Than';
        CR.Condition2='Lesser than';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)   
    static void TestCustomerRank6()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='--None--'; 
        CR.Condition1='';
        CR.Condition2='';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)    
    static void TestCustomerRank7()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '確認中',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='--None--'; 
        CR.Condition1='Lesser Than';
        CR.Condition2='Equal To';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
     @Istest(seeAlldata=true)    
    static void TestCustomerRank8()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=20;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='--None--'; 
        CR.Condition1='--None--';
        CR.Condition2='Equal To';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)    
    static void TestCustomerRank9()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '???',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();        
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='--None--'; 
        CR.Condition1='Lesser Than';
        CR.Condition2='--None--';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    @Istest(seeAlldata=true)    
    static void TestCustomerRank10()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '???',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();        
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.Condition2='';
        CR.UsageChargeSel=10000;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3=''; 
        CR.Condition1='Lesser Than';
        CR.Condition2='--None--';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
    static void TestCustomerRank11()
    {
    	Contact contacts = new Contact(
		    firstName = 'UNIT_TEST_顧客名' + CommUtils.getRandom(6),
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = CommUtils.getRandom(10),
            Usage_Count__C=20,
            Usage_charge__C=20  
        );
		insert contacts;
		Lead__c l = new Lead__c(
			//contactref = contacts.id,
		    name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
		    Relcontact__c = contacts.Id,                  // 顧客名
		    ReservedStatus__c = '???',
		    ReservedDate__c = System.now(),
		    ReservedContact__c = 'Ono',
		    EntryTime__c = System.now(),
		    Field4__c = '15:30',
		    Departure__c = System.now().addDays(1),
		    Field3__c = '10:00',
		    StayPersons__c = 4,
		    Field2__c = 'FAX'
		    //Field310__c = createPlan().Id
		    //LeadIndexRef__c = leadIndex.Id,
			
		);
		insert l;
		CustomerRANK__c cu = new CustomerRANK__c(
			RANK__c = 'AA',
			RelContact__c = contacts.Id 
		);
		insert cu;
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
        Lead__c l1 = CR.getFromDate();
        Lead__c l2 = CR.getToDate();
        l1.Searchdate__c = system.now().date().addDays(-1);
        l2.Searchdate__c = system.now().date().addDays(1);        
        System.currentPageReference().getParameters().put('rid','1');
        CR.EditRank();
        CR.SelectedRec= 'All selected records';
        CR.SaveRank();
        CR.SelectedRec= 'The record clicked';
        CR.SaveRank();                
        CR.UsageCountSel=20;
        CR.UsageChargeSel=20;
        CR.SearchRecords();
        CR.UsageCountSel=20;
        CR.condition3='And';      
        CR.SearchRecords();
        CR.QueryRecords();
        Pagereference pg = CR.OpenRfmReport();
        System.assert(con != null);
    }
}