public with sharing class CustomerRankController {
	// 2018/11/01 BEGIN
    /*public Integer UsageChargeSel { get; set; }
    public String Condition2 { get; set; }
    public String Condition3 { get; set; }
    public Integer UsageCountSel { get; set; }
    public String Condition1 { get; set; }
    boolean showpopup = false;
    Boolean showRadio = false;
    public PageReference ShowPDF() 
    {
        ContactId  = System.currentPageReference().getParameters().get('rid');             
        PageReference PageRef = new PageReference('/apex/PDFGenerator?id='+ContactId);        
        return PageRef;
    }

     Integer nn;
    public Void EditRank() 
    {
        nn = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
        System.debug('NNNNNNNNN Value'+nn);
        integer y = 0;
        for(InnerClass ii : InnerClassList)
        {
            if(ii.RecCount == nn )
            {
                 System.debug('In Loop+++++');
                crank.ps__RANK__c = ii.customerRank.ps__RANK__c;
                ii.IsChecked  = true;
                ii.ShowInput = true;
                showpopup = true;               
            }
            else
            {
                ii.ShowInput = false;
            }
            if(ii.IsChecked==true)
            {
                y++;
            }            
        }
       
        SelectedRec  = 'The record clicked';
        if(y > 1)
        {
            showRadio = true;
        }
        else
        {
            showRadio = false;
        }
    }


    public Integer totalUsageRecsCount = 0;
    public integer noOfRecInBetwnDate = 0;
    public boolean isSelected {get;set;}
    public String RankSelectd {get;set;}
    public Integer TotalUsageCount {get;set;}
    public Decimal TotalUsageCharge {get;set;}
    public String NearestUsageDay {get;set;}
    public String ReportsToName {get;set;}
    public boolean AllergyYes {get;set;}
    public boolean AllergyNo {get;set;}        
    String ContactId;
    List<ps__Lead__c> LeadCount = new List<ps__Lead__c>();
    List<ps__AccountAcount__c> AccountCharge = new List<ps__AccountAcount__c>();
    Contact ConRec = new Contact();
    Contact ConRec1 = new Contact();
    Contact ConRec2 = new Contact();
    
    public CustomerRankController()
    {
       InitData(); 
    }
    
    public void InitData()
    {
    List<contact> contactlist=[select id, Name,(select id,ps__RelContact__c,ps__RANK__c from ps__CutomerRANKWG3x__r),ps__Usage_Charge__C,ps__Usage_Count__C,FirstName , LastName from Contact  ORDER BY ps__Usage_Count__C DESC limit 10];
    Integer j=1;
      for(contact c:contactlist)
      {   
         InnerClass I=new InnerClass ();
            if(c.ps__Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.ps__Usage_Count__C);
             if(c.ps__Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.ps__Usage_charge__C);
             i.contactName=C;
             if(c.ps__CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.ps__CutomerRANKWG3x__r[0];
             //i.ColCount=j;
             i.RecCount=j;
          
            InnerClassList.add(i);
         
            j++;
      }
    }
    
    public List<InnerClass> getInnserClassList() {
        return InnerClassList;
    }
     public List<InnerClass>  InnerClassList = new List<InnerClass>();
    public class InnerClass
    {
        public integer UsageCount{get;set;}
        public integer UsageCharge{get;set;}  
        public Contact contactName{get;set;}  
        public ps__CustomerRANK__c customerRank{get;set;}
        public Integer ColCount {get;set;}
        public Integer RecCount {get;set;}
        public Boolean ShowInput {get;set;}   
        public Boolean ShowNone {get;set;}
        public Boolean IsChecked {get;set;}    
        
    } 
    public List<InnerClass> innerList = new List<InnerClass>();

    public boolean getShowResult() 
    {
        if(InnerClassList.size() > 0)
        {
            return true;
        }
        else
        {
            return false;
        }
        
    }


    public Void CancelRank() 
    {
        showpopup = false;
    }


    public Void SaveRank() 
    {
            //Integer n = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
        List<ps__CustomerRANK__c> RankList = new List<ps__CustomerRANK__c>();
        for(InnerClass ii : InnerClassList)
        {
            System.debug('111111111111111111111'+ii.IsChecked);
            
            if(ii.RecCount == nn && SelectedRec  == 'The record clicked')
            {
                ii.ShowInput = false;  
                if(ii.customerRank==null)
                {    
                    crank.ps__RelContact__c=ii.contactName.id;
                    ii.customerRank=crank;
                    
                }
                else
                {                
                    ii.customerRank.ps__Rank__c = crank.ps__RANK__c;
                }              
                //ii.customerRank.Rank__c = crank.RANK__c;
                RankList.add(ii.customerRank); 
            }            
            if(SelectedRec  == 'All selected records')
            {
              if(ii.IsChecked==true )
               {
                   if(ii.customerRank==null)
                    {    
                        ps__CustomerRANK__c crank2=new ps__CustomerRANK__c();
                        crank2.ps__RelContact__c=ii.contactName.id;
                        crank2.ps__RANK__c=crank.ps__RANK__c;
                        ii.customerRank=crank2;
                    
                    }
                    else
                    {                
                        ii.customerRank.ps__Rank__c = crank.ps__RANK__c;
                    }
                   //ii.customerRank.Rank__c = crank.RANK__c ;
                   RankList.add(ii.customerRank);
               }
                                        
            } 
                   
        }
        if(RankList.size() > 0)
        {
           upsert RankList;
        }
        showpopup = false;
    }


    public String SelectedRec { get; set; }

    public boolean  getShowRadio() {
        return showRadio;
    }

    ps__CustomerRANK__c crank = new ps__CustomerRANK__c();
    public ps__CustomerRANK__c getRank() {
        return crank ;
    }


    public boolean getDispPopUp() {
        return showpopup;
    }


    public Void SearchRecords() 
    {
        Set<ID> Contactid=new Set<id>();
        Map<Id,Contact> Mapcon=new Map<Id,Contact>([select id, Name,(select id,ps__RelContact__c,ps__RANK__c from ps__CutomerRANKWG3x__r),ps__Usage_Charge__C,ps__Usage_Count__C,FirstName , LastName from Contact limit 10000]);
        List<contact> contactlist=Mapcon.values();
        if(InnerClassList.size()>0)
        InnerClassList.clear();
       
          Datetime fromDate=l1.ps__Searchdate__c;
          Datetime ToDate=l2.ps__Searchdate__c;
        // String QueryString='select id, Name, FirstName ,LastName from Contact where  Usage_Count__C'+Operator1+UsageCountSel+' and Usage_Charge__C'+Operator2+UsageChargeSel;
         String StrQuery='select ps__Relcontact__c from ps__Lead__c where ps__EntryTime__c >=:fromDate AND ps__EntryTime__c <=:ToDate';
        
        
        // where EntryTime__c >='+l1.Searchdate__c+' AND EntryTime__c <'+l2.Searchdate__c
         list<ps__lead__c> leadlist=database.query(StrQuery);
      // If(l1.Searchdate__c!=null && l2.Searchdate__c!=null)
     // {
     //list<lead__c> leadlist=[select  Relcontact__c from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c];
         Integer j=1;
        for(ps__Lead__C l:leadlist)
        {
        
         InnerClass I=new InnerClass ();
         if(!Contactid.contains(l.ps__Relcontact__c))
         {
         Contactid.add(l.ps__Relcontact__c);
         if(l.ps__Relcontact__c!=null)
         {
         
         Contact c=Mapcon.get(l.ps__Relcontact__c);
         
         //if((Condition2 == 'Equal To' && c.Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.Usage_charge__C>UsageChargeSel) ) 
         if(condition3 == 'AND' ) 
         { 
            if(((Condition1 == 'Equal To' && c.ps__Usage_Count__C==UsageCountSel) || (Condition1 == 'Lesser Than' && c.ps__Usage_Count__C<UsageCountSel) ||(Condition1 == 'Greater Than' && c.ps__Usage_Count__C>UsageCountSel)) && ((Condition2 == 'Equal To' && c.ps__Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.ps__Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.ps__Usage_charge__C>UsageChargeSel) ) ) 
           {
         
             if(c.ps__Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.ps__Usage_Count__C);
             if(c.ps__Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.ps__Usage_charge__C);
             i.contactName=C;
             if(c.ps__CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.ps__CutomerRANKWG3x__r[0];
             //i.ColCount=j;
             i.RecCount=j;
          
            InnerClassList.add(i);
         
            j++;
           }
         }
         else if(condition3 == 'OR' || condition3 =='--None--' ) 
         { 
            if(((Condition1 == 'Equal To' && c.ps__Usage_Count__C==UsageCountSel) || (Condition1 == 'Lesser Than' && c.ps__Usage_Count__C<UsageCountSel) ||(Condition1 == 'Greater Than' && c.ps__Usage_Count__C>UsageCountSel)) || ((Condition2 == 'Equal To' && c.ps__Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.ps__Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.ps__Usage_charge__C>UsageChargeSel) ) ) 
           {
         
             if(c.ps__Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.ps__Usage_Count__C);
             if(c.ps__Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.ps__Usage_charge__C);
             i.contactName=C;
             if(c.ps__CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.ps__CutomerRANKWG3x__r[0];
             //i.ColCount=j;
             i.RecCount=j;
          
            InnerClassList.add(i);
         
            j++;
           }
         }
        }
        }
         //
         totalUsageRecsCount = 0;
        for(InnerClass IC : InnerClassList)
        {
            if(IC.UsageCount >= 2)
            {   
                totalUsageRecsCount = totalUsageRecsCount +  1;
            }
        }               
        if(InnerClassList.size() != 0)
        {            
            decimal q = Decimal.valueOf(InnerClassList.size());
            usagePercentage = (totalUsageRecsCount*100/q);
        }
        else
        {
            usagePercentage = 0;
        }
       
       // }
      }
    // TestMsg=string.valueof(leadlist);
    */
    // 2018/11/01 END
    /*
      Decimal m = UsageChargeSel;
      integer n = UsageCountSel;
      string Operator1,Operator2; 
     //list<contact> conlist=[select id, Name, FirstName , LastName from Contact where Usage_Charge__C<:m];
       if(Condition1=='Equal To')
          {
          Operator1='=';
          }
          else if(Condition1=='Greater Than')
          {Operator1='>';}
          else if(Condition1=='Lesser Than')
          {Operator1='>';}
        if(Condition2=='Equal To')
          {
          Operator2='=';
          }
          else if(Condition2=='Greater Than')
          {Operator2='>';}
          else if(Condition2=='Lesser Than')
          {Operator2='>';}  
         
         
         
        String QueryString='select id, Name, FirstName ,LastName from Contact where  Usage_Count__C+Operator1+UsageCountSel and Usage_Charge__C+Operator2+UsageChargeSel';
         
         
         
         
          list<contact> conlist=database.query(QueryString); 
       if(Condition1!= '--None--'&& condition3 == '--None--'&& Condition2== '--None--' ) 
       { 
          //String QueryString='select id, Name, FirstName ,LastName from Contact where  Usage_Count__C+Operator1+UsageCountSel';
         
         // list<contact> conlist=database.query(QueryString);      
       }
       else if(Condition1=='--None--'&& condition3 == '--None--'&& Condition2!= '--None--' ) 
       { 
          //String QueryString='select id, Name, FirstName ,LastName from Contact where Usage_Charge__C+Operator2+UsageChargeSel';
         
          //list<contact> conlist=database.query(QueryString);      
       }
      
      //if(Condition2  == 'Greater Than')
      //if(Condition1 == 'Equal To')       
      //if(condition3 != '--None--' && condition3 != 'OR')      
     */
    // 2018/11/01 BEGIN
    //}
	// 2018/11/01 END
	// 2018/11/01 BEGIN
    /*public Decimal usagePercentage { get; set; }
    //public string showPercentage{set;get;}
    public boolean getShowPercentage()
     {
         if(InnerClassList.size() > 0)
         {
             return true;
         } 
         else
         {
             return false;
         }    
     }
    
    ps__Lead__c l2 = new ps__Lead__c();
    public ps__Lead__c getToDate() {
        return l2;
    }


    ps__Lead__c l1 = new ps__Lead__c();
    public ps__Lead__c getFromDate() {
        return l1;
    }
    */
	// 2018/11/01 END
/**
*2015-11-18 
*テストクラスCustomerRankControllerTestに移行する
@Istest(seeAlldata=true) static void TestCustomerRank()
    { 
        Contact con=[select id from contact limit 1];
        //CustomerRankController CRS=new CustomerRankController(new apexpages.standardcontroller(con));
        CustomerRankController CR=new CustomerRankController();
        CR.getInnserClassList();
        CR.getShowPercentage();
        CR.getRank();
        //CR.getStartDate();
        //CR.getEndDate();
        CR.getFromDate();
        CR.getToDate();
        CR.ShowPDF();
        //CR.getGraphValues();
        //CR.getRowSize();
        //CR.getConRec();
        //CR.getConRec1();
        //CR.getConRec2();
        //CR.getSearchResults();
        CR.getShowResult();
        CR.getshowRadio();
        CR.CancelRank();
        //CR.SaveRecords();
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
        //CR.QueryRecords();
        System.assert(CR != null);
    }

*/  
    
}