public with sharing class CashPdfBulkPrintCtrl extends CommBaseCtrl{
	public list<Yadochou__c> yadoList {get;set;} // 宿帳
	public Yadochou__c yadoNew {get;set;} // 宿帳
	public BookingTimeTable__c selectDate{get; private set;} // 日期
	public List<String> shopCode{get; set;} //店铺
	public Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
	public String isShowMoneyUrlInfo{get; private set;} // 全画面から金額表示する・しないパラメータ情報を格納
	//public Boolean conFirmFlg {get; set;} // 记忆check
	// 初期値设定
    public CashPdfBulkPrintCtrl(){
    	selectDate = new BookingTimeTable__c();
    	yadoNew = new Yadochou__c();
    	// 获取店铺和时间
    	shopCode = new List<String>();
    	// ルームインジケータ画面から金額表示する、しないフラグを格納する[]
    	if (ApexPages.currentPage().getParameters().containsKey('smy')) isShowMoneyUrlInfo = '&smy=1';
    	else isShowMoneyUrlInfo = '';
    	String branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        if (!CommUtils.isBlank(branchShopNm)) shopCode.addAll(CommUtils.nullToBlank(branchShopNm).split(','));
    	String workDateStr = ApexPages.currentPage().getParameters().get('cardDate');
    	Date workDate = CommUtils.isBlank(workDateStr) ? Date.today() : CommUtils.stringToDate(workDateStr);
    	selectDate.Checkinday__c = workDate;
    	String queryNewStr = ' select Id,Name,Field11__c,Field15__c,Field15__r.Name,Field1__c,Field1__r.Name,Field1__r.StayPersons__c,Field1__r.LeadIndexRef__r.EntryDate__c,Field1__r.LeadIndexRef__r.DepartureDate__c,Field1__r.LeadIndexRef__r.Nights__c,Field1__r.Field2__c,Field1__r.ReservedType__c,Field1__r.Segment__c,Field1__r.Relcontact__r.Name,Field1__r.Relcontact__c from Yadochou__c where Field1__r.CancelBool__c != :cancelFlg ';
    	if (!shopCode.isEmpty()) queryNewStr += ' AND (Field1__r.Rroom__r.ShopInfoRef__r.ShopCode__c  =:shopCode or Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode) ' ;
    	if(selectDate.Checkinday__c != null) queryNewStr += ' AND DAY_ONLY(convertTimezone(Field1__r.EntryTime__c)) = :workDate ' ;
		queryNewStr += ' Order By Field1__r.Rroom__r.Seq__c,Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c'; 
		yadoList = DataBase.query(queryNewStr);
		getyadoLayoutInfo();
    	getRoomType();
    	
		// DBから設定情報を取得する
		/*
		conFirmFlg = false;
		map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
		String configSwapFlgKey = UserConfigCompCtrl.KREP_SUBTYPE.YADOFLG.name();
		String configSwapFlgVal = '';
		if (userConfigMap.containsKey(configSwapFlgKey)) configSwapFlgVal = CommUtils.nullToBlank(userConfigMap.get(configSwapFlgKey));
		if (!CommUtils.isBlank(configSwapFlgVal)) conFirmFlg = Boolean.valueOf(configSwapFlgVal);
		*/
    }
    // 获取对应房型
    public List<SelectOption> RoomTypeLst{get; private set;}
    public String RoomTypeNm{get; set;}
    private void getRoomType() {
    	roomTypeNm = '';
    	RoomTypeLst = new List<SelectOption>();
    	String RTqueryStr = ' select id,name from TypeOfRooms__c ';
    	if (!shopCode.isEmpty()) RTqueryStr +=' where ShopInfoRef__r.ShopCode__c =: shopCode ';
    	list<TypeOfRooms__c> rooms = DataBase.query(RTqueryStr);
    	for(TypeOfRooms__c RT : rooms){
    		RoomTypeLst.add(new SelectOption(RT.id, RT.name));
    	}
    }
	public void gotoDate() {
		// 获取数据集
		//yadoList = new list<Yadochou__c>();
		Date workDate = selectDate.Checkinday__c;
		String strWorkDate = null;
		Id contactId = yadoNew.Field15__c;
		String queryStr =' Select Id,Name,Field11__c,Field15__c,Field15__r.Name,Field1__c,Field1__r.Name,Field1__r.StayPersons__c,Field1__r.LeadIndexRef__r.EntryDate__c,Field1__r.LeadIndexRef__r.DepartureDate__c,Field1__r.LeadIndexRef__r.Nights__c,Field1__r.Field2__c,Field1__r.ReservedType__c,Field1__r.Segment__c,Field1__r.Relcontact__r.Name,Field1__r.Relcontact__c from Yadochou__c where Field1__r.CancelBool__c != :cancelFlg ' ;
		if (!shopCode.isEmpty()) queryStr += ' AND (Field1__r.Rroom__r.ShopInfoRef__r.ShopCode__c  =:shopCode or Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode) ' ;
		if(!CommUtils.isBlank(RoomTypeNm)) queryStr += ' AND Field1__r.refTypeOfRooms__c =:RoomTypeNm ' ;
		if(workDate != null) {
			// 20万件以上制限対応済み場合、「EntryDateKey__c」項目で到着日として検索を行う
			if (DataFixManagerUtils.isLeadKeyFixed()) {
				strWorkDate = CommUtils.dateToYYYYMMDD(workDate);
				queryStr += ' AND Field1__r.EntryDateKey__c = :strWorkDate ' ;
			} else {
				queryStr += ' AND DAY_ONLY(convertTimezone(Field1__r.EntryTime__c)) = :workDate ' ;
			}
		}
		if(!CommUtils.isBlank(yadoNew.Field15__c)) queryStr += ' AND (Field15__c =:contactId or Field1__r.Relcontact__c = :contactId)' ;
		queryStr += ' Order By Field1__r.Rroom__r.Seq__c,Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c'; 
		yadoList = DataBase.query(queryStr);
		getyadoLayoutInfo();
	}
	// 数据处理
    private void getyadoLayoutInfo(){
		yadoItemLst = new List<ItemInfo>();
		for(Yadochou__c yado : yadoList) {
			ItemInfo layoutItem = new ItemInfo(yado);
			yadoItemLst.add(layoutItem);
		}
		yadoItemJson = JSON.serialize(yadoItemLst);
    }
    public List<ItemInfo> yadoItemLst{get;set;}
    public String yadoItemJson{get;set;}
    public class ItemInfo{
    	// 页面的check
    	public Boolean checkFlg{get; set;}
    	// 页面的宿帐
    	public String yadoId{get; set;}
    	// 页面的顾客
    	public String conId{get; set;}
    	public String conName{get; set;}
    	// 页面的予约
    	public String leadId{get; set;}
    	public String leadName{get; set;}
    	// 页面的予约人数
    	public Decimal leadStayPersons{get; set;}
    	// 页面的予约到着日/出发日
    	public String leadEntry{get; set;}
    	public String leadDepar{get; set;}
    	// 页面的予约泊数
    	public String leadStayNight{get; set;}
    	// 页面的予約チャネル
    	public String leadChannel{get; set;}
    	// 页面的予約タイプ
    	public String leadReservedType{get; set;}
    	// 页面的予约セグメント
    	public String leadSegment{get; set;}
    	// 页面的房间
    	public String roomName{get; set;}
    	
    	public ItemInfo(Yadochou__c yd){
    		checkFlg = true;
    		yadoId = yd.Id;
    		conId = CommUtils.nullToBlank(yd.Field15__c);
    		conName = CommUtils.nullToBlank(yd.Field15__r.Name);
    		if(CommUtils.isBlank(conId)){
    			conId = CommUtils.nullToBlank(yd.Field1__r.Relcontact__c);
    			conName = CommUtils.nullToBlank(yd.Field1__r.Relcontact__r.Name);
    		}
    		leadId = CommUtils.nullToBlank(yd.Field1__c);
    		leadName = CommUtils.nullToBlank(yd.Field1__r.Name);
    		roomName = CommUtils.nullToBlank(yd.Field11__c);
    		leadStayPersons = CommUtils.nullToZero(yd.Field1__r.StayPersons__c);
    		leadEntry = CommUtils.nullToBlank(yd.Field1__r.LeadIndexRef__r.EntryDate__c == null ? '' : yd.Field1__r.LeadIndexRef__r.EntryDate__c.format());
    		leadDepar = CommUtils.nullToBlank(yd.Field1__r.LeadIndexRef__r.DepartureDate__c == null ? '' : yd.Field1__r.LeadIndexRef__r.DepartureDate__c.format());
    		leadStayNight = CommUtils.nullToBlank(yd.Field1__r.LeadIndexRef__r.Nights__c);
    		leadChannel = CommUtils.nullToBlank(yd.Field1__r.Field2__c);
    		leadReservedType = CommUtils.nullToBlank(yd.Field1__r.ReservedType__c);
    		leadSegment = CommUtils.nullToBlank(yd.Field1__r.Segment__c);
    	}
    }
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
	public String switchCode{get{return CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;}set;}
	public String shopLst{get{
	    	Boolean CashLogoFlg = CommConst.APPOTION_CARREGISTER_LOGO_FLG;
	    	String shopLstStr ='';
	    	if(CashLogoFlg) {
	    		List<String> ShopInfoLst = ShopInfoUtil.getCanSelectShopLst(UserInfo.getUserId());
	    		if(!ShopInfoLst.isEmpty() && ShopInfoLst.size() > 1) shopLstStr = JSON.serialize(ShopInfoLst);
	    	}
	    	return shopLstStr;
	}}
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
}