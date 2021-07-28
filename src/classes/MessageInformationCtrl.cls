public with sharing class MessageInformationCtrl{
    // 2016/12/23 IOT状態管理機能の追加 BEGIN
    private static final Boolean IotStatusManagerFlg = CommDefine__c.getOrgDefaults().IotNormalStatusAlertFlg__c == null ? true : CommDefine__c.getOrgDefaults().IotNormalStatusAlertFlg__c;
    private static final String MessagetStatusInfo = 'Info';
    // 2016/12/23 IOT状態管理機能の追加 END
    public MessageInformationCtrl() {
        isIncludeMode = ApexPages.currentPage().getParameters().containsKey('frame');//別のページに含めているがどうか
    	numberOfDispRec = CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().maxrecords_DSP__c);
    	// 2018/03/27 默认值设置修正 WGCH BEGIN
    	// if(numberOfDispRec == null) numberOfDispRec = 6;
        if(numberOfDispRec == 0) numberOfDispRec = 6;
        // 2018/03/27 默认值设置修正 WGCH END
        messageLst = new List<MessageItem>();
        MessageInfoLst();
    }  
    // 別ページからINCLUDE
    public Boolean isIncludeMode{get;private set;}
    public Integer numberOfDispRec{get;private set;}
  	public transient List<MessageItem> messageLst{get;set;}
    public List<MessageItem> MessageInfoLst() {
		//String strQuery = 'SELECT Id, Name, Type__c, MessageCode__c, MessageLevel__c,LastModifiedDate FROM MessageInformation__c order BY LastModifiedDate DESC, Id Desc ';
		String strQuery = CommSqlUtils.generateQueryString('MessageInformation__c');
		if (!IotStatusManagerFlg) strQuery+= ' Where (MessageType__c = \'IOT\' And MessageLevel__c != \'Info\') OR (MessageType__c != \'IOT\') ';
		strQuery += ' order BY LastModifiedDate DESC, Id Desc ';
		strQuery += 'limit ' + numberOfDispRec;
		for (MessageInformation__c message : Database.query(strQuery)) {
			MessageItem item = new MessageItem(message);
			messageLst.add(item);
		}
		return this.messageLst;
	}
	public class MessageItem {
		public 	MessageItem(MessageInformation__c psobj) {
			sobj = psobj;
			// 2016/11/25 TIMEZON fix BEGIN by zh
			//lastModifiedDate = sobj.LastModifiedDate.Format(CommBaseCtrl.getDateTimeFormat());
			lastModifiedDate = sobj.LastModifiedDate.Format();
			// 2016/11/25 TIMEZON fix END by zh
			// 2017/03/23 指定URL対応 BEGIN
			helpUrl = CommUtils.isBlank(sobj.MessageHelpUrl__c) ? ('/'+sobj.Id) : Commutils.nullToBlank(sobj.MessageHelpUrl__c);
			// 2017/03/23 指定URL対応 END
		}
		// MessageInformation情報格納する
		public MessageInformation__c sobj{get; private set;}
		public String lastModifiedDate{get; private set;}
		// 2017/03/23 指定URL対応 BEGIN
		public String helpUrl{get;private set;}
		// 2017/03/23 指定URL対応 END
	}
	public String getDateTimeFormat() {
        return CommBaseCtrl.getDateTimeFormat();
    }
}