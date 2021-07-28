/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class JR_LeadSyncProcessBatchTest {
    // 連携結果実施済「異常ケース」
    static testMethod void JR_NotifyCase_001() {
        // XML DOCUMENT CREATE
        createConfigDoc();
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Test.startTest();
        createErrorXml();
        // 子連携結果情報を作成する
        // 正常ケース
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        JR_LeadSyncProcessBatch batch = new JR_LeadSyncProcessBatch();
        ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();
    }
    // 連携結果実施済「異常ケース」
    static testMethod void JR_NotifyCase_002() {
        // XML DOCUMENT CREATE
        createConfigDoc();
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Test.startTest();
        CooperationResult__c cooperationResultInfo = TestCommon.createCooperationParentXMLImpot('','JR');
        // 異常ケース
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,true));
        JR_LeadSyncNotifyBatchExtend batch = new JR_LeadSyncNotifyBatchExtend();
        ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest();  
    } 
    // XML取り込み処理[]
    static testMethod void JR_XmlImportCase_001() {
        // XML DOCUMENT CREATE
        createConfigDoc();
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        TestCommon.createBillSimpleHelpConfigDoc();
        // 2015/12/01 Assert END
        Test.startTest();
        // 正常ケース
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl());
        JR_LeadSyncXmlImportBatch batch = new JR_LeadSyncXmlImportBatch();    
        ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
        
    }
    // XML取り込み処理[API ERROR]
    static testMethod void JR_XmlImportCase_002() {
        // XML DOCUMENT CREATE
        createConfigDoc();
        System.assertEquals([select Id from Document where Name = 'JRServiceConfigXml'].size(), 1);
        // 2015/12/01 Assert END
        Test.startTest();
        // 正常ケース
        Test.setMock(HttpCalloutMock.class, new TestCommonMockImpl(true,true));
        JR_LeadSyncXmlImportBatch batch = new JR_LeadSyncXmlImportBatch();    
        ID batchprocessid = Database.executeBatch(batch,1);
        Test.stopTest(); 
        
    }
    private static void createConfigDoc() {
        TestCommon.createJr2WayConfigDoc();
    }
    
    private static void createErrorXml() {
        String infoTravelXML = '';
        infoTravelXML +=    '<soap:Body1>'+
                        '<GetBookingReply>'+
                        '<TransactionType><DataFrom>FromRakutsu</DataFrom><DataClassification>GetBookingReply</DataClassification><GetBookingID>1234567890</GetBookingID><SystemDate>2018-04-09</SystemDate><SystemTime>18:30</SystemTime></TransactionType>'+
                        '<ResultInformation><ResultCode>0</ResultCode></ResultInformation>'+
                        '$$_Booking_$$'+
                        '</GetBookingReply>'+
                        '</soap:Body1>';
        String wkXml = '<Booking no="1">'+
                       '<BookingType>NewBookReport</BookingType><DataID>D18040600007</DataID><AccommodationInformation><AccommodationName>らく通すみれホテル</AccommodationName><AccommodationCode>SURH</AccommodationCode><SalesOfficeInformation><SalesOfficeCompanyCode>JAL</SalesOfficeCompanyCode><SalesOfficeCompanyName>ＪＡＬ</SalesOfficeCompanyName><SalesOfficeName>ＪＡＬＰＡＫ</SalesOfficeName><SalesOfficeCode /><SalesOfficePersonInCharge /><SalesOfficePhoneNumber>03-9999-9999</SalesOfficePhoneNumber></SalesOfficeInformation>'+
                       '<BasicInformation><TravelAgencyBookingNumber>5PUWT23621</TravelAgencyBookingNumber><TravelAgencyBookingDate>2018-04-06</TravelAgencyBookingDate><TravelAgencyBookingTime>18:02:57</TravelAgencyBookingTime><TravelAgencyReportNumber>T0023621</TravelAgencyReportNumber><GuestOrGroupNameSingleByte>ニッコウ　タロウ</GuestOrGroupNameSingleByte><GuestOrGroupNameKanjiName>ニッコウ　タロウ</GuestOrGroupNameKanjiName><CheckInDate>2018-12-31</CheckInDate><CheckInTime /><CheckOutDate>2019-01-05</CheckOutDate><Nights>5</Nights><Transportaion /><TotalRoomCount>1</TotalRoomCount><GrandTotalPaxCount>1</GrandTotalPaxCount><TotalPaxMaleCount>1</TotalPaxMaleCount><TotalPaxFemaleCount /><TotalChildA70Count /><TotalChildB50Count /><TotalChildC30Count /><TotalChildDNoneCount /><TotalChildECount  /><TotalChildFCount  /><TotalChildOtherCount /><PackageType>Package</PackageType><PackagePlanName>北海道・冬春スペシャル・フ</PackagePlanName><PackagePlanCode>ＮＥ６１５０Ａ</PackagePlanCode><MealCondition>1nightMeal</MealCondition><SpecialServiceRequest>　　ＪＡＬＰＡＫ　２０１８／０４／０６らく通すみれホテル　ＳＵＲＨ</SpecialServiceRequest><OtherServiceInformation>等級９Ｉ ※クーポン無し ＃ニッコウ タロウ ３５Ｍ ＪＭＢ１２３４５６７ 変更新規 到着フライト：ＪＬ０５０３（０９：０５） 出発フライト：ＪＬ０５１２（１４：００） （等級内容 等級９Ｉ） 喫煙／朝食付き （付帯条件 等級９Ｉ） 喫煙喫煙 発地：ＴＹＯ 北海道 冬春スペシャル フリーチョイス設定ホテル</OtherServiceInformation><TravelAgencyEmail /></BasicInformation>'+
                       '<BasicRateInformation><TaxServiceFee>IncludingServiceWithoutTax</TaxServiceFee><Payment /><TotalAccommodationCharge>21000</TotalAccommodationCharge></BasicRateInformation><RoomAndGuestInformation><RoomAndGuestList><RoomInformation><RoomTypeCode>ＡＢ０００１</RoomTypeCode><RoomTypeName>ＡＢ０００１</RoomTypeName><RoomCategory /><ViewType /><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount /><RoomChildA70Count /><RoomChildB50Count /><RoomChildC30Count /><RoomChildDNoneCount /><RoomChildECount  /><RoomChildFCount  /><RoomChildOtherCount /></RoomInformation><RoomRateInformation><RoomDate>2018-12-31</RoomDate><PerPaxRate /><PerPaxMaleRate>7000</PerPaxMaleRate><PerPaxFemaleRate /><PerChildA70Rate /><PerChildB50Rate /><PerChildC30Rate /><PerChildDRate /><PerChildERate  /><PerChildFRate  /><PerChildOtherRate /><TotalPerRoomRate /><RoomDateGuestList><GuestTypeCode>大人男</GuestTypeCode><GuestType>大人（男）</GuestType><Rate>7000</Rate><Count>1</Count></RoomDateGuestList></RoomRateInformation><GuestInformation><GuestInformationList><GuestNameSingleByte>ニッコウ　タロウ</GuestNameSingleByte><GuestKanjiName>ニッコウ　タロウ</GuestKanjiName><GuestPhoneNumber /><GuestEmail /><GuestStateProvidence /><GuestPostalCode /></GuestInformationList></GuestInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>ＡＢ０００１</RoomTypeCode><RoomTypeName>ＡＢ０００１</RoomTypeName><RoomCategory /><ViewType /><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount /><RoomChildA70Count /><RoomChildB50Count /><RoomChildC30Count /><RoomChildDNoneCount /><RoomChildECount  /><RoomChildFCount  /><RoomChildOtherCount /></RoomInformation><RoomRateInformation><RoomDate>2019-01-02</RoomDate><PerPaxRate /><PerPaxMaleRate>7000</PerPaxMaleRate><PerPaxFemaleRate /><PerChildA70Rate /><PerChildB50Rate /><PerChildC30Rate /><PerChildDRate /><PerChildERate  /><PerChildFRate  /><PerChildOtherRate /><TotalPerRoomRate /><RoomDateGuestList><GuestTypeCode>大人男</GuestTypeCode><GuestType>大人（男）</GuestType><Rate>7000</Rate><Count>1</Count></RoomDateGuestList></RoomRateInformation><GuestInformation><GuestInformationList><GuestNameSingleByte>ニッコウ　タロウ</GuestNameSingleByte><GuestKanjiName>ニッコウ　タロウ</GuestKanjiName><GuestPhoneNumber /><GuestEmail /><GuestStateProvidence /><GuestPostalCode /></GuestInformationList></GuestInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>ＡＢ０００１</RoomTypeCode><RoomTypeName>ＡＢ０００１</RoomTypeName><RoomCategory /><ViewType /><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount /><RoomChildA70Count /><RoomChildB50Count /><RoomChildC30Count /><RoomChildDNoneCount /><RoomChildECount  /><RoomChildFCount  /><RoomChildOtherCount /></RoomInformation><RoomRateInformation><RoomDate>2019-01-04</RoomDate><PerPaxRate /><PerPaxMaleRate>7000</PerPaxMaleRate><PerPaxFemaleRate /><PerChildA70Rate /><PerChildB50Rate /><PerChildC30Rate /><PerChildDRate /><PerChildERate  /><PerChildFRate  /><PerChildOtherRate /><TotalPerRoomRate /><RoomDateGuestList><GuestTypeCode>大人男</GuestTypeCode><GuestType>大人（男）</GuestType><Rate>7000</Rate><Count>1</Count></RoomDateGuestList></RoomRateInformation><GuestInformation><GuestInformationList><GuestNameSingleByte>ニッコウ　タロウ</GuestNameSingleByte><GuestKanjiName>ニッコウ　タロウ</GuestKanjiName><GuestPhoneNumber /><GuestEmail /><GuestStateProvidence /><GuestPostalCode /></GuestInformationList></GuestInformation></RoomAndGuestList></RoomAndGuestInformation>'+
                       '<Member><UserName>ニッコウ　タロウ</UserName><UserKana /><UserTel /><UserMailAddr /><UserZip /><UserAddr /><UserCorp /><UserID /><UserUsePoints /><TotalAccommodationDecleasePoints /></Member></AccommodationInformation>'+
                       '</Booking>';
        infoTravelXML = infoTravelXML.replace('$$_Booking_$$',wkXml);
        CooperationResult__c coop = TestCommon.createLeadImportAndImpotNG('');
        
        String dateKey = System.now().format('yyMMddHHMMssSSS');
        Attachment newAttach = new Attachment(
                                    ParentId = coop.Id,
                                    Name = 'JRPDATA_' + dateKey + '1_Test.xml', 
                                    ContentType = 'text/xml',
                                    Body = Blob.valueOf(infoTravelXML)
                                );
        insert newAttach;
    }
}