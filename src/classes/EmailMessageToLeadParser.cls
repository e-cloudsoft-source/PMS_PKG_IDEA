public with sharing class EmailMessageToLeadParser { 
	public EmailMessageToLeadParser() {}
	public CommLogUtils mLogUtils{get; private set;}
	public EmailMessageToLeadSync.BI_EMAIL_SyncInfo parse(String strXmlBody,String shopCode){
			mLogUtils = new CommLogUtils('EmailMessageToLeadParser',true);
			mLogUtils.write_method_start('parse');
			EmailMessageToLeadSync.BI_EMAIL_SyncResult rs = new EmailMessageToLeadSync.BI_EMAIL_SyncResult();
			EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo = new EmailMessageToLeadSync.BI_EMAIL_SyncInfo();
	    	// String -> XML OBJECT
			Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
			Dom.XMLNode root = doc.getRootElement();
			
			Dom.XMLNode transactionTypeNode,accommodationNode,salesOfficeNode,
						basicNode,rateNode,roomAndGuestNode,risaplsNode;
			
			for(Dom.XMLNode childNode : root.getChildElements()) {
				
				if(childNode.getName() == 'TransactionType'){
					transactionTypeNode = childNode;
				}else
				if(childNode.getName() == 'AccommodationInformation'){
					accommodationNode = childNode;
				}else
				if(childNode.getName() == 'SalesOfficeInformation'){
					salesOfficeNode = childNode;
				}else
				if(childNode.getName() == 'BasicInformation'){
					basicNode = childNode;
				}else
				if(childNode.getName() == 'BasicRateInformation'){
					rateNode = childNode;
				}else
				if(childNode.getName() == 'RoomAndGuestInformation'){
					roomAndGuestNode = childNode;
				}else
				if(childNode.getName() == 'RisaplsInformation'){
					risaplsNode = childNode;
				}
			}
			if(transactionTypeNode != null){ 
				bookingInfo.DataFrom = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataFrom'));
				bookingInfo.DataClassification = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataClassification'));
				String DataID = CommUtils.nullToBlank(getChildElementByName(transactionTypeNode,'DataID'));
	            if(!CommUtils.isBlank(DataID)){
	            	 String[] ws = DataID.split('-');
		            if(!ws.isEmpty())
		            	bookingInfo.DataID = ws[0];
		            else
		            	bookingInfo.DataID = DataID;
	            }
	           
				bookingInfo.SystemDate = CommUtils.stringToDate(getChildElementByName(transactionTypeNode,'SystemDate'));
				bookingInfo.SystimTime = CommUtils.stringToTime(getChildElementByName(transactionTypeNode,'SystimTime'));
				mLogUtils.write_log('情報区分パーサー完了');
			} 
			if(accommodationNode != null){
				bookingInfo.AccommodationName = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationName'));
				bookingInfo.AccommodationCode = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationCode'));
				// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
				bookingInfo.AccommodationArea = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationArea'));					
				bookingInfo.ChainName = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'ChainName'));			
				bookingInfo.AccommodationPersonInCharge = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationPersonInCharge'));			
				bookingInfo.AccommodationEmail = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationEmail'));			
				bookingInfo.AccommodationPhoneNumber = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationPhoneNumber'));
				bookingInfo.AccommodationCPUAddress = CommUtils.nullToBlank(getChildElementByName(accommodationNode,'AccommodationCPUAddress'));
				
				Dom.XMLNode BankLstNode = accommodationNode.getChildElement('BankList', null);
				List<EmailMessageToLeadSync.BI_EMAIL_BankInfo> bankLst = new List<EmailMessageToLeadSync.BI_EMAIL_BankInfo>();
				EmailMessageToLeadSync.BI_EMAIL_BankInfo bank = new EmailMessageToLeadSync.BI_EMAIL_BankInfo();
				if(BankLstNode != null){
					for(Dom.XMLNode childNode : BankLstNode.getChildElements()){						
						bank.BankName = CommUtils.nullToBlank(getChildElementByName(BankLstNode,'BankName'));
						bank.BankAccountNumber = CommUtils.nullToBlank(getChildElementByName(BankLstNode,'BankAccountNumber'));		
						bank.BankBranchName = CommUtils.nullToBlank(getChildElementByName(BankLstNode,'BankBranchName'));		
						bank.BankAccountClassification = CommUtils.nullToBlank(getChildElementByName(BankLstNode,'BankAccountClassification'));		
						bank.BankAccountName = CommUtils.nullToBlank(getChildElementByName(BankLstNode,'BankAccountName'));	
						bankLst.add(bank);
					}
				}				
				mLogUtils.write_log('宿泊施設側情報パーサー完了');
				// 2015/08/07 TL2WAY対応するため、項目追加 END
			}
			if(salesOfficeNode != null){
				bookingInfo.SalesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCompanyCode'));
				bookingInfo.SalesOfficeCompanyName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCompanyName'));
				bookingInfo.SalesOfficeName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeName'));
				bookingInfo.SalesOfficeCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCode'));
				bookingInfo.SalesOfficePersonInCharge = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficePersonInCharge'));
				bookingInfo.SalesOfficeEmail = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeEmail'));
				bookingInfo.SalesOfficePhoneNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficePhoneNumber'));
				bookingInfo.SalesOfficeStateProvidence = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeStateProvidence'));
				bookingInfo.SalesOfficeCityName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCityName'));
				bookingInfo.SalesOfficeAddressLine = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeAddressLine'));
				bookingInfo.SalesOfficeStreetNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeStreetNumber'));
				bookingInfo.SalesOfficePostalCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficePostalCode'));
				// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
				bookingInfo.SalesOfficeRegisteredCategory = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeRegisteredCategory'));			
				bookingInfo.SalesOfficeLicenseNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeLicenseNumber'));			
				bookingInfo.SalesOfficeRegisteredPrefecture = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeRegisteredPrefecture'));			
				bookingInfo.SalesOfficeCPUAddress = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'SalesOfficeCPUAddress'));			
				bookingInfo.RetailerCompanyName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerCompanyName'));			
				bookingInfo.RetailerOfficeName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerOfficeName'));			
				bookingInfo.RetailerOfficeCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerOfficeCode'));			
				bookingInfo.RetailerPersonInCharge = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerPersonInCharge'));			
				bookingInfo.RetailerEmail = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerEmail'));			
				bookingInfo.RetailerPhoneNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerPhoneNumber'));			
				bookingInfo.RetailerStateProvidence = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerStateProvidence'));			
				bookingInfo.RetailerCityName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerCityName'));			
				bookingInfo.RetailerAddressLine = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerAddressLine'));			
				bookingInfo.RetailerStreetNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerStreetNumber'));			
				bookingInfo.RetailerPostalCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerPostalCode'));			
				bookingInfo.RetailerRegisteredCategory = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerRegisteredCategory'));			
				bookingInfo.RetailerLicenseNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerLicenseNumber'));			
				bookingInfo.RetailerRegisteredPrefecture = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode,'RetailerRegisteredPrefecture'));
				// 2015/08/07 TL2WAY対応するため、項目追加 END
				mLogUtils.write_log('旅行会社情報報パーサー完了');
			}
			if(basicNode != null){
				bookingInfo.TravelAgencyBookingNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'TravelAgencyBookingNumber'));
				bookingInfo.TravelAgencyBookingDate = CommUtils.stringToDate(getChildElementByName(basicNode,'TravelAgencyBookingDate'));
				bookingInfo.TravelAgencyBookingTime = CommUtils.stringToTime(getChildElementByName(basicNode,'TravelAgencyBookingTime'));
				bookingInfo.TravelAgencyReportNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'TravelAgencyReportNumber'));
				bookingInfo.GuestOrGroupNameSingleByte = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameSingleByte'));
				bookingInfo.GuestOrGroupNameDoubleByte = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameDoubleByte'));
				bookingInfo.GuestOrGroupNameKanjiName = CommUtils.nullToBlank(getChildElementByName(basicNode,'GuestOrGroupNameKanjiName'));
				bookingInfo.CheckInDate = CommUtils.stringToDate(getChildElementByName(basicNode,'CheckInDate'));
				bookingInfo.CheckInTime = CommUtils.stringToTime(getChildElementByName(basicNode,'CheckInTime'));
				bookingInfo.CheckOutDate = CommUtils.stringToDate(getChildElementByName(basicNode,'CheckOutDate'));
				bookingInfo.CheckOutTime = CommUtils.stringToTime(getChildElementByName(basicNode,'CheckOutTime'));
				bookingInfo.Nights = CommUtils.nullToIntZero(getChildElementByName(basicNode,'Nights'));
				bookingInfo.Transportaion = CommUtils.nullToBlank(getChildElementByName(basicNode,'Transportaion'));
				bookingInfo.TotalRoomCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalRoomCount'));
				bookingInfo.GrandTotalPaxCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'GrandTotalPaxCount'));
				bookingInfo.TotalPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalPaxMaleCount'));
				bookingInfo.TotalPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalPaxFemaleCount'));
				bookingInfo.TotalChildA70Count = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalChildA70Count'));
				bookingInfo.TotalChildB50Count = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalChildB50Count'));
				bookingInfo.TotalChildC30Count = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalChildC30Count'));
				bookingInfo.TotalChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalChildDNoneCount'));
				bookingInfo.PackagePlanName = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackagePlanName'));
				// 改行存在可能性がありますので、個別処理を追加する
				bookingInfo.PackagePlanName = CommUtils.nullToBLank(bookingInfo.PackagePlanName.replace('\n',''));// 改行削除
				// 2016/06/27 bug plan length > 80 insert excepiton fix by shuu begin
				if (bookingInfo.PackagePlanName.length() > 80)
					bookingInfo.PackagePlanName =  bookingInfo.PackagePlanName.subString(0,80);
				// 2016/06/27 bug plan length > 80 insert excepiton fix by shuu end
				bookingInfo.PackagePlanCode = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackagePlanCode'));
				bookingInfo.PackagePlanContent = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackagePlanContent'));
				bookingInfo.MealCondition = CommUtils.nullToBlank(getChildElementByName(basicNode,'MealCondition'));
				bookingInfo.SpecificMealCondition = CommUtils.nullToBlank(getChildElementByName(basicNode,'SpecificMealCondition'));
				bookingInfo.MealPlace = CommUtils.nullToBlank(getChildElementByName(basicNode,'MealPlace'));
				bookingInfo.SpecialServiceRequest = CommUtils.nullToBlank(getChildElementByName(basicNode,'SpecialServiceRequest'));
				bookingInfo.OtherServiceInformation = CommUtils.nullToBlank(getChildElementByName(basicNode,'OtherServiceInformation'));
				// 自動改行対応
				bookingInfo.OtherServiceInformation = bookingInfo.OtherServiceInformation.replace('\n','<br/>');
				bookingInfo.FollowUpInformation = CommUtils.nullToBlank(getChildElementByName(basicNode,'FollowUpInformation'));
				// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
				bookingInfo.AccommodationConfirmationNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'AccommodationConfirmationNumber'));			
				bookingInfo.GroupNameWelcomeBoard = CommUtils.nullToBlank(getChildElementByName(basicNode,'GroupNameWelcomeBoard'));			
				bookingInfo.CoachCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'CoachCount'));			
				bookingInfo.CoachCompany = CommUtils.nullToBlank(getChildElementByName(basicNode,'CoachCompany'));		
				bookingInfo.TotalChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalChildOtherCount'));	
				bookingInfo.TotalTourConductorCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalTourConductorCount'));			
				bookingInfo.TotalCoachDriverCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalCoachDriverCount'));			
				bookingInfo.TotalGuideCount = CommUtils.nullToIntZero(getChildElementByName(basicNode,'TotalGuideCount'));			
				bookingInfo.TypeOfGroup = CommUtils.nullToBlank(getChildElementByName(basicNode,'TypeOfGroup'));			
				bookingInfo.Status = CommUtils.nullToBlank(getChildElementByName(basicNode,'Status'));			
				bookingInfo.PackageType = CommUtils.nullToBlank(getChildElementByName(basicNode,'PackageType'));			
				bookingInfo.BanquetRoom = CommUtils.nullToBlank(getChildElementByName(basicNode,'BanquetRoom'));			
				bookingInfo.ModificationType = CommUtils.nullToBlank(getChildElementByName(basicNode,'ModificationType'));			
				bookingInfo.ModificationPoint = CommUtils.nullToBlank(getChildElementByName(basicNode,'ModificationPoint'));			
				bookingInfo.CancellationNumber = CommUtils.nullToBlank(getChildElementByName(basicNode,'CancellationNumber'));			
				bookingInfo.PreviousPlace = CommUtils.nullToBlank(getChildElementByName(basicNode,'PreviousPlace'));			
				bookingInfo.PreviousAccommodationName = CommUtils.nullToBlank(getChildElementByName(basicNode,'PreviousAccommodationName'));
				// 2015/08/07 TL2WAY対応するため、項目追加 END
				mLogUtils.write_log('基本宿泊情報 パーサー完了');
			}
			if(rateNode != null){
				bookingInfo.CouponLst = new List<EmailMessageToLeadSync.BI_EMAIL_CouponInfo>();
				for(Dom.Xmlnode childNode : rateNode.getChildElements()){
					if(childNode.getName().equalsIgnoreCase('RoomRateOrPersonalRate'))
						bookingInfo.RoomRateOrPersonalRate = CommUtils.nullToBlank(getChildElementByName(rateNode,'RoomRateOrPersonalRate'));
					if(childNode.getName().equalsIgnoreCase('TaxServiceFee')) {
						// 税区分変換を行う
						Integer taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB;
						// XMLの税区分設定情報を取得,SF側の税区分に変換を行う
						String taxServiceFee = CommUtils.nullToBlank(getChildElementValue(childNode));
						if(taxServiceFee == 'IncludingServiceWithOutTax'){
							taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP4;
						}else if(taxServiceFee == 'IncludingServiceAndTax'){
							taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP2;
						}else if(taxServiceFee == 'WithoutServiceAndTax'){
							taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP3;
						}else if(taxServiceFee == 'WithoutServiceAndIncludingTax'){
							taxRateKbn = CommConst.APPOPTION_UTP_DEF_KB_OP1;
						}
					  	bookingInfo.TaxServiceFee = String.valueOf(taxRateKbn);
					}
					if(childNode.getName().equalsIgnoreCase('Payment'))
					  	bookingInfo.Payment = CommUtils.nullToBlank(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('BareNetRate'))
						bookingInfo.BareNetRate = CommUtils.nullToIntZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('CreditCardAuthority'))
						bookingInfo.CreditCardAuthority = CommUtils.nullToBlank(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('CreditCardNumber'))
						bookingInfo.CreditCardNumber = CommUtils.nullToBlank(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationCharge'))
						bookingInfo.TotalAccommodationCharge = CommUtils.nullToZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationHotSpringTax'))
						bookingInfo.TotalAccommodationHotSpringTax = CommUtils.nullToZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationServiceFee'))
						bookingInfo.TotalAccommodationServiceFee = CommUtils.nullToZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationOtherFee'))
						bookingInfo.TotalAccommodationOtherFee = CommUtils.nullToZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('CommissionPercentage'))
						bookingInfo.CommissionPercentage = CommUtils.nullToZero(getChildElementValue(childNode));
					// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
					if(childNode.getName().equalsIgnoreCase('CouponList')){
						EmailMessageToLeadSync.BI_EMAIL_CouponInfo coupon = new EmailMessageToLeadSync.BI_EMAIL_CouponInfo();
						coupon.CouponAmount = CommUtils.nullToZero(getChildElementByName(childNode,'CouponAmount'));
						coupon.CouponType = CommUtils.nullToBlank(getChildElementByName(childNode,'CouponType'));		
						coupon.CouponNumber = CommUtils.nullToBlank(getChildElementByName(childNode,'CouponNumber'));		
						coupon.CouponIssueDate = CommUtils.stringToDate(getChildElementByName(childNode,'CouponIssueDate'));		
						bookingInfo.CouponLst.add(coupon);
					}
					if(childNode.getName().equalsIgnoreCase('CancellationCharge'))
						bookingInfo.CancellationCharge = CommUtils.nullToIntZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('ExpireDate'))
						bookingInfo.ExpireDate = CommUtils.stringToDate(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('CardHolderName'))
						bookingInfo.CardHolderName = CommUtils.nullToBlank(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationConsumptionTax'))
						bookingInfo.TotalAccommodationConsumptionTax = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationHotelTax'))
						bookingInfo.TotalAccommodationHotelTax = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationBreakfastFee'))
						bookingInfo.TotalAccommodationBreakfastFee = CommUtils.nullToIntZero(getChildElementValue(childNode));		
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationCommissionAmount'))
						bookingInfo.TotalAccommodationCommissionAmount = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationCommissionConsumptionTax'))
						bookingInfo.TotalAccommodationCommissionConsumptionTax = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationChargeAfterCheckIn'))
						bookingInfo.TotalAccommodationChargeAfterCheckIn = CommUtils.nullToIntZero(getChildElementValue(childNode));			
					if(childNode.getName().equalsIgnoreCase('TotalBalanceAfterCheckIn'))
						bookingInfo.TotalBalanceAfterCheckIn = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('TotalAccommodationConsumptionAfterCheckIn'))
						bookingInfo.TotalAccommodationConsumptionAfterCheckIn = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					if(childNode.getName().equalsIgnoreCase('CancellationChargeAfterCheckIn'))
						bookingInfo.CancellationChargeAfterCheckIn = CommUtils.nullToIntZero(getChildElementValue(childNode));			
					if(childNode.getName().equalsIgnoreCase('MembershipFee'))
						bookingInfo.MembershipFee = CommUtils.nullToIntZero(getChildElementValue(childNode));
					if(childNode.getName().equalsIgnoreCase('AdjustmentFee'))	
						bookingInfo.AdjustmentFee = CommUtils.nullToIntZero(getChildElementValue(childNode));	
					// 2015/08/07 TL2WAY対応するため、項目追加 END
				}
				mLogUtils.write_log('基本情報 パーサー完了');
			} 
			if(roomAndGuestNode != null){
				List<EmailMessageToLeadSync.BI_EMAIL_RoomAndGuestInfo> roomAndGuestLst = new List<EmailMessageToLeadSync.BI_EMAIL_RoomAndGuestInfo>();
				//roomAndGuestLst; tag = RoomAndGuestList 1-N
				for(Dom.XMLNode childNode : roomAndGuestNode.getChildElements()){
					//system.debug(logginglevel.INFO,'-childNode.getName()---------' + childNode.getName());
					if(childNode.getName().equalsIgnoreCase('RoomAndGuestList')){
						EmailMessageToLeadSync.BI_EMAIL_RoomAndGuestInfo roomAndGuestInfo = new EmailMessageToLeadSync.BI_EMAIL_RoomAndGuestInfo();
						List<EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation> roomRateLst = new List<EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation>();
						List<EmailMessageToLeadSync.BI_EMAIL_GuestInfo> guestLst  = new List<EmailMessageToLeadSync.BI_EMAIL_GuestInfo>();
						for(Dom.XMLNode childDomNode :childNode.getChildElements()){
							//tag - RoomInformation 1-1
							if(childDomNode.getName().equalsIgnoreCase('RoomInformation')){
								Dom.XMLNode roomNode = childDomNode;
								EmailMessageToLeadSync.BI_EMAIL_RoomsInfo room = new EmailMessageToLeadSync.BI_EMAIL_RoomsInfo();
								if(roomNode != null){
									room.RoomTypeCode = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomTypeCode'));
									room.RoomTypeName = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomTypeName'));
									// 改行存在可能性がありますので、個別処理を追加する
									room.RoomTypeName = CommUtils.nullToBLank(room.RoomTypeName.replace('\n',''));// 改行削除
									room.ViewType = CommUtils.nullToBlank(getChildElementByName(roomNode,'ViewType')); 
									room.PerRoomPaxCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'PerRoomPaxCount'));
									room.RoomPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomPaxMaleCount'));
									room.RoomPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomPaxFemaleCount'));
									room.Facilities = CommUtils.nullToBlank(getChildElementByName(roomNode,'Facilities'));
									room.AssignedRoomNumber = CommUtils.nullToBlank(getChildElementByName(roomNode,'AssignedRoomNumber'));
									room.RoomCategory = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomCategory'));
									room.RoomChildA70Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildA70Count'));
									room.RoomChildB50Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildB50Count'));
									room.RoomChildC30Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildC30Count'));
									room.RoomChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildDNoneCount'));
									room.SmokingOrNonSmoking = CommUtils.nullToBlank(getChildElementByName(roomNode,'SmokingOrNonSmoking'));
									// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
									room.RoomChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildOtherCount'));	
									room.RoomByRoomStatus = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomByRoomStatus'));	
									room.RoomByRoomConfirmationNumber = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomByRoomConfirmationNumber'));	
									room.RoomSpecialRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomSpecialRequest'));	
									// 2015/08/07 TL2WAY対応するため、項目追加 END
									roomAndGuestInfo.room = room;
								}
							}
							//tag RoomRateInformation 1:N
							if(childDomNode.getName() == 'RoomRateInformation'){
								Dom.Xmlnode rateInfoNode = childDomNode;
								if(rateInfoNode != null){ 
									//system.debug(logginglevel.INFO,'-rateInfoNode---------' + rateInfoNode);
									EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation rate = new EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation();
									rate.PerChildA70Rate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerChildA70Rate'));
									rate.PerChildB50Rate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerChildB50Rate'));
									rate.PerChildC30Rate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerChildC30Rate'));
									rate.PerChildDRate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerChildDRate'));
									rate.PerPaxRate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerPaxRate'));
									rate.RoomDate = CommUtils.stringToDate(getChildElementByName(rateInfoNode,'RoomDate'));
									rate.TotalPerRoomRate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomRate'));
									rate.TotalPerRoomServiceFee = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomServiceFee'));
									rate.TotalRoomHotSpringTax = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalRoomHotSpringTax'));
									// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN 
									rate.PerChildOtherRate = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'PerChildOtherRate'));	
									rate.TotalPerRoomConsumptionTax = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomConsumptionTax'));	
									rate.TotalPerRoomHotelTax = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomHotelTax'));	
									rate.TotalPerRoomBreakfastFee = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomBreakfastFee'));	
									rate.TotalPerRoomOtherFee = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomOtherFee'));	
									rate.TotalPerRoomCommissionAmount = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomCommissionAmount'));	
									rate.TotalPerRoomCommissionConsumptionTax = CommUtils.nullToZero(getChildElementByName(rateInfoNode,'TotalPerRoomCommissionConsumptionTax'));	
									// 2015/08/07 TL2WAY対応するため、項目追加 END
									roomRateLst.add(rate);
								}
							}
							//tag - GuestInformation 0-1
							if(childDomNode.getName() == 'GuestInformation'){
								Dom.Xmlnode gusetLstNode = childDomNode;
								if(gusetLstNode != null){
									for(Dom.Xmlnode gusetNode : gusetLstNode.getChildElements()){
										if(gusetNode != null){
											if(gusetNode.getName().equalsIgnoreCase('GuestInformationList')){
												EmailMessageToLeadSync.BI_EMAIL_GuestInfo guest = new EmailMessageToLeadSync.BI_EMAIL_GuestInfo();
												guest.GuestAge = CommUtils.nullToIntZero(getChildElementByName(gusetNode,'GuestAge'));
												//guest.GuestDateOfBirthGuestAge = CommUtils.nullToIntZero(gusetNode.getChildElement('GuestDateOfBirthGuestAge', null).getText());
												guest.GuestDateOfBirth = CommUtils.stringToDate(getChildElementByName(gusetNode,'GuestDateOfBirth'));
												guest.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmail'));
												guest.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmergencyPhoneNumber'));
												guest.GuestGender = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestGender'));
												guest.GuestKanjiName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestKanjiName'));
												guest.GuestNameSingleByte = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestNameSingleByte'));
												guest.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPhoneNumber'));
												guest.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStateProvidence'));
												guest.GuestSurName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestSurName'));
												// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
												guest.GuestGivenName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestGivenName'));
												guest.GuestMiddleName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestMiddleName'));
												guest.GuestNamePrefix = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestNamePrefix'));
												guest.GuestType = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestType'));
												guest.GuestShubetsu = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestShubetsu'));
												guest.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPhoneNumber'));
												guest.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmergencyPhoneNumber'));
												guest.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmail'));
												guest.GuestCountry = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCountry'));
												guest.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStateProvidence'));
												guest.GuestCityName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCityName'));
												guest.GuestAddressLine = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestAddressLine'));
												guest.GuestStreetNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStreetNumber'));
												guest.GuestPostalCode = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPostalCode'));
												guest.GuestBuildingName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestBuildingName'));
												guest.GuestFFPCarrier = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestFFPCarrier'));
												guest.GuestFFPNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestFFPNumber'));
												guest.GuestCoachNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCoachNumber'));
												guest.SpecialInformation = CommUtils.nullToBlank(getChildElementByName(gusetNode,'SpecialInformation'));
												// 2015/08/07 TL2WAY対応するため、項目追加 END										
												guestLst.add(guest);
											}
										}
									}
								}
							}
						}
						roomAndGuestInfo.guestLst = guestLst;
						roomAndGuestInfo.roomRateLst = roomRateLst;
						roomAndGuestLst.add(roomAndGuestInfo);
					}
				}
				//system.debug(logginglevel.INFO,'-roomAndGuestLst---------' + roomAndGuestLst);
				bookingInfo.roomAndGuestLst = roomAndGuestLst;
				mLogUtils.write_log('￼個々の部屋とお客様情報 パーサー完了');
			}
			if(risaplsNode != null){
				Dom.XMLNode commonInfoNode = risaplsNode.getChildElement('RisaplsCommonInformation', null);
				EmailMessageToLeadSync.BI_EMAIL_Risaplsinformation risaplsinformation = new EmailMessageToLeadSync.BI_EMAIL_Risaplsinformation();
				// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
				Dom.XMLNode agentNativeInfoNode = risaplsNode.getChildElement('AgentNativeInformation', null);
				EmailMessageToLeadSync.BI_EMAIL_AgentNativeInformation agentNativeInformation = new EmailMessageToLeadSync.BI_EMAIL_AgentNativeInformation();
				// 2015/08/07 TL2WAY対応するため、項目追加 END	
				
				if(commonInfoNode != null){
					EmailMessageToLeadSync.BI_EMAIL_RisaplsCommonInformation risaplsCommonInformation = new EmailMessageToLeadSync.BI_EMAIL_RisaplsCommonInformation();
					EmailMessageToLeadSync.BI_EMAIL_RisaplBasic risaplBasic = new EmailMessageToLeadSync.BI_EMAIL_RisaplBasic();
					EmailMessageToLeadSync.BI_EMAIL_Member member = new EmailMessageToLeadSync.BI_EMAIL_Member();
					Dom.XMLNode basicInfoNode = commonInfoNode.getChildElement('Basic', null);
					Dom.XMLNode memberNode = commonInfoNode.getChildElement('Member', null);
					// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
					EmailMessageToLeadSync.BI_EMAIL_Allotment allotment = new EmailMessageToLeadSync.BI_EMAIL_Allotment();
					Dom.XMLNode allotmentInfoNode = commonInfoNode.getChildElement('Allotment', null);
					
					EmailMessageToLeadSync.BI_EMAIL_OtherInfo otherInfo = new EmailMessageToLeadSync.BI_EMAIL_OtherInfo();
					Dom.XMLNode otherInfoNode = commonInfoNode.getChildElement('OtherInfo', null);
					
					EmailMessageToLeadSync.BI_EMAIL_BasicRate basicRate = new EmailMessageToLeadSync.BI_EMAIL_BasicRate();
					Dom.XMLNode basicRateNode = commonInfoNode.getChildElement('BasicRate', null);
					
					//optionLst
					List<EmailMessageToLeadSync.BI_EMAIL_Option> optionLst = new List<EmailMessageToLeadSync.BI_EMAIL_Option>();
					List<EmailMessageToLeadSync.BI_EMAIL_BlockReport> blockReportLst = new List<EmailMessageToLeadSync.BI_EMAIL_BlockReport>();
					List<EmailMessageToLeadSync.BI_EMAIL_RoomAndRoomRateInformation> roomAndRoomRateInfoLst = new List<EmailMessageToLeadSync.BI_EMAIL_RoomAndRoomRateInformation>();
					EmailMessageToLeadSync.BI_EMAIL_RoomAndRoomRateInformation roomAndRoomRateInfo = new EmailMessageToLeadSync.BI_EMAIL_RoomAndRoomRateInformation();
					for(Dom.XMLNode childNode : commonInfoNode.getChildElements()){
						if(childNode.getName().equalsIgnoreCase('RoomAndRoomRateInformation')){
							List<EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation> roomRateLst = new List<EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation>();	
							List<EmailMessageToLeadSync.BI_EMAIL_GuestInfo> guestLst  = new List<EmailMessageToLeadSync.BI_EMAIL_GuestInfo>();
							EmailMessageToLeadSync.BI_EMAIL_RoomsInfo room = new EmailMessageToLeadSync.BI_EMAIL_RoomsInfo();
							for(Dom.XMLNode roomInfoNode : childNode.getChildElements()){
								if(roomInfoNode.getName() == 'RoomInformation'){
									Dom.XMLNode roomNode = roomInfoNode;
									if(roomNode != null){
										room.RoomTypeCode = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomTypeCode'));
										room.RoomTypeName = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomTypeName'));
										room.ViewType = CommUtils.nullToBlank(getChildElementByName(roomNode,'ViewType')); 
										room.PerRoomPaxCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'PerRoomPaxCount'));
										room.RoomPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomPaxMaleCount'));
										room.RoomPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomPaxFemaleCount'));
										room.Facilities = CommUtils.nullToBlank(getChildElementByName(roomNode,'Facilities'));
										room.AssignedRoomNumber = CommUtils.nullToBlank(getChildElementByName(roomNode,'AssignedRoomNumber'));
										room.RoomCategory = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomCategory'));
										room.RoomChildA70Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildA70Count'));
										room.RoomChildB50Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildB50Count'));
										room.RoomChildC30Count = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildC30Count'));
										room.RoomChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildDNoneCount'));
										room.SmokingOrNonSmoking = CommUtils.nullToBlank(getChildElementByName(roomNode,'SmokingOrNonSmoking'));
										room.RoomChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildOtherCount'));	
										room.RoomChildOtherCount2 = CommUtils.nullToIntZero(getChildElementByName(roomNode,'RoomChildOtherCount2'));
										room.RoomByRoomStatus = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomByRoomStatus'));	
										room.RoomByRoomConfirmationNumber = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomByRoomConfirmationNumber'));	
										room.RoomSpecialRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomSpecialRequest'));	
										room.RoomPaxMaleRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomPaxMaleRequest'));
										room.RoomPaxFemaleRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomPaxFemaleRequest'));
										room.RoomChildA70Request = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildA70Request'));
										room.RoomChildB50Request = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildB50Request'));
										room.RoomChildC30Request = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildC30Request'));
										room.RoomChildDNoneRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildDNoneRequest'));
										room.RoomChildOtherRequest = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildOtherRequest'));
										room.RoomChildOtherRequest2 = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomChildOtherRequest2'));
										room.RoomTypeAgent = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomTypeAgent'));
										room.RoomFrame = CommUtils.nullToBlank(getChildElementByName(roomNode,'RoomFrame'));
										room.NetRmTypeGroupCode = CommUtils.nullToBlank(getChildElementByName(roomNode,'NetRmTypeGroupCode'));
										room.PlanGroupCode = CommUtils.nullToBlank(getChildElementByName(roomNode,'PlanGroupCode'));
										room.RepresentativePersonName = CommUtils.nullToBlank(getChildElementByName(roomNode,'RepresentativePersonName'));
									}
								}
								if(roomInfoNode.getName() == 'RoomRateInformation'){
									Dom.Xmlnode rateInfoNode = roomInfoNode;
									if(rateInfoNode != null){
										EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation rate = new EmailMessageToLeadSync.BI_EMAIL_RoomRateInfomation();
										rate.PerChildA70Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildA70Rate'));
										rate.PerChildB50Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildB50Rate'));
										rate.PerChildC30Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildC30Rate'));
										rate.PerChildDRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildDRate'));
										rate.PerPaxRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerPaxRate'));
										rate.RoomDate = CommUtils.stringToDate(getChildElementByName(rateInfoNode,'RoomDate'));
										rate.TotalPerRoomRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomRate'));
										rate.TotalPerRoomServiceFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomServiceFee'));
										rate.TotalRoomHotSpringTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalRoomHotSpringTax'));
										rate.PerChildOtherRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildOtherRate'));	
										rate.TotalPerRoomConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomConsumptionTax'));	
										rate.TotalPerRoomHotelTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomHotelTax'));	
										rate.TotalPerRoomBreakfastFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomBreakfastFee'));	
										rate.TotalPerRoomOtherFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomOtherFee'));	
										rate.TotalPerRoomCommissionAmount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomCommissionAmount'));	
										rate.TotalPerRoomCommissionConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'TotalPerRoomCommissionConsumptionTax'));	
										rate.PerChildOtherRate2 = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerChildOtherRate'));							
										rate.PerMaleRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerMaleRate'));
										rate.PerFemaleRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'PerFemaleRate'));
										rate.RoomRatePaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRatePaxMaleCount'));
										rate.RoomRatePaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRatePaxFemaleCount'));	
										rate.RoomRateChildA70Count = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRateChildA70Count'));	
										rate.RoomRateChildB50Count = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRateChildB50Count'));	
										rate.RoomRateChildC30Count = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRateChildC30Count'));	
										rate.RoomRateChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode,'RoomRateChildDNoneCount'));																																
										rate.RoomRatePaxMaleRequest = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRatePaxMaleRequest'));
										rate.RoomRatePaxFemaleRequest = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRatePaxFemaleRequest'));
										rate.RoomRateChildA70Request = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRateChildA70Request'));
										rate.RoomRateChildB50Request = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRateChildB50Request'));
										rate.RoomRateChildC30Request = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRateChildC30Request'));
										rate.RoomRateChildDNoneRequest = CommUtils.nullToBlank(getChildElementByName(rateInfoNode,'RoomRateChildDNoneRequest'));						
										roomRateLst.add(rate);
									}
								}
								if(roomInfoNode.getName() == 'GuestInformation'){
									Dom.Xmlnode gusetLstNode = roomInfoNode;
									if(gusetLstNode != null){
										for(Dom.Xmlnode gusetNode : gusetLstNode.getChildElements()){
											if(gusetNode.getName().equalsIgnoreCase('GuestInformationList')){
												EmailMessageToLeadSync.BI_EMAIL_GuestInfo guest = new EmailMessageToLeadSync.BI_EMAIL_GuestInfo();
												guest.GuestAge = CommUtils.nullToIntZero(getChildElementByName(gusetNode,'GuestAge'));
												//guest.GuestDateOfBirthGuestAge = CommUtils.nullToIntZero(gusetNode.getChildElement('GuestDateOfBirthGuestAge', null).getText());
												guest.GuestDateOfBirth = CommUtils.stringToDate(getChildElementByName(gusetNode,'GuestDateOfBirth'));
												guest.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmail'));
												guest.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmergencyPhoneNumber'));
												guest.GuestGender = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestGender'));
												guest.GuestKanjiName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestKanjiName'));
												guest.GuestNameSingleByte = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestNameSingleByte'));
												guest.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPhoneNumber'));
												guest.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStateProvidence'));
												guest.GuestSurName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestSurName'));
												guest.GuestGivenName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestGivenName'));
												guest.GuestMiddleName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestMiddleName'));
												guest.GuestNamePrefix = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestNamePrefix'));
												guest.GuestType = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestType'));
												guest.GuestShubetsu = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestShubetsu'));
												guest.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPhoneNumber'));
												guest.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmergencyPhoneNumber'));
												guest.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestEmail'));
												guest.GuestCountry = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCountry'));
												guest.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStateProvidence'));
												guest.GuestCityName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCityName'));
												guest.GuestAddressLine = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestAddressLine'));
												guest.GuestStreetNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestStreetNumber'));
												guest.GuestPostalCode = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestPostalCode'));
												guest.GuestBuildingName = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestBuildingName'));
												guest.GuestFFPCarrier = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestFFPCarrier'));
												guest.GuestFFPNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestFFPNumber'));
												guest.GuestCoachNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode,'GuestCoachNumber'));
												guest.SpecialInformation = CommUtils.nullToBlank(getChildElementByName(gusetNode,'SpecialInformation'));
												guestLst.add(guest);
											}
										}
									}
								}
								roomAndRoomRateInfo.guestLst = guestLst;
								roomAndRoomRateInfo.room = room;
								roomAndRoomRateInfo.roomRateLst = roomRateLst;
								roomAndRoomRateInfoLst.add(roomAndRoomRateInfo);
							}
						}
						//tag option 
						if(childNode.getName().equalsIgnoreCase('Option')){
							EmailMessageToLeadSync.BI_EMAIL_Option option = new EmailMessageToLeadSync.BI_EMAIL_Option();
							option.OptionDate = CommUtils.stringToDate(getChildElementByName(childNode,'OptionDate'));		
							option.Name = CommUtils.nullToBlank(getChildElementByName(childNode,'Name'));		
							option.NameRequest = CommUtils.nullToBlank(getChildElementByName(childNode,'NameRequest'));		
							option.OptionCount = CommUtils.nullToIntZero(getChildElementByName(childNode,'OptionCount'));		
							option.OptionRate = CommUtils.nullToIntZero(getChildElementByName(childNode,'OptionRate'));		
							option.OptionCode = CommUtils.nullToBlank(getChildElementByName(childNode,'OptionCode'));	
							optionLst.add(option);
						}					
						if(childNode.getName().equalsIgnoreCase('BlockReport')){
							EmailMessageToLeadSync.BI_EMAIL_BlockReport blockReport = new EmailMessageToLeadSync.BI_EMAIL_BlockReport();
							if(childNode != null){
								blockReport.RoomTypeCode = CommUtils.nullToBlank(getChildElementByName(childNode,'RoomTypeCode'));
								blockReport.InquiryDate = CommUtils.nullToBlank(getChildElementByName(childNode,'InquiryDate'));
								blockReport.TotalRoomsBlock = CommUtils.nullToIntZero(getChildElementByName(childNode,'TotalRoomsBlock'));	
								blockReport.TotalRoomsNotYetSold = CommUtils.nullToIntZero(getChildElementByName(childNode,'TotalRoomsNotYetSold'));
								blockReportLst.add(blockReport);
							}
						}
					}
					risaplsCommonInformation.option = optionLst; 
					risaplsCommonInformation.blockReportLst = blockReportLst;
					// 2015/08/07 TL2WAY対応するため、項目追加 END		
							
					if(basicInfoNode != null){
						risaplBasic.AccommodationId = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'AccommodationId'));
						risaplBasic.Address = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'Address'));
						risaplBasic.BranchFaxNumber = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'BranchFaxNumber'));
						risaplBasic.Email = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'Email'));
						risaplBasic.PhoneNumber = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'PhoneNumber'));
						risaplBasic.PostalCode = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'PostalCode'));
						risaplBasic.RepresentativeAge = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeAge'));
						risaplBasic.RepresentativeCellularPhone = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeCellularPhone'));
						risaplBasic.RepresentativeGendar = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeGendar'));
						risaplBasic.RepresentativeGeneration = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeGeneration'));
						risaplBasic.RepresentativeOfficialPhone = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeOfficialPhone'));
						risaplBasic.RepresentativePhoneType = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativePhoneType'));
						risaplBasic.SalesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'SalesOfficeCompanyCode'));
						risaplBasic.TelegramData = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'TelegramData'));
						risaplBasic.TotalPaxManCount = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'TotalPaxManCount'));
						risaplBasic.Version = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'Version'));
						// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
						risaplBasic.TelegramDiv = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'TelegramDiv'));	
						risaplBasic.RisaplsDataID = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RisaplsDataID'));	
						risaplBasic.RisaplsTelegramNumber = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RisaplsTelegramNumber'));	
						risaplBasic.RepresentativeMiddleName = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeMiddleName'));	
						risaplBasic.RepresentativeCorp = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeCorp'));	
						risaplBasic.RepresentativeDep = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeDep'));	
						risaplBasic.RepresentativeOccupation = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeOccupation'));	
						risaplBasic.RepresentativePost = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativePost'));	
						risaplBasic.RepresentativeOfficeAddr = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeOfficeAddr'));	
						risaplBasic.RepresentativeOfficeFAX = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeOfficeFAX'));	
						risaplBasic.RepresentativeID = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeID'));	
						risaplBasic.RepresentativeType = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeType'));	
						risaplBasic.RepresentativeDateOfBirth = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeDateOfBirth'));	
						risaplBasic.RepresentativeMailMagazineFromAccommodation = CommUtils.nullToBlank(getChildElementByName(basicInfoNode,'RepresentativeMailMagazineFromAccommodation'));
						// 2015/08/07 TL2WAY対応するため、項目追加 END							
						risaplsCommonInformation.risaplBasic = risaplBasic;
					}
					if(memberNode != null){
						member.MemberOfficePostalCode = CommUtils.nullToBlank(getChildElementByName(memberNode,'MemberOfficePostalCode'));
						member.UserAddr = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserAddr'));
						member.UserCorp = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserCorp'));
						member.UserCorpID = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserCorpID'));
						member.UserCorpKana = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserCorpKana'));
						member.UserDateOfBirth = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserDateOfBirth'));
						member.UserDep = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserDep'));
						member.UserEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserEmergencyPhoneNumber'));
						member.UserGendar = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserGendar'));
						member.UserGivingPoints = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserGivingPoints'));
						member.UserID = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserID'));
						member.UserKana = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserKana'));
						member.UserMailAddr = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserMailAddr'));
						member.UserName = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserName'));
						member.UserOfficePhone = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserOfficePhone'));
						member.UserTel = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserTel'));
						member.UserType = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserType'));
						member.UserUsePoints = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserUsePoints'));
						member.UserZip = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserZip'));
						// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
						member.UserOccupation = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserOccupation'));
						member.UserMailMagazineFromAccommodation = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserMailMagazineFromAccommodation'));
						member.UserMiddleName = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserMiddleName'));
						member.UserPost = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserPost'));
						member.UserOfficeAddr = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserOfficeAddr'));
						member.UserOfficeFAX = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserOfficeFAX'));
						member.UserTotalPoint = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserTotalPoint'));
						member.UserCorpID = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserCorpID'));
						member.UserCorpKana = CommUtils.nullToBlank(getChildElementByName(memberNode,'UserCorpKana'));
						member.MemberOfficePostalCode = CommUtils.nullToBlank(getChildElementByName(memberNode,'MemberOfficePostalCode'));	
						// 2015/08/07 TL2WAY対応するため、項目追加 END	
						risaplsCommonInformation.member = member;
					}
					// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
					if(allotmentInfoNode != null){
						allotment.AssignDiv = CommUtils.nullToIntZero(getChildElementByName(memberNode,'AssignDiv'));	
						allotment.GenderDiv = CommUtils.nullToIntZero(getChildElementByName(memberNode,'GenderDiv'));	
						allotment.HandleDiv = CommUtils.nullToIntZero(getChildElementByName(memberNode,'HandleDiv'));	
						allotment.RsvUserDiv = CommUtils.nullToIntZero(getChildElementByName(memberNode,'RsvUserDiv'));	
						allotment.UseDiv = CommUtils.nullToIntZero(getChildElementByName(memberNode,'UseDiv'));
						risaplsCommonInformation.allotment = allotment;							
					}
					
					if(otherInfoNode != null){
						Dom.XMLNode QuestionAndAnswerLstNode = otherInfoNode.getChildElement('QuestionAndAnswerList', null);
						List<EmailMessageToLeadSync.BI_EMAIL_QuestionAndAnswerInfo> questionAndAnswerLst = new List<EmailMessageToLeadSync.BI_EMAIL_QuestionAndAnswerInfo>();
						EmailMessageToLeadSync.BI_EMAIL_QuestionAndAnswerInfo questionAndAnswer = new EmailMessageToLeadSync.BI_EMAIL_QuestionAndAnswerInfo();
						if(QuestionAndAnswerLstNode != null){
							for(Dom.XMLNode childNode : QuestionAndAnswerLstNode.getChildElements()){						
								questionAndAnswer.QuestionToGuest = CommUtils.nullToBlank(getChildElementByName(QuestionAndAnswerLstNode,'QuestionToGuest'));
								questionAndAnswer.AnswerToHotel = CommUtils.nullToBlank(getChildElementByName(QuestionAndAnswerLstNode,'AnswerToHotel'));		
								questionAndAnswerLst.add(questionAndAnswer);
							}
						}
						otherInfo.Reference = CommUtils.nullToBlank(getChildElementByName(otherInfoNode,'Reference'));
						otherInfo.GuestRequest = CommUtils.nullToBlank(getChildElementByName(otherInfoNode,'GuestRequest'));
						otherInfo.AdditionalInformation = CommUtils.nullToBlank(getChildElementByName(otherInfoNode,'AdditionalInformation'));				
					}
					if(basicRateNode != null){
						List<EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo> pointsDiscountLst = new List<EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo>();
						List<EmailMessageToLeadSync.BI_EMAIL_DepositInfo> depositLst = new List<EmailMessageToLeadSync.BI_EMAIL_DepositInfo>();
						for(Dom.Xmlnode childNode : basicRateNode.getChildElements()){
							if(childNode.getName().equalsIgnoreCase('TotalAccomodationServiceCharge')){
								basicRate.TotalAccomodationServiceCharge = CommUtils.nullToIntZero(childNode.getText());	
							}
							if(childNode.getName().equalsIgnoreCase('PointsDiscountList')){
								EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo pointsDiscount = new EmailMessageToLeadSync.BI_EMAIL_PointsDiscountInfo();	
								pointsDiscount.PointsDiv = CommUtils.nullToIntZero(getChildElementByName(childNode,'PointsDiv'));
								pointsDiscount.PointsDiscountName = getChildElementByName(childNode,'PointsDiscountName');
								pointsDiscount.PointsDiscount = CommUtils.nullToIntZero(getChildElementByName(childNode,'PointsDiscount'));
								pointsDiscountLst.add(pointsDiscount);
							}
							if(childNode.getName().equalsIgnoreCase('DepositList')){
								EmailMessageToLeadSync.BI_EMAIL_DepositInfo deposit = new EmailMessageToLeadSync.BI_EMAIL_DepositInfo();
								deposit.DepositAmount = CommUtils.nullToIntZero(getChildElementByName(childNode,'DepositAmount'));
								depositLst.add(deposit);		
							}
						}
						//system.debug(logginglevel.info,'-----pointsDiscountLst---------' + pointsDiscountLst);
											
						basicRate.pointsDiscountLst = pointsDiscountLst;
						basicRate.depositLst = depositLst;
						risaplsCommonInformation.basicRate = basicRate;
					}
				// 2015/08/07 TL2WAY対応するため、項目追加 END	
					risaplsinformation.risaplsCommonInformation = risaplsCommonInformation;
				}
				//system.debug(logginglevel.info,'agentNativeInfoNode:::' + agentNativeInfoNode);
				// 2015/08/07 TL2WAY対応するため、項目追加 BEGIN
				if(agentNativeInfoNode != null){
					EmailMessageToLeadSync.BI_EMAIL_Extend extend = new EmailMessageToLeadSync.BI_EMAIL_Extend();
					Dom.XMLNode extendNode = agentNativeInfoNode.getChildElement('Extend', null);
					EmailMessageToLeadSync.BI_EMAIL_Extendmytrip extendmytrip = new EmailMessageToLeadSync.BI_EMAIL_Extendmytrip();
					Dom.XMLNode extendmytripNode = agentNativeInfoNode.getChildElement('Extendmytrip', null);
					
					if(extendNode != null){
						extend.PointDiv = CommUtils.nullToBlank(getChildElementByName(extendNode,'PointDiv'));
						extend.PointName = CommUtils.nullToBlank(getChildElementByName(extendNode,'PointName'));
						extend.Points = CommUtils.nullToZero(getChildElementByName(extendNode,'Points'));
						extend.TotalAccommodationDecleasePoints = CommUtils.nullToIntZero(getChildElementByName(extendNode,'TotalAccommodationDecleasePoints'));
						extend.TotalAccommodationConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(extendNode,'TotalAccommodationConsumptionTax'));
						extend.AmountClaimed = CommUtils.nullToIntZero(getChildElementByName(extendNode,'CommUtils'));
						extend.Pamphlet = CommUtils.nullToBlank(getChildElementByName(extendNode,'Pamphlet'));
						extend.FromHotelQuestion = CommUtils.nullToBlank(getChildElementByName(extendNode,'FromHotelQuestion'));
						extend.ToHotelAnswer = CommUtils.nullToBlank(getChildElementByName(extendNode,'ToHotelAnswer'));
						extend.AgentComment = CommUtils.nullToBlank(getChildElementByName(extendNode,'AgentComment'));							
						agentNativeInformation.extend = extend;
					}
					if(extendmytripNode != null){
						extendmytrip.VIPCode = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'VIPCode'));
						extendmytrip.GetPoint = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'GetPoint'));
						extendmytrip.UsePoint = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'UsePoint'));
						extendmytrip.ChargeEquation = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'ChargeEquation'));
						extendmytrip.ReceiveDateTime = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'ReceiveDateTime'));
						extendmytrip.CancelDateTime = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'CancelDateTime'));
						extendmytrip.Answer1 = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Answer1'));
						extendmytrip.Answer2 = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Answer2'));
						extendmytrip.Answer3 = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Answer3'));
						extendmytrip.Answer4 = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Answer4'));
						extendmytrip.Answer5 = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Answer5'));
						extendmytrip.AgoRsvNumber = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'AgoRsvNumber'));
						extendmytrip.FromRsvNumber = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'FromRsvNumber'));
						extendmytrip.TodayReserve = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'TodayReserve'));
						extendmytrip.RoomSelect = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'RoomSelect'));
						extendmytrip.Reference = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'Reference'));
						extendmytrip.TotalFemaleCount = CommUtils.nullToIntZero(getChildElementByName(extendmytripNode,'TotalFemaleCount'));
						extendmytrip.SettlementDiv = CommUtils.nullToIntZero(getChildElementByName(extendmytripNode,'SettlementDiv'));
						extendmytrip.CancellationCharge = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'CancellationCharge'));
						extendmytrip.CancellationNotice = CommUtils.nullToBlank(getChildElementByName(extendmytripNode,'CancellationNotice'));
						agentNativeInformation.extendmytrip = extendmytrip;
					}
					risaplsinformation.agentNativeInformation = agentNativeInformation;
				}
				
				// 2015/08/07 TL2WAY対応するため、項目追加 END									
				bookingInfo.risaplsinformation = risaplsinformation;
				mLogUtils.write_log('リザプリ情報　パーサー完了');
			}
			
			
			//bookingInfo.dmlAction = EmailMessageToLeadSync.getDmlAction(bookingInfo.DataClassification);
			checkDmlAction(bookingInfo);
			//EmailMessageToLeadSync.BI_EMAIL_DmlAction.INS;
//System.debug(logginglevel.INFO, 'bookingInfo:::' + bookingInfo);
		mLogUtils.write_method_end();
		return bookingInfo;
	}
	private static void checkDmlAction(EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo){
		String dataClassification = bookingInfo.DataClassification;
		if(dataClassification == 'CancellationReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.CANCEL;
		else if(dataClassification == 'NewBookReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.INS;
		else if(dataClassification == 'ModificationReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.UPD;
		else if(dataClassification == 'Reconfirmatio')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.CONFIRM;
		else if(dataClassification == 'TejimaiReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.TEJIMA;
		else if(dataClassification == 'IssueReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.ISSUE;
		else if(dataClassification == 'OtherReport')
			bookingInfo.dmlAction = EmailMessageToLeadSync.BI_EMAIL_DmlAction.OTHER;
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
}