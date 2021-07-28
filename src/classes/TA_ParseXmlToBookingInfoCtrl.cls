public with sharing class TA_ParseXmlToBookingInfoCtrl {
	public TA_ParseXmlToBookingInfoCtrl() {
		mLogUtils = new CommLogUtils('TA_ParseXmlToBookingInfoCtrl',true); 
	}
    public CommLogUtils mLogUtils{get; private set;}
    public TA_LeadInfoSync.BI_TA_SyncInfo parse(String strXmlBodyS,String shopCodeS){	 		
			mLogUtils.write_method_start('parse');	
			TA_LeadInfoSync.BI_TA_SyncResult rs = new TA_LeadInfoSync.BI_TA_SyncResult();		
			TA_LeadInfoSync.BI_TA_SyncInfo bookingInfo = new TA_LeadInfoSync.BI_TA_SyncInfo();
	    	// String -> XML OBJECT    	 
			Dom.Document doc = new Dom.Document();
			doc.load(strXmlBodyS);
			Dom.XMLNode allotmentBookingReportNode = doc.getRootElement();
			/*			
   	        if(transactionInformationNode != null){ 
				bookingInfo.EndFlag = CommUtils.nullToBlank(getChildElementByName(transactionInformationNode,'EndFlag'));
	          	String DataID = CommUtils.nullToBlank(getChildElementByName(transactionInformationNode,'DataID'));
	            if(!CommUtils.isBlank(DataID)){
	            	 String[] ws = DataID.split('-');
		            if(!ws.isEmpty()) 
		            	bookingInfo.DataID = ws[0];
		            else
		            	bookingInfo.DataID = DataID;
	            } 
			}*/ 
			  	 		
   	       if(allotmentBookingReportNode != null){   
				for(Dom.XMLNode childNode : allotmentBookingReportNode.getChildElements()){
				   if(childNode.getName().equalsIgnoreCase('TransactionType')){						   	 
						Dom.XMLNode transactionTypeNode = childNode;
						if(transactionTypeNode != null){
							bookingInfo.transactionType.DataFrom = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataFrom'));
							bookingInfo.transactionType.DataClassification = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataClassification'));
							bookingInfo.transactionType.SystemDate = CommUtils.stringToDate(getChildElementByName(transactionTypeNode,'SystemDate')); 
							bookingInfo.transactionType.SystemTime = CommUtils.stringToTime(getChildElementByName(transactionTypeNode,'SystemTime'));				
				    		bookingInfo.DataID = convertDataId(CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'BookingDataID')));
				    		checkDmlAction(bookingInfo);
				    	}
				    	mLogUtils.write_log('情報区分パーサー完了');
					}				
								
					if(childNode.getName().equalsIgnoreCase('AccommodationInformation')){
						Dom.XMLNode accommodationNode = childNode;
						if(accommodationNode != null){
							bookingInfo.accommodation.AccommodationName = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationName'));
							bookingInfo.accommodation.AccommodationCode = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationCode'));						
				    	}
				    	mLogUtils.write_log('宿泊施設側情報パーサー完了');
					}

					if(childNode.getName().equalsIgnoreCase('SalesOfficeInformation')){
						Dom.XMLNode salesOfficeNode = childNode;
						if(salesOfficeNode != null){
							bookingInfo.salesOffice.SalesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCompanyCode'));
							bookingInfo.salesOffice.SalesOfficeCompanyName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCompanyName'));
							bookingInfo.salesOffice.SalesOfficeName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeName'));
							bookingInfo.salesOffice.SalesOfficeCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCode'));	
							bookingInfo.salesOffice.SalesOfficePersonInCharge = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficePersonInCharge'));
							bookingInfo.salesOffice.SalesOfficePhoneNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficePhoneNumber'));							
				    	}
				    	mLogUtils.write_log('旅行会社情報報パーサー完了');
					}	
					
					if(childNode.getName().equalsIgnoreCase('BasicInformation')){
						Dom.XMLNode basicNode = childNode;
						if(basicNode != null){
							bookingInfo.basic.TravelAgencyBookingNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'TravelAgencyBookingNumber'));
							bookingInfo.basic.TravelAgencyBookingDate = CommUtils.stringToDate(getChildElementByName(basicNode,'TravelAgencyBookingDate'));
							bookingInfo.basic.TravelAgencyBookingTime = CommUtils.stringToTime(getChildElementByName(basicNode,'TravelAgencyBookingTime'));
							bookingInfo.basic.GuestOrGroupNameSingleByte = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameSingleByte'));	
							bookingInfo.basic.GuestOrGroupNameDoubleByte = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameDoubleByte'));
							bookingInfo.basic.GuestOrGroupNameKanjiName = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameKanjiName'));	
							bookingInfo.basic.CheckInDate = CommUtils.stringToDate(getChildElementByName(basicNode,'CheckInDate'));
							//bookingInfo.basic.CheckInTime = CommUtils.stringToTime(getChildElementByName(basicNode,'CheckInTime'));
							//bookingInfo.basic.CheckInTime = CommUtils.stringToTimeOrNull(getChildElementByName(basicNode,'CheckInTime'));
							bookingInfo.basic.CheckInTime = stringToTimeOrNull(getChildElementByName(basicNode,'CheckInTime'));
							bookingInfo.basic.CheckOutDate = CommUtils.stringToDate(getChildElementByName(basicNode,'CheckOutDate'));
							bookingInfo.basic.Nights = CommUtils.nullToIntZero(getChildElementByName(basicNode,'Nights'));	
							bookingInfo.basic.PackagePlanName = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackagePlanName'));
							// 2016/06/27 bug plan length > 80 insert excepiton fix by shuu begin
							if (bookingInfo.basic.PackagePlanName.length() > 80)
								bookingInfo.basic.PackagePlanName =  bookingInfo.basic.PackagePlanName.subString(0,80);
							// 2016/06/27 bug plan length > 80 insert excepiton fix by shuu end
							bookingInfo.basic.PackagePlanCode = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackagePlanCode'));	
							bookingInfo.basic.SpecialServiceRequest = CommUtils.nullToBlank(getChildElementByName(basicNode,'SpecialServiceRequest'));
							bookingInfo.basic.OtherServiceInformation = CommUtils.nullToBlank(getChildElementByName(basicNode,'OtherServiceInformation'));						
				    	}
				    	mLogUtils.write_log('基本宿泊情報 パーサー完了');
					}	
					if(childNode.getName().equalsIgnoreCase('BasicRateInformation')){
						Dom.XMLNode basicRateNode = childNode;
						if(basicRateNode != null){
							bookingInfo.basicRate.RoomRateOrPersonalRate = CommUtils.nullToBlank(getChildElementByName(basicRateNode,'RoomRateOrPersonalRate'));
							bookingInfo.basicRate.TaxServiceFee = CommUtils.nullToBlank(getChildElementByName(basicRateNode,'TaxServiceFee'));
							// 税区分変換を行う
						  	bookingInfo.basicRate.TaxServiceFee = convertTaxKbn(bookingInfo);
							bookingInfo.basicRate.Payment = CommUtils.nullToBlank(getChildElementByName(basicRateNode,'Payment'));
							bookingInfo.basicRate.TotalAccommodationCharge = CommUtils.nullToZero(getChildElementByName(basicRateNode,'TotalAccommodationCharge'));						
				    	}
				    	mLogUtils.write_log('基本情報 パーサー完了');
					}
					if(childNode.getName().equalsIgnoreCase('RoomAndGuestInformation')){
						Dom.XMLNode RoomAndGuestInfoNode = childNode;
						if(RoomAndGuestInfoNode != null){
							List<TA_LeadInfoSync.BI_TA_RoomAndGuestInfo> roomAndGuestLst = new List<TA_LeadInfoSync.BI_TA_RoomAndGuestInfo>();
								for(Dom.XMLNode node : RoomAndGuestInfoNode.getChildElements()){
									if(node.getName().equalsIgnoreCase('RoomAndGuestList')){
										TA_LeadInfoSync.BI_TA_RoomAndGuestInfo roomAndGuestInfo = new TA_LeadInfoSync.BI_TA_RoomAndGuestInfo();
										for(Dom.Xmlnode childDomNode : node.getChildElements()){						
											if(childDomNode.getName().equalsIgnoreCase('RoomInformation')){
												Dom.XMLNode roomInfoNode = childDomNode;
												TA_LeadInfoSync.BI_TA_RoomInformation roomInfo = new TA_LeadInfoSync.BI_TA_RoomInformation();
												if(roomInfoNode != null){
													roomInfo.RoomTypeCode = CommUtils.nullToBlank(getChildElementByName(roomInfoNode,'RoomTypeCode'));
													roomInfo.RoomTypeName = CommUtils.nullToBlank(getChildElementByName(roomInfoNode,'RoomTypeName'));
													roomInfo.PerRoomPaxCount = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'PerRoomPaxCount')); 
													roomInfo.RoomPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomPaxMaleCount'));
													roomInfo.RoomPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomPaxFemaleCount'));
													roomInfo.RoomChildA70Count = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomChildA70Count'));
													roomInfo.RoomChildB50Count = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomChildB50Count'));
													roomInfo.RoomChildC30Count = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomChildC30Count'));
													roomInfo.RoomChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomChildDNoneCount'));
													roomInfo.RoomChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(roomInfoNode,'RoomChildOtherCount'));	
													roomAndGuestInfo.roomI = roomInfo;																																							     												     	
											     }	
											      
											 }
											 if(childDomNode.getName().equalsIgnoreCase('RoomRateInformation')){
												Dom.XMLNode roomRateNode = childDomNode;
												TA_LeadInfoSync.BI_TA_RoomRateInformation roomRate = new TA_LeadInfoSync.BI_TA_RoomRateInformation();
												if(roomRateNode != null){
													roomRate.RoomDate = CommUtils.stringToDate(getChildElementByName(roomRateNode,'RoomDate'));
													roomRate.PerPaxRate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerPaxRate'));
													roomRate.PerChildA70Rate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerChildA70Rate')); 
													roomRate.PerChildB50Rate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerChildB50Rate'));
													roomRate.PerChildC30Rate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerChildC30Rate'));
													roomRate.PerChildDRate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerChildDRate'));
													roomRate.PerChildOtherRate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'PerChildOtherRate'));
													roomRate.TotalPerRoomRate = CommUtils.strToNullOrNumber(getChildElementByName(roomRateNode,'TotalPerRoomRate'));																						    	
											        roomAndGuestInfo.roomRateLst.add(roomRate);											    												    					    	
											     }
											  }
											  if(childDomNode.getName() == 'GuestInformation'){
												Dom.Xmlnode gusetLstINode = childDomNode;
												if(gusetLstINode != null){
													for(Dom.Xmlnode gusetNode : gusetLstINode.getChildElements()){
														if(gusetNode != null){
															if(gusetNode.getName().equalsIgnoreCase('GuestInformationList')){
																TA_LeadInfoSync.BI_TA_GuestInformation guest = new TA_LeadInfoSync.BI_TA_GuestInformation();
																guest.GuestNameSingleByte = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestNameSingleByte'));										
																guest.GuestSurName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestSurName'));
																guest.GuestKanjiName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestKanjiName'));
																guest.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPhoneNumber'));
																guest.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmergencyPhoneNumber'));
																guest.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmail'));
																guest.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStateProvidence'));	
																guest.GuestPostalCode = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPostalCode'));																   
															    roomAndGuestInfo.guestInfoLst.add(guest);
															}															
														}											   																												
													}													
												}
										     }
										}
										roomAndGuestInfo.guestInfoLst = roomAndGuestInfo.guestInfoLst;
										roomAndGuestInfo.roomRateLst = roomAndGuestInfo.roomRateLst;
										roomAndGuestLst.add(roomAndGuestInfo);
									}
								}
								bookingInfo.roomAndGuestLst = roomAndGuestLst;
								mLogUtils.write_log('￼個々の部屋とお客様情報 パーサー完了');
							}
						}
						
						if(childNode.getName().equalsIgnoreCase('Member')){
							Dom.XMLNode MemberNode = childNode;
							if(MemberNode != null){
								bookingInfo.member.UserName = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserName'));
								bookingInfo.member.UserKana = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserKana'));
								bookingInfo.member.UserTel = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserTel'));
								bookingInfo.member.UserMailAddr = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserMailAddr'));
								bookingInfo.member.UserZip = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserZip'));
								bookingInfo.member.UserAddr = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserAddr'));
								bookingInfo.member.UserCorp = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserCorp'));
								bookingInfo.member.UserGivinPoints = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserGivinPoints'));
								bookingInfo.member.UserUsePoints = CommUtils.nullToBlank(getChildElementByName(MemberNode,'UserUsePoints'));
								bookingInfo.member.TotalAccommodationDecleasePoints = CommUtils.nullToIntZero(getChildElementByName(MemberNode,'TotalAccommodationDecleasePoints'));
								bookingInfo.member.AmountClaimed = CommUtils.nullToIntZero(getChildElementByName(MemberNode,'AmountClaimed'));				
					    	}
					    	mLogUtils.write_log('予約者・会員情報　パーサー完了');
						}
				 }
			}
			//checkDmlAction(bookingInfo);	
		   	mLogUtils.write_method_end();	
		   	System.debug(loggingLevel.INFO, 'パーサーLOG='+mLogUtils.getAllLog());
		   	//System.debug(loggingLevel.INFO,'::::::::::::::::::'+ bookingInfo);         
   	       	return bookingInfo;
    }
    private static String convertDataId(String bookingDataID){
    	return bookingDataID.split('-')[0];
    }
    private static void checkDmlAction(TA_LeadInfoSync.BI_TA_SyncInfo bookingInfo){
		String dataClassification = bookingInfo.transactionType.DataClassification;
		if(dataClassification == 'CancellationReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.CANCEL;
		else if(dataClassification == 'NewBookReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.INS;
		else if(dataClassification == 'ModificationReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.UPD;
			/*
		else if(dataClassification == 'Reconfirmatio')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.CONFIRM;
		else if(dataClassification == 'TejimaiReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.TEJIMA;
		else if(dataClassification == 'IssueReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.ISSUE;
		else if(dataClassification == 'OtherReport')
			bookingInfo.dmlAction = TA_LeadInfoSync.BI_TA_DmlAction.OTHER;*/
	}
	private static string convertTaxKbn(TA_LeadInfoSync.BI_TA_SyncInfo bookingInfo){
		// 税区分変換を行う
		Integer taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB;
		if(bookingInfo.basicRate.TaxServiceFee == 'IncludingServiceWithOutTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP4;
		}else if(bookingInfo.basicRate.TaxServiceFee == 'IncludingServiceAndTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP2;
		}else if(bookingInfo.basicRate.TaxServiceFee == 'WithoutServiceAndTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP3;
		}else if(bookingInfo.basicRate.TaxServiceFee == 'WithoutServiceAndIncludingTax'){
			taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP1;
		}
		return CommUtils.nullToBlank(taxRateKbn);
	}
	private static string getChildElementByName(Dom.XMLNode parentNode,String elementName){
		if (parentNode == null) return null;
		Dom.XMLNode childrenNode = parentNode.getChildElement(elementName, null);
		return getChildElementValue(childrenNode);
	}
	private static String getChildElementValue(Dom.XMLNode childNode) {
		if (childNode == null) return null;
		return CommUtils.nullToBlank(childNode.getText());
	}
	// 2016/07/26 チェックインタイム不具合修正 BEGIN
    public static Time stringToTimeOrNull(String p) {
    	if (String.isEmpty(p)) return null;
    	try {
	        String[] times = new String[]{'0','0'};
	        String[] splits = p.split(':');
	        if (splits.size() == 0) return null;
	        if (splits.size() == 1) {
	        	times[0] = splits[0];
	        } else if (splits.size() >= 2) {
	        	for(Integer i = 0; i < times.size(); i++) times[i] = splits[i].trim();
	        }
	        return Time.newInstance(Integer.valueOf(times[0]), Integer.valueOf(times[1]), 0, 0);
    	} catch (Exception e) {
    		return null;
    	}
    }
	// 2016/07/26 チェックインタイム不具合修正 END
}