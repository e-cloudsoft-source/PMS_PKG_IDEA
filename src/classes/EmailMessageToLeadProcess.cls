public with sharing class EmailMessageToLeadProcess {
	// メール受信時刻を格納する
	private static final DateTime gRecMailTime;
	private static String HtmlBody;
	//private final String gMailBody;
	public Map<String,Map<String,String>> customerFieldMap;
	static {
		gRecMailTime = System.now();
//System.debug(loggingLevel.INFO, 'gRecMailTime::' + gRecMailTime);
	}
	public EmailMessageToLeadProcess(EmailMessageToLeadHelp.AgtInfo agtInfo) {
		String templateName = agtInfo.emailTemplate;
		Dom.XMLNode root = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc(templateName,new String[]{'<EMIAL_TAG_FORMAT>','</EMIAL_TAG_FORMAT>'});
    	for(Dom.XmlNode parentNode : root.getChildElements()){
    		String nodeName = parentNode.getName();
    		if (nodeName == 'TransactionType') {
    			TransactionType = new TransactionTypeDef(parentNode, agtInfo);
    		} else if (nodeName == 'AccommodationInformation') {
    			AccommodationInformation = new AccommodationInformationDef(parentNode);
    		} else if (nodeName == 'SalesOfficeInformation') {
    			SalesOfficeInformation = new SalesOfficeInformationDef(parentNode, agtInfo);
    		} else if (nodeName == 'BasicInformation') {
    			BasicInformation = new BasicInformationDef(parentNode);
    		} else if (nodeName == 'BasicRateInformation') {
    			BasicRateInformation = new BasicRateInformationDef(parentNode);
    		} else if (nodeName == 'RoomAndGuestInformation') {
    			RoomAndGuestInformation = new RoomAndGuestInformationDef(parentNode);
    		} else if (nodeName == 'RisaplsInformation') {
    			RisaplsInformation = new RisaplsInformationDef(parentNode);
    		} else if (nodeName == 'CUSTOMER_SETTING') {
    			CustomerSetting  = new CustomerSettingDef(parentNode);
    		}
    	}
	}
   	//普通节点处理用
    //public static List<ParseInf> parseInfos;
    //明细部分处理用
    //public static List<ParseInf> detailInfos;
    //明细共同处理
    //public static CommPrice commPriceInfo;
    //public static String BEGIN_TAG = '<$$_START_$$>';
    //public static String END_TAG = '</$$_END_$$>\n';
    //邮件内容
    //static String emailContent;
    //明细内容
   //public String detailContent;
    //泊数
    //private Integer nights;
    //自定义设定
    //public Map<String,CustomerSettingInfo> customMap;
    
    // 標準レイアウトタグ定義情報格納
    private TransactionTypeDef TransactionType;
    private AccommodationInformationDef AccommodationInformation;
    private SalesOfficeInformationDef SalesOfficeInformation;
    private static BasicInformationDef BasicInformation;
    private BasicRateInformationDef BasicRateInformation;
    private RoomAndGuestInformationDef RoomAndGuestInformation;
    private RisaplsInformationDef RisaplsInformation;
    private CustomerSettingDef CustomerSetting;
    abstract class XmlBase {
    	public String startTag{get;set;}
    	public String endTag{get;set;}
    	public String tagName{get;set;}
    	public String agtCode{get;set;}
    }
    
    class TransactionTypeDef extends XmlBase{
    	public TransactionTypeDef(Dom.XMLNode parentNode, EmailMessageToLeadHelp.AgtInfo agtInfo) {
    		DataClassification = new List<NodeItem>();
    		//SystemDate = gRecMailTime.format('yyyy-MM-dd');
    		
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		agtCode = agtInfo.agtCd;
    		
    		for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'DataFrom') {
    				DataFrom = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'DataClassification') {
    				NodeItem item = new NodeItem(nodeName, xmlNode);
    				DataClassification.add(item);
    			} else if (nodeName == 'DataID') {
    				DataID = new NodeItem(nodeName, xmlNode);
    			}
    		}
    		SystemDate = new NodeItem('SystemDate', gRecMailTime.format('yyyy-MM-dd'));
    	}
    	public NodeItem DataFrom{get;set;}
    	public list<NodeItem> DataClassification{get;set;}
    	public NodeItem DataID{get;set;}
    	public NodeItem SystemDate{get;set;}
    	
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			if (DataFrom != null) xmlBody += DataFrom.toXml(DataFrom.getValue(mailBody));
			// 予約処理区分
			Boolean isSetDefaultVal = true;
			for (NodeItem item : DataClassification) {
				//xmlBody += item.getValue(mailBody);
				String val = item.getValue(mailBody);
				if (!Commutils.isBlank(val)) {
					xmlBody += item.toXml(val);
					isSetDefaultVal = false;
					break;
				}
			}
			if (isSetDefaultVal ) {
				NodeItem item = DataClassification[0]; 
				xmlBody += item.toXml('NewBookReport');
			}
			if (DataID != null) {
				String strDataId = DataID.getValue(mailBody);
				if (!CommUtils.isBlank(strDataId)) {
					strDataId = 'IMP_' + agtCode + '_' + strDataId;
				}
				xmlBody += DataID.toXml(strDataId);
			}
			if (SystemDate != null) xmlBody += SystemDate.toXml(SystemDate.getValue(mailBody));
			
			return xmlBody + '</' + tagName + '>\n';
		}
    }
    class AccommodationInformationDef extends XmlBase{
    	public AccommodationInformationDef(Dom.XMLNode parentNode) {
    		/*
    		Dom.XMLNode AccommodationNameField = parentNode.getChildElement('AccommodationName', null);
    		Dom.XMLNode AccommodationCodeField = parentNode.getChildElement('AccommodationCode', null);
    		if (AccommodationNameField != null) AccommodationName = CommUtils.nullToBlank(AccommodationNameField.getText());
    		if (AccommodationCodeField != null) AccommodationCode = CommUtils.nullToBlank(AccommodationCodeField.getText());
    		*/
    		tagName = parentNode.getName();
    		
    		for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'AccommodationName'){
    				Dom.XmlNode tagNode = xmlNode.getChildElement('EMAIL_TAG',null);
    				if (tagNode != null) AccommodationName = new NodeItem(nodeName,xmlNode);
    				else AccommodationName = new NodeItem(nodeName, CommUtils.nullToBlank(xmlNode.getText()));
    			}else if (nodeName == 'AccommodationCode') {
    				Dom.XmlNode tagNode = xmlNode.getChildElement('EMAIL_TAG',null);
    				if (tagNode != null) AccommodationCode = new NodeItem(nodeName,xmlNode);
    				else AccommodationCode = new NodeItem(nodeName, CommUtils.nullToBlank(xmlNode.getText()));
    			}
    		}
    	}
    	public NodeItem AccommodationName{get;set;}
    	public NodeItem AccommodationCode{get;set;}
    	
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			if (AccommodationName != null) xmlBody += //AccommodationName.toXmlChild(mailBody);
			AccommodationName.toXml(AccommodationName.getValue(mailBody));
			if (AccommodationCode != null) xmlBody += //AccommodationCode.toXmlChild(mailBody);
			AccommodationCode.toXml(AccommodationCode.getValue(mailBody));
			
			return xmlBody + '</' + tagName + '>\n';
		}
    }
    class SalesOfficeInformationDef extends XmlBase{
    	public SalesOfficeInformationDef(Dom.XMLNode parentNode, EmailMessageToLeadHelp.AgtInfo agtInfo) {
    		
    		tagName = parentNode.getName();
    		
    		for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'SalesOfficeCompanyName'){
    				Dom.XmlNode tagNode = xmlNode.getChildElement('EMAIL_TAG',null);
    				if (tagNode != null) SalesOfficeCompanyName = new NodeItem(nodeName,xmlNode);
    				else SalesOfficeCompanyName = new NodeItem(nodeName, CommUtils.nullToBlank(xmlNode.getText()));
    			}
    			//else if (nodeName == 'SalesOfficeCompanyCode')
    				//SalesOfficeCompanyCode = new NodeItem(nodeName, CommUtils.nullToBlank(xmlNode.getText()));
    		}
    		// AGT CODE
    		SalesOfficeCompanyCode = new NodeItem('SalesOfficeCompanyCode', agtInfo.agtCd);
    	}
    	//public NodeItem AccommodationName{get;set;}
    	//public NodeItem AccommodationCode{get;set;}
    	public NodeItem SalesOfficeCompanyName{get;set;}
    	public NodeItem SalesOfficeCompanyCode{get;set;}
    	
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			if (SalesOfficeCompanyName != null) xmlBody += SalesOfficeCompanyName.toXmlChild(mailBody);
			//.toXml(SalesOfficeCompanyName.getValue(mailBody));
			if (SalesOfficeCompanyCode != null) xmlBody += SalesOfficeCompanyCode.toXmlChild(mailBody);
			//.toXml(SalesOfficeCompanyCode.getValue(mailBody));
			
			return xmlBody + '</' + tagName + '>\n';
		}
    }
    class BasicInformationDef extends XmlBase{
    	public BasicInformationDef(Dom.XMLNode parentNode) {
    		
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'TravelAgencyBookingNumber') {
    				TravelAgencyBookingNumber = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TravelAgencyBookingDate') {
    				TravelAgencyBookingDate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TravelAgencyBookingTime') {
    				TravelAgencyBookingTime = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TravelAgencyReportNumber') {
    				TravelAgencyReportNumber = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestOrGroupNameSingleByte') {
    				GuestOrGroupNameSingleByte = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestOrGroupNameKanjiName') {
    				GuestOrGroupNameKanjiName = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestOrGroupNameDoubleByte') {
    				GuestOrGroupNameDoubleByte = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CheckInDate') {
    				CheckInDate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CheckInTime') {
    				CheckInTime = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CheckOutDate') {
    				CheckOutDate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CheckOutTime') {
    				CheckOutTime = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'Nights') {
    				Nights = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'Transportaion') {
    				Transportaion = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalRoomCount') {
    				TotalRoomCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PackagePlanName') {
    				PackagePlanName = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PackagePlanCode') {
    				PackagePlanCode = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomTypeCode') {
    				RoomTypeCode = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomTypeName') {
    				RoomTypeName = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'OtherServiceInformation') {
    				OtherServiceInformation = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'SpecificMealCondition') {
    				SpecificMealCondition = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'MealCondition') {
    				MealCondition = new NodeItem(nodeName, xmlNode);
    			}
    		}
    	}
    	public NodeItem TravelAgencyBookingNumber{get;set;}	//
    	public NodeItem TravelAgencyBookingDate{get;set;}		// 
    	public NodeItem TravelAgencyBookingTime{get;set;}
    	public NodeItem TravelAgencyReportNumber{get;set;}
    	public NodeItem GuestOrGroupNameSingleByte{get;set;}	// 必須[かな]
    	public NodeItem GuestOrGroupNameKanjiName{get;set;}
    	public NodeItem GuestOrGroupNameDoubleByte{get;set;}
        public NodeItem CheckInDate{get;set;}
        public NodeItem CheckInTime{get;set;}
        public NodeItem CheckOutDate{get;set;}
        public NodeItem CheckOutTime{get;set;}
        public NodeItem Nights{get;set;}
        public NodeItem Transportaion{get;set;}
        ////利用客室合計数
        public NodeItem TotalRoomCount{get;set;}
        ////お客様総合計人数
        // 処理対象外
        /*
        public Integer GrandTotalPaxCount;
        public Integer TotalPaxMaleCount;
        public Integer TotalPaxFemaleCount;
        public Integer TotalChildA70Count;
        public Integer TotalChildB50Count;
        public Integer TotalChildC30Count;
        public Integer TotalChildDNoneCount;
        */
        public NodeItem PackagePlanName{get;set;}
        public NodeItem PackagePlanCode{get;set;}
        
        public NodeItem RoomTypeCode{get;set;}
        public NodeItem RoomTypeName{get;set;}
        /*
        //public String PackagePlanContent;
        ////食事条件:TODO　名から実際のあ約タイプに変換する
       */
        public NodeItem MealCondition;
        ////食事有無情報
        public NodeItem SpecificMealCondition;
       /*
        ////食事個所情報
        public String MealPlace;                  // 非使用		
        public String ModificationPoint;                //変更ポイント説明
        public String CancellationNumber;               //宿泊施設取消番号
        */
        // 備考
        public NodeItem OtherServiceInformation;
        /*
        // 詳細情報有無
        public String FollowUpInformation;        // 非使用
        */
        // 2017/11/15 ０泊の場合対応　by　zy BEGIN
        public String checkInDateStr;
        public String checkOutDateStr;
        // 2017/11/15 ０泊の場合対応　by　zy END
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			
			if (TravelAgencyBookingNumber != null) xmlBody += TravelAgencyBookingNumber.toXml(TravelAgencyBookingNumber.getValue(mailBody));
			if (TravelAgencyBookingDate != null) {
				xmlBody += TravelAgencyBookingDate.toXml(TravelAgencyBookingDate.getValue(mailBody));
			} else {
				xmlBody += new NodeItem('TravelAgencyBookingDate').toXml(gRecMailTime.format('yyyy-MM-dd'));
			}
			if (TravelAgencyBookingTime != null) {
				xmlBody += TravelAgencyBookingTime.toXml(TravelAgencyBookingTime.getValue(mailBody));
			} else {
				xmlBody += new NodeItem('TravelAgencyBookingTime').toXml(gRecMailTime.format('HH:mm'));
			}
			if (TravelAgencyReportNumber != null) xmlBody += TravelAgencyReportNumber.toXmlChild(mailBody);
			//.toXml(TravelAgencyReportNumber.getValue(mailBody));
			if (GuestOrGroupNameSingleByte != null) xmlBody += GuestOrGroupNameSingleByte.toXmlChild(mailBody);
			//.toXml(GuestOrGroupNameSingleByte.getValue(mailBody));
			if (GuestOrGroupNameKanjiName != null) xmlBody += GuestOrGroupNameKanjiName.toXmlChild(mailBody);
			//.toXml(GuestOrGroupNameKanjiName.getValue(mailBody));
			if (GuestOrGroupNameDoubleByte != null) {
				String val = GuestOrGroupNameDoubleByte.getValue(mailBody);
				if (GuestOrGroupNameSingleByte == null && !CommUtils.isBlank(val) ) {
					xmlBody += ((new NodeItem('GuestOrGroupNameSingleByte')).toXml(CommStringUtils.zenkakuToHankaku(val)));
				}
				xmlBody += GuestOrGroupNameDoubleByte.toXml(val);
			}
			// 2017/11/15 ０泊の場合対応　by　zy BEGIN
			if (CheckInDate != null) {
				checkInDateStr = CheckInDate.getValue(mailBody);
				xmlBody += CheckInDate.toXml(checkInDateStr);
			}
			// 2017/11/15 ０泊の場合対応　by　zy END
			if (CheckInTime != null) xmlBody += CheckInTime.toXml(CheckInTime.getValue(mailBody));
			// 2017/11/15 ０泊の場合対応　by　zy BEGIN
			if (CheckOutDate != null) {
				checkOutDateStr = CheckOutDate.getValue(mailBody);
				xmlBody += CheckOutDate.toXml(checkOutDateStr);
			}
			// 2017/11/15 ０泊の場合対応　by　zy END
			if (CheckOutTime != null) xmlBody += CheckOutTime.toXml(CheckOutTime.getValue(mailBody));
			if (Nights != null) xmlBody += Nights.toXml(Nights.getValue(mailBody));
			else {
				Nights = new NodeItem('Nights');
				xmlBody += Nights.toBlankNodeXml();
			}
			if (Transportaion != null) xmlBody += Transportaion.toXml(Transportaion.getValue(mailBody));

			if (TotalRoomCount != null) xmlBody += TotalRoomCount.toXml(TotalRoomCount.getValue(mailBody));
			else {
				TotalRoomCount = new NodeItem('TotalRoomCount');
				xmlBody += TotalRoomCount.toBlankNodeXml();
			}
			if (PackagePlanName != null) xmlBody += PackagePlanName.toXml(PackagePlanName.getValue(mailBody));
			if (PackagePlanCode != null) xmlBody += PackagePlanCode.toXml(PackagePlanCode.getValue(mailBody));
			else {
				// プランコードがNULLの場合、プラン名とAGTと店舗と合せてプランコードを設定
			}
			if (OtherServiceInformation != null) xmlBody += OtherServiceInformation.toXmlChild(mailBody);
			//OtherServiceInformation.toXml(OtherServiceInformation.getValue(mailBody));
			if (SpecificMealCondition != null) xmlBody += SpecificMealCondition.toXmlChild(mailBody);
			//.toXml(SpecificMealCondition.getValue(mailBody));
			
			if (MealCondition != null) xmlBody += MealCondition.toXmlChild(mailBody);
			//.toXml(MealCondition.getValue(mailBody));

			if (RoomTypeCode != null) RoomTypeCode.getValue(mailBody);
			if (RoomTypeName != null) RoomTypeName.getValue(mailBody);
			
//System.debug(loggingLevel.INFO,'RoomTypeCode.value='+ RoomTypeCode.value);
//System.debug(loggingLevel.INFO,'RoomTypeName.value='+ RoomTypeName.value);
       // public NodeItem TotalRoomCount{get;set;}
       // public NodeItem PackagePlanName{get;set;}
       // public NodeItem PackagePlanCode{get;set;}

			return xmlBody + '</' + tagName + '>\n';
		}  
    }
    
    class BasicRateInformationDef extends XmlBase{

    	public BasicRateInformationDef(Dom.XMLNode parentNode) {
    		
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		TaxServiceFee = new list<NodeItem>();
    		CouponList = new List<CouponListDef>();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'RoomRateOrPersonalRate') {
    				RoomRateOrPersonalRate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TaxServiceFee') {
    				//TaxServiceFee = new NodeItem(nodeName, xmlNode);
    				NodeItem item = new NodeItem(nodeName, xmlNode);
    				TaxServiceFee.add(item);
    			} else if (nodeName == 'Payment') {
    				Payment = new NodeItem(nodeName, xmlNode);
				} else if (nodeName == 'TotalAccommodationCharge') {
    				TotalAccommodationCharge = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CouponList'){
    				CouponListDef d = new CouponListDef(xmlNode);
    				CouponList.add(d);
    			}
			}
    	}
    	public NodeItem RoomRateOrPersonalRate{get;set;}
    	public List<NodeItem> TaxServiceFee{get;set;}
    	public List<CouponListDef> CouponList{get;set;}
    	public NodeItem Payment{get;set;}
    	public NodeItem TotalAccommodationCharge;
    	
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			if (RoomRateOrPersonalRate != null) xmlBody += RoomRateOrPersonalRate.toXml(RoomRateOrPersonalRate.getValue(mailBody));
			//if (TaxServiceFee != null) xmlBody += TaxServiceFee.toXml(TaxServiceFee.getValue(mailBody));
			Boolean isSetDefaultVal = true;
			for (NodeItem item : TaxServiceFee) {
				String val = item.getValue(mailBody);
				if (!Commutils.isBlank(val)) {
					xmlBody += item.toXml(val);
					isSetDefaultVal = false;
					break;
				}
			}
			if (isSetDefaultVal) {}
			
			if (Payment != null) xmlBody += Payment.toXml(Payment.getValue(mailBody));
			if (TotalAccommodationCharge != null) xmlBody += TotalAccommodationCharge.toXmlChild(mailBody);
			//.toXml(TotalAccommodationCharge.getValue(mailBody));
			if (!CouponList.isEmpty()){
				for(CouponListDef c : CouponList){
					if(c != null)
						xmlBody += c.generalXml(mailBody);
				}
			}
			
			
			return xmlBody + '</' + tagName + '>\n';
		}
    }
    class CouponListDef extends XmlBase{
    	public NodeItem CouponAmount;
    	public NodeItem CouponType;
    	public NodeItem CouponNumber;
    	public NodeItem CouponIssueDate;
    	private string tagName;
    	public CouponListDef(Dom.XMLNode parentNode) {
    		tagName = parentNode.getName();
    		for(Dom.XMLNode node : parentNode.getChildElements()){
    			String nodeName = node.getName();
    			if ( nodeName == 'CouponAmount' ){
    				CouponAmount = new NodeItem(nodeName,node);
    			} else if ( nodeName == 'CouponType' ){
    				CouponType = new NodeItem(nodeName,node);
    			} else if ( nodeName == 'CouponNumber' ){
    				CouponNumber = new NodeItem(nodeName,node);
    			} else if ( nodeName == 'CouponIssueDate' ){
    				CouponIssueDate = new NodeItem(nodeName,node);
    			}
    		}
    	}
    	public String generalXml(String mailBody) {
    		String xmlBody = '';
    		if (CouponAmount != null) xmlBody += CouponAmount.toXml(CouponAmount.getValue(mailBody));
    		if (CouponType != null) xmlBody += CouponType.toXml(CouponType.getValue(mailBody));
    		if (CouponNumber != null) xmlBody += CouponNumber.toXml(CouponNumber.getValue(mailBody));
    		if (CouponIssueDate != null) xmlBody += CouponIssueDate.toXml(CouponIssueDate.getValue(mailBody));
	    	
	    	if(!CommUtils.isBlank(xmlBody))
	    	 	xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
	    	return xmlBody;
    	}
    }
    class RoomAndGuestInformationDef extends XmlBase{
    	public RoomAndGuestInformationDef(Dom.XMLNode parentNode) {
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		orderType = CommUtils.nullToIntZero(parentNode.getAttribute('orderType',null));
    		splitTag = CommUtils.nullToBlank(parentNode.getAttribute('SPLIT_TAG',null));
    		
    		tagName = parentNode.getName();

			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'RoomInformation') {
    				RoomInformation = new RoomInformationDef(xmlNode);
    			} else if (nodeName == 'RoomRateInformation') {
    				RoomRateInformation = new RoomRateInformationDef(xmlNode);
    			} else if (nodeName == 'GuestInformation' ) {
    				GuestInformation = new GuestInformationDef(xmlNode);
    			}
			}
    	}
    	public RoomInformationDef RoomInformation{get;set;}
    	public RoomRateInformationDef RoomRateInformation{get;set;}
    	public GuestInformationDef GuestInformation{get;set;}
    	public Integer orderType{get;set;}
    	public String splitTag{get;set;}
    	public Integer nights{get;set;}
    	public Integer rooms{get;set;}	// 部屋数
		public String generalXml(String mailBody) {
			String xmlBody = '<' + tagName + '>\n';
			String[] splitKeys = new String[]{'',''};
			if(!CommUtils.isBlank(splitTag)){
				String[] splitKeyWk = splitTag.split(',');
				if (splitKeyWk.size() > 0) splitKeys[0] = splitKeyWk[0];
				if (splitKeyWk.size() > 1) splitKeys[1] = splitKeyWk[1];
			}
			List<List<String>> firstLst = new List<List<String>>();
			
			String[] mailContents = mailBody.split(splitKeys[0]);
			nights = 0;
			rooms = 0;
			
			Map<String,List<string>> mainkeyMap = new Map<String,List<string>>();
	    	if(RoomInformation.PerRoomPaxCount != null){
	    		List<String> mainKey = RoomInformation.PerRoomPaxCount.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('PerRoomPaxCount',mainKey);
//system.debug(logginglevel.info,'mainKey:::' + mainKey);
	    	}
	    	if(RoomInformation.RoomPaxMaleCount != null){
	    		List<String> mainKey = RoomInformation.RoomPaxMaleCount.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomPaxMaleCount',mainKey);
	    	}
	    	if(RoomInformation.RoomPaxFemaleCount != null){
	    		List<String> mainKey = RoomInformation.RoomPaxFemaleCount.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomPaxFemaleCount',mainKey);
	    	}
	    	if(RoomInformation.RoomChildA70Count != null){
	    		List<String> mainKey = RoomInformation.RoomChildA70Count.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomChildA70Count',mainKey);
	    	}
	    	if(RoomInformation.RoomChildB50Count != null){
	    		List<String> mainKey = RoomInformation.RoomChildB50Count.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomChildB50Count',mainKey);
	    	}
	    	if(RoomInformation.RoomChildC30Count != null){
	    		List<String> mainKey = RoomInformation.RoomChildC30Count.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomChildC30Count',mainKey);
	    	}
	    	if(RoomInformation.RoomChildDNoneCount != null){
	    		List<String> mainKey = RoomInformation.RoomChildDNoneCount.getEmailTags();
	    		if(!mainKey.isEmpty()) mainkeyMap.put('RoomChildDNoneCount',mainKey);
	    	}
//system.debug(logginglevel.info,'mainkeyMap:::' + mainkeyMap);
			
			// 到着日
			// 1:順番は日付ー＞部屋順
			// 2:順番は部屋ー＞日付順
			Date curDate = CommUtils.stringToDate(BasicInformation.CheckInDate.value);
			for(String mailContent : mailContents){
//System.debug(logginglevel.INFo, 'mailContent=' +mailContent);
				// 次のLOOP
				String[] detailContents = mailContent.split(splitKeys[1]);
				List<String> secondLst = new List<String>();
				
				for(String detailContent : detailContents){
//System.debug(logginglevel.INFo, 'detailContent=' +detailContent);
					String rateCon = '';
					rateCon = generalXmlRoomAndGuest(detailContent,mainkeyMap,RoomInformation,RoomRateInformation);
					if(curDate != null && !CommUtils.isBlank(rateCon)){
						NodeItem RoomDate = new NodeItem('RoomDate');
System.debug(logginglevel.INFo, 'RoomDate.toBlankNodeXml()=' +RoomDate.toBlankNodeXml());
						rateCon = rateCon.replaceAll(RoomDate.toBlankNodeXml(),RoomDate.toXml(curDate.addDays(nights).format()));
						if(orderType == 2) nights++;
					}
					if (GuestInformation != null){
						GuestInformationDef GuestInformationClone = GuestInformation.clone();
						rateCon += GuestInformationClone.generalXml(detailContent);	 
					}
					if(!CommUtils.isBlank(rateCon)){
						secondLst.add(rateCon);
					}
				}
				if(!secondLst.isEmpty()){
					if(orderType == 2) nights = 0;
					else nights++;
					firstLst.add(secondLst);
				}
			}
			
			// 1:順番は日付ー＞部屋順
			// 2:順番は部屋ー＞日付順
			// →作成の目標：N部屋→１泊目、N部屋→２泊目
			if(orderType == 1){
				nights = firstLst.size();
				if (nights > 0) rooms = firstLst[0].size();
				for(List<String> child : firstLst){
					for(String content : child){
						//system.debug(logginglevel.info,'content:::' + content);
						xmlBody += '<RoomAndGuestList>\n' + content + '</RoomAndGuestList>\n';
					}
				}
			} else if(orderType == 2){
				rooms = firstLst.size();
				if (rooms > 0) nights = firstLst[0].size();
				for(integer i = 0; i < nights;i++){
					for (integer j = 0; j < rooms; j++) {
						List<String> oneRoomNdays = firstLst[j];
						xmlBody += '<RoomAndGuestList>\n' + oneRoomNdays[i] + '</RoomAndGuestList>\n';
					}
				}
			}
//System.debug(loggingLevel.INFO, 'xmlBody:::' + xmlBody);
			return xmlBody + '</' + tagName + '>\n';
		}
		private String generalXmlRoomAndGuest(String mailContent, Map<String,List<string>> mainkeyMap , RoomInformationDef RoomInformation , RoomRateInformationDef RoomRateInformation){
	    	String result;
	    	String xmlBody = '';
	    	
	    	boolean continueFlag = true;
	    	String beforeKey;
	    	String afterKey;
	    	List<String> contentLst = new List<String>();
	    	Map<String , List<String>> countMap = new Map<String , List<String>>();
	    	String content = mailContent;
	    	integer beginIdx = 0;
	    	integer lastIdx; 
	    	while(continueFlag){
	    		
	    		Map<Integer,String> minMainKey = new Map<Integer,String>();
	    		Map<Integer,String> tagNameMap = new Map<Integer,String>();
	    		for(String key : mainkeyMap.keySet()){
	    			List<String> mainKeyLst = mainkeyMap.get(key);
	    			
	    			for(String mainKey : mainKeyLst){
	    				Integer curIdx = content.indexOf(mainKey);
		    			if(curIdx >= 0){
		    				if(!minMainKey.containsKey(curIdx)) 
		    					minMainKey.put(curIdx,mainKey);
		    				if(!tagNameMap.containsKey(curIdx)) 
		    					tagNameMap.put(curIdx,key);
		    			} else continue;
		    			if ( lastIdx == null) {
		    				lastIdx = curIdx;
		    			} else if(beginIdx >= lastIdx){
		    				if(lastIdx < curIdx){
		    					lastIdx = curIdx;
		    				}
		    			} else if(lastIdx > curIdx && beginIdx < curIdx){
		    				lastIdx = curIdx;
		    			}
	    			}
	    		}

	    		if( lastIdx <= beginIdx) {
	    			continueFlag = false;
	    			if(tagNameMap.containsKey(beginIdx)){
		    			String currentKey = tagNameMap.get(beginIdx);
		    			if(!countMap.containsKey(currentKey))
		    				countMap.put(currentKey,new List<String>());
		    			countMap.get(currentKey).add(content.subString(beginIdx));
	    			}
	    		} else if (lastIdx == null){
	    			continueFlag = false;
	    		}
	    		if(CommUtils.isBlank(beforeKey)) { 
	    			beginIdx = lastIdx;
	    			beforeKey = minMainKey.get(beginIdx);
	    			//beginIdx = content.indexOf(beforeKey)
	    			//content = content.subStringAfter(beforeKey);
	    		} else {
	    			afterKey =  minMainKey.get(lastIdx);
	    			String currentKey = tagNameMap.get(beginIdx);
	    			String currentContent = content.subString(beginIdx,lastIdx);
	    			if(CommUtils.isBlank(currentContent)) continue;
	    			if(!countMap.containsKey(currentKey))
	    				countMap.put(currentKey,new List<String>());
	    			
	    			countMap.get(currentKey).add(currentContent);
	    			beginIdx = 0;
	    			beforeKey = null;
	    			content = content.replace(currentContent,'');
	    		}
	    	}
	    	if(countMap.isEmpty()) return '';
	    	Integer perCountInt = 0;
	    	integer perRoomCountInt = 0;
	    	Integer RoomPaxMaleCountInt = 0;
	    	Integer RoomPaxFemaleCountInt = 0;
	    	Integer RoomChildA70CountInt = 0;
	    	Integer RoomChildB50CountInt = 0;
	    	Integer RoomChildC30CountInt = 0;
	    	Integer RoomChildDNoneCountInt = 0;
	    	String roomCountXml = '';
	    	
	    	List<String> roomRateLst = new List<String>();
	    	Map<String,Integer> roomAndRateMap = new Map<String,Integer>();
	    	for(String key : countMap.keySet()) {
	    		List<String> detailLst = countMap.get(key);
	    		if( !detailLst.isEmpty()){
	    			for(String detailContent : detailLst){
	    				if(key == 'PerRoomPaxCount'){
		    				String value = RoomInformation.PerRoomPaxCount.getValue(detailContent);
		    				Integer countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
		    				perCountInt += countInt;
		    				String rateValue = RoomRateInformation.PerPaxRate.getValue(detailContent);
		    				String perKey = 'PerPaxRate' + '_' + CommUtils.nullToZero(rateValue);
							if(roomAndRateMap.containskey(perKey)) { 
								Integer perCount = roomAndRateMap.get(perKey);
								perCount += countInt;
								roomAndRateMap.put(perKey,perCount);
							} else roomAndRateMap.put(perKey,countInt);
							value = RoomInformation.RoomPaxMaleCount.getValue(detailContent);
							countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
							RoomPaxMaleCountInt += countInt;
							perRoomCountInt += countInt;
							//perCountInt	+= countInt;
							value = RoomInformation.RoomPaxFemaleCount.getValue(detailContent);
							countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
							RoomPaxFemaleCountInt += countInt;
							perRoomCountInt += countInt;
							//perCountInt	+= countInt;
		    			}else if (key == 'RoomChildA70Count') { 
							String value = RoomInformation.RoomChildA70Count.getValue(detailContent);
		    				Integer countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
		    				RoomChildA70CountInt += countInt;
		    				String rateValue = RoomRateInformation.PerChildA70Rate.getValue(detailContent);
		    				String perKey = 'PerChildA70Rate' + '_' + CommUtils.nullToZero(rateValue);
		    				perRoomCountInt += countInt;
							if(roomAndRateMap.containskey(perKey)) { 
								Integer perCount = roomAndRateMap.get(perKey);
								perCount += countInt;
								roomAndRateMap.put(perKey,perCount);
							} else roomAndRateMap.put(perKey,countInt);
	    				}else if (key == 'RoomChildB50Count') {
							String value = RoomInformation.RoomChildB50Count.getValue(detailContent);
		    				Integer countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
		    				RoomChildB50CountInt += countInt;
		    				String rateValue = RoomRateInformation.PerChildB50Rate.getValue(detailContent);
		    				String perKey = 'PerChildB50Rate' + '_' + CommUtils.nullToZero(rateValue);
							if(roomAndRateMap.containskey(perKey)) { 
								Integer perCount = roomAndRateMap.get(perKey);
								perCount += countInt;
								roomAndRateMap.put(perKey,perCount);
							} else roomAndRateMap.put(perKey,countInt);
							perRoomCountInt += countInt;
			    		} else if (key == 'RoomChildC30Count') { 
							String value = RoomInformation.RoomChildC30Count.getValue(detailContent);
		    				Integer countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
		    				RoomChildC30CountInt += countInt;
		    				String rateValue = RoomRateInformation.PerChildC30Rate.getValue(detailContent);
		    				String perKey = 'PerChildC30Rate' + '_' + CommUtils.nullToZero(rateValue);
							if(roomAndRateMap.containskey(perKey)) { 
								Integer perCount = roomAndRateMap.get(perKey);
								perCount += countInt;
								roomAndRateMap.put(perKey,perCount);
							} else roomAndRateMap.put(perKey,countInt);
							perRoomCountInt += countInt;
						} else if (key == 'RoomChildDNoneCount') {
							String value = RoomInformation.RoomChildDNoneCount.getValue(detailContent);
		    				Integer countInt = CommUtils.nullToIntZero(CommUtils.isNumber(value) ? value : '0' );
		    				RoomChildDNoneCountInt += countInt;
		    				String rateValue = RoomRateInformation.PerChildDRate.getValue(detailContent);
		    				String perKey = 'PerChildDRate' + '_' + CommUtils.nullToZero(rateValue);
							if(roomAndRateMap.containskey(perKey)) { 
								Integer perCount = roomAndRateMap.get(perKey);
								perCount += countInt;
								roomAndRateMap.put(perKey,perCount);
							} else roomAndRateMap.put(perKey,countInt);
							perRoomCountInt += countInt;
						}
					}
	    		}
	    	}
system.debug(logginglevel.info,'roomAndRateMap:::' + roomAndRateMap);
	    	if (RoomInformation.SmokingOrNonSmoking != null) xmlBody += RoomInformation.SmokingOrNonSmoking.toXml(RoomInformation.SmokingOrNonSmoking.getValue(mailContent));
	    	
	    	if (RoomPaxMaleCountInt > 0 ) xmlBody += RoomInformation.RoomPaxMaleCount.toXml(String.valueOf(RoomPaxMaleCountInt));
	    	if (RoomPaxFemaleCountInt > 0 ) xmlBody += RoomInformation.RoomPaxFemaleCount.toXml(String.valueOf(RoomPaxFemaleCountInt));
	    	if (RoomChildA70CountInt > 0 ) xmlBody += RoomInformation.RoomChildA70Count.toXml(String.valueOf(RoomChildA70CountInt));
	    	if (RoomChildB50CountInt > 0 ) xmlBody += RoomInformation.RoomChildB50Count.toXml(String.valueOf(RoomChildB50CountInt));
	    	if (RoomChildC30CountInt > 0 ) xmlBody += RoomInformation.RoomChildC30Count.toXml(String.valueOf(RoomChildC30CountInt));
	    	if (RoomChildDNoneCountInt > 0 ) xmlBody += RoomInformation.RoomChildDNoneCount.toXml(String.valueOf(RoomChildDNoneCountInt));
	    	//部屋名と部屋タイプを追加
	    	// 2016/08/01 HTML（Expedia)レイアウトの解析と取り込み by shuu BEGIN
			if (!CommUtils.isBlank(mailContent)){
				NodeItem RoomTypeCode;
				NodeItem RoomTypeName;
				if (BasicInformation.RoomTypeCode != null) RoomTypeCode = BasicInformation.RoomTypeCode.clone();
				if (BasicInformation.RoomTypeName != null) RoomTypeName = BasicInformation.RoomTypeName.clone();
				//detail had rule
				if (RoomInformation.RoomTypeCode != null) RoomTypeCode = RoomInformation.RoomTypeCode.clone();
				if (RoomInformation.RoomTypeName != null) RoomTypeName = RoomInformation.RoomTypeName.clone();
				
				if (RoomTypeCode != null) xmlBody += RoomTypeCode.toXml(RoomTypeCode.value);
				if (RoomTypeName != null) xmlBody += RoomTypeName.toXml(RoomTypeName.value);
			}
			// 2016/08/01 HTML（Expedia)レイアウトの解析と取り込み by shuu END
	    			
			if ( perRoomCountInt > 0 || perCountInt > 0 ) {
				NodeItem paxCountNode = new NodeItem('PerRoomPaxCount');
				if(perRoomCountInt < perCountInt) perRoomCountInt =  perCountInt;
				xmlBody += paxCountNode.toXml(String.valueOf(perRoomCountInt));
			}

			if(!CommUtils.isBlank(xmlBody)){
				xmlBody = '<' + RoomInformation.tagName + '>\n' + xmlBody + '</' + RoomInformation.tagName + '>\n';
				mapToListRate(roomAndRateMap);
				String otherMessage = '';
				if (RoomRateInformation.TotalPerRoomRate != null) otherMessage += RoomRateInformation.TotalPerRoomRate.toXml(RoomRateInformation.TotalPerRoomRate.getValue(mailContent));
				if (RoomRateInformation.TotalRoomHotSpringTax != null) otherMessage += RoomRateInformation.TotalRoomHotSpringTax.toXml(RoomRateInformation.TotalRoomHotSpringTax.getValue(mailContent));
				if (RoomRateInformation.TotalPerRoomServiceFee != null) otherMessage += RoomRateInformation.TotalPerRoomServiceFee.toXml(RoomRateInformation.TotalPerRoomServiceFee.getValue(mailContent));
				
				for( String roomRateStr : roomRateXmlLst){
					if(!CommUtils.isBlank(roomRateStr)) {
						if (RoomRateInformation.RoomDate != null)  roomRateStr += RoomRateInformation.RoomDate.toXml(RoomRateInformation.RoomDate.getValue(mailContent));
						else {
							NodeItem RoomDate = new NodeItem('RoomDate');
							roomRateStr += RoomDate.toBlankNodeXml();
						}
						if (!CommUtils.isBlank(otherMessage)) {
							roomRateStr = otherMessage + roomRateStr;
							otherMessage = '';
						}
						xmlBody += '<' + RoomRateInformation.tagName + '>\n' + roomRateStr + '</' + RoomRateInformation.tagName + '>\n';
					}
				}
			}
    		return xmlBody;
	    }
	    List<String> roomRateXmlLst;
	    private void mapToListRate(Map<String,Integer> roomAndRateMap){
	    	Set<String> processedSet = new Set<String>();
 	    	roomRateXmlLst = new List<String>();
	    	for(String key : roomAndRateMap.keySet()){
	    		String[] result = key.split('_');
	    		String tagName = result[0];
	    		String roomRate = result[1];
	    		Integer perCount = roomAndRateMap.get(key);

	    		if(processedSet.contains(tagName)){
    				for(integer i = 0; i < perCount;i++){
		    			setValue('<' + tagName + '>' + roomRate + '</' + tagName + '>\n',tagName);
		    		}
	    		}else{
	    			setValue('<' + tagName + '>' + roomRate + '</' + tagName + '>\n',tagName);
	    			processedSet.add(tagName);
	    		}
	    		
	    	}
	    }
	     /*
        * 字符串拼接若list中包含节点名 则追加，若不包含则增加字符串
        */
        private void setValue(String parseXml,String leadXmlTag){
        	boolean hadContainsFlag = false;
        	for (integer i = 0 ; i < roomRateXmlLst.size() ; i++){
        		String content = roomRateXmlLst[i] ;
        		if(!content.contains(leadXmlTag)){
					roomRateXmlLst[i] += parseXml;
					hadContainsFlag = true;
					break;
				}
        	}
			if(!hadContainsFlag) roomRateXmlLst.add(parseXml);
        }
    }
    private List<String> contentLst;
    
    
    
    class RoomInformationDef extends XmlBase{
		public RoomInformationDef(Dom.XMLNode parentNode) {
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		splitTag = CommUtils.nullToBlank(parentNode.getAttribute('SPLIT_TAG',null));
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			//if (nodeName == 'RoomTypeCode') {
    			//	RoomTypeCode = new NodeItem(nodeName, xmlNode);
    			//} else if (nodeName == 'RoomTypeName') {
    			//	RoomTypeName = new NodeItem(nodeName, xmlNode);
    			if (nodeName == 'SmokingOrNonSmoking') {
    				SmokingOrNonSmoking = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerRoomPaxCount') {
    				PerRoomPaxCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomPaxMaleCount') {
    				RoomPaxMaleCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomPaxFemaleCount') {
    				RoomPaxFemaleCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomChildA70Count') {
    				RoomChildA70Count = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomChildB50Count') {
    				RoomChildB50Count = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomChildC30Count') {
    				RoomChildC30Count = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RoomChildDNoneCount') {
    				RoomChildDNoneCount = new NodeItem(nodeName, xmlNode);
    			}
			}
    	}
        public NodeItem RoomTypeCode;         	//部屋タイプコード
        public NodeItem RoomTypeName;         	//部屋タイプ名
        public NodeItem SmokingOrNonSmoking;	//喫煙/禁煙
        public NodeItem PerRoomPaxCount;		//1室利用人数
        public NodeItem RoomPaxMaleCount;		//大人人員(男性)
        public NodeItem RoomPaxFemaleCount;		//大人人員(女性)
        public NodeItem RoomChildA70Count;		//子供A人数
    	public NodeItem RoomChildB50Count;		//子供B人数
        public NodeItem RoomChildC30Count;		//子供C人数
        public NodeItem RoomChildDNoneCount;	//子供D人数
        public String splitTag;
    }
    class RoomRateInformationDef extends XmlBase{
		public RoomRateInformationDef(Dom.XMLNode parentNode) {
			
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		splitTag = CommUtils.nullToBlank(parentNode.getAttribute('SPLIT_TAG',null));
    		
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'RoomDate') {
    				RoomDate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerPaxRate') {
    				PerPaxRate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerChildA70Rate') {
    				PerChildA70Rate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerChildB50Rate') {
    				PerChildB50Rate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerChildC30Rate') {
    				PerChildC30Rate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PerChildDRate') {
    				PerChildDRate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalPerRoomRate') {
    				TotalPerRoomRate = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalRoomHotSpringTax') {
    				TotalRoomHotSpringTax = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalPerRoomServiceFee') {
    				TotalPerRoomServiceFee = new NodeItem(nodeName, xmlNode);
    			}
			}
    	}
        public NodeItem RoomDate;
        public NodeItem PerPaxRate;
        public NodeItem PerChildA70Rate;
        public NodeItem PerChildB50Rate;
        public NodeItem PerChildC30Rate;
        public NodeItem PerChildDRate;
        public NodeItem TotalPerRoomRate;
        public NodeItem TotalRoomHotSpringTax;
        public NodeItem TotalPerRoomServiceFee;
        public String splitTag;
        private List<String> contentLst;
        /*
        * 字符串拼接若list中包含节点名 则追加，若不包含则增加字符串
        */
        private void setValue(String parseXml,String leadXmlTag){
        	boolean hadContainsFlag = false;
        	for (integer i = 0 ; i < contentLst.size() ; i++){
        		String content = contentLst[i] ;
        		if(!content.contains(leadXmlTag)){
					contentLst[i] += parseXml;
					hadContainsFlag = true;
					break;
				}
        	}
			if(!hadContainsFlag) contentLst.add(parseXml);
        }
    }
    class GuestInformationDef {
    	List<GuestInformationListDef> GuestInformationList;
    	String tagName;
    	public GuestInformationDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
    		GuestInformationList = new List<GuestInformationListDef>();
    		for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'GuestInformationList') {
    				GuestInformationListDef g = new GuestInformationListDef(xmlNode);
    				GuestInformationList.add(g);
    			}
    		}
    	}
    	public String generalXml(String mailContent) {
    		String xmlBody = '';
			if (GuestInformationList != null) { 
				for(GuestInformationListDef g : GuestInformationList){
					xmlBody += g.generalXml(mailContent);
				}
			}
			if(!CommUtils.isBlank(xmlBody)) {
				xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			}
			return xmlBody;
    	}
    }
    class GuestInformationListDef  extends XmlBase{
    	public NodeItem GuestNameSingleByte;
    	public NodeItem GuestDateOfBirth;
    	public NodeItem GuestKanjiName;
    	public NodeItem GuestGender ;
    	public NodeItem GuestAge;
    	String tagName;
    	public GuestInformationListDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'GuestNameSingleByte') {
    				GuestNameSingleByte = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestDateOfBirth') {
    				GuestDateOfBirth = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestKanjiName') {
    				GuestKanjiName = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestGender') {
    				GuestGender = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GuestAge') {
    				GuestAge = new NodeItem(nodeName, xmlNode);
    			} 
			}
    	}
    	public String generalXml(String mailContent) {
	    	
	    	String xmlBody = '';
			if (GuestNameSingleByte != null) xmlBody += GuestNameSingleByte.toXml(GuestNameSingleByte.getValue(mailContent));
			if (GuestDateOfBirth != null) xmlBody += GuestDateOfBirth.toXml(GuestDateOfBirth.getValue(mailContent));
			if (GuestKanjiName != null) xmlBody += GuestKanjiName.toXml(GuestKanjiName.getValue(mailContent));
			if (GuestGender != null) xmlBody += GuestGender.toXml(GuestGender.getValue(mailContent));
			if (GuestAge != null) xmlBody += GuestAge.toXml(GuestAge.getValue(mailContent));
			// 
			if(!CommUtils.isBlank(xmlBody)) {
				xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			}
			return xmlBody;
    	}
    }
    // ******* 拡張情報の設定 ******
    class RisaplsInformationDef extends XmlBase{
    	public RisaplsCommonInformationDef RisaplsCommonInformation;	// リザプリ情報
    	public AgentNativeInformationDef AgentNativeInformation;	// 旅行サイト独自情報
    	public RisaplsInformationDef(Dom.XMLNode parentNode) {
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		//splitTag = CommUtils.nullToBlank(parentNode.getAttribute('SPLIT_TAG',null));
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'RisaplsCommonInformation') {
    				RisaplsCommonInformation = new RisaplsCommonInformationDef(xmlNode);
    			} else if (nodeName == 'AgentNativeInformation') {
    				AgentNativeInformation = new AgentNativeInformationDef(xmlNode);
				}
			}
    	}
    	public String generalXml(String mailContent, String emailBody) {
    		String xmlBody = '';
    		
    		if (RisaplsCommonInformation != null) {
    			String commonInformationXml = RisaplsCommonInformation.generalXml(mailContent, emailBody);
    			if(!CommUtils.isBlank(commonInformationXml)) xmlBody += commonInformationXml;
    		}
    		if (AgentNativeInformation != null) {
    			String agentNativeInformationXml = AgentNativeInformation.generalXml(mailContent);
    			if(!CommUtils.isBlank(agentNativeInformationXml)) xmlBody += agentNativeInformationXml;
    		}
    		
    		if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
    		return xmlBody;
    	}
    } 
    // リザプリ共通情報
    class RisaplsCommonInformationDef extends XmlBase{
    	public BasicDef Basic;			// 予約基本情報
    	public AllotmentDef Allotment;	// 予約情報
    	public OtherInfoDef OtherInfo;	// オプション情報
    	public BasicRateDef basicRate;
    	public MemberDef member;
    	public List<OptionDef> optionLst;
    	public RisaplsCommonInformationDef(Dom.XMLNode parentNode){
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
    		optionLst = new List<OptionDef>();
    		//splitTag = CommUtils.nullToBlank(parentNode.getAttribute('SPLIT_TAG',null));
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'Basic') {
    				Basic = new BasicDef(xmlNode);
    			} else if (nodeName == 'Allotment') {
    				Allotment = new AllotmentDef(xmlNode);
				} else if (nodeName == 'OtherInfo') {
    				OtherInfo = new OtherInfoDef(xmlNode);
    			} else if (nodeName == 'BasicRate') {
    				basicRate = new BasicRateDef(xmlNode);
    			} else if (nodeName == 'Member'){
    				member = new MemberDef(xmlNode);
    			} else if (nodeName == 'Option'){
    				OptionDef o  = new OptionDef(xmlNode);
    				optionLst.add(o);
system.debug(logginglevel.info,'optionLst:::' + optionLst);
    			}
			}
    	}
    	public String generalXml(String mailContent, String emailBody) {
    		String xmlBody = '';
    		if (Basic != null) {
	    		String basicXml = Basic.generalXml(mailContent, emailBody);
	    		if(!CommUtils.isBlank(basicXml)) xmlBody += basicXml;
    		}
    		
    		if (Allotment != null) {
	    		String AllotmentXml = Allotment.generalXml(mailContent);
	    		if(!CommUtils.isBlank(AllotmentXml)) xmlBody += AllotmentXml;
    		}
    		if (OtherInfo != null) {
	    		String OtherInfoXml = OtherInfo.generalXml(mailContent);
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		//system.debug(logginglevel.info,'member:::' + member);
    		if (member != null) {
	    		String OtherInfoXml = member.generalXml(mailContent);
	    		//system.debug(logginglevel.info,'OtherInfoXml:::' + OtherInfoXml);
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		
    		if (!optionLst.isEmpty()){
    			for(OptionDef o : optionLst){
    				String OtherInfoXml = o.generalXml(mailContent);
	    			if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    			}
    		}
    		if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
    		return xmlBody;
    	}
    }
    class OptionDef extends XmlBase{
    	public NodeItem OptionDate;
    	public NodeItem Name;
    	public NodeItem NameRequest;
    	public NodeItem OptionCount; 
    	public NodeItem OptionRate;
    	public NodeItem OptionCode;
    	private string tagName;
    	public OptionDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
    		for(Dom.XMLNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
	    		if (nodeName == 'OptionDate') {
					OptionDate = new NodeItem(nodeName,xmlNode);
				} else if (nodeName == 'Name') {
					Name = new NodeItem(nodeName,xmlNode);
				} else if (nodeName == 'NameRequest') {
					NameRequest = new NodeItem(nodeName,xmlNode);
				} else if (nodeName == 'OptionCount'){
					OptionCount = new NodeItem(nodeName,xmlNode);
				} else if (nodeName == 'OptionRate'){
					OptionRate = new NodeItem(nodeName,xmlNode);
				} else if (nodeName == 'OptionCode'){
					OptionCode = new NodeItem(nodeName,xmlNode);
				} 
    		}
    	}
    	public String generalXml(String emailBody) {
    		String xmlBody = '';
    		if (OptionDate != null) {
	    		String basicXml = OptionDate.toXml(OptionDate.getValue(emailBody));
	    		if(!CommUtils.isBlank(basicXml)) xmlBody += basicXml;
    		}
    		if (Name != null) {
	    		String OtherInfoXml = Name.toXml(Name.getValue(emailBody));
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		if (NameRequest != null) {
	    		String OtherInfoXml = NameRequest.toXml(NameRequest.getValue(emailBody));
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		if (OptionCount != null) {
	    		String OtherInfoXml = OptionCount.toXml(OptionCount.getValue(emailBody));
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		if (OptionRate != null) {
	    		String OtherInfoXml = OptionRate.toXml(OptionRate.getValue(emailBody));
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		if (OptionCode != null) {
	    		String OtherInfoXml = OptionCode.toXml(OptionCode.getValue(emailBody));
	    		if(!CommUtils.isBlank(OtherInfoXml)) xmlBody += OtherInfoXml;
    		}
    		if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
    		return xmlBody;
    	}
    }
    // 予約基本情報
    class BasicDef extends XmlBase{
    	public NodeItem SalesOfficeCompanyCode;
    	public NodeItem TelegramData;
    	public NodeItem PhoneNumber;
    	public NodeItem Email;
    	public NodeItem PostalCode;
    	public NodeItem Address;
    	/*
    	public NodeItem TotalPaxManCount;
    	public NodeItem BranchFaxNumber;
    	*/
    	// 初期化
    	public BasicDef(Dom.XMLNode parentNode){
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'SalesOfficeCompanyCode') {
    				SalesOfficeCompanyCode = new NodeItem(nodeName, xmlNode);
    			}
    			// else if (nodeName == 'TelegramData') {
    				
    			//} 
    			else if (nodeName == 'PhoneNumber') {
    				PhoneNumber = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'Email') {
    				Email = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PostalCode') {
    				PostalCode = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'Address') {
    				Address = new NodeItem(nodeName, xmlNode);
    			} 
			}
			TelegramData =  new NodeItem('TelegramData');//xmlNode
    	}
    	public String generalXml(String mailContent, String emailBody) {
			String xmlBody = '';
//system.debug(logginglevel.info,'BasicDef:::' + mailContent);
			//String emailBody = TelegramData.getValue(mailContent);
			if (!CommUtils.isBlank(HtmlBody))
			xmlBody += TelegramData.toXml(HtmlBody);
			else xmlBody += TelegramData.toXml(emailBody);

			if (SalesOfficeCompanyCode != null) xmlBody += SalesOfficeCompanyCode.toXml(SalesOfficeCompanyCode.getValue(mailContent));
			//if (TelegramDiv != null) xmlBody += TelegramDiv.toXml(TelegramDiv.getValue(mailContent));
			//if (RoomDate != null) xmlBody += RoomDate.toXml(RoomDate.getValue(mailContent));
			//if (TelegramData != null) 
			//gMailBody.escapeXml()
			if (PhoneNumber != null) xmlBody += PhoneNumber.toXml(PhoneNumber.getValue(mailContent));
			if (Email != null) {
				xmlBody += Email.toXml(Email.getValue(mailContent));
			}
//system.debug(logginglevel.info,'BasicDef:::xmlBody:::' + xmlBody);
			if (PostalCode != null) xmlBody += PostalCode.toXml(PostalCode.getValue(mailContent));
			if (Address != null) xmlBody += Address.toXml(Address.getValue(mailContent));
			//if (BranchFaxNumber != null) xmlBody += BranchFaxNumber.toXml(BranchFaxNumber.getValue(mailContent));
			//if (TotalPaxManCount != null) xmlBody += TotalPaxManCount.toXml(TotalPaxManCount.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
		}
    }
    class MemberDef extends XmlBase{
    	public NodeItem UserName;
    	public NodeItem UserKana;
    	public NodeItem UserTel;
    	public NodeItem UserMailAddr;
    	public NodeItem UserZip;
    	public NodeItem UserAddr;
    	public NodeItem UserCorp;
    	public NodeItem UserDep;
    	
    	public NodeItem UserID;
    	public NodeItem UserGivingPoints;
    	public NodeItem UserUsePoints;
    	public NodeItem UserType;
    	
    	public NodeItem UserDateOfBirth;
    	public NodeItem UserGendar;
    	public NodeItem UserEmergencyPhoneNumber;
    	
    	public NodeItem UserOfficePhone;
    	public NodeItem UserCorpID;
    	public NodeItem UserCorpKana;
    	public NodeItem MemberOfficePostalCode;
    	private String tagName;
    	public MemberDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
    		for(Dom.XMLNode node : parentNode.getChildElements()){
    			String nodeName = node.getName();
    			if (nodeName == 'UserName'){
    				UserName = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserKana') {
    				UserKana = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserTel') {
    				UserTel = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserMailAddr') {
    				UserMailAddr = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserCorp') {
    				UserCorp = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserDep') {
    				UserDep = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserID') {
    				UserID = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserGivingPoints') {
    				UserGivingPoints = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserUsePoints') {
    				UserUsePoints = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserType') {
    				UserType = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserDateOfBirth') {
    				UserDateOfBirth = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserGendar') {
    				UserGendar = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserEmergencyPhoneNumber') {
    				UserEmergencyPhoneNumber = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserOfficePhone') {
    				UserOfficePhone = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserCorpID') {
    				UserCorpID = new NodeItem(nodeName,node);
    			} else if (nodeName == 'UserCorpKana') {
    				UserCorpKana = new NodeItem(nodeName,node);
    			} else if (nodeName == 'MemberOfficePostalCode') {
    				MemberOfficePostalCode = new NodeItem(nodeName,node);
    			}
    		}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
			if (UserName != null) xmlBody += UserName.toXml(UserName.getValue(mailContent));
			if (UserKana != null) xmlBody += UserKana.toXml(UserKana.getValue(mailContent));
			if (UserTel != null) xmlBody += UserTel.toXml(UserTel.getValue(mailContent));
			if (UserMailAddr != null) xmlBody += UserMailAddr.toXml(UserMailAddr.getValue(mailContent));
			if (UserZip != null) xmlBody += UserZip.toXml(UserZip.getValue(mailContent));
			
			if (UserAddr != null) xmlBody += UserAddr.toXml(UserAddr.getValue(mailContent));
			if (UserCorp != null) xmlBody += UserCorp.toXml(UserCorp.getValue(mailContent));
			if (UserDep != null) xmlBody += UserDep.toXml(UserDep.getValue(mailContent));
			
			if (UserID != null) xmlBody += UserID.toXml(UserID.getValue(mailContent));
			if (UserGivingPoints != null) xmlBody += UserGivingPoints.toXml(UserGivingPoints.getValue(mailContent));
			if (UserUsePoints != null) xmlBody += UserUsePoints.toXml(UserUsePoints.getValue(mailContent));
			if (UserType != null) xmlBody += UserType.toXml(UserType.getValue(mailContent));
			if (UserDateOfBirth != null) xmlBody += UserDateOfBirth.toXml(UserDateOfBirth.getValue(mailContent));
			 
			if (UserGendar != null) xmlBody += UserGendar.toXml(UserGendar.getValue(mailContent));
			if (UserEmergencyPhoneNumber != null) xmlBody += UserEmergencyPhoneNumber.toXml(UserEmergencyPhoneNumber.getValue(mailContent));
			if (UserOfficePhone != null) xmlBody += UserOfficePhone.toXml(UserOfficePhone.getValue(mailContent));
			if (UserCorpID != null) xmlBody += UserCorpID.toXml(UserCorpID.getValue(mailContent));
			if (UserCorpKana != null) xmlBody += UserCorpKana.toXml(UserCorpKana.getValue(mailContent));
			if (MemberOfficePostalCode != null) xmlBody += MemberOfficePostalCode.toXml(MemberOfficePostalCode.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
		}
    }
    class AllotmentDef extends XmlBase{
    	public NodeItem AssignDiv;
    	public NodeItem GenderDiv;
    	public NodeItem HandleDiv;
    	public NodeItem RsvUserDiv;
    	public NodeItem UseDiv;
    	public AllotmentDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'AssignDiv') {
    				AssignDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'GenderDiv') {
    				GenderDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'HandleDiv') {
    				HandleDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'RsvUserDiv') {
    				RsvUserDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'UseDiv') {
    				UseDiv = new NodeItem(nodeName, xmlNode);
    			}
			}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
			if (AssignDiv != null) xmlBody += AssignDiv.toXml(AssignDiv.getValue(mailContent));
			if (GenderDiv != null) xmlBody += GenderDiv.toXml(GenderDiv.getValue(mailContent));
			if (HandleDiv != null) xmlBody += HandleDiv.toXml(HandleDiv.getValue(mailContent));
			if (RsvUserDiv != null) xmlBody += RsvUserDiv.toXml(RsvUserDiv.getValue(mailContent));
			if (UseDiv != null) xmlBody += UseDiv.toXml(UseDiv.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    }
    class OtherInfoDef extends XmlBase{
    	public NodeItem GuestRequest;
    	public NodeItem AdditionalInformation;
    	public List<QuestionAndAnswerListDef> QuestionAndAnswerList;
    	private String tagName;
    	public OtherInfoDef(Dom.XMLNode parentNode){
    		QuestionAndAnswerList = new List<QuestionAndAnswerListDef>();
    		for(Dom.XMLNode node : parentNode.getChildElements()){
    			String nodeName = node.getName();
    			if (nodeName == 'GuestRequest'){
    				GuestRequest = new NodeItem(nodeName,node);
    			} else if (nodeName == 'AdditionalInformation') {
    				AdditionalInformation = new NodeItem(nodeName,node);
    			} else if (nodeName == 'QuestionAndAnswerList'){
    				QuestionAndAnswerListDef q = new QuestionAndAnswerListDef(node);
    				QuestionAndAnswerList.add(q);
    			}
    		} 
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
			if (GuestRequest != null) xmlBody += GuestRequest.toXml(GuestRequest.getValue(mailContent));
			if (AdditionalInformation != null) xmlBody += AdditionalInformation.toXml(AdditionalInformation.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    }
    class QuestionAndAnswerListDef extends XmlBase{
    	public NodeItem QuestionToGuest;
    	public NodeItem AnswerToHotel;
    	private string tagName;
    	public QuestionAndAnswerListDef(Dom.XMLNode parentNode){
    		tagName = parentNode.getName();
    		for(Dom.XMLNode node : parentNode.getChildElements()){
    			String nodeName = node.getName();
    			if (nodeName == 'QuestionToGuest'){
    				QuestionToGuest = new NodeItem(nodeName,node);
    			}else if (nodeName == 'AnswerToHotel'){
    				AnswerToHotel = new NodeItem(nodeName,node);
    			}
    		}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			if (QuestionToGuest != null) xmlBody += QuestionToGuest.toXml(QuestionToGuest.getValue(mailContent));
			if (AnswerToHotel != null) xmlBody += AnswerToHotel.toXml(AnswerToHotel.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			
			return xmlBody;
    	}
    }
    class BasicRateDef extends XmlBase{
    	public NodeItem TotalAccomodationServiceCharge;
    	public List<PointsDiscountListDef> PointsDiscountList;
    	public List<DepositListDef> DepositList;
    	private String tagName;
    	public BasicRateDef(Dom.XMLNode parentNode){
    		PointsDiscountList = new List<PointsDiscountListDef>();
    		DepositList = new List<DepositListDef>();
    		tagName = parentNode.getName();
    		for(Dom.XMLNode child : parentNode.getChildElements()){
    			String childName = child.getName();
    			if(childName == 'PointsDiscountList'){
    				PointsDiscountListDef def = new PointsDiscountListDef(child);
    				PointsDiscountList.add(def);
    			}else if(childName == 'DepositList'){
    				DepositListDef def = new DepositListDef(child);
    				DepositList.add(def);
    			}else if(childName == 'TotalAccomodationServiceCharge'){
    				TotalAccomodationServiceCharge = new NodeItem(tagName,child);
    			} 
    		}
    		tagName = parentNode.getName();
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			if(TotalAccomodationServiceCharge != null)xmlBody += TotalAccomodationServiceCharge.getValue(mailContent);
			if(!PointsDiscountList.isEmpty()){
				for(PointsDiscountListDef p : PointsDiscountList)
					if(p != null)
						xmlBody += p.generalXml(mailContent);
			}
			if(!DepositList.isEmpty()){
				for(DepositListDef d : DepositList)
					if(d != null)
						xmlBody += d.generalXml(mailContent);
			}
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			
			return xmlBody;
    	}
    }
    class PointsDiscountListDef extends XmlBase{
    	public NodeItem PointsDiv;
    	public NodeItem PointsDiscountName;
    	public NodeItem PointsDiscount;
    	public PointsDiscountListDef(Dom.XMLNode parentNode){
    		Dom.XMLNode PointsDivNode = parentNode.getChildElement('PointsDiv',null);
    		if(PointsDivNode != null){
    			PointsDiv =  new NodeItem('PointsDiv', PointsDivNode);
    		}
    		Dom.XMLNode PointsDiscountNameNode = parentNode.getChildElement('PointsDiscountName',null);
    		if(PointsDiscountNameNode != null){
    			PointsDiscountName =  new NodeItem('PointsDiscountName', PointsDiscountNameNode);
    		}
    		Dom.XMLNode PointsDiscountNode = parentNode.getChildElement('PointsDiscount',null);
    		if(PointsDiscountNode != null){
    			PointsDiscount =  new NodeItem('PointsDiv', PointsDiscountNode);
    		}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
    		if (PointsDiv != null) {
	    		String content = PointsDiv.toXml(PointsDiv.getValue(mailContent));
	    		if(!CommUtils.isBlank(content)) xmlBody += content;
    		}
    		if (PointsDiscountName != null) {
	    		String content = PointsDiscountName.toXml(PointsDiscountName.getValue(mailContent));
	    		if(!CommUtils.isBlank(content)) xmlBody += content;
    		}
    		if (PointsDiscount != null) {
	    		String content = PointsDiscount.toXml(PointsDiscount.getValue(mailContent));
	    		if(!CommUtils.isBlank(content)) xmlBody += content;
    		}
    		
			return xmlBody;
    	}
    }
    class DepositListDef extends XmlBase{
    	public NodeItem DepositAmount;
    	private String tagName;
    	public DepositListDef(Dom.xmlNode parentNode){
    		tagName = parentNode.getName();
    		for(Dom.xmlNode node : parentNode.getChildElements()){
    			String nodeName = node.getName();
    			if(nodeName == 'DepositAmount'){
    				DepositAmount = new NodeItem(tagName,node);
    			}
    		}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
    		if (DepositAmount != null) {
	    		String content = DepositAmount.toXml(DepositAmount.getValue(mailContent));
	    		if(!CommUtils.isBlank(content)) xmlBody += content;
    		}
    		if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    	
    }
    class AgentNativeInformationDef extends XmlBase{
    	
    	public ExtendDef Extend;	// 独自情報1
    	public ExtendmytripDef Extendmytrip;	// 独自情報2
    	public AgentNativeInformationDef(Dom.XMLNode parentNode){
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'Extend') {
    				Extend = new ExtendDef(xmlNode);
    			} else if (nodeName == 'Extendmytrip') {
    				Extendmytrip = new ExtendmytripDef(xmlNode);
    			}
			}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			
    		if (Extend != null) {
	    		String ExtendXml = Extend.generalXml(mailContent);
	    		if(!CommUtils.isBlank(ExtendXml)) xmlBody += ExtendXml;
    		}
    		if (Extendmytrip != null) {
	    		String ExtendmytripXml = Extendmytrip.generalXml(mailContent);
	    		if(!CommUtils.isBlank(ExtendmytripXml)) xmlBody += ExtendmytripXml;
    		}
    		if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    	
    }
   class ExtendDef extends XmlBase{
        public NodeItem PointDiv;            //ポイント区分
        public NodeItem PointName;               //ポイント名称・補助金名称
        public NodeItem Points;             //ポイント割引金額・補助金額
        public NodeItem TotalAccommodationDecleasePoints;               //割引後の総額
        public NodeItem TotalAccommodationConsumptionTax;               //割引後の総額に対する、消費税額
    	public NodeItem AmountClaimed;
    	public ExtendDef(Dom.XMLNode parentNode){
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'PointDiv') {
    				PointDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'PointName') {
    				PointName = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'Points') {
    				Points = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalAccommodationDecleasePoints') {
    				TotalAccommodationDecleasePoints = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalAccommodationConsumptionTax') {
    				TotalAccommodationConsumptionTax = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'AmountClaimed') {
    				AmountClaimed = new NodeItem(nodeName, xmlNode);
    			}
			}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			if (PointDiv != null) xmlBody += PointDiv.toXml(PointDiv.getValue(mailContent));
			if (PointName != null) xmlBody += PointName.toXml(PointName.getValue(mailContent));
			if (Points != null) xmlBody += Points.toXml(Points.getValue(mailContent));
			if (TotalAccommodationDecleasePoints != null) xmlBody += TotalAccommodationDecleasePoints.toXml(TotalAccommodationDecleasePoints.getValue(mailContent));
			if (TotalAccommodationConsumptionTax != null) xmlBody += TotalAccommodationConsumptionTax.toXml(TotalAccommodationConsumptionTax.getValue(mailContent));
			if (AmountClaimed != null) xmlBody += AmountClaimed.toXml(AmountClaimed.getValue(mailContent));

			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    }
    class ExtendmytripDef extends XmlBase{
    	public NodeItem SettlementDiv;
    	public NodeItem VIPCode;
    	public NodeItem AgoRsvNumber;
    	public NodeItem FromRsvNumber;
    	public NodeItem TodayReserve;
    	public NodeItem TotalMaleCount;
    	public NodeItem TotalFemaleCount;
    	public NodeItem CancellationCharge;
    	public NodeItem CancellationNotice;
    	public ExtendmytripDef(Dom.XMLNode parentNode){
    		startTag = CommUtils.nullToBlank(parentNode.getAttribute('START_TAG',null));
    		endTag = CommUtils.nullToBlank(parentNode.getAttribute('END_TAG',null));
    		tagName = parentNode.getName();
			for(Dom.XmlNode xmlNode : parentNode.getChildElements()){
    			String nodeName = xmlNode.getName();
    			if (nodeName == 'SettlementDiv') {
    				SettlementDiv = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'VIPCode') {
    				VIPCode = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'AgoRsvNumber') {
    				AgoRsvNumber = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'FromRsvNumber') {
    				FromRsvNumber = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TodayReserve') {
    				TodayReserve = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalMaleCount') {
    				TotalMaleCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'TotalFemaleCount') {
    				TotalFemaleCount = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CancellationCharge') {
    				CancellationCharge = new NodeItem(nodeName, xmlNode);
    			} else if (nodeName == 'CancellationNotice') {
    				CancellationNotice = new NodeItem(nodeName, xmlNode);
    			}
			}
    	}
    	public String generalXml(String mailContent) {
			String xmlBody = '';
			if (SettlementDiv != null){ 
				string value = SettlementDiv.getValue(mailContent);
//system.debug(logginglevel.info,'SettlementDiv::value:' + value);
				//if(value == '現地決済' || value == '事前決済') value = '3';
				xmlBody += SettlementDiv.toXml(value);
			}
			if (VIPCode != null) xmlBody += VIPCode.toXml(VIPCode.getValue(mailContent));
			if (AgoRsvNumber != null) xmlBody += AgoRsvNumber.toXml(AgoRsvNumber.getValue(mailContent));
			if (FromRsvNumber != null) xmlBody += FromRsvNumber.toXml(FromRsvNumber.getValue(mailContent));
			if (TodayReserve != null) xmlBody += TodayReserve.toXml(TodayReserve.getValue(mailContent));
			if (TotalMaleCount != null) xmlBody += TotalMaleCount.toXml(TotalMaleCount.getValue(mailContent));
			if (TotalFemaleCount != null) xmlBody += TotalFemaleCount.toXml(TotalFemaleCount.getValue(mailContent));
			if (CancellationCharge != null) xmlBody += CancellationCharge.toXml(CancellationCharge.getValue(mailContent));
    		if (CancellationNotice != null) xmlBody += CancellationNotice.toXml(CancellationNotice.getValue(mailContent));
			
			if(!CommUtils.isBlank(xmlBody)) xmlBody = '<' + tagName + '>\n' + xmlBody + '</' + tagName + '>\n';
			return xmlBody;
    	}
    }
    class CustomerSettingDef{
    	Map<String,Map<String,NodeItem>> nodeItemMap;
    	public CustomerSettingDef(Dom.XMLNode parentNode){
    		nodeItemMap = new Map<String,Map<String,NodeItem>>();
    		for(Dom.XMLNode objDom : parentNode.getChildElements()){
    			Dom.XMLNode nameNode = objDom.getChildElement('NAME',null);
    			String objectName = '';
    			if(nameNode != null){
    				objectName = nameNode.getText();
    			}
    			Map<String,NodeItem> fieldMap = new Map<String,NodeItem>();
    			Dom.XMLNode mapNode = objDom.getChildElement('MAPPINGS',null);
    			for(Dom.XMLNode fieldNode : mapNode.getChildElements()){
    				NodeItem node = new NodeItem('customer',	fieldNode);
    				String fieldName = fieldNode.getAttribute('apiname',null);
    				if (!CommUtils.isBlank(fieldName)) fieldName = fieldName.replaceAll(CommConst.APPOTION_NAMESPACE ,'');
    				fieldMap.put(fieldName,node);
    			}
    			nodeItemMap.put(objectName,fieldMap);
    		}
    	}
    	public Map<String,Map<String,String>> exportNodeItemResult(String mailbody){
    		Map<String,Map<String,String>> result = new Map<String,Map<String,String>>();
    		for(String key : nodeItemMap.keySet()){
    			Map<String,NodeItem> fieldItemMap = nodeItemMap.get(key);
    			Map<String,String> fieldValueMap = new Map<String,String>();
    			for(String field : fieldItemMap.keySet()){
    				String value = fieldItemMap.get(field).getValue(mailbody);
    				if(!CommUtils.isBlank(value))
    					fieldValueMap.put(field,value);
    			}
    			if(!fieldValueMap.isEmpty())
    				result.put(key,fieldValueMap);
    		}
    		return result;
    	}
    }
    
	class NodeItem {
		public NodeItem(String key ) {
			value = '';
			leadXmlTag = key;
			forwardFlag = false;
			saveKeyFlag = false;
			oneRowProcessFlag = false;
			exculdeStr = '';
			operation = '';
			emailType = '';
		}
		public NodeItem(String key, Dom.XMLNode xmlNode) {
			value = '';
			// 取込用XMLタグ値を格納する
			leadXmlTag = key;
			forwardFlag = false;
			saveKeyFlag = false;
			oneRowProcessFlag = false;
			emailType = '' ;
			// 
			fixedVal = CommUtils.nullToBlank(xmlNode.getText());
			 
			childItems = new List<NodeItem>();
			List<Dom.XMLNode> xmlnodes = new List<Dom.XMLNode>{xmlNode};
			Dom.XMLNode operationField = xmlNode.getChildElement('EMAIL_LOGIC', null);
			//含有运算操作的节点进行子节点押入
			if (operationField != null) {
				operation = CommUtils.nullToBlank(operationField.getText());
				xmlnodes = xmlNode.getChildElements();
				for(Dom.XMLNode node : xmlnodes){
					String nodeName = node.getName();
					if(nodeName == 'EMAIL_DETAIL')
						childItems.add(new NodeItem(leadXmlTag, node));
				}
			//不含操作节点的 若是detail默认为or操作
			} else {
				Dom.XMLNode emailTagDetail = xmlNode.getChildElement('EMAIL_DETAIL', null);
				
				if(emailTagDetail != null){
					xmlnodes = xmlNode.getChildElements();
					for(Dom.XMLNode node : xmlnodes){
						childItems.add(new NodeItem(leadXmlTag, node));
					}
				} else {
					Dom.XMLNode emailTagField = xmlNode.getChildElement('EMAIL_TAG', null);
					if (emailTagField != null){ 
						emailTag = CommUtils.nullToBlank(emailTagField.getText());
						forwardFlag = isTrue(emailTagField.getAttribute('forward',null));
						saveKeyFlag = isTrue(emailTagField.getAttribute('saveKey',null));
						oneRowProcessFlag = isTrue(emailTagField.getAttribute('oneRowProcess',null));
					}
					Dom.XMLNode emailTagBegField = xmlNode.getChildElement('EMAIL_BEG', null);
					if (emailTagBegField != null) emailTagBegKey = CommUtils.nullToBlank(emailTagBegField.getText());
					
					Dom.XMLNode emailTagEndField = xmlNode.getChildElement('EMAIL_END', null);
					if (emailTagEndField != null) emailTagEndKey = CommUtils.nullToBlank(emailTagEndField.getText());
		
					Dom.XMLNode emailTagFormatField = xmlNode.getChildElement('EMIAL_TAG_FORMAT', null);
					if (emailTagFormatField != null) emailTagFormat = CommUtils.nullToBlank(emailTagFormatField.getText());
		
					Dom.XMLNode emailTagFormatJoinKeyField = xmlNode.getChildElement('EMAIL_TAG_FORMAT_JOINKEY', null);
					if (emailTagFormatJoinKeyField != null) emailTagFormatJoinKey = CommUtils.nullToBlank(emailTagFormatJoinKeyField.getText());
					
					Dom.XMLNode convertValField = xmlNode.getChildElement('CONVERT_VAL', null);
					if (convertValField != null) convertVal = CommUtils.nullToBlank(convertValField.getText());
				}
			}
			Dom.XMLNode exculdStrField = xmlNode.getChildElement('EMAIL_EXCULDE', null);
			if (exculdStrField != null) exculdeStr = CommUtils.nullToBlank(exculdStrField.getText());
			Dom.XMLNode emailTypeField = xmlNode.getChildElement('EMAIL_TYPE', null);
			if (emailTypeField != null) emailType = CommUtils.nullToBlank(emailTypeField.getText());
			
			
		}
		public NodeItem(String key, String nodeText) {
			leadXmlTag = key;
			value = '';
			exculdeStr = '';
			operation = '';
			forwardFlag = false;
			saveKeyFlag = false;
			oneRowProcessFlag = false;
			emailType = '';
			fixedVal = nodeText;//直接設定値
		}
		public string leadXmlTag{get;set;}		// メールから取得の情報は該当タグ名にXMLを取得する
		public string emailTag{get;set;}		// 該当キーを見つかると、これから以後の文字列は取得対象
		public string emailTagBegKey{get;set;}	
		public string emailTagEndKey{get;set;}	// 該当XML関連情報は該当キーを見つかると、取得完了
		//public Integer subStrLen{get;set;}		// 指定開始から指定の文字数を取得する
		public string emailTagFormat{get;set;}	// 該当タグをParseする正規表現
		public string convertVal{get;set;}
		public string emailTagFormatJoinKey{get;set;}
		public string fixedVal{get;set;}
		public string value{get;set;}
		public string exculdeStr{get;set;}
		public string operation{get;set;}
		public boolean saveKeyFlag{get;set;}
		public boolean forwardFlag{get;set;}
		public boolean oneRowProcessFlag{get;set;}
		public List<NodeItem> childItems{get;set;}
		private String emailType;
		public Boolean isNoConfigKey{get{
			return (CommUtils.isBlank(emailTag) &&
					CommUtils.isBlank(emailTagBegKey) &&
					CommUtils.isBlank(emailTagEndKey) &&
					CommUtils.isBlank(emailTagFormat));
					
		}}
		/*
		public override string toString() {
			return '<'+leadXmlTag+'>';
		}*/
		private boolean isTrue(Object s){
			String result = CommUtils.nullToblank(s);
			if(CommUtils.isBlank(result)) return false;
			if(result.equalsIgnoreCase('true')) return true;
			return false;
		}
		public List<String> getEmailTags(){
			List<String> result = new List<String>();
			if(!CommUtils.isBlank(emailTag)) result.add(emailTag);
			else if(!childItems.isEmpty()){
				for(NodeItem n : childItems){
					List<String> childs = n.getEmailTags();
					if(childs.isEmpty()) continue;
					result.addAll(childs);
				}
			}
			return result;
		}
		Set<integer> hadProcessedSet; 
		public String getDetailValue(String s){
			if (!CommUtils.isBlank(fixedVal)){ 
				value = fixedVal;
				if(saveKeyFlag)
					if(forwardFlag) value = value + emailTag;
					else value = emailTag + value;
				if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
				return value;
			}
			else {
				// 該当項目存在チェックを行う　
				List<NodeItem> checkItems = new List<NodeItem>{this};
				if(childItems != null && !childItems.isEmpty()) checkItems = childItems;
				boolean andFlag = operation == 'AND' ? true : false;
				for(NodeItem item : checkItems){
					
			
					if (item.isNoConfigKey) {
						if (!item.childItems.isEmpty()){
							value = item.getValue(s);
							if(!andFlag) return value;
						}
						continue;
					}
					Integer emailTagIdx = s.indexOf(item.emailTag);
					if(hadProcessedSet.contains(emailTagIdx)) continue;
					String wkStr = CommUtils.nullToBlank(s);
					if (!CommUtils.isBlank(item.emailTag))
						if(forwardFlag) wkStr = wkStr.substringBefore(item.emailTag);
						else  wkStr = wkStr.substringAfter(item.emailTag);
					if (!CommUtils.isBlank(item.emailTagBegKey)) wkStr = wkStr.substringAfter(item.emailTagBegKey);
					
					Integer emailTagBegIdx = s.indexOf(item.emailTagBegKey);
					if(hadProcessedSet.contains(emailTagBegIdx)) continue;
					// End Tag
					if (!CommUtils.isBlank(item.emailTagEndKey)) {
						if (item.emailTagEndKey == '\\n') wkStr = wkStr.substringBefore('\n');
						if (item.emailTagEndKey == '<' || item.emailTagEndKey == '&lt;') wkStr = wkStr.substringBefore('<');
						else wkStr = wkStr.substringBefore(item.emailTagEndKey);
					}
					Integer emailTagEndIdx = s.indexOf(item.emailTagEndKey);
					if(hadProcessedSet.contains(emailTagEndIdx)) continue;
					hadProcessedSet.clear();
					hadProcessedSet.add(emailTagIdx);
					hadProcessedSet.add(emailTagBegIdx);
					hadProcessedSet.add(emailTagEndIdx);
					// Format
					Boolean isFinded = false;
					if (!CommUtils.isBlank(item.emailTagFormat)) {
						String[] formatter = item.emailTagFormat.split(';');
						for (String formatterStr : formatter) {
							Pattern wkPattern = Pattern.Compile(formatterStr);
							Matcher mathch = wkPattern.matcher(wkStr);
							if (mathch.find()) {
								
								// 転換値が存在する場合、転換値から戻る
								if (!CommUtils.isBlank(item.convertVal)) {
									value = item.convertVal;
									if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
									//and 下 进行多次判断
									if(andFlag) continue;
									return value;
								}
								wkStr = '';
								Integer size = mathch.groupCount();
								for (integer i =1; i <= size; i++) {
									wkStr += mathch.group(i);
									if (size > 1 && i < size && !CommUtils.isBlank(item.emailTagFormatJoinKey)) wkStr += item.emailTagFormatJoinKey;
								}	
								//wkStr = mathch.group(0);
								isFinded = true;
								break;
							}
						} // End For
					} else {
						isFinded = true;
					}
					if (isFinded && !CommUtils.isBlank(wkStr)) {
						value = wkStr;
						if(saveKeyFlag)
							if(forwardFlag) value = value + emailTag;
							else value = emailTag + value;
						if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
						return value;
					} 
				}
			} // End Else
			return '';
		}
		public String getValue(String s) {
//System.debug(loggingLevel.INFO, 'TAG::['+leadXmlTag+']');
//System.debug(loggingLevel.INFO, 'STRING::['+s+']');
			if (!CommUtils.isBlank(fixedVal)){ 
				value = fixedVal;
				if(saveKeyFlag)
					if(forwardFlag) value = value + emailTag;
					else value = emailTag + value;
				if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
				return value;
			}
			else {
				// 該当項目存在チェックを行う　
				//Integer startPos = s.IndexOf(emailTag);
				//if (startPos < 0) return '';
				List<NodeItem> checkItems = new List<NodeItem>{this};
				if(childItems != null && !childItems.isEmpty()) checkItems = childItems;
//System.debug(logginglevel.INFO, 'checkItems='+checkItems);	
				boolean andFlag = operation == 'AND' ? true : false;
				for(Integer j = 0 ; j < checkItems.size(); j++){
					NodeItem item = checkItems[j];
					boolean checkLastFlag = j == (checkItems.size() - 1);
					if (item.isNoConfigKey) {
						if (!item.childItems.isEmpty()){
							value = item.getValue(s);
							if(!andFlag || checkLastFlag) 
							return value;
						}
						continue;
					}
//System.debug(logginglevel.INFO, 'ALLINFO='+item);					
					String wkStr = CommUtils.nullToBlank(s);
//System.debug(logginglevel.INFO, 'ORG WKSTR='+wkStr);
					if (!CommUtils.isBlank(item.emailTag)){
						if(wkStr.indexOf(item.emailTag) >= 0){
							if(forwardFlag) wkStr = wkStr.substringBefore(item.emailTag);
							else  wkStr = wkStr.substringAfter(item.emailTag);
						}else continue;
//System.debug(logginglevel.INFO, 'AFTER emailTag='+wkStr);
						if (oneRowProcessFlag) wkStr = wkStr.substringBefore('\n');
					}
					if (!CommUtils.isBlank(item.emailTagBegKey)) { 
						if (item.emailTagBegKey == '\\n') wkStr = wkStr.substringAfter('\n');
						else if (item.emailTagBegKey == '<' || item.emailTagBegKey == '&lt;') wkStr = wkStr.substringAfter('<');
						else if(wkStr.indexOf(item.emailTagBegKey) >= 0)
							wkStr = wkStr.substringAfter(item.emailTagBegKey);
						else continue;
					}
//System.debug(logginglevel.INFO, 'ORG emailTagBegKey='+emailTagBegKey);
//System.debug(logginglevel.INFO, 'AFTER emailTagBegKey='+wkStr);
	
					// End Tag
					//if (!CommUtils.isBlank(emailTagEndKey)) wkStr = wkStr.substringBefore(emailTagEndKey);
					if (!CommUtils.isBlank(item.emailTagEndKey)) {
//System.debug(logginglevel.INFO, 'emailTagEndKey='+emailTagEndKey);
//System.debug(logginglevel.INFO, 'emailTagEndKey EQU \n='+(emailTagEndKey == '\n'));
//System.debug(logginglevel.INFO, 'emailTagEndKey EQU < ='+(emailTagEndKey == '<'));
//System.debug(logginglevel.INFO, 'emailTagEndKey EQU &lt; ='+(emailTagEndKey == '&lt;'));
						if (item.emailTagEndKey == '\\n') wkStr = wkStr.substringBefore('\n');
						else if (item.emailTagEndKey == '<' || item.emailTagEndKey == '&lt;') wkStr = wkStr.substringBefore('<');
						else if(wkStr.indexOf(item.emailTagEndKey) >= 0){
							integer endIdx = wkStr.indexOf(item.emailTagEndKey);
							wkStr = wkStr.substring(0,endIdx);
						}else continue;
					}
//System.debug(logginglevel.INFO, 'AFTER emailTagEndKey='+wkStr);
					// Format
					Boolean isFinded = false;
					if (!CommUtils.isBlank(item.emailTagFormat)) {
						String[] formatter = item.emailTagFormat.split(';');
						for (String formatterStr : formatter) {
//System.debug(logginglevel.INFO, 'emailTagFormat='+formatterStr);
//System.debug(logginglevel.INFO, 'wkStr='+wkStr);
							Pattern wkPattern = Pattern.Compile(formatterStr);
							Matcher mathch = wkPattern.matcher(wkStr);
							if (mathch.find()) {
								
								// 転換値が存在する場合、転換値から戻る
								if (!CommUtils.isBlank(item.convertVal)) {
//System.debug(logginglevel.INFO, 'item.convertVal='+item.convertVal);
									value = item.convertVal;
									if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
									//and 下 进行多次判断
									if(andFlag && !checkLastFlag) { 
										continue;
									}
//System.debug(logginglevel.INFO, 'andFlag:::' + andFlag);
									return value;
								}
								wkStr = '';
								Integer size = mathch.groupCount();
								for (integer i =1; i <= size; i++) {
									wkStr += mathch.group(i);
//System.debug(logginglevel.INFO, 'wkStr FIND='+wkStr);
									if (size > 1 && i < size && !CommUtils.isBlank(item.emailTagFormatJoinKey)) wkStr += item.emailTagFormatJoinKey;
								}	
//System.debug(logginglevel.INFO, 'wkStr[find]='+wkStr);
								//wkStr = mathch.group(0);
								isFinded = true;
								break;
							}
						} // End For
					} else {
						isFinded = true;
					}
					
//System.debug(logginglevel.INFO, 'RETURN VALUE['+leadXmlTag+']='+wkStr);
//System.debug(logginglevel.INFO, 'isFinded VALUE['+isFinded+']');
					if (isFinded && !CommUtils.isBlank(wkStr)) {
						value = wkStr;
						if(saveKeyFlag)
							if(forwardFlag) value = value + emailTag;
							else value = emailTag + value;
						if(!CommUtils.isBlank(exculdeStr) && exculdeStr.contains(value)) value = '';
						return value;
					} 
					/*
					else if(!item.childItems.isEmpty()) {
						System.debug(logginglevel.INFO, 'item.childItems VALUE='+item.childItems);
						//and 下 进行多次判断
						if(andFlag) value = item.getValue(s);
						else return item.getValue(s);
					}*/
					
				}
			} // End Else
			return '';
		}
		public String toXmlChild(String xmlContent) {
			String xmlString = '';
			boolean intTypeFlag = false;
			if(emailType.contains('int')||emailType.contains('num')) intTypeFlag = true;
			if (operation == 'SUM'){
				if(!childItems.isEmpty()){
					Decimal intValue = 0;
					for(NodeItem n : childItems){
						String value = n.getValue(xmlContent);
						if(intTypeFlag)
							intValue += CommUtils.nullToZero(value);
						else
							xmlString += value;
//system.debug(logginglevel.info,'value::::' + value);
					}
					if(intTypeFlag)
					xmlString = String.valueOf(intValue);
				}
			}else{
				xmlString = getValue(xmlContent);
			}
			if (!CommUtils.isBlank(xmlString)) return '<'+leadXmlTag+'>' + xmlString.escapeXml() + '</' + leadXmlTag + '>\n';
			else return '';
		}
		public String toXml(String val) {
			
			if (!CommUtils.isBlank(val)) return '<'+leadXmlTag+'>' + val.escapeXml() + '</' + leadXmlTag + '>\n';
			else return '';
		}
		public String toBlankNodeXml() {
			return '<'+leadXmlTag+'></' + leadXmlTag + '>\n';
		}
		public override string toString() {
			String msg = 'TAG=' + leadXmlTag + '\n' +
						'emailTag=' + emailTag + '\n' +
						'emailTagBegKey=' + emailTagBegKey + '\n' +
						'emailTagEndKey=' + emailTagEndKey + '\n' +
						'emailTagFormat=' + emailTagFormat + '\n' +
						'convertVal=' + convertVal + '\n' +
						'emailTagFormatJoinKey=' + emailTagFormatJoinKey + '\n'+
						'fixedVal=' + fixedVal + '\n';	
			return msg;
		}
	}
	private String htmlBodyStr;
	/** MAIL PARSE **/
	public String parseMailToXml(String emailBody) {
		//
		if (!CommUtils.isBlank(htmlBodyStr)) HtmlBody = htmlBodyStr;
		String resultXml = '<AllotmentBookingReport>\n';
		// 基本情報からParseする　
		String parserXmlSection = emailBody;
		if (!CommUtils.isBlank(TransactionType.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(TransactionType.startTag);
		}
		if (!CommUtils.isBlank(TransactionType.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(TransactionType.endTag);
		}
		String TransactionTypeSecXml = TransactionType.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'TransactionTypeSecXml=' + TransactionTypeSecXml);
		resultXml += TransactionTypeSecXml + '\n';

		// 宿泊施設と旅行会社情報の設定
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(AccommodationInformation.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(AccommodationInformation.startTag);
		}
		if (!CommUtils.isBlank(AccommodationInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(AccommodationInformation.endTag);
		}
		String AccommodationInformationSecXml = AccommodationInformation.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'AccommodationInformationSecXml=' + AccommodationInformationSecXml);
		resultXml += AccommodationInformationSecXml + '\n';
		
		// 宿泊施設と旅行会社情報の設定
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(SalesOfficeInformation.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(SalesOfficeInformation.startTag);
		}
		if (!CommUtils.isBlank(SalesOfficeInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(SalesOfficeInformation.endTag);
		}
		String SalesOfficeInformationSecXml = SalesOfficeInformation.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'SalesOfficeInformationSecXml=' + SalesOfficeInformationSecXml);
		resultXml += SalesOfficeInformationSecXml + '\n';
		
		// 基本情報
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(BasicInformation.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(BasicInformation.startTag);
		}
		if (!CommUtils.isBlank(BasicInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(BasicInformation.endTag);
		}
		String BasicInformationSecXml = BasicInformation.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'BasicInformation=' + BasicInformation);
		resultXml += BasicInformationSecXml + '\n';
		
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(BasicRateInformation.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(BasicRateInformation.startTag);
		}
		if (!CommUtils.isBlank(BasicRateInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(BasicRateInformation.endTag);
		}
		String BasicRateInformationSecXml = BasicRateInformation.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'BasicRateInformationSecXml=' + BasicRateInformationSecXml);
		resultXml += BasicRateInformationSecXml + '\n';
		
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(RoomAndGuestInformation.startTag)) {
//System.debug(loggingLevel.INFO, 'RoomAndGuestInformation.startTag=' + RoomAndGuestInformation.startTag);	
			parserXmlSection = parserXmlSection.substringAfter(RoomAndGuestInformation.startTag);
		}
		if (!CommUtils.isBlank(RoomAndGuestInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(RoomAndGuestInformation.endTag);
		}
//System.debug(loggingLevel.INFO, 'parserXmlSection=' + parserXmlSection);	
		String RoomAndGuestInformationSecXml = RoomAndGuestInformation.generalXml(parserXmlSection);
//System.debug(loggingLevel.INFO, 'RoomAndGuestInformationSecXml=' + RoomAndGuestInformationSecXml);
		resultXml += RoomAndGuestInformationSecXml + '\n';
		
		parserXmlSection = emailBody;
		if (!CommUtils.isBlank(RisaplsInformation.startTag)) {
			parserXmlSection = parserXmlSection.substringAfter(RisaplsInformation.startTag);
		}
		if (!CommUtils.isBlank(RisaplsInformation.endTag)) {
			parserXmlSection = parserXmlSection.substringBefore(RisaplsInformation.endTag);
		}
		String RisaplsInformationSecXml = RisaplsInformation.generalXml(parserXmlSection, emailBody);
//System.debug(loggingLevel.INFO, 'RisaplsInformationSecXml=' + RisaplsInformationSecXml);
		resultXml += RisaplsInformationSecXml + '\n';	
		NodeItem nights = BasicInformation.Nights;
		// 2017/11/15 ０泊の場合対応　by　zy BEGIN
		if(nights == null || CommUtils.isBlank(nights.value)){
			Integer otherNight = RoomAndGuestInformation.nights;
			if (!CommUtils.isBlank(BasicInformation.checkInDateStr) && !CommUtils.isBlank(BasicInformation.checkOutDateStr) && BasicInformation.checkInDateStr == BasicInformation.checkOutDateStr) 
				otherNight = 0;
			resultXml = resultXml.replace(nights.toBlankNodeXml(),nights.clone().toXml(CommUtils.nullToblank(otherNight)));
		}
		// 2017/11/15 ０泊の場合対応　by　zy END
		NodeItem TotalRoomCount = BasicInformation.TotalRoomCount;
		if(TotalRoomCount == null || CommUtils.isBlank(TotalRoomCount.value)){
			resultXml = resultXml.replace(TotalRoomCount.toBlankNodeXml(),TotalRoomCount.clone().toXml(CommUtils.nullToblank(RoomAndGuestInformation.rooms)));
		}
		// 関連項目のチェックと自動設定
		if (CustomerSetting != null) customerFieldMap = CustomerSetting.exportNodeItemResult(emailBody);
		
		return resultXml+'</AllotmentBookingReport>';
	}
	public void setHtmlBody(String content){
		htmlBodyStr = content;
	}
}