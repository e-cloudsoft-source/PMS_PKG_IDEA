/************************
* 見積明細設定機能
* 2014/08/05 過去の合計計算不具合修正と部屋宿泊税自動設定機能外す
* 2014/09/17 金額小数がない場合、画面に小数非表示対応
* 2015/01/26 ハンコ表示・非表示機能対応
* 2015/10/25 クリアする場合、元の見積明細情報はプランすると、プラン明細情報をクリアを行う
*************************/
global with sharing class BookingEstimateItemSetups extends CommBaseCtrl{
    // 遷移先からパラメータ情報を格納する
    private Map<String,String> paramMap;
    // 予約ID
    public Lead__c leasSobj{get; private set;}
    public String leadId{get;set;}
	public transient String subId{get;set;}
	public transient String parId{get;set;}
	// 照会指定日情報を格納する
	public BookingTimeTable__c timeTable{get;set;}
	// 見積名+说明的list
	public List<QuotaInfo> quotaOptionLst{get; private set;}
	public String windowSetting{get;set;}	
	public String QUOTA_TEMP{get{return QUOTA_STATUS_TEMP;}}
	public String QUOTA_KARI{get{return QUOTA_STATUS_KARI;}}
	public String QUOTA_FORMAL{get{return QUOTA_STATUS_FORMAL;}}
	private static String QUOTA_STATUS_TEMP = '集計';
	private static String QUOTA_STATUS_KARI = '仮保存';
	private static String QUOTA_STATUS_FORMAL = '本保存';
    // 予約Controll
    //private ApexPages.StandardController ctrl;
	public BookingEstimateItemSetups(ApexPages.StandardController controller) {
		leadId = controller.getId();
		// 窗口大小初始化
		initWindowSetting();
		// 初期化処理を行う
		if (!initInfo()) return;
	}
	//リアル予約下全て見積
	public void refreshDetail(){
		quotaOptionLst = queryQuotaLst(null,leasSobj.id);
	}
	private Boolean initInfo() {
		if (CommUtils.isBlank(leadId)) {
			//パラメータ設定不正、管理者に連絡ください。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_011_0069));
			return false;
		}
		// 全画面から引渡「予約ID」を取得する
		paramMap = Apexpages.currentPage().getParameters();
		subId = paramMap.get('subid');
		parId = paramMap.get('parid');
		// テンプレートと既存見積
        quotaOptionLst = new List<QuotaInfo>();
		// リード存在チェックを行う
		List<Lead__c> leadLst = new List<Lead__c>();
		// 2015/09/28 ADD BEGIN
		if (!CommUtils.isBlank(subId))
			leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c ,
									LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__c,LeadIndexRef__r.name,Field298__c,StayPersons__c,Field2__c,Rroom__c,Rroom__r.name
									from Lead__c where LeadIndexSubId__c = :subId And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG Order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c];
        else if(!CommUtils.isBlank(leadId))
        	leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,
        			QuotationComment__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__r.name,Field298__c,StayPersons__c,Field2__c,Rroom__c,Rroom__r.name from Lead__c where Id = :leadId];
		else if (!CommUtils.isBlank(parId)){
			leadLst = [select id, Name,EntryTime__c, Departure__c,LeadPdfShopCode__c, StampIsShowDiv__c, LeadReceiptDate__c, Field310__c,Relcontact__r.name,Relcontact__r.Account.Name,QuotationName__c,QuotationComment__c ,
									LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__c,LeadIndexRef__r.name,Field298__c,StayPersons__c,Field2__c,Rroom__c,Rroom__r.name from Lead__c where LeadIndexRef__c = :parId];
		}
		if (leadLst.isEmpty()) {
			//予約データはすでに削除された。
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_011_0070));
			return false;
		}
		
		leasSobj = leadLst[0];
		leadId = leasSobj.id;
		List<Id> leadIdLst = new List<Id>();
		timeTable = new BookingTimeTable__c(Checkinday__c=Date.today());
		String subId = '';
		for(Lead__c lead : [select id, Name,Rroom__c,UnitPriceDefKbCal__c,Relcontact__c,
				StayPersons__c,EntryTime__c,Departure__c,Field4__c,Field3__c,Comment3__c
			from Lead__c 
			where LeadIndexRef__c = :leasSobj.LeadIndexRef__c 
			And LeadIndexSubId__c = :leasSobj.LeadIndexSubId__c
			And RoomGroupNo__c = :leasSobj.RoomGroupNo__c
			And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
			Order By EntryTime__c ] ){
				leadIdLst.add(lead.id);
				subId += lead.id + ',';
		}
		List<QuotaInfo> infoLst = queryQuotaLst(null,leadId);
		boolean hadCreatedFlag = false;
		// 不存在見積
		// 最新情報
		QuotaInfo quotaInfo = new QuotaInfo();
		quotaInfo.quo.QuotaStatus__c = QUOTA_STATUS_TEMP;
		quotaInfo.quo.QuotaDescription__c = Label.MSG_011_0089;//予約の見積明細から自動取得
		quotaInfo.quo.QuotaName__c = Label.MSG_011_0088;
		quotaInfo.subId = subId;
		quotaInfo.sobjId = leasSobj.id;
		quotaOptionLst.add(quotaInfo);
		if (!infoLst.isEmpty()) quotaOptionLst.addAll(infoLst);
		return true;
	}
	// 窗口自定义
	private void initWindowSetting(){
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,UserUtil.CurrentUser.id,'');
		windowSetting = CommUtils.nullToBlank(userBookMap.get(SUBTYPE_RESIZE));
	}
	// 全部見積リスト
	// 2018/11/30 多見積の内容金額不正bug fixed by zy BEGIN
	private static List<QuotaInfo> queryQuotaLst(String quotaId,String leadId){
	// 2018/11/30 多見積の内容金額不正bug fixed by zy END	
		List<QuotaInfo> result = new List<QuotaInfo>();
		// 作成予約
		//Quota__c hadLeadQuota = null;
		// 现在选择
		//Quota__c curLeadQuota = null;
		// 收藏列表
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,UserUtil.CurrentUser.id,'');
        String markStr = CommUtils.nullToBlank(userBookMap.get(SUBTYPE_BOOKMARK));
        Set<String> markSet = new Set<String>(markStr.split(','));
        // 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
        for (Quota__c s: [select id, Name,QuotaDescription__c,QuotaStatus__c,ExpirationDate__c,TotalInc__c, QuotaName__c,LeadRef__c,LeadRef__r.Name,LeadRef__r.Relcontact__r.Id,LeadRef__r.Relcontact__r.name,LastModifiedBy.Name,LastModifiedById,LastModifiedDate from Quota__c where LeadRef__c =:leadId   order by LastModifiedDate desc,Name limit 50]) {
		// 2017/12/11 見積明細金額合計機能追加　by　zy END	
			//boolean marFlag = markSet.contains(s.id);           
            // 已经作成予約置顶
            //if (s.QuotaStatus__c == QUOTA_STATUS_FORMAL) hadLeadQuota = s;
            //else if (!CommUtils.isBlank(quotaId) && quotaId == s.id)  curLeadQuota = s;
            //else 
            result.add(new QuotaInfo(s,markSet.contains(s.id)));
        }
        //if (hadLeadQuota != null) result.add(new QuotaInfo(hadLeadQuota,markSet.contains(hadLeadQuota.id))); 
        //if (curLeadQuota != null) result.add(new QuotaInfo(curLeadQuota,markSet.contains(curLeadQuota.id)));
        //result.addAll(quotas);
        return result;
	}
	private static String SUBTYPE_BOOKMARK = UserConfigCompCtrl.KREP_SUBTYPE.BOOKMARK.name();
	private static String SUBTYPE_RESIZE = UserConfigCompCtrl.KREP_SUBTYPE.RESIZE.name();
	@remoteaction
	global static String saveBookMark(String ajaxReq){
		AJAXRequest req = (AJAXRequest)JSON.deserializeStrict( ajaxReq, AJAXRequest.class);
		String userId = UserUtil.CurrentUser.id;
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,userId,'');
		List<String> bookLst = new List<String>();
		List<String> selectLst = new List<String>();
		if (userBookMap.containsKey(SUBTYPE_BOOKMARK)) {
			String bookStr = CommUtils.nullToBlank(userBookMap.get(SUBTYPE_BOOKMARK));
			bookLst = bookStr.split(',');
			// 去空值
			for (String quotaId : bookLst) {
				if (CommUtils.isBlank(quotaId)) continue;
				selectLst.add(quotaId);
			}
		}
		// 过滤見積メッセージ
		String result = '';
		List<Id> curQuotaLst = new List<Id>();
		// 数据库检索去除无效
		for ( Quota__c quota : [select id from Quota__c where id=:selectLst]) {
			if (quota.id == req.quotaid) continue;
			result += quota.id + ',';
			curQuotaLst.add(quota.id);
		}
		String reqResult = '';
		// 收藏限制
		if (curQuotaLst.size() >= 50 && req.mark) {
			reqResult = LABEL.MSG_011_0093;//'ブックマーク最大５０件超出しました、マック失敗';
		} else if (!CommUtils.isBlank(req.quotaid)) {
			if (req.mark) result += req.quotaid + ',';
			UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,SUBTYPE_BOOKMARK,result,userId,'');
		}
		return reqResult;
	}
	// 删除見積时联动删除关注
	private static void deleteBookMark(String deleteId){
		String userId = UserUtil.CurrentUser.id;
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,userId,'');
		List<String> bookLst = new List<String>();
		if (userBookMap.containsKey(SUBTYPE_BOOKMARK)) {
			String bookStr = CommUtils.nullToBlank(userBookMap.get(SUBTYPE_BOOKMARK));
			bookLst = bookStr.split(',');
		}
		String result = '';
		// 过滤見積メッセージ
		for (String quotaId : bookLst) {
			if (CommUtils.isBlank(quotaId)) continue;
			if (quotaId == deleteId) continue;
			result += quotaId + ',';
		}
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,SUBTYPE_BOOKMARK,result,userId,'');
	}
	@remoteaction 
	global static void deleteQuota(String ajaxReq){
		AJAXRequest req = (AJAXRequest)JSON.deserializeStrict( ajaxReq, AJAXRequest.class);
		String quotaId = req.quotaid;
		// clear user config
		List<QuotaItem__c> items = [select id from QuotaItem__c where QuotaRef__c =: quotaId Order By RowNo__c,Name];
		deleteBookMark(quotaId);
		delete items;
		delete [select id from Quota__c where id=:quotaId];
	}
	@remoteaction
	global static List<Object> saveQuota(String ajaxReq){
		// 解析传值
		List<AJAXRequest> reqLst = (List<AJAXRequest>)JSON.deserializeStrict( ajaxReq, List<AJAXRequest>.class);
		List<Quota__c> quotaLst = new List<Quota__c>();
		List<Id> quotaIdLst = new List<Id>();
		// 根据指定field设定值
		for (AJAXRequest req : reqLst) {
			Quota__c q = new Quota__c();
			q.id = req.quotaid;
			if (!CommUtils.isBlank(req.field)) {
				if (req.field == 'quotaDesc') q.QuotaDescription__c = req.value;
				else if (req.field == 'quotaDate') q.ExpirationDate__c = CommUtils.stringtoDate(req.value);
				else if (req.field == 'quotaName') q.QuotaName__c = req.value;
				quotaLst.add(q);
				quotaIdLst.add(q.id);
			}
		}
		// 更新見積
		if (!quotaLst.isEmpty()) update quotaLst;
		// 取得最新見積
		List<Quota__c> queryLst = [select id, name, LeadRef__c,QuotaStatus__c, MainQuotaFlg__c, ExpirationDate__c, QuotaDescription__c, QuotaName__c,TotalInc__c,LastModifiedBy.Name,LastModifiedById,LastModifiedDate from Quota__c where id = :quotaIdLst];
		List<QuotaJson> resps = new List<QuotaJson>();
		if (!queryLst.isEmpty()) {
			for (Quota__c q : queryLst) {
				resps.add(new QuotaJson(q));
			}
		}
		return resps;
	}
	@remoteaction
	global static void saveResize(String ajaxReq){
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.ESTIMATE,SUBTYPE_RESIZE,CommUtils.nullToBlank(ajaxReq),UserUtil.CurrentUser.id,'');
	}
	// 2018/11/30 多見積の内容金額不正bug fixed by zy BEGIN
	@remoteaction
	global static object remoteQuery(String queryType,String req){
		if (queryType == 'refreshDetails') return refreshDetails(req);
		return null;
	}
	private static object refreshDetails(String req){
		List<QuotaInfo> infoLst = queryQuotaLst(null,req);
		List<BookingEstimateItemSetup.QuotaJson> result = new List<BookingEstimateItemSetup.QuotaJson>();
		for (QuotaInfo inf : infoLst) {
			result.add(new BookingEstimateItemSetup.QuotaJson(inf.quo));
		}
		return result;
	}
	// 2018/11/30 多見積の内容金額不正bug fixed by zy END
	public class QuotaInfo{
		public Quota__c quo{get;set;}
		public boolean bookMarkFlag{get;set;}
		public String subId{get;set;}
		public String sobjId{get;set;}
		public boolean autoFlag{get;set;}
		public QuotaInfo () {
			quo = new Quota__c();
			autoFlag = true;
		}
		public QuotaInfo (Quota__c q , boolean flag) {
			quo = q ; 
			sobjId = q.id;
			autoFlag = false;
			bookMarkFlag = false;
			if ( flag != null) bookMarkFlag = flag;
		}
	}
	// remoteaction用クラス
	public class AJAXRequest{
		String quotaid;
		boolean mark;
		String field;
		String value;
	}
	// 页面之间，用于前台js刷新行信息
	public class QuotaJson {
		String id;
		String name;
		String quotaName;
		String status;
		String quoDesc;
		String quoDate;
		// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
		Decimal quoTotal;
		// 2017/12/11 見積明細金額合計機能追加　by　zy END
		String createBy;
		String createDate;
		String createById;
		public QuotaJson(Quota__c q) {
			id = q.id;
			name = CommUtils.nullToBlank(q.name);
			quotaName = CommUtils.nullToBlank(q.QuotaName__c);
			status = CommUtils.nullToBlank(q.QuotaStatus__c);
			quoDesc = CommUtils.nullToBlank(q.QuotaDescription__c);
			if (q.ExpirationDate__c != null ) quoDate = q.ExpirationDate__c.format();
			else quoDate = '';
			createBy = CommUtils.nullToBlank(q.LastModifiedBy.Name);
			createById = CommUtils.nullToBlank(q.LastModifiedById);
			if (q.LastModifiedDate != null) createDate = q.LastModifiedDate.format(CommBaseCtrl.getDateTimeFormat());
			// 2017/12/11 見積明細金額合計機能追加　by　zy BEGIN
			quoTotal = CommUtils.nullToZero(q.TotalInc__c);
			// 2017/12/11 見積明細金額合計機能追加　by　zy END
		}
	}
	// 2017/11/21参照見積関連追加　by　zy END
}