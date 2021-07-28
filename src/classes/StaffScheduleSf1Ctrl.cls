public with sharing class StaffScheduleSf1Ctrl {

    public User loginUser{get; set;}
    public Date sWorkDay{get; set;}
    public StaffSchedule__c staffObj{get; set;}
    private Map<Date,StaffSchedule__c> sMap{get; set;}
    public String customComment{get; set;}
    public String customStatus{get; set;}
    public List<SelectOption> commentLabLst{get; set;}
    public List<SelectOption> statusLabLst{get; set;}
    public List<String> commentSelLst{get; set;}
    public List<String> statusSelLst{get; set;}
    public Boolean isPostDate{get{return staffObj == null ? false : staffObj.WorkDay__c < Date.today();}}

    public StaffScheduleSf1Ctrl() {
        loginUser = UserUtil.getUser(UserInfo.getUserId());
        sWorkDay = Date.today();
        staffObj = new StaffSchedule__c(WorkDay__c = sWorkDay);
        sMap = new Map<Date,StaffSchedule__c>();
        init(sWorkDay);
    }
    public void init(Date dt) {
        sMap = staffMap(dt);
        commentLabLst = new List<SelectOption>();
        commentLabLst = staffOp(StaffSchedule__c.CommentLst__c.getDescribe());
        statusLabLst = new List<SelectOption>();
        statusLabLst = staffOp(StaffSchedule__c.StatusLst__c.getDescribe());
        commentSelLst = new List<String>();
        statusSelLst = new List<String>();
        customComment = '';
        customStatus = '';
        if (sMap.containsKey(dt)) {
            staffObj = sMap.get(dt);
            String mc = CommUtils.nullToBlank(staffObj.CommentLst__c);
            String ms = CommUtils.nullToBlank(staffObj.StatusLst__c);
            List<String> comSel = mc.split(':');
            List<String> staSel = ms.split(':');
            if (comSel.size() == 2) 
            customComment = comSel[1];
            if (staSel.size() == 2) 
            customStatus = staSel[1];

            if (comSel.size() > 0) {
                String s1 = comSel[0].replace(' ', '');
                commentSelLst = s1.split(',');
            }
            if (staSel.size() > 0) {
                String s2 = staSel[0].replace(' ', '');
                statusSelLst = s2.split(',');
            }
        }else {
            staffObj.WorkDay__c = dt;
        }
    }

    public void gotoDate() {
        init(staffObj.WorkDay__c);
    }
    private List<SelectOption> staffOp(Schema.DescribeFieldResult dfr) {
        List<SelectOption> commentTypeLst = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = dfr;
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple) {
            commentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return commentTypeLst;
    }
    private Map<Date,StaffSchedule__c> staffMap(Date workDate) {
        Map<Date,StaffSchedule__c> staffMap = new Map<Date,StaffSchedule__c>();
        List<StaffSchedule__c> staffList = new List<StaffSchedule__c>();
        staffList = [select Id, Name, StaffUserRef__c, WorkDay__c, StatusLst__c, TimeManagementRef__c, SearchKey__c, CommentLst__c from StaffSchedule__c where StaffUserRef__c = :UserInfo.getUserId() And WorkDay__c = :workDate];
        if (staffList.size() > 0) {
            for (StaffSchedule__c s:staffList ) {
                staffMap.put(s.WorkDay__c, s);
            }
        }
        return staffMap;
    }
    public void upsertData() {
        String tmps = '';
        String tmpc = '';
        staffObj.StatusLst__c = '';
        for (String s:statusSelLst ) {
            tmps += s + ',';
        }
        if (!CommUtils.isBLank(tmps)) tmps = tmps.removeEnd(',');
        staffObj.StatusLst__c += tmps + ((CommUtils.isBlank(customStatus)) ? '' : ':' + customStatus);

        staffObj.CommentLst__c = '';
        for (String s:commentSelLst ) {
            tmpc += s + ',';
        }
        if (!CommUtils.isBLank(tmpc)) tmpc = tmpc.removeEnd(',');
        staffObj.CommentLst__c += tmpc + ((CommUtils.isBlank(customComment)) ? '' : ':' + customComment);
        staffObj.StaffUserRef__c = UserInfo.getUserId();
        staffObj.SearchKey__c = staffObj.StaffUserRef__c + '_' + staffObj.WorkDay__c.format();
        staffObj.Id = null;
        upsert staffObj StaffSchedule__c.SearchKey__c;
    }
}