/**
 * XMLの予約情報はINNERクラスに設定する
 * JRラク通機能連携
 */
global with sharing class JR_ParseXmlToBookingInfoCtrl {
    // ログ情報初期化する
    public CommLogUtils mLogUtils {get;private set;}
    // インスタンス化
    public JR_ParseXmlToBookingInfoCtrl() {
        mLogUtils = new CommLogUtils('JR_ParseXmlToBookingInfoCtrl', true);
    }
    // XML情報はクラスへ反映する
    public BI_JR_LeadInfoSync.BI_JR_SyncInfo parse(String strXmlBody, String shopCode) {
        mLogUtils.write_method_start('parse');
        
        // String -> XML OBJECT
        Dom.Document doc = new Dom.Document();
        doc.load(strXmlBody);
        Dom.XMLNode root = doc.getRootElement();
        // 各セクション変数を定義する
        Dom.XMLNode accommodationNode, salesOfficeNode,basicNode, basicRateNode, roomAndGuestNode, memberNode;
        // XML情報はDAOクラスに設定する
        BI_JR_LeadInfoSync.BI_JR_SyncInfo bookingInfo = new BI_JR_LeadInfoSync.BI_JR_SyncInfo();
        for (Dom.XMLNode childNode: root.getChildElements()) {
            if (childNode.getName() == 'BookingType') {
                // ACTION転換する
                bookingInfo.dmlAction = convertDmlAction(CommUtils.nullToBlank(childNode.getText()));
            } else if (childNode.getName() == 'DataID') {
                String DataID = CommUtils.nullToBlank(childNode.getText());
                if (!CommUtils.isBlank(DataID)) {
                    String[] ws = DataID.split('-');
                    if (!ws.isEmpty())
                        bookingInfo.DataID = ws[0];
                    else
                        bookingInfo.DataID = DataID;
                }
            } else if (childNode.getName() == 'AccommodationInformation') {
                accommodationNode = childNode;
                for (Dom.XMLNode childsNode: accommodationNode.getChildElements()) {
                    if (childsNode.getName() == 'SalesOfficeInformation') {
                        salesOfficeNode = childsNode;
                    } else
                    if (childsNode.getName() == 'BasicInformation') {
                        basicNode = childsNode;
                    } else
                    if (childsNode.getName() == 'BasicRateInformation') {
                        basicRateNode = childsNode;
                    } else
                    if (childsNode.getName() == 'RoomAndGuestInformation') {
                        roomAndGuestNode = childsNode;
                    } else
                    if (childsNode.getName() == 'Member') {
                        memberNode = childsNode;
                    }
                }
            }
        }
        if (accommodationNode != null) {
            bookingInfo.AccommodationName = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationName'));
            bookingInfo.AccommodationCode = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationCode'));
            bookingInfo.AccommodationArea = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationArea'));
            bookingInfo.ChainName = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'ChainName'));
            bookingInfo.AccommodationPersonInCharge = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationPersonInCharge'));
            bookingInfo.AccommodationEmail = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationEmail'));
            bookingInfo.AccommodationPhoneNumber = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationPhoneNumber'));
            bookingInfo.AccommodationCPUAddress = CommUtils.nullToBlank(getChildElementByName(accommodationNode, 'AccommodationCPUAddress'));
            List <BI_JR_LeadInfoSync.BI_JR_BankInformation> bankLst = new List < BI_JR_LeadInfoSync.BI_JR_BankInformation> ();
            for (Dom.Xmlnode childNode: accommodationNode.getChildElements()) {
                if (childNode.getName().equalsIgnoreCase('BankList')) {
                    BI_JR_LeadInfoSync.BI_JR_BankInformation bank = new BI_JR_LeadInfoSync.BI_JR_BankInformation();
                    bank.BankName = CommUtils.nullToBlank(getChildElementByName(childNode, 'BankName'));
                    bank.BankAcountNumber = CommUtils.nullToBlank(getChildElementByName(childNode, 'BankAcountNumber'));
                    bank.BankBranchName = CommUtils.nullToBlank(getChildElementByName(childNode, 'BankBranchName'));
                    bank.BankAccountClassification = CommUtils.nullToBlank(getChildElementByName(childNode, 'BankAccountClassification'));
                    bank.BankAccountName = CommUtils.nullToBlank(getChildElementByName(childNode, 'BankAccountName'));
                    bankLst.add(bank);
                }
            }
            bookingInfo.BankList = bankLst;
            mLogUtils.write_log('宿泊施設側情報パーサー完了');
            if (salesOfficeNode != null) {
                bookingInfo.SalesOfficeCompanyCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeCompanyCode'));
                bookingInfo.SalesOfficeCompanyName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeCompanyName'));
                bookingInfo.SalesOfficeName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeName'));
                bookingInfo.SalesOfficeCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeCode'));
                bookingInfo.SalesOfficePersonInCharge = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficePersonInCharge'));
                bookingInfo.SalesOfficeEmail = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeEmail'));
                bookingInfo.SalesOfficePhoneNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficePhoneNumber'));
                bookingInfo.SalesOfficeFaxNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeFaxNumber'));
                bookingInfo.SalesOfficeStateProvidence = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeStateProvidence'));
                bookingInfo.SalesOfficeCityName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeCityName'));
                bookingInfo.SalesOfficeAddressLine = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeAddressLine'));
                bookingInfo.SalesOfficeStreetNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeStreetNumber'));
                bookingInfo.SalesOfficePostalCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficePostalCode'));
                bookingInfo.SalesOfficeRegisteredCategory = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeRegisteredCategory'));
                bookingInfo.SalesOfficeLicenseNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeLicenseNumber'));
                bookingInfo.SalesOfficeRegisteredPrefecture = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeRegisteredPrefecture'));
                bookingInfo.SalesOfficeCPUAddress = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'SalesOfficeCPUAddress'));
                bookingInfo.RetailerCompanyName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerCompanyName'));
                bookingInfo.RetailerOfficeName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerOfficeName'));
                bookingInfo.RetailerOfficeCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerOfficeCode'));
                bookingInfo.RetailerPersonInCharge = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerPersonInCharge'));
                bookingInfo.RetailerEmail = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerEmail'));
                bookingInfo.RetailerPhoneNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerPhoneNumber'));
                bookingInfo.RetailerStateProvidence = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerStateProvidence'));
                bookingInfo.RetailerCityName = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerCityName'));
                bookingInfo.RetailerAddressLine = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerAddressLine'));
                bookingInfo.RetailerStreetNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerStreetNumber'));
                bookingInfo.RetailerPostalCode = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerPostalCode'));
                bookingInfo.RetailerRegisteredCategory = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerRegisteredCategory'));
                bookingInfo.RetailerLicenseNumber = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerLicenseNumber'));
                bookingInfo.RetailerRegisteredPrefecture = CommUtils.nullToBlank(getChildElementByName(salesOfficeNode, 'RetailerRegisteredPrefecture'));
                mLogUtils.write_log('旅行会社情報報パーサー完了');
            }
            if (basicNode != null) {
                bookingInfo.TravelAgencyBookingNumber = CommUtils.nullToBlank(getChildElementByName(basicNode, 'TravelAgencyBookingNumber'));
                bookingInfo.TravelAgencyBookingDate = CommUtils.stringToDate(getChildElementByName(basicNode, 'TravelAgencyBookingDate'));
                bookingInfo.TravelAgencyBookingTime = CommUtils.stringToTime(getChildElementByName(basicNode, 'TravelAgencyBookingTime'));
                bookingInfo.TravelAgencyReportNumber = CommUtils.nullToBlank(getChildElementByName(basicNode, 'TravelAgencyReportNumber'));
                bookingInfo.AccommodationConfirmationNumber = CommUtils.nullToBlank(getChildElementByName(basicNode, 'AccommodationConfirmationNumber'));
                bookingInfo.GuestOrGroupNameSingleByte = CommUtils.nullToBlank(getChildElementByName(basicNode, 'GuestOrGroupNameSingleByte'));
                bookingInfo.GuestOrGroupNameDoubleByte = CommUtils.nullToBlank(getChildElementByName(basicNode, 'GuestOrGroupNameDoubleByte'));
                bookingInfo.GuestOrGroupNameKanjiName = CommUtils.nullToBlank(getChildElementByName(basicNode, 'GuestOrGroupNameKanjiName'));
                bookingInfo.GroupNameWelcomeBoard = CommUtils.nullToBlank(getChildElementByName(basicNode, 'GroupNameWelcomeBoard'));
                bookingInfo.CheckInDate = CommUtils.stringToDate(getChildElementByName(basicNode, 'CheckInDate'));
                bookingInfo.CheckInTime = CommUtils.stringToTimeOrNull(getChildElementByName(basicNode, 'CheckInTime'));
                bookingInfo.CheckOutDate = CommUtils.stringToDate(getChildElementByName(basicNode, 'CheckOutDate'));
                bookingInfo.CheckOutTime = CommUtils.stringToTimeOrNull(CommUtils.nullToBlank(getChildElementByName(basicNode, 'CheckOutTime')));
                bookingInfo.Nights = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'Nights'));
                bookingInfo.Transportaion = CommUtils.nullToBlank(getChildElementByName(basicNode, 'Transportaion'));
                bookingInfo.CoachCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'CoachCount'));
                //bookingInfo.CoachCompany = CommUtils.nullToBlank(getChildElementByName(basicNode, 'CoachCompany'));
                bookingInfo.TotalRoomCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalRoomCount'));
                bookingInfo.GrandTotalPaxCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'GrandTotalPaxCount'));
                bookingInfo.TotalPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalPaxMaleCount'));
                bookingInfo.TotalPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalPaxFemaleCount'));
                bookingInfo.TotalChildA70Count = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildA70Count'));
                bookingInfo.TotalChildB50Count = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildB50Count'));
                bookingInfo.TotalChildC30Count = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildC30Count'));
                bookingInfo.TotalChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildDNoneCount'));
                bookingInfo.TotalChildFCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildFCount'));
                bookingInfo.TotalChildECount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildECount'));
                bookingInfo.TotalChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalChildOtherCount'));
                bookingInfo.TotalTourConductorCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalTourConductorCount'));
                bookingInfo.TotalCoachDriverCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalCoachDriverCount'));
                bookingInfo.TotalGuideCount = CommUtils.nullToIntZero(getChildElementByName(basicNode, 'TotalGuideCount'));
                //bookingInfo.TypeOfGroup = CommUtils.nullToBlank(getChildElementByName(basicNode, 'TypeOfGroup'));
                bookingInfo.Status = CommUtils.nullToBlank(getChildElementByName(basicNode, 'Status'));
                bookingInfo.PackageType = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PackageType'));
                bookingInfo.PackagePlanName = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PackagePlanName'));
                bookingInfo.PackagePlanCode = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PackagePlanCode'));
                bookingInfo.PackagePlanContent = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PackagePlanContent'));

                List < BI_JR_LeadInfoSync.BI_JR_OptionInformation > optionLst = new List < BI_JR_LeadInfoSync.BI_JR_OptionInformation > ();
                for (Dom.Xmlnode childNode: basicNode.getChildElements()) {
                    if (childNode.getName().equalsIgnoreCase('Option')) {
                        BI_JR_LeadInfoSync.BI_JR_OptionInformation option = new BI_JR_LeadInfoSync.BI_JR_OptionInformation();
                        option.OptionDate = CommUtils.stringToDate(getChildElementByName(childNode, 'OptionDate'));
                        option.Name = CommUtils.nullToBlank(getChildElementByName(childNode, 'Name'));
                        option.NameRequest = CommUtils.nullToBlank(getChildElementByName(childNode, 'NameRequest'));
                        option.OptionCount = CommUtils.nullToIntZero(getChildElementByName(childNode, 'OptionCount'));
                        option.OptionRate = CommUtils.nullToIntZero(getChildElementByName(childNode, 'OptionRate'));
                        optionLst.add(option);
                    }
                }
                bookingInfo.optionList = optionLst;
                bookingInfo.MealCondition = CommUtils.nullToBlank(getChildElementByName(basicNode, 'MealCondition'));
                bookingInfo.SpecificMealCondition = CommUtils.nullToBlank(getChildElementByName(basicNode, 'SpecificMealCondition'));
                bookingInfo.MealPlace = CommUtils.nullToBlank(getChildElementByName(basicNode, 'MealPlace'));
                bookingInfo.BanquetRoom = CommUtils.nullToBlank(getChildElementByName(basicNode, 'BanquetRoom'));
                bookingInfo.ModificationType = CommUtils.nullToBlank(getChildElementByName(basicNode, 'ModificationType'));
                bookingInfo.ModificationPoint = CommUtils.nullToBlank(getChildElementByName(basicNode, 'ModificationPoint'));
                bookingInfo.CancellationNumber = CommUtils.nullToBlank(getChildElementByName(basicNode, 'CancellationNumber'));
                bookingInfo.PreviousPlace = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PreviousPlace'));
                bookingInfo.PreviousAccommodationName = CommUtils.nullToBlank(getChildElementByName(basicNode, 'PreviousAccommodationName'));
                bookingInfo.SpecialServiceRequest = CommUtils.nullToBlank(getChildElementByName(basicNode, 'SpecialServiceRequest'));
                bookingInfo.OtherServiceInformation = CommUtils.nullToBlank(getChildElementByName(basicNode, 'OtherServiceInformation'));
                bookingInfo.FollowUpInformation = CommUtils.nullToBlank(getChildElementByName(basicNode, 'FollowUpInformation'));
                bookingInfo.TravelAgencyEmail = CommUtils.nullToBlank(getChildElementByName(basicNode, 'TravelAgencyEmail'));
                mLogUtils.write_log('基本宿泊情報 パーサー完了');
            }
            if (basicRateNode != null) {
                bookingInfo.RoomRateOrPersonalRate = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'RoomRateOrPersonalRate'));
                bookingInfo.TaxServiceFee = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'TaxServiceFee'));
                bookingInfo.Payment = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'Payment'));
                bookingInfo.BareNetRate = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'BareNetRate'));
                bookingInfo.CancellationCharge = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'CancellationCharge'));
                bookingInfo.CreditCardAuthority = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'CreditCardAuthority'));
                bookingInfo.CreditCardNumber = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'CreditCardNumber'));
                bookingInfo.ExpireDate = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'ExpireDate'));
                bookingInfo.CardHolderName = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'CardHolderName'));
                bookingInfo.TotalAccommodationCharge = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationCharge'));
                bookingInfo.TotalAccommodationConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationConsumptionTax'));
                bookingInfo.TotalAccommodationHotSpringTax = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationHotSpringTax'));
                bookingInfo.TotalAccommodationHotelTax = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationHotelTax'));
                bookingInfo.TotalAccommodationServiceFee = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationServiceFee'));
                bookingInfo.TotalAccommodationBreakfastFee = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationBreakfastFee'));
                bookingInfo.TotalAccommodationOtherFee = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationOtherFee'));
                bookingInfo.CommissionPercentage = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'CommissionPercentage'));
                bookingInfo.TotalAccommodationCommissionAmount = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationCommissionAmount'));
                bookingInfo.TotalAccommodationCommissionConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationCommissionConsumptionTax'));
                bookingInfo.TotalAccommodationChargeAfterCheckIn = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationChargeAfterCheckIn'));
                bookingInfo.TotalBalanceAfterCheckIn = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalBalanceAfterCheckIn'));
                bookingInfo.TotalAccommodationConsumptionAfterCheckIn = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'TotalAccommodationConsumptionAfterCheckIn'));
                bookingInfo.CancellationChargeAfterCheckIn = CommUtils.nullToIntZero(getChildElementByName(basicRateNode, 'CancellationChargeAfterCheckIn'));
                bookingInfo.MembershipFee = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'MembershipFee'));
                bookingInfo.AdjustmentFee = CommUtils.nullToBlank(getChildElementByName(basicRateNode, 'AdjustmentFee'));
                List < BI_JR_LeadInfoSync.BI_JR_CouponInformation > couponLst = new List < BI_JR_LeadInfoSync.BI_JR_CouponInformation > ();
                for (Dom.Xmlnode couponNode: basicRateNode.getChildElements()) {
                    if (couponNode.getName().equalsIgnoreCase('CouponList')) {
                        BI_JR_LeadInfoSync.BI_JR_CouponInformation coupon = new BI_JR_LeadInfoSync.BI_JR_CouponInformation();
                        coupon.CouponAmount = CommUtils.nullToBlank(getChildElementByName(couponNode, 'CouponAmount'));
                        coupon.CouponType = CommUtils.nullToBlank(getChildElementByName(couponNode, 'CouponType'));
                        coupon.CouponTypeRequest = CommUtils.nullToBlank(getChildElementByName(couponNode, 'CouponTypeRequest'));
                        coupon.CouponNumber = CommUtils.nullToBlank(getChildElementByName(couponNode, 'CouponNumber'));
                        coupon.CouponIssueDate = CommUtils.nullToBlank(getChildElementByName(couponNode, 'CouponIssueDate'));
                        couponLst.add(coupon);
                    }
                }
                bookingInfo.couponList = couponLst;
            }
            mLogUtils.write_log('基本情報 パーサー完了');

            if (roomAndGuestNode != null) {
                List < BI_JR_LeadInfoSync.BI_JR_RoomAndGuestInfo > roomAndGuestLst = new List < BI_JR_LeadInfoSync.BI_JR_RoomAndGuestInfo > ();
                //roomAndGuestLst; tag = RoomAndGuesJRist 1-N
                for (Dom.XMLNode childNode: roomAndGuestNode.getChildElements()) {
                    //system.debug(logginglevel.INFO,'-childNode.getName()---------' + childNode.getName());
                    if (childNode.getName().equalsIgnoreCase('RoomAndGuestList')) {
                        BI_JR_LeadInfoSync.BI_JR_RoomAndGuestInfo roomAndGuestInfo = new BI_JR_LeadInfoSync.BI_JR_RoomAndGuestInfo();
                        BI_JR_LeadInfoSync.BI_JR_RoomInformation room = new BI_JR_LeadInfoSync.BI_JR_RoomInformation();
                        BI_JR_LeadInfoSync.BI_JR_RoomRateInfomation roomRate = new BI_JR_LeadInfoSync.BI_JR_RoomRateInfomation();
                        BI_JR_LeadInfoSync.BI_JR_GuestInfo guest = new BI_JR_LeadInfoSync.BI_JR_GuestInfo();
                        for (Dom.XMLNode childDomNode: childNode.getChildElements()) {
                            //tag - RoomInformation 1-1
                            if (childDomNode.getName().equalsIgnoreCase('RoomInformation')) {
                                Dom.XMLNode roomNode = childDomNode;
                                if (roomNode != null) {
                                    room.RoomTypeCode = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomTypeCode'));
                                    room.RoomTypeName = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomTypeName'));
                                    room.RoomCategory = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomCategory'));
                                    room.ViewType = CommUtils.nullToBlank(getChildElementByName(roomNode, 'ViewType'));
                                    room.SmokingOrNonSmoking = CommUtils.nullToBlank(getChildElementByName(roomNode, 'SmokingOrNonSmoking'));
                                    room.PerRoomPaxCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'PerRoomPaxCount'));
                                    room.RoomPaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomPaxMaleCount'));
                                    room.RoomPaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomPaxFemaleCount'));
                                    room.RoomChildA70Count = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildA70Count'));
                                    room.RoomChildB50Count = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildB50Count'));
                                    room.RoomChildC30Count = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildC30Count'));
                                    room.RoomChildDNoneCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildDNoneCount'));
                                    room.RoomChildECount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildECount'));
                                    room.RoomChildFCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildFCount'));
                                    room.RoomChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(roomNode, 'RoomChildOtherCount'));
                                    room.RoomByRoomStatus = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomByRoomStatus'));
                                    room.RoomByRoomConfirmationNumber = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomByRoomConfirmationNumber'));
                                    room.Facilities = CommUtils.nullToBlank(getChildElementByName(roomNode, 'Facilities'));
                                    room.AssignedRoomNumber = CommUtils.nullToBlank(getChildElementByName(roomNode, 'AssignedRoomNumber'));
                                    room.RoomSpecialRequest = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomSpecialRequest'));
                                    room.RoomTypeAgent = CommUtils.nullToBlank(getChildElementByName(roomNode, 'RoomTypeAgent'));
                                    roomAndGuestInfo.room = room;
                                }
                            }
                            //tag RoomRateInformation 1:N
                            if (childDomNode.getName() == 'RoomRateInformation') {
                                Dom.Xmlnode rateInfoNode = childDomNode;
                                if (rateInfoNode != null) {
                                    roomRate.RoomDate = CommUtils.stringToDate(getChildElementByName(rateInfoNode, 'RoomDate'));
                                    roomRate.PerPaxRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerPaxRate'));
                                    roomRate.PerPaxMaleRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerPaxMaleRate'));
                                    roomRate.PerPaxFemaleRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerPaxFemaleRate'));
                                    roomRate.PerChildA70Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildA70Rate'));
                                    roomRate.PerChildB50Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildB50Rate'));
                                    roomRate.PerChildC30Rate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildC30Rate'));
                                    roomRate.PerChildDRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildDRate'));
                                    roomRate.PerChildERate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildERate'));
                                    roomRate.PerChildFRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildFRate'));
                                    roomRate.PerChildOtherRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'PerChildOtherRate'));
                                    //roomRate.RoomRatePaxMaleCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRatePaxMaleCount'));
                                    //roomRate.RoomRatePaxFemaleCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRatePaxFemaleCount'));
                                    //roomRate.RoomRateChildACount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildACount'));
                                    //roomRate.RoomRateChildBCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildBCount'));
                                    //roomRate.RoomRateChildCCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildCCount'));
                                    //roomRate.RoomRateChildDCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildDCount'));
                                    //roomRate.RoomRateChildECount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildECount'));
                                    //roomRate.RoomRateChildFCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildFCount'));
                                    //roomRate.RoomRateChildOtherCount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'RoomRateChildOtherCount'));
                                    roomRate.TotalPerRoomRate = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomRate'));
                                    roomRate.TotalPerRoomConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomConsumptionTax'));
                                    roomRate.TotalPerlRoomHotSpringTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerlRoomHotSpringTax'));
                                    roomRate.TotalPerRoomHotelTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomHotelTax'));
                                    roomRate.TotalPerRoomServiceFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomServiceFee'));
                                    roomRate.TotalPerRoomBreakfastFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomBreakfastFee'));
                                    roomRate.TotalPerRoomOtherFee = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomOtherFee'));
                                    roomRate.TotalPerRoomCommissionAmount = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomCommissionAmount'));
                                    roomRate.TotalPerRoomCommissionConsumptionTax = CommUtils.nullToIntZero(getChildElementByName(rateInfoNode, 'TotalPerRoomCommissionConsumptionTax'));

                                    List < BI_JR_LeadInfoSync.BI_JR_RoomDateGuest > roomDateGuestLst = new List < BI_JR_LeadInfoSync.BI_JR_RoomDateGuest > ();
                                    for (Dom.Xmlnode rateNode: rateInfoNode.getChildElements()) {
                                        if (rateNode.getName().equalsIgnoreCase('RoomDateGuestList')) {
                                            BI_JR_LeadInfoSync.BI_JR_RoomDateGuest roomDateGuest = new BI_JR_LeadInfoSync.BI_JR_RoomDateGuest();
                                            roomDateGuest.GuestTypeCode = CommUtils.nullToBlank(getChildElementByName(rateNode, 'GuestTypeCode'));
                                            roomDateGuest.GuestType = CommUtils.nullToBlank(getChildElementByName(rateNode, 'GuestType'));
                                            roomDateGuest.Rate = CommUtils.nullToIntZero(getChildElementByName(rateNode, 'Rate'));
                                            roomDateGuest.Count = CommUtils.nullToIntZero(getChildElementByName(rateNode, 'Count'));
                                            roomDateGuestLst.add(roomDateGuest);
                                        }
                                    }
                                    roomRate.roomDateGuestList = roomDateGuestLst;
                                    roomAndGuestInfo.roomRate = roomRate;
                                }
                            }
                            //tag - GuestInformation 0-1
                            if (childDomNode.getName() == 'GuestInformation') {
                                Dom.Xmlnode gusetLstNode = childDomNode;
                                if (gusetLstNode != null) {
                                    List < BI_JR_LeadInfoSync.BI_JR_GuestInformationList > guestInformationList = new List < BI_JR_LeadInfoSync.BI_JR_GuestInformationList >();
                                    for (Dom.Xmlnode gusetNode: gusetLstNode.getChildElements()) {
                                        if (gusetNode != null) {
                                            if (gusetNode.getName().equalsIgnoreCase('GuestInformationList')) {
                                            	BI_JR_LeadInfoSync.BI_JR_GuestInformationList guestInfo = new BI_JR_LeadInfoSync.BI_JR_GuestInformationList();
                                                guestInfo.GuestSurName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestSurName'));
                                                guestInfo.GuestGivenName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestGivenName'));
                                                guestInfo.GuestMiddleName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestMiddleName'));
                                                guestInfo.GuestNamePrefix = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestNamePrefix'));
                                                guestInfo.GuestKanjiName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestKanjiName'));
                                                guestInfo.GuestGender = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestGender'));
                                                guestInfo.GuestAge = CommUtils.nullToIntZero(getChildElementByName(gusetNode, 'GuestAge'));
                                                guestInfo.GuestDateOfBirth = CommUtils.stringToDate(getChildElementByName(gusetNode, 'GuestDateOfBirth'));
                                                guestInfo.GuestType = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestType'));
                                                guestInfo.GuestShubetsu = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestShubetsu'));
                                                guestInfo.GuestPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestPhoneNumber'));
                                                guestInfo.GuestEmergencyPhoneNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestEmergencyPhoneNumber'));
                                                guestInfo.GuestEmail = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestEmail'));
                                                guestInfo.GuestCountry = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestCountry'));
                                                guestInfo.GuestStateProvidence = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestStateProvidence'));
                                                guestInfo.GuestCityName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestCityName'));
                                                guestInfo.GuestAddressLine = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestAddressLine'));
                                                guestInfo.GuestStreetNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestStreetNumber'));
                                                guestInfo.GuestPostalCode = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestPostalCode'));
                                                guestInfo.GuestBuildingName = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestBuildingName'));
                                                guestInfo.GuestFFPCarrier = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestFFPCarrier'));
                                                guestInfo.GuestFFPNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestFFPNumber'));
                                                guestInfo.GuestCoachNumber = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'GuestCoachNumber'));
                                                guestInfo.SpecialInformation = CommUtils.nullToBlank(getChildElementByName(gusetNode, 'SpecialInformation'));
                                            	guestInformationList.add(guestInfo);
                                            }
                                            guest.guestInformationList = guestInformationList;
                                            roomAndGuestInfo.guest = guest;
                                        }
                                    }
                                }
                            }
                        }
                        roomAndGuestLst.add(roomAndGuestInfo);
                    }
                }
                // 2018/04/19 氏名変更のみケース対応 BEGIN
				bookingInfo.isUpdForName = false;
				for (BI_JR_LeadInfoSync.BI_JR_RoomAndGuestInfo rg : roomAndGuestLst) {
				    if (rg.room == null || rg.roomRate== null || 
				        CommUtils.isBlank(rg.room.RoomTypeCode) || rg.roomRate.RoomDate == null) {
				        bookingInfo.isUpdForName = true;
				        break;     
                    }
				}
				// 2018/04/19 氏名変更のみケース対応 END
                bookingInfo.roomAndGuestLst = roomAndGuestLst;
                mLogUtils.write_log('￼個々の部屋とお客様情報 パーサー完了');
            }
            if (memberNode != null) {
                BI_JR_LeadInfoSync.BI_JR_Member member = new BI_JR_LeadInfoSync.BI_JR_Member();
                member.UserName = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserName'));
                member.UserKana = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserKana'));
                member.UserTel = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserTel'));
                member.UserMailAddr = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserMailAddr'));
                member.UserZip = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserZip'));
                member.UserAddr = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserAddr'));
                member.UserCorp = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserCorp'));
                member.UserDep = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserDep'));
                member.UserID = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserID'));
                member.VIPCode = CommUtils.nullToBlank(getChildElementByName(memberNode, 'VIPCode'));
                member.PointCompanyName = CommUtils.nullToBlank(getChildElementByName(memberNode, 'PointCompanyName'));
                member.PointName = CommUtils.nullToBlank(getChildElementByName(memberNode, 'PointName'));
                member.UserGivinPoints = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserGivinPoints'));
                member.UserUsePoints = CommUtils.nullToBlank(getChildElementByName(memberNode, 'UserUsePoints'));
                member.TotalAccommodationDecleasePoints = CommUtils.nullToIntZero(getChildElementByName(memberNode, 'TotalAccommodationDecleasePoints'));
                member.TotalAccommodationConsumptaionTax = CommUtils.nullToIntZero(getChildElementByName(memberNode, 'TotalAccommodationConsumptaionTax'));
                member.AmountClaimed = CommUtils.nullToIntZero(getChildElementByName(memberNode, 'AmountClaimed'));
                member.ChargeEquation = CommUtils.nullToBlank(getChildElementByName(memberNode, 'ChargeEquation'));
                bookingInfo.member = member;
            }

            mLogUtils.write_log('リザプリ情報　パーサー完了');
            //heckDmlAction(bookingInfo);
        }
        mLogUtils.write_method_end();
        return bookingInfo;
    }
    private static BI_JR_LeadInfoSync.BI_JR_DmlAction convertDmlAction(String dataClassification) {
        if (dataClassification == 'CancellationReport')
            return BI_JR_LeadInfoSync.BI_JR_DmlAction.CANCEL;
        else if (dataClassification == 'NewBookReport')
            return BI_JR_LeadInfoSync.BI_JR_DmlAction.INS;
        else if (dataClassification == 'ModificationReport')
           return BI_JR_LeadInfoSync.BI_JR_DmlAction.UPD;
        else if (dataClassification == 'NameModificationReport')
           return BI_JR_LeadInfoSync.BI_JR_DmlAction.UPD;
        return null;
    }
    private static string getChildElementByName(Dom.XMLNode parentNode, String elementName) {
        return CommXmlUtils.getChildElementByName(parentNode, elementName);
    }
}