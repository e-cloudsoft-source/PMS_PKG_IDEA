public with sharing class eventItem {
    public Event ev;
    public String formatedDate; 
    public eventItem(Event e) { 
        ev= e;
        // build formated date
        //9:00 AM - 1:00 PM
    //  system.debug(e.activitydatetime.format('MMM a'));
    //  system.debug(e.DurationInMinutes);
    //2012.12.21    Datetime endd = e.activitydatetime.addMinutes(e.DurationInMinutes);
        //system.debug(e.activitydatetime.format('h:mm a '));
    //2012.12.21    formatedDate = e.activitydatetime.format('h:mm a') + ' - ' + endd.format('h:mm a');
    //2012.12.21    system.debug(formateddate);
    }
    public Event getEv() { return ev; }
    public String getFormatedDate() { return formatedDate; }
}