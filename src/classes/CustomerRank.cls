public with sharing class CustomerRank
{
    Public String Condition1 {get;set;}
    public String Condition2 {get;set;}
    public String Condition3 {get;set;}
    
    public Integer UsageCountSel{get;set;}
    public Integer UsageChargeSel{get;set;} 
    
    public Decimal usagePercentage {get;set;}
    public Integer totalUsageRecsCount = 0;
    public integer noOfRecInBetwnDate = 0;
   
    public boolean isSelected {get;set;}
    public String RankSelectd {get;set;}
    public String SelectedRec {get;set;}
    
    public Integer TotalUsageCount {get;set;}
    public Decimal TotalUsageCharge {get;set;}
    public String NearestUsageDay {get;set;}
    public String ReportsToName {get;set;}
    public boolean AllergyYes {get;set;}
    public boolean AllergyNo {get;set;}
        
    String ContactId;
    List<Lead__c> LeadCount = new List<Lead__c>();
    List<AccountAcount__c> AccountCharge = new List<AccountAcount__c>();
    Contact ConRec = new Contact();
    Contact ConRec1 = new Contact();
    Contact ConRec2 = new Contact();
    
    public contact getConRec()
    {        
        return ConRec;
    }
    public contact getConRec1()
    {
        ConRec1.Allergy__c = ConRec.Allergy__c;
        return ConRec1;
    }
    public contact getConRec2()
    {
        ConRec2.Allergy__c = !ConRec.Allergy__c;
        return ConRec2;
    }
    
    // 2013/10/28 RFMレポートURL格納
    public String reportId{get;set;}
    
    public CustomerRank(ApexPages.StandardController cntrl)
    {       
        ContactId = cntrl.getRecord().Id; 
                
        if(!(ContactId == null || ContactId == ''))
        {
           ConRec = [Select Name, Field1__c, Allergy__c, DetailedAllergy__c, ReportsToId from Contact where id =: ContactId];
           LeadCount = [Select Id, ReservedDate__c, No__c from Lead__c where Relcontact__c =: ContactId AND (ReservedStatus__c = '確認中' OR ReservedStatus__c = '確定') Order By ReservedDate__c desc];
           if(ConRec.Allergy__c)
           {
               AllergyYes = true;
               AllergyNo = false;
           }
           else 
           {
               AllergyNo = true;
               AllergyYes = false;
           }
           TotalUsageCount =  LeadCount.size();
           if(LeadCount.size() > 0)
           {
               if(LeadCount[0].ReservedDate__c != null)
               {
                   System.debug('rrrrrrrrrrrrrrrrrrrrrrr'+LeadCount[0].ReservedDate__c);
                   System.debug('qqqqqqqqqqqqqqqqqqqqqq'+Date.valueOf(LeadCount[0].ReservedDate__c));
                   NearestUsageDay  = String.valueOf(Date.valueOf(LeadCount[0].ReservedDate__c));                   
               }
           }
           System.debug('11111111111111111111'+LeadCount);
           if(ConRec.ReportsToId != null)
           {
               Contact ccc = [select Name from Contact where id =: ConRec.ReportsToId ];
               ReportsToName  = ccc.Name;
           } 
           AccountCharge = [Select Field147__c, Field148__c from AccountAcount__c where relaccount__c =: ContactId AND OutSideAccount__c =:1];
           TotalUsageCharge = 0;
           for(AccountAcount__c aa : AccountCharge )
           {
              TotalUsageCharge = TotalUsageCharge  + aa.Field147__c; 
           }  
        }  
        
    }
    public CustomerRank()
    {
       InitData(); 
    }
    
    public List<AccountAcount__c> getGraphValues()
    {
        System.debug('@@@@@@@@AccountCharge'+AccountCharge);
        return AccountCharge; 
    }
    public Integer getRowSize()
    {
        System.debug('@@@@@@@@AccountCharge Size'+AccountCharge.size());
        return AccountCharge.size();
    }
   
    public PageReference ShowPDF()
    {
        ContactId  = System.currentPageReference().getParameters().get('rid');             
        PageReference PageRef = new PageReference('/apex/PDFGenerator?id='+ContactId);        
        return PageRef;   
    }
    
    List<AccountAcount__c> SearchResult = new List<AccountAcount__c>();
    AccountAcount__c A1 = new AccountAcount__c();
    CustomerRANK__c crank = new CustomerRANK__c();
    public CustomerRANK__c getRank()
    {
        return crank; 
    }
    public AccountAcount__c getStartDate()
    {
        return A1;
    }
    AccountAcount__c A2 = new AccountAcount__c();
    public AccountAcount__c getEndDate()
    {
        return A2;
    }   
    Lead__c l1 = new Lead__c();
    Lead__c l2 = new Lead__c();
    public Lead__c getFromDate()
    {
        return l1;
    } 
    public Lead__c getToDate()
    {
        return l2;
    }
    public String TestMsg{set;get;}
    public void InitData()
    {
    // 2013/10/28 RFMレポートURLのIDを取得する
    List<Report> rfmReps = [Select Id, Name From Report where Name = :CommConst.APPOPTION_CUSTOMER_RANK_REPNM];
    if (!rfmReps.isEmpty()) reportId = rfmReps[0].Id;
    
    return;
    List<contact> contactlist=[select id, Name,(select id,RelContact__c,RANK__c from CutomerRANKWG3x__r),Usage_Charge__C,Usage_Count__C,FirstName , LastName from Contact  ORDER BY Usage_Count__C DESC limit 10];
    Integer j=1;
      for(contact c:contactlist)
      {   
         InnerClass I=new InnerClass ();
            if(c.Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.Usage_Count__C);
             if(c.Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.Usage_charge__C);
             i.contactName=C;
             if(c.CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.CutomerRANKWG3x__r[0];
             //i.ColCount=j;
             i.RecCount=j;
          
            InnerClassList.add(i);
         
            j++;
      }
    }
    // 2013/10/28 RFMレポート起動URL
    public PageReference OpenRfmReport(){
    	if (CommUtils.isBlank(reportId)) {
    		//設定情報が不正するため。レポートのロードに失敗しました。
    		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_013_0029));
    		return null;
    	}
    	String reportUrl = reportId + '?';
    	if (!CommUtils.isBlank(Condition1)) {
    		reportUrl += 'pn0=' + Condition1 + '&pv0=' + UsageCountSel + '&';
    	} else {
    		reportUrl += 'pn0=ne&pv0=-1&';
   		}
    	if (!CommUtils.isBlank(Condition2)) {
    		reportUrl += 'pn1=' + Condition2 + '&pv1=' + UsageChargeSel + '&';
    	} else {
    		reportUrl += 'pn1=ne&pv0=-1&';
   		}
   		if (l1.Searchdate__c != null || l2.Searchdate__c != null) {
   			reportUrl += 'colDt_q=custom&';
   		}
   		if (l1.Searchdate__c != null) {
   			reportUrl += 'colDt_s='+(l1.Searchdate__c).format()+'&';
   		} else {
   			reportUrl += 'colDt_s=&';
   		}
   		if (l2.Searchdate__c != null) {
   			reportUrl += 'colDt_e='+(l2.Searchdate__c).format()+'&';
   		} else {
   			reportUrl += 'colDt_e=&';
   		}
   		if (!CommUtils.isBlank(Condition3)) {
   			reportUrl += 'bool_filter=1+'+Condition3+'+2';
   		}
   		// 2018/03/07 Security Check BEGIN
   		return (new PageReference('/' + reportUrl));
   		// 2018/03/07 Security Check END
    }
    
    public void SearchRecords()
    {   Set<ID> Contactid=new Set<id>();
        Map<Id,Contact> Mapcon=new Map<Id,Contact>([select id, Name,(select id,RelContact__c,RANK__c from CutomerRANKWG3x__r limit 50000),Usage_Charge__C,Usage_Count__C,FirstName , LastName from Contact limit 50000]);
        List<contact> contactlist=Mapcon.values();
        if(InnerClassList.size()>0)
        InnerClassList.clear();
       
          Datetime fromDate=l1.Searchdate__c;
          Datetime ToDate=l2.Searchdate__c;
        // String QueryString='select id, Name, FirstName ,LastName from Contact where  Usage_Count__C'+Operator1+UsageCountSel+' and Usage_Charge__C'+Operator2+UsageChargeSel;
         String StrQuery='select Relcontact__c from Lead__c where EntryTime__c >=:fromDate AND EntryTime__c <=:ToDate';
        
        
        // where EntryTime__c >='+l1.Searchdate__c+' AND EntryTime__c <'+l2.Searchdate__c
         list<lead__c> leadlist=database.query(StrQuery);
      // If(l1.Searchdate__c!=null && l2.Searchdate__c!=null)
     // {
     //list<lead__c> leadlist=[select  Relcontact__c from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c];
         Integer j=1;
        for(Lead__C l:leadlist)
        {
        
         InnerClass I=new InnerClass ();
         if(!Contactid.contains(l.Relcontact__c))
         {
         Contactid.add(l.Relcontact__c);
         if(l.Relcontact__c!=null)
         {
         
         Contact c=Mapcon.get(l.Relcontact__c);
         // 2018/11/01 获取的Contact数据为Null的bug对应 BEGIN
         if(c == null) continue;
         // 2018/11/01 获取的Contact数据为Null的bug对应 END
         
         //if((Condition2 == 'Equal To' && c.Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.Usage_charge__C>UsageChargeSel) ) 
         if(condition3 == 'AND' ) 
         { 
            if(((Condition1 == 'Equal To' && c.Usage_Count__C==UsageCountSel) || (Condition1 == 'Lesser Than' && c.Usage_Count__C<UsageCountSel) ||(Condition1 == 'Greater Than' && c.Usage_Count__C>UsageCountSel)) && ((Condition2 == 'Equal To' && c.Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.Usage_charge__C>UsageChargeSel) ) ) 
           {
         
             if(c.Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.Usage_Count__C);
             if(c.Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.Usage_charge__C);
             i.contactName=C;
             if(c.CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.CutomerRANKWG3x__r[0];
             //i.ColCount=j;
             i.RecCount=j;
          
            InnerClassList.add(i);
         
            j++;
           }
         }
         else if(condition3 == 'OR' || condition3 =='--None--' ) 
         { 
            if(((Condition1 == 'Equal To' && c.Usage_Count__C==UsageCountSel) || (Condition1 == 'Lesser Than' && c.Usage_Count__C<UsageCountSel) ||(Condition1 == 'Greater Than' && c.Usage_Count__C>UsageCountSel)) || ((Condition2 == 'Equal To' && c.Usage_charge__C==UsageChargeSel) || (Condition2 == 'Lesser Than' && c.Usage_charge__C<UsageChargeSel) ||(Condition2 == 'Greater Than' && c.Usage_charge__C>UsageChargeSel) ) ) 
           {
         
             if(c.Usage_Count__C!=null)
             i.UsageCount=integer.valueof(c.Usage_Count__C);
             if(c.Usage_charge__C!=null)
             i.UsageCharge=integer.valueof(c.Usage_charge__C);
             i.contactName=C;
             if(c.CutomerRANKWG3x__r.size()>0)
             i.CustomerRANK=c.CutomerRANKWG3x__r[0];
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
    
    }
    Public void QueryRecords()
    {           
        
        System.debug('****************** Date '+A1.SearchDate__c);
        System.debug('****************** Date '+A2.SearchDate__c);
        
        decimal recUsageCount = 0;
        
        totalUsageRecsCount = 0;
        
        List<Contact> contacts = [select id, Name, FirstName , LastName from Contact limit 40000 ];
        
        Set<String> Contactids = new Set<String>();
        
        for(Contact c : Contacts)
        {
            Contactids.add(c.id);
        }
       
                
       // List<aggregateResult> UsageCharge = [select relaccount__c,sum(Field147__c) total from AccountAcount__c where OutSideAccount__c = 1 group by relaccount__c];
        Decimal m = UsageChargeSel;
        List<aggregateResult> UsageCharge = new List<aggregateResult>();
        if(Condition2 == 'Equal To')
        {
            UsageCharge = [select relaccount__c,sum(Field147__c) total from AccountAcount__c where  OutSideAccount__c = 1 group by relaccount__c having sum(Field147__c) =: m];
        }
        else if(Condition2  == 'Greater Than')
        {
            UsageCharge = [select relaccount__c,sum(Field147__c) total from AccountAcount__c where  OutSideAccount__c = 1 group by relaccount__c having sum(Field147__c) >: m];
            System.debug('**************UC'+UsageCharge );
        }
        else if(Condition2  == 'Lesser Than')
        {
            UsageCharge = [select relaccount__c,sum(Field147__c) total from AccountAcount__c where OutSideAccount__c = 1 group by relaccount__c having sum(Field147__c) <: m];
        }
        else
        {
            //UsageCharge = [select relaccount__c,sum(Field147__c) total from AccountAcount__c where OutSideAccount__c = 1 group by relaccount__c ];
        }   
           
        integer n = UsageCountSel;
        List<aggregateResult> UsageCount = new List<aggregateResult>();        
       
         if(condition3 != '--None--')
         {   
            if(Condition1 == 'Equal To')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c AND (ReservedStatus__c = '???' OR ReservedStatus__c = '??') group by Relcontact__c having count(Id) =: n];
               
            }
            else if(Condition1  == 'Greater Than')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c AND (ReservedStatus__c = '???' OR ReservedStatus__c = '??')  group by Relcontact__c having count(Id) >: n];
            }
            else if(Condition1  == 'Lesser Than')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c AND (ReservedStatus__c = '???' OR ReservedStatus__c = '??') group by Relcontact__c having count(Id) <: n];
            }
            else
            {
                
                //UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where EntryTime__c >=: l1.Searchdate__c AND EntryTime__c <=: l2.Searchdate__c AND (ReservedStatus__c = '???' OR ReservedStatus__c = '??') group by Relcontact__c ];
            } 
            
         }
         else
         {
             if(Condition1 == 'Equal To')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where ReservedStatus__c = '???' OR ReservedStatus__c = '??' group by Relcontact__c having count(Id) =: n];
            }
            else if(Condition1  == 'Greater Than')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where ReservedStatus__c = '???' OR ReservedStatus__c = '??' group by Relcontact__c having count(Id) >: n];
            }
            else if(Condition1  == 'Lesser Than')
            {
                UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where ReservedStatus__c = '???' OR ReservedStatus__c = '??' group by Relcontact__c having count(Id) <: n];
            }
            else
            {
                
                //UsageCount = [select  Relcontact__c, count(Id) cunt from Lead__c where ReservedStatus__c = '???' OR ReservedStatus__c = '??' group by Relcontact__c ];
            } 
         }       
        List<CustomerRANK__c> Rlist =[select RANK__c, RelContact__c from CustomerRANK__c where  RelContact__c =: Contactids ];
        InnerClassList = new List<InnerClass>();
        
        integer iii = 1;
        for(Contact c : contacts)
        {
            InnerClass i = new InnerClass();
            
            boolean UsageCountBoolean = false, UsageChargeBoolean  = false, RankBoolean  = false;
            
            for(AggregateResult UCharge : UsageCharge)
            {
                if((ID) UCharge.get('ps__relaccount__c') == c.id ) 
                {
                    UsageChargeBoolean = true;                   
                    i.UsageCharge = Integer.valueOf((decimal)UCharge.get('total'));                   
                    break;
                }
            }
            
            if(!UsageChargeBoolean)
            {
               i.UsageCharge = 0; 
            }
            
             for(AggregateResult UCount : UsageCount)
            {
                if((ID) UCount.get('ps__Relcontact__c') == c.id) // Add namespace for Invalid 
                {
                    UsageCountBoolean = true;
                    i.UsageCount = (Integer) UCount.get('cunt');
                    break;
                }
            }
            
            if(!UsageCountBoolean)
            {
               i.UsageCount = 0;
               UsageCountBoolean = false; 
            }
            
             for(CustomerRANK__c r : RList)
         {
             if(c.id == r.RelContact__c)
             {
                 i.customerRank = r;
                 RankBoolean = true;
                 break;
             }
         }  
     
          if(!RankBoolean)
            {
               CustomerRANK__c CR = new CustomerRANK__c();
               i.customerRank = CR; 
               i.ShowNone = false;
            }
            else
            {
                i.ShowNone = true;
            }
            i.ContactName = c;
            
            if(condition3 == 'AND')
            {
                if(UsageChargeBoolean && UsageCountBoolean )
                {
                    if(Math.Mod(iii,2)==0)
                    {
                        i.ColCount = 1;
                    }
                    else
                    {
                        i.ColCount = 0;
                    }
                     
                     i.IsChecked = false;
                     i.RecCount = iii;
                     i.ShowInput  = false; 
                     iii++;               
                    InnerClassList.add(i);
                }
            }            
            else if(condition3 == '--None--')
            {
                if(Condition1 == '--None--' && Condition2 != '--None--' )
                {   
                    if(UsageChargeBoolean)
                    {
                        if(Math.Mod(iii,2)==0)
                        {
                            i.ColCount = 1;
                        }
                        else
                        {
                            i.ColCount = 0;
                        }
                         
                         i.IsChecked = false;
                         i.RecCount = iii;
                         i.ShowInput  = false; 
                         iii++;               
                        InnerClassList.add(i);
                    }
                }
                else if(Condition1 != '--None--' && Condition2 == '--None--')
                {
                    if(UsageCountBoolean)
                    {
                        if(Math.Mod(iii,2)==0)
                        {
                            i.ColCount = 1;
                        }
                        else
                        {
                            i.ColCount = 0;
                        }
                         
                         i.IsChecked = false;
                         i.RecCount = iii;
                         i.ShowInput  = false; 
                         iii++;               
                        InnerClassList.add(i);
                    }
                }                
            }
            else
            {
                if(UsageChargeBoolean || UsageCountBoolean)
                {
                    if(Math.Mod(iii,2)==0)
                    {
                        i.ColCount = 1;
                    }
                    else
                    {
                        i.ColCount = 0;
                    }
                     
                     i.IsChecked = false;
                     i.RecCount = iii;
                     i.ShowInput  = false; 
                     iii++;               
                    InnerClassList.add(i);
                }            
            }            
            
                       
        } 
        
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
       
    }  
     
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
     
     public List<InnerClass> getInnserClassList()
     {
         return InnerClassList;
     }
     public List<InnerClass>  InnerClassList = new List<InnerClass>();
    public class InnerClass
    {
        public integer UsageCount{get;set;}
        public integer UsageCharge{get;set;}  
        public Contact contactName{get;set;}  
        public CustomerRANK__c customerRank{get;set;}
        public Integer ColCount {get;set;}
        public Integer RecCount {get;set;}
        public Boolean ShowInput {get;set;}   
        public Boolean ShowNone {get;set;}
        public Boolean IsChecked {get;set;}    
        
    } 
    public List<InnerClass> innerList = new List<InnerClass>();
    
    Public List< AccountAcount__c> getSearchResults()
    {
        return SearchResult;               
    }
    public void SaveRecords()
    {
       /*List<CustomerRANK__c> RankList = new List<CustomerRANK__c>();
        for(InnerClass ii : InnerClassList)
        {
           RankList.add(ii.customerRank);  
        }
        System.debug('******************* RankList'+RankList);
        if(RankList.size()> 0)
        {
            Update RankList; 
        }*/
    }
    
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
    Integer nn;
    public void EditRank()
    {
        nn = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
        System.debug('NNNNNNNNN Value'+nn);
        integer y = 0;
        for(InnerClass ii : InnerClassList)
        {
            if(ii.RecCount == nn )
            {
                 System.debug('In Loop+++++');
                crank.RANK__c = ii.customerRank.RANK__c;
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
    
    Boolean showRadio = false;
    public boolean getshowRadio()
    {
        return showRadio;
    } 
    
   /* public void SaveRank()
    {
        //Integer n = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
        List<CustomerRANK__c> RankList = new List<CustomerRANK__c>();
        for(InnerClass ii : InnerClassList)
        {
            System.debug('111111111111111111111'+ii.IsChecked);
            
            if(ii.RecCount == nn && SelectedRec  == 'The record clicked')
            {
                ii.ShowInput = false;  
                if(ii.customerRank==null)
                {    
                    crank.RelContact__c=ii.contactName.id;
                    ii.customerRank=crank;
                    
                }
                else
                {                
                    ii.customerRank.Rank__c = crank.RANK__c;
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
                        CustomerRANK__c crank2=new CustomerRANK__c();
                        crank2.RelContact__c=ii.contactName.id;
                        crank2.RANK__c=crank.RANK__c;
                        ii.customerRank=crank2;
                    
                    }
                    else
                    {                
                        ii.customerRank.Rank__c = crank.RANK__c;
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
    }*/
    
    public void SaveRank()
    {
    	// 2017/02/21 Field Security Check BEGIN
		List<String> chkFields = new List<String>{'RelContact__c','Rank__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.CustomerRANK__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFields, m)) {
			return;
		}
		// 2017/02/21 Field Security Check End
        integer stream=0;
        integer StreamExt=0;       
        List<CustomerRANK__c> RankList = new List<CustomerRANK__c>();
        for(InnerClass ii : InnerClassList)
        {        
            
            if(ii.RecCount == nn && SelectedRec  == 'The record clicked')
            {
                
                System.debug('Clicked Record');
                ii.ShowInput = false;  
                if(ii.customerRank==null)
                {  
                    CustomerRANK__c crank2=new CustomerRANK__c();
                    crank2.RelContact__c=ii.contactName.id;
                    crank2.Rank__c=crank.RANK__c;                    
                    StreamExt++;
                    RankList.add(crank2); 
                    
                }
                else
                {                
                    ii.customerRank.Rank__c = crank.RANK__c;                    
                    RankList.add(ii.customerRank);
                }          
                 
            }            
            if(SelectedRec  == 'All selected records')
            {
                
                if(ii.IsChecked==true )
                {
                    if(ii.customerRank==null)
                    {    
                        CustomerRANK__c crank2=new CustomerRANK__c();
                        crank2.RelContact__c=ii.contactName.id;
                        crank2.RANK__c=crank.RANK__c;                        
                        RankList.add(crank2);
                        stream++;                    
                    }
                    else
                    {  
                        ii.customerRank.Rank__c = crank.RANK__c;
                        RankList.add(ii.customerRank);
                    }                  
                   
                }
                                        
            } 
                   
        }
        if(RankList.size() > 0)
        {
           upsert RankList;
        }
        showpopup = false;
        if(StreamExt>0)
        {
            for(InnerClass ii : InnerClassList)
            {
                if(ii.RecCount == nn)
                    ii.customerRank=RankList[0];
            }
            
        }
        if(stream>0)
        SearchRecords();
    }
    public void CancelRank()
    {
       /*
            Integer n = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
            for(InnerClass ii : InnerClassList)
            {
                ii.ShowInput = false;           
            }
        */
        //QueryRecords();
        showpopup = false;
    }
   /*     
    public void Deleterank()
    {
               
        Integer n = 0;
        String s = System.currentPageReference().getParameters().get('rid');
        if(!(s == null || s == ''))
        {
            n = Integer.valueOf(System.currentPageReference().getParameters().get('rid'));
        }
        List<CustomerRANK__c> RankList = new List<CustomerRANK__c>();
         if( n != 0)
         {   
            System.debug('@@@@@@@@@@@@@@@@@'+n);
            for(InnerClass ii : InnerClassList)
            {
                if(ii.RecCount == n && !(ii.customerRank.RANK__c == null || ii.customerRank.RANK__c == ''))
                {                
                                       
                    //RankList.add(ii.customerRank);
                }
                
            }
         }
          System.debug('@@@@@@@@@@@@@@@@@'+RankList);
        
         if(RankList.size() > 0)
         {            
             Delete RankList;
             QueryRecords();
         } 
                 
        QueryRecords();
    }
   */ 
    boolean showpopup = false;
    public boolean getDispPopUp()
    {
        return showpopup;
    }
/**
*2015-11-18 
*テストクラスCustomerRankTestに移行する    
@Istest(seeAlldata=true) static void TestCustomerRank()
    {
        Contact con=[select id from contact limit 1];
        CustomerRank CRS=new CustomerRank (new apexpages.standardcontroller(con));
        CustomerRank CR=new CustomerRank ();
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
        System.assert(con != null);
    }
*/    
        
}