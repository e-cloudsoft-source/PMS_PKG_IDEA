public with sharing class Month {
    private List<Week> weeks;
    public Date firstDate; // always the first of the month
    private Date upperLeft;
    
    
    
    /*------------------------------------------------------
                          CONSTRUCTOR
    ------------------------------------------------------*/
    public Month( Date value ) {                            
        weeks = new List<Week>();
        firstDate = value.toStartOfMonth();
        upperLeft = firstDate.toStartOfWeek();
        Date tmp = upperLeft;
        for (Integer i = 0; i < 5; i++) {
            Week w = new Week(i+1,tmp,value.month());
            system.assert(w!=null);
            this.weeks.add( w );
            tmp = tmp.addDays(7);
        }   
    }
    
    /*------------------------------------------------------
                            GETTERS
    ------------------------------------------------------*/
    // first day of the month
    public Date getfirstDate() { 
        return firstDate; 
    }
    
    // weeks
    public List<Week> getWeeks() {
        system.assert(weeks!=null,'could not create weeks list');
        return this.weeks;
    }
    
    // month
    public String getMonthName() {                                      
        return DateTime.newInstance(firstDate.year(),firstdate.month(),firstdate.day()).format('MM');
    }

    // year
    public String getYearName() {
        return DateTime.newInstance(firstDate.year(),firstdate.month(),firstdate.day()).format('yyyy');
    }

    public List<Date> getValidDateRange() {
        // return one date from the upper left, and one from the lower right
        List<Date> ret = new List<Date>();
        ret.add(upperLeft);
        ret.add(upperLeft.addDays(5*7) );
        return ret;
    }

    public void setEvents(List<Event> ev) {
        // merge these events into the proper day
        for(Event e:ev) {
            for(Week w:weeks) {
                for(Day c: w.getDays() ) {
                    if ( e.ActivityDate.isSameDay(c.theDate)) {
                        // add this event to this calendar date
                        c.eventsToday.add(new EventItem(e));
                        // add only three events, then a More... label if there are more
                    }
                }
            }
        }
    }

    /*-------------------------------------------------------------------------
                HELPER CLASSES TO DEFINE MONTH IN TERMS OF WEEK & DAY
    -------------------------------------------------------------------------*/
    //WEEK CLASS
    public class Week {
        public List<Day> days;
        public Integer weekNumber;
        public Date startingDate;
        
        public Week () {
            days = new List<Day>();
        }
        public Week(Integer value,Date sunday,Integer month) {
            this();
            weekNumber = value;
            startingDate = sunday;
            Date tmp = startingDate;
            for (Integer i = 0; i < 7; i++) {
                Day d = new Day( tmp,month );
                tmp = tmp.addDays(1);
                d.dayOfWeek = i+1;
                // system.debug(d);
                days.add(d);
            }
        }
        public List<Day> getDays() { 
            return this.days; 
        }
        public Integer getWeekNumber() { 
            return this.weekNumber;
        }
        public Date getStartingDate() { 
            return this.startingDate;
        }
    } // end of week class
    
    // DAY CLASS
    public class Day {
        public Day(){}
        public Double dSum00 = 0;   // sum of StayPersons__c
        public Double dSum01 = 0;   // sum of 客室の昼
        public Double dSum02 = 0;   // sum of 客室の夕
        public Double dSum03 = 0;   // sum of 客室OUT
        public Double dSum04 = 0;   // sum of 客室のIN
        public Double dSum05 = 0;   // sum of 客室のSTAY
        public Double dSum06 = 0;   // sum of 伊勢の昼
        public Double dSum07 = 0;   // sum of 伊勢の夕
        public Double dSum08 = 0;   // sum of 藤の昼
        public Double dSum09 = 0;   // sum of 藤の夕
        public Double dSum10 = 0;   // sum of 竹河の昼
        public Double dSum11 = 0;   // sum of 竹河の夕
        public Double dSum12 = 0;   // sum of 源氏館の昼
        public Double dSum13 = 0;   // sum of 源氏館の夕
        public Double dSum14 = 0;   // sum of 平安の昼
        public Double dSum15 = 0;   // sum of 平安の夕
        public Date theDate;
        public List<EventItem> eventsToday; // list of events for this date
        public Integer month, dayOfWeek;
        public String formatedDate; // for the formated time
        private String cssclass = 'calActive';
    
        public Date getDate() { return theDate; }
        public Integer getDayOfMonth() { return theDate.day(); }
        public String getDayOfMonth2() {
        if ( theDate.day() <= 9 )
            return '0'+theDate.day();
            return String.valueof( theDate.day());
        }
        public Integer getDayOfYear() { return theDate.dayOfYear(); }
        public List<EventItem> getDayAgenda() { return eventsToday; }
        public String getFormatedDate() { return formatedDate; }
        public Integer getDayNumber() { return dayOfWeek; }
        public List<EventItem> getEventsToday() { return eventsToday; }
        public String getCSSName() { return cssclass; }
        
        public Day(Date value,Integer vmonth) {
            theDate=value; month=vmonth;
            formatedDate = '12 21 08';// time range..
            //9:00 AM - 1:00 PM
            eventsToday = new List<EventItem>();
            // three possible Inactive,Today,Active
            if ( theDate.daysBetween(System.today()) == 0 ) cssclass ='calToday';
            // define inactive, is the date in the month?
            if ( theDate.month() != month) cssclass = 'calInactive';
        }
    
        // What day? 
        public String getChargetype() {     
            Map<String, String> mapDayName = new Map<String, String>{};                                                                 
        
                                                                                    /* for Map list Initialize */
            mapDayName.clear();
                                                                            /* 2010 */
/*            mapDayName.put('2010/09/20', 'BHOL');
            mapDayName.put('2010/09/23', 'BHOL');
            mapDayName.put('2010/10/11', 'BHOL');
            mapDayName.put('2010/11/03', 'BHOL');
            mapDayName.put('2010/11/23', 'BHOL');
            mapDayName.put('2010/12/23', 'BHOL'); */
                                                                            /* 2011 */
/*            mapDayName.put('2011/01/01', 'BHOL');
            mapDayName.put('2011/01/02', 'NEWY');
            mapDayName.put('2011/01/03', 'NEWY');
            mapDayName.put('2011/01/04', 'NEWY');           
            mapDayName.put('2011/01/10', 'BHOL');
            mapDayName.put('2011/02/11', 'BHOL');
            mapDayName.put('2011/03/21', 'BHOL');
            mapDayName.put('2011/04/29', 'BHOL');
            mapDayName.put('2011/05/03', 'BHOL');
            mapDayName.put('2011/05/04', 'BHOL');           
            mapDayName.put('2011/05/05', 'BHOL');
            mapDayName.put('2011/07/18', 'BHOL');
            mapDayName.put('2011/09/19', 'BHOL');
            mapDayName.put('2011/09/23', 'BHOL');
            mapDayName.put('2011/10/10', 'BHOL');
            mapDayName.put('2011/11/03', 'BHOL');
            mapDayName.put('2011/11/23', 'BHOL');
            mapDayName.put('2011/12/23', 'BHOL'); */
                                                                            /* 2012 */                                              
            mapDayName.put('2012/01/01', 'BHOL');
            mapDayName.put('2012/01/02', 'NEWY');
            mapDayName.put('2012/01/03', 'NEWY');
            mapDayName.put('2012/01/04', 'NEWY');
            mapDayName.put('2012/01/09', 'BHOL');
            mapDayName.put('2012/02/11', 'BHOL');
            mapDayName.put('2012/03/20', 'BHOL');
            mapDayName.put('2012/04/29', 'BHOL');
            mapDayName.put('2012/04/30', 'BHOL');
            mapDayName.put('2012/05/03', 'BHOL');
            mapDayName.put('2012/05/04', 'BHOL');
            mapDayName.put('2012/05/05', 'BHOL');           
            mapDayName.put('2012/07/16', 'BHOL');
            mapDayName.put('2012/09/17', 'BHOL');
            mapDayName.put('2012/09/22', 'BHOL');
            mapDayName.put('2012/10/08', 'BHOL');
            mapDayName.put('2012/11/03', 'BHOL');
            mapDayName.put('2012/11/23', 'BHOL');
            mapDayName.put('2012/12/23', 'BHOL');
            mapDayName.put('2012/12/24', 'BHOL');

            /* '2013' => '0101,0114,0211,0320,0429,0503,0504,0505,0506,0715,0916,0923,1014,1103,11 04,1123,1223',*/


            Date wd = theDate.addDays(1);                                   /* konojiGet Click day + 1 (Next day) */
            String keyDate = wd.format();                                   /* Change Date type to String type */
                                                                            /* Check Key Map and Get Date name */
                system.debug(keyDate);
            IF (mapDayName.get(keyDate) == null) {                          /*  found */
                if (dayOfWeek == 6 || dayOfWeek == 7) {                     /* friday or Satuday */
                    return 'BHOL';
                }else {
                    return 'WEEK';
                }
            } else {                                                        /* Not found */
                return mapDayName.get(keyDate);
            }
        }
    /*  
        public String getareReserved() {
            //Lead__c[] reserves;
            Double totalReserved = 0;
            
            
            //Get Reserved persons for the date
            for(Lead__c mq:[SELECT StayPersons__c FROM Lead__c
            WHERE ReservationDate__c = :theDate
            AND StayPersons__c != null
            AND CancelBool__c != 1]) {
            totalReserved += mq.StayPersons__c;
            }
            
            // Totals the miles in the request
            //for (StayPersons__c m:miles) {
            //totalReserved += m.miles__c;
            //if(totalMiles > MAX_MILES_PER_DAY)
            //m.addError('Mileage request exceeds daily limit: ' + MAX_MILES_PER_DAY);
            //}
            
            return totalReserved.format();
        }
        */
        
        /*----------------------------------------------------------
               GETTING THE SUM VALUES FOR THE CALENDAR TABLE
        ----------------------------------------------------------*/
        // sum of StayPersons__c
        public String getSumValues(){
            Double retVal = 0;
            AggregateResult[] aggRes = [SELECT SUM(StayPersons__c) Sum00,   // sum of StayPersons__c
                                               SUM(Sum01__c) Sum01,         // sum of 客室の昼
                                               SUM(Sum02__c) Sum02,         // sum of 客室の夕
                                               SUM(Sum03__c) Sum03,         // sum of 客室のOUT
                                               SUM(Sum04__c) Sum04,         // sum of 客室のIN
                                               SUM(Sum05__c) Sum05,         // sum of 客室のSTAY
                                               SUM(Sum06__c) Sum06,         // sum of 伊勢の昼
                                               SUM(Sum07__c) Sum07,         // sum of 伊勢の夕
                                               SUM(Sum08__c) Sum08,         // sum of 藤の昼
                                               SUM(Sum09__c) Sum09,         // sum of 藤の夕
                                               SUM(Sum10__c) Sum10,         // sum of 竹河の昼
                                               SUM(Sum11__c) Sum11,         // sum of 竹河の夕
                                               SUM(Sum12__c) Sum12,         // sum of 源氏館の昼
                                               SUM(Sum13__c) Sum13,         // sum of 源氏館の夕
                                               SUM(Sum14__c) Sum14,         // sum of 平安の昼
                                               SUM(Sum15__c) Sum15          // sum of 平安の夕
                                        FROM Lead__c
                                        WHERE ReservationDate__c = :theDate
                                        AND StayPersons__c != null
                                        AND CancelBool__c != 1]; //end of select query
                                       
                            /*-----------------------------------------------------
                                STORE VALUES FROM AGGREGATE LIST TO VARIABLES
                            -----------------------------------------------------*/    
                            dSum00 = Double.valueOf(aggRes[0].get('Sum00'));
                            dSum01 = Double.valueOf(aggRes[0].get('Sum01'));
                            dSum02 = Double.valueOf(aggRes[0].get('Sum02'));
                            dSum03 = Double.valueOf(aggRes[0].get('Sum03'));    
                            dSum04 = Double.valueOf(aggRes[0].get('Sum04'));    
                            dSum05 = Double.valueOf(aggRes[0].get('Sum05'));    
                            dSum06 = Double.valueOf(aggRes[0].get('Sum06'));    
                            dSum07 = Double.valueOf(aggRes[0].get('Sum07'));    
                            dSum08 = Double.valueOf(aggRes[0].get('Sum08'));    
                            dSum09 = Double.valueOf(aggRes[0].get('Sum09'));    
                            dSum10 = Double.valueOf(aggRes[0].get('Sum10'));    
                            dSum11 = Double.valueOf(aggRes[0].get('Sum11'));    
                            dSum12 = Double.valueOf(aggRes[0].get('Sum12'));    
                            dSum13 = Double.valueOf(aggRes[0].get('Sum13'));    
                            dSum14 = Double.valueOf(aggRes[0].get('Sum14'));    
                            dSum15 = Double.valueOf(aggRes[0].get('Sum15'));

                                                                                                                /* Get OUT counts of Gest room for deperture date 2011.10.18 Ryoma Morimoto. */
            AggregateResult[] aggResOUT = [SELECT SUM(Sum03__c) Sum03 FROM Lead__c WHERE checkoutdate__c = :theDate AND StayPersons__c != null AND CancelBool__c != 1];
            dSum03 = Double.valueOf(aggResOUT[0].get('Sum03'));                                     
                             
            if(dSum00 == null)
            { dSum00 = 0; dSum01 = 0; dSum02 = 0; dSum03 = 0; dSum04 = 0;
              dSum05 = 0; dSum06 = 0; dSum07 = 0; dSum08 = 0; dSum09 = 0;
              dSum10 = 0; dSum11 = 0; dSum12 = 0; dSum13 = 0; dSum14 = 0;
              dSum15 = 0; retVal = 0;}
            else { retVal = dSum00; }
            
            System.debug(' ************ dSum08 = ' + dSum08);
            System.debug(' ************ dSum09 = ' + dSum09);
            
            
            return retVal.format();
        }
        
        // sum of 客室の昼
        public String getSum01(){
            Double retVal = 0;
            retVal = dSum01; 
            if(retVal == null){retVal = 0;}
            return retVal.format();
        }
        // sum of 客室の夕
        public String getSum02(){
            Double retVal = 0;
            retVal = dSum02; 
            if(retVal == null){retVal = 0;}
            return retVal.format();
        }
        
        // sum of 客室のOUT
        public String getSum03(){
            Double retVal = 0;
            retVal = dSum03; 
            if(retVal == null){retVal = 0;}
            return retVal.format();
        }
        
        // sum of 客室のIN
        public String getSum04(){
            Double retVal = 0;
            retVal = dSum04; 
            if(retVal == null){retVal = 0;}
            return retVal.format();
        }
        // sum of 客室のSTAY
        public String getSum05(){
            Double retVal = 0;
            retVal = dSum05; 
            if(retVal == null){retVal = 0;}
            return retVal.format();
        }
        // sum of 伊勢の昼
        public String getSum06(){
            String retVal = ' ';
            if(dSum06 == null){ retVal = '-'; }
            if(dSum06 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 伊勢の夕
        public String getSum07(){
            String retVal = ' ';
            if(dSum07 == null){ retVal = '-'; }
            if(dSum07 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 藤の昼
        public String getSum08(){
            String retVal = ' ';
            if(dSum08 == null){ retVal = '-'; }
            if(dSum08 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 藤の夕
        public String getSum09(){
            String retVal = ' ';
            if(dSum09 == null){ retVal = '-'; }
            if(dSum09 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 竹河の昼
        public String getSum10(){
            String retVal = ' ';
            if(dSum10 == null){ retVal = '-'; }
            if(dSum10 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 竹河の夕
        public String getSum11(){
            String retVal = ' ';
            if(dSum11 == null){ retVal = '-'; }
            if(dSum11 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 源氏館の昼
        public String getSum12(){
            String retVal = ' ';
            if(dSum12 == null){ retVal = '-'; }
            if(dSum12 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 源氏館の夕
        public String getSum13(){
            String retVal = ' ';
            if(dSum13 == null){ retVal = '-'; }
            if(dSum13 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 平安の昼
        public String getSum14(){
            String retVal = ' ';
            if(dSum14 == null){ retVal = '-'; }
            if(dSum14 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
        // sum of 平安の夕
        public String getSum15(){
            String retVal = ' ';
            if(dSum15 == null){ retVal = '-'; }
            if(dSum15 <> 0){ retVal = '○'; } else{retVal = '-'; }
            return retVal;
        }
    } // end of day class   
}