public with sharing class ApplicationFormPDF{
	// 予約ID
	private final Id leadId;
	// 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
	public Boolean isApplicationFormTimeFlg{get{return CommConst.APPOTION_APPLICATIONFORMTIME_FLG;}}
	// 2019/03/31 日帰り時刻を表記 BY zyz END
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	public Boolean RespectFlg{get;set;}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	// 予約画面　OR　宿帳　から画面を開く
	public ApplicationFormPDF(ApexPages.StandardController controller){
		// 予約IDを取得、設定を行う
		leadId = ApexPages.currentPage().getParameters().get('id');
	}
	/**
	* PDF出力情報を取得、設定を行う
	**/
	public void initPdf() {
		// 予約情報を取得する
		setHeaderInfo(leadId);
	}
	// 組織名
	public String orgName{get; private set;}
	// 画面表示情報を格納変数
	public LeadInfo oLeadInf{get; private set;}
	// 画面表示情報を格納用クラス
	public class LeadInfo {
		public LeadInfo(Lead__c pLead) {
			leadInf = pLead;
			address = CommUtils.nullToBlank(pLead.Relcontact__r.MailingCountry)
					+ CommUtils.nullToBlank(pLead.Relcontact__r.MailingState) 
					+ CommUtils.nullToBlank(pLead.Relcontact__r.MailingCity)
					+ CommUtils.nullToBlank(pLead.Relcontact__r.MailingStreet);
			String phoneStr = pLead.Relcontact__r.Phone == null? pLead.Relcontact__r.HomePhone : pLead.Relcontact__r.Phone;
			phone = CommUtils.isBlank(phoneStr) ? pLead.Relcontact__r.MobilePhone : phoneStr;
			childCount =CommUtils.nullToIntZero(pLead.ChildFA__c) + 
						CommUtils.nullToIntZero(pLead.Childs__c) +
						CommUtils.nullToIntZero(pLead.ChildC__c) + 
						CommUtils.nullToIntZero(pLead.ChildD__c) +
						CommUtils.nullToIntZero(pLead.ChildE__c) + 
						CommUtils.nullToIntZero(pLead.ChildF__c);
			
		}
		public Lead__c leadInf{get; private set;}
		public String entryDate{get; set;}
		public String departureDate{get;set;}
		public String customName{get;set;}
		public String address{get;set;}
		public String phone{get;set;}
		public integer childCount{get;set;}
		// 2019/03/15 日帰り時刻を表記 BY zyz BEGIN
		public Integer stayDays{get; private set;}		// 泊数
		public String arrivalTime{get;private set;}		// 到 着 時 間
		public String departureTime{get; private set;} 	// 出 発 時 間
		// 2019/03/15 日帰り時刻を表記 BY zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		public String mrStr{get; private set;}
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	}
	
    // ヘーダ情報を設定する
    private void setHeaderInfo(String leadId) {
    	// 2013/01/11 EDIT  Rroom__r.Rnumber__c -> Rroom__r.Name
		Lead__c leadDetail = [  Select Id, Name, Rroom__r.Name, Relcontact__r.Id, Relcontact__r.Name,Field276__c,
								Relcontact__r.MailingPostalCode,Relcontact__r.MailingStreet, Relcontact__r.MailingState,
								Relcontact__r.MailingCountry,Relcontact__r.MailingCity,
								Relcontact__r.Phone,Relcontact__r.Phone2__c, 
								Relcontact__r.MobilePhone,Relcontact__r.HomePhone,
								Relcontact__r.Email,Field292__c,LeadIndexSubId__c, LeadIndexRef__c, 
								RoomGroupNo__c, ReservedStatus__c, EntryTime__c, Field4__c,Femails__c,ChildFA__c,Childs__c,
								ChildC__c,ChildD__c,ChildE__c,ChildF__c,Mans__c,
								LeadIndexRef__r.EntryDate__c,LeadIndexRef__r.DepartureDate__c,
                                Departure__c, Field3__c, Field310__r.Name, Field298__c,StayPersons__c,SeminarOrderFlg__c,Field2__c,
                                Field308__c,Comment3__c 
                                // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
                                ,RespectLst__c
                                // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
                                From Lead__c where Id = :leadId];
        /*
        // 連泊情報を取得する
        List<Lead__c> leads = [ select id, EntryTime__c,Departure__c
                                from Lead__c 
                                where LeadIndexRef__c = :leadDetail.LeadIndexRef__c 
                                And LeadIndexSubId__c = :leadDetail.LeadIndexSubId__c
                                And RoomGroupNo__c = :leadDetail.RoomGroupNo__c
                                And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG 
                                Order By EntryTime__c];
        */
		// 宿泊部屋情報
		oLeadInf = new LeadInfo(leadDetail);
        // お客様
        //roomInfoDetail.customId = leadDetail.Relcontact__c;
        oLeadInf.customName = CommUtils.nullToBlank(leadDetail.Relcontact__r.Name);
        // 到着日
        if (leadDetail.LeadIndexRef__r.EntryDate__c != null) {
        	Date entryDt = leadDetail.LeadIndexRef__r.EntryDate__c;
        	oLeadInf.entryDate = (DateTime.newInstance(entryDt.year(), entryDt.month(), entryDt.day())).format('yyyy年MM月dd日');
        } else {
        	oLeadInf.entryDate = '';
        }
        // 出発日
        if (leadDetail.LeadIndexRef__r.DepartureDate__c != null) {
        	Date depDt = leadDetail.LeadIndexRef__r.DepartureDate__c;
        	oLeadInf.departureDate = (DateTime.newInstance(depDt.year(), depDt.month(), depDt.day())).format('yyyy年MM月dd日');
        } else {
        	oLeadInf.departureDate = '';
        }
        // 2019/03/15 日帰り時刻を表記 BY zyz BEGIN
        // 泊数計算
        if (!CommUtils.isBlank(oLeadInf.entryDate) && !CommUtils.isBlank(oLeadInf.departureDate)) {
        	Date entryDt = leadDetail.LeadIndexRef__r.EntryDate__c;
        	Date depDt = leadDetail.LeadIndexRef__r.DepartureDate__c;
        	oLeadInf.stayDays = entryDt.daysBetween(depDt);
        }
		//到 着 時 間
		DateTime arrivalDtTime = leadDetail.EntryTime__c;
		if (!CommUtils.isBlank(leadDetail.Field4__c)) {
			Time arrTime = CommUtils.stringToTime(leadDetail.Field4__c);
			arrivalDtTime = DateTime.newInstance(arrivalDtTime.date(), arrTime);
		}
		// 到着时间 ： HH:mm 格式
		oLeadInf.arrivalTime = arrivalDtTime.format('HH:mm');
		DateTime departureDtTime = leadDetail.Departure__c;
		if (!CommUtils.isBlank(leadDetail.Field3__c)) {
			Time arrTime = CommUtils.stringToTime(leadDetail.Field3__c);
			departureDtTime = DateTime.newInstance(departureDtTime.date(), arrTime);
		}
		// 出发时间 ： HH:mm 格式
		oLeadInf.departureTime = departureDtTime.format('HH:mm');
        // 2019/03/15 日帰り時刻を表記 BY zyz END
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
        RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
		Schema.DescribeFieldResult fieldResult = Lead__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
	   	   if(CommUtils.isBlank(leadDetail.RespectLst__c) && f.isDefaultValue()) leadDetail.RespectLst__c = f.getLabel();
	   	}
	   	oLeadInf.mrStr = '様';
	   	if(RespectFlg) oLeadInf.mrStr = leadDetail.RespectLst__c;
        // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
        // 組織情報を取得、設定する
        orgName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().FacilityName__c);
        if (CommUtils.isBlank(orgName)) {
	        List<Organization> orgLst = [Select Name From Organization limit 1];
	        if (!orgLst.isEmpty()) orgName = orgLst[0].Name;
        }
    }
/**
*2015-11-18 
*テストクラスApplicationFormPDFTestに移行する	
	@isTest
	static void testCase1() {
    	// 予約情報を作成する[プラン付け]
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
		// Normal商品
		List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
		List<AccountMaster__c> productLst2 = TestCommon.createFullProductMst(5);
		// プラン商品作成
		AccountMaster__c planProd0 = TestCommon.createPlanProd();
		AccountMaster__c planProd1 = TestCommon.createPlanProd();
		AccountMaster__c planProd2 = TestCommon.createPlanProd();
		//　上記プランの関連プラン商品を取得する
		// 見積明細を作成する
    	TestCommon.createBookEstItems(leadInfo, productLst);
		Test.startTest();
		// Lead Id 設定する
		Apexpages.currentPage().getParameters().put('id',leadInfo.Id);
		Pagereference pg = ApexPages.currentPage();
		Test.setCurrentPage(pg);
    	ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
    	ApplicationFormPDF ctrl = new ApplicationFormPDF(contrl);
		ctrl.initPdf();
		Test.stopTest();
		System.assert(ctrl.oLeadInf != null);
	}
*/
}