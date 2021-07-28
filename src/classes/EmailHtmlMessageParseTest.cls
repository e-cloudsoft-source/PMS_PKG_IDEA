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
private class EmailHtmlMessageParseTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        insertConfigDoc();
        createCommParse();
        String emailContent = createDocument();
    	EmailMessageToLeadHelp.AgtInfo currAgt = null;
    	String emailBody = 'Expedia';
    	list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
		for (EmailMessageToLeadHelp.AgtInfo agtInf : agtLst) {
			
			if (emailBody.containsIgnoreCase(agtInf.agtNm)) {
				currAgt = agtInf; 
				break;
			}
		}
		EmailHtmlMessageParse e = new EmailHtmlMessageParse(currAgt);
		//list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
		String content1 = e.exportEamil(emailContent);
    }
    static void createCommParse(){
    	String documentFile = '	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>		'+
'	<AllotmentBookingReport>		'+
'	    <TransactionType START_TAG="■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■" END_TAG="-----------------------------------------------------------">		'+
'	        <DataFrom>FromTravelAgency</DataFrom>		'+
'	        <DataClassification>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMIAL_TAG_FORMAT>キャンセルメール</EMIAL_TAG_FORMAT>		'+
'	                <CONVERT_VAL>CancellationReport</CONVERT_VAL>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMIAL_TAG_FORMAT>新規予約メール</EMIAL_TAG_FORMAT>		'+
'	                <CONVERT_VAL>NewBookReport</CONVERT_VAL>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMIAL_TAG_FORMAT>予約変更メール</EMIAL_TAG_FORMAT>		'+
'	                <CONVERT_VAL>ModificationReport</CONVERT_VAL>		'+
'	            </EMAIL_DETAIL>		'+
'	        </DataClassification>		'+
'	        <DataID>		'+
'	            <EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </DataID>		'+
'	    </TransactionType>		'+
'	    <AccommodationInformation>		'+
'	        <AccommodationName>		'+
'		<EMAIL_TAG>【宿泊施設名】</EMAIL_TAG>	'+
'	            <EMAIL_BEG>：</EMAIL_BEG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </AccommodationName>		'+
'	        <AccommodationCode>		'+
'		<EMAIL_TAG>【宿泊施設コード】</EMAIL_TAG>	'+
'	            <EMAIL_BEG>：</EMAIL_BEG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </AccommodationCode>		'+
'	    </AccommodationInformation>		'+
'	    <SalesOfficeInformation>		'+
'	        <SalesOfficeCompanyName>		'+
'		<EMAIL_TAG>【旅行会社名】</EMAIL_TAG>	'+
'	            <EMAIL_BEG>：</EMAIL_BEG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </SalesOfficeCompanyName>		'+
'	        <SalesOfficeCompanyCode>		'+
'		<EMAIL_TAG>【旅行会社コード】</EMAIL_TAG>	'+
'	            <EMAIL_BEG>：</EMAIL_BEG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </SalesOfficeCompanyCode>		'+
'	    </SalesOfficeInformation>		'+
'	    <BasicInformation START_TAG="メール＞=========" END_TAG="料金明細">>		'+
'	        <TravelAgencyBookingNumber>		'+
'	            <EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </TravelAgencyBookingNumber>		'+
'	        <TravelAgencyBookingDate>		'+
'	            <EMAIL_TAG>受付時間：</EMAIL_TAG>		'+
'	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>		'+
'	            <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	        </TravelAgencyBookingDate>		'+
'	        <TravelAgencyBookingTime>		'+
'	            <EMAIL_TAG>受付時間：</EMAIL_TAG>		'+
'	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>		'+
'	            <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	        </TravelAgencyBookingTime>		'+
'	        <GuestOrGroupNameDoubleByte>		'+
'	            <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		'+
'	            <EMAIL_END>\n</EMAIL_END>		'+
'	        </GuestOrGroupNameDoubleByte>		'+
'	        <GuestOrGroupNameKanjiName>		'+
'	            <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		'+
'	            <EMAIL_END>様</EMAIL_END>		'+
'		</GuestOrGroupNameKanjiName>	'+
'		<CheckInDate>	'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○チェックイン日時</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>\n</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9]{4})/([0-9]{1}|[0-9]{2})/([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>		'+
'	                <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○ご利用日時</EMAIL_TAG>		'+
'	                <EMAIL_END>)</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>		'+
'	                <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	            </EMAIL_DETAIL>		'+
'		</CheckInDate>	'+
'	        <CheckInTime>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>		'+
'	                <EMAIL_BEG>)</EMAIL_BEG>		'+
'	                <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>		'+
'	                <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○ご利用日時</EMAIL_TAG>		'+
'	                <EMAIL_BEG>)</EMAIL_BEG>		'+
'	                <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>		'+
'	                <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	            </EMAIL_DETAIL>		'+
'	        </CheckInTime>		'+
'	        <Nights>		'+
'	            <EMAIL_TAG>○泊数</EMAIL_TAG>		'+
'	            <EMAIL_END>泊</EMAIL_END>		'+
'	            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>		'+
'	        </Nights>		'+
'	        <TotalRoomCount>		'+
'	            <EMAIL_TAG>○部屋数</EMAIL_TAG>		'+
'	            <EMAIL_BEG>：</EMAIL_BEG>		'+
'	            <EMAIL_END>部屋</EMAIL_END>		'+
'	            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>		'+
'	        </TotalRoomCount>		'+
'	        <!--		'+
'	         <PackagePlanCode>		'+
'		<EMAIL_TAG>○プラン名</EMAIL_TAG>	'+
'		<EMAIL_BEG>(</EMAIL_BEG>	'+
'		<EMAIL_END>)</EMAIL_END>	'+
'	         </PackagePlanCode>		'+
'	         -->		'+
'	        <PackagePlanName>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○プラン名</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>○誕生日</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○プラン名</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>携帯電話番号</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○プラン名</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>○ご要望・ご質問</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○プラン名</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>\n</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	        </PackagePlanName>		'+
'			'+
'	         <RoomTypeCode>		'+
'	         <EMAIL_TAG>○部屋タイプ</EMAIL_TAG>		'+
'	         <EMAIL_BEG>(</EMAIL_BEG>		'+
'	         <EMAIL_END>)</EMAIL_END>		'+
'	         </RoomTypeCode>		'+
'			'+
'	        <RoomTypeName>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○部屋タイプ</EMAIL_TAG>		'+
'	                <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                <EMAIL_END>-</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	        </RoomTypeName>		'+
'	        <OtherServiceInformation>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>○プラン名</EMAIL_TAG>		'+
'	                <EMAIL_BEG>\n</EMAIL_BEG>		'+
'	                <EMAIL_END>---------</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	        </OtherServiceInformation>		'+
'	    </BasicInformation>		'+
'	    <BasicRateInformation>		'+
'	        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>		'+
'	        <TaxServiceFee>WithoutSerivceAndTax</TaxServiceFee>		'+
'	        <TotalAccommodationCharge>		'+
'	            <EMAIL_TAG>【合計金額】</EMAIL_TAG>		'+
'	            <EMAIL_END>JPY</EMAIL_END>		'+
'		<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	'+
'	        </TotalAccommodationCharge>		'+
'	        <TotalAccommodationHotSpringTax>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>合計宿泊料金入湯税</EMAIL_TAG>		'+
'	                <EMAIL_BEG>:</EMAIL_BEG>		'+
'	                <EMAIL_END>\n</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	        </TotalAccommodationHotSpringTax>		'+
'	        <TotalAccommodationServiceFee>		'+
'	            <EMAIL_DETAIL>		'+
'	                <EMAIL_TAG>合計宿泊料金サービス料</EMAIL_TAG>		'+
'	                <EMAIL_BEG>:</EMAIL_BEG>		'+
'	                <EMAIL_END>\n</EMAIL_END>		'+
'	            </EMAIL_DETAIL>		'+
'	        </TotalAccommodationServiceFee>		'+
'	    </BasicRateInformation>		'+
'	    <RoomAndGuestInformation orderType="2"  START_TAG="料金明細" SPLIT_TAG="部屋目,([0-9]{4})/([0-9]{1}|[0-9]{2})/([0-9]{1}|[0-9]{2})">		'+
'			'+
'	        <RoomInformation >		'+
'	            <PerRoomPaxCount>		'+
'	                <EMAIL_TAG>大人</EMAIL_TAG>		'+
'	                <EMAIL_BEG>:</EMAIL_BEG>		'+
'	                <EMAIL_END>名</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	            </PerRoomPaxCount>		'+
'	            <RoomPaxMaleCount>		'+
'	                <EMAIL_TAG>大人</EMAIL_TAG>		'+
'	                <EMAIL_BEG>男性</EMAIL_BEG>		'+
'	                <EMAIL_END>名</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	            </RoomPaxMaleCount>		'+
'	            <RoomPaxFemaleCount>		'+
'	                <EMAIL_TAG>大人</EMAIL_TAG>		'+
'	                <EMAIL_BEG>女性</EMAIL_BEG>		'+
'	                <EMAIL_END>名</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	            </RoomPaxFemaleCount>		'+
'	            <RoomChildA70Count>		'+
'	                <EMAIL_TAG>小学生</EMAIL_TAG>		'+
'	                <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                <EMAIL_END>名</EMAIL_END>		'+
'	                <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	            </RoomChildA70Count>		'+
'	            <RoomChildB50Count>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小B</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </RoomChildB50Count>		'+
'	            <RoomChildC30Count>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小C</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </RoomChildC30Count>		'+
'	            <RoomChildDNoneCount>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小D</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </RoomChildDNoneCount>		'+
'	            <RoomChildOtherCount>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小E</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>×</EMAIL_BEG>		'+
'	                    <EMAIL_END>名</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </RoomChildOtherCount>		'+
'	            <!--		'+
'	             <RoomChildDNoneCount>0</RoomChildDNoneCount> -->		'+
'	        </RoomInformation>		'+
'	        <RoomRateInformation >		'+
'	            <PerPaxRate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>大人</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>名)</EMAIL_BEG>		'+
'	                    <EMAIL_END>）</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>大人</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>名)</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerPaxRate>		'+
'	            <PerChildA70Rate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小学生</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>）</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小学生</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerChildA70Rate>		'+
'	            <PerChildB50Rate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>）</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>）</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小B</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerChildB50Rate>		'+
'	            <PerChildC30Rate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>）</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小C</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerChildC30Rate>		'+
'	            <PerChildDRate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小D</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerChildDRate>		'+
'	            <PerChildOtherRate>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>小E</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </PerChildOtherRate>		'+
'	            <TotalPerRoomRate>		'+
'		<EMAIL_DETAIL>	'+
'	                    <EMAIL_TAG>部屋料金</EMAIL_TAG>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </TotalPerRoomRate>		'+
'	            <TotalRoomHotSpringTax>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>入湯税</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>=</EMAIL_BEG>		'+
'	                    <EMAIL_END>円</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </TotalRoomHotSpringTax>		'+
'	            <TotalPerRoomServiceFee>		'+
'	                <EMAIL_DETAIL>		'+
'	                    <EMAIL_TAG>サービス料</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>=</EMAIL_BEG>		'+
'	                    <EMAIL_END>円</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </EMAIL_DETAIL>		'+
'	            </TotalPerRoomServiceFee>		'+
'	        </RoomRateInformation>		'+
'	        <GuestInformation>		'+
'	            <GuestInformationList>		'+
'	                <GuestNameSingleByte>		'+
'	                    <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>(</EMAIL_BEG>		'+
'	                    <EMAIL_END>)</EMAIL_END>		'+
'	                </GuestNameSingleByte>		'+
'	                <GuestKanjiName>		'+
'	                    <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		'+
'	                    <EMAIL_END>様</EMAIL_END>		'+
'	                </GuestKanjiName>		'+
'	                <GuestDateOfBirth>		'+
'	                    <EMAIL_TAG>○誕生日</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                </GuestDateOfBirth>		'+
'	            </GuestInformationList>		'+
'	        </GuestInformation>		'+
'	    </RoomAndGuestInformation>		'+
'			'+
'	    <RisaplsInformation>		'+
'	        <RisaplsCommonInformation>		'+
'	            <Basic>		'+
'	                <SalesOfficeCompanyCode>28</SalesOfficeCompanyCode>		'+
'	                <PhoneNumber>		'+
'	                    <EMAIL_TAG>【電話番号】</EMAIL_TAG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                </PhoneNumber>		'+
'	                <Email>		'+
'	                    <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>【メールアドレス】</EMAIL_BEG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                </Email>		'+
'	                <PostalCode>		'+
'	                    <EMAIL_TAG>【住所】</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>〒</EMAIL_BEG>		'+
'	                    <EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>		'+
'	                </PostalCode>		'+
'	                <Address>		'+
'	                    <EMAIL_TAG>【住所】</EMAIL_TAG>		'+
'	                    <EMAIL_BEG> </EMAIL_BEG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([\u4e00-\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>		'+
'	                </Address>		'+
'	            </Basic>		'+
'	        </RisaplsCommonInformation>		'+
'	        <AgentNativeInformation>		'+
'	            <Extend>		'+
'	                <!--		'+
'	                 <PointName>		'+
'			'+
'	                 </PointName>		'+
'	                 <Points>		'+
'			'+
'	                 </Points> -->		'+
'			'+
'	            </Extend>		'+
'	            <Extendmytrip>		'+
'	                <!-- <SettlementDiv></SettlementDiv> -->		'+
'	            </Extendmytrip>		'+
'	        </AgentNativeInformation>		'+
'	    </RisaplsInformation>		'+
'	    <!-- 拡張項目取り込みマッピング定義機能【ps__Lead__c/ps__LeadIndex__c/contact】定義可能 -->		'+
'	    <CUSTOMER_SETTING>		'+
'	        <OBJECT>		'+
'	            <NAME>Lead__c</NAME>		'+
'	            <MAPPINGS>		'+
'	                <EMAIL_FIELD apiname="Field375__c">		'+
'	                    <EMAIL_DETAIL>		'+
'	                        <EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>		'+
'	                        <EMAIL_END>)</EMAIL_END>		'+
'	                        <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>		'+
'	                        <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	                    </EMAIL_DETAIL>		'+
'	                    <EMAIL_DETAIL>		'+
'	                        <EMAIL_TAG>○ご利用日時</EMAIL_TAG>		'+
'	                        <EMAIL_END>)</EMAIL_END>		'+
'	                        <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>		'+
'	                        <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	                    </EMAIL_DETAIL>		'+
'	                </EMAIL_FIELD>		'+
'	                <EMAIL_FIELD apiname="Field305__c">		'+
'	                    <EMIAL_TAG_FORMAT>○ご利用日時</EMIAL_TAG_FORMAT>		'+
'	                    <CONVERT_VAL>TRUE</CONVERT_VAL>		'+
'	                </EMAIL_FIELD>		'+
'	            </MAPPINGS>		'+
'	        </OBJECT>		'+
'	        <OBJECT>		'+
'	            <NAME>LeadIndex__c</NAME>		'+
'	            <MAPPINGS>		'+
'	                <EMAIL_FIELD apiname="Rooms__c">		'+
'	                    <EMAIL_TAG>○部屋数</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                    <EMAIL_END>部屋</EMAIL_END>		'+
'	                </EMAIL_FIELD> 		'+
'	            </MAPPINGS>		'+
'	        </OBJECT>		'+
'	        <OBJECT>		'+
'	            <NAME>Contact</NAME>		'+
'	            <MAPPINGS>		'+
'	                <EMAIL_FIELD apiname="Birthdate">		'+
'	                    <EMAIL_TAG>○誕生日</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                    <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>		'+
'	                    <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		'+
'	                </EMAIL_FIELD>		'+
'	                <EMAIL_FIELD apiname="MobilePhone">		'+
'	                    <EMAIL_TAG>携帯電話番号[Mobile Phone Number]</EMAIL_TAG>		'+
'	                    <EMAIL_BEG>：</EMAIL_BEG>		'+
'	                    <EMAIL_END>\n</EMAIL_END>		'+
'	                </EMAIL_FIELD>		'+
'	            </MAPPINGS>		'+
'	        </OBJECT>		'+
'			'+
'	    </CUSTOMER_SETTING>		'+
'	</AllotmentBookingReport>		';
    	// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'EmailTemplateForHtml';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(documentFile);
		insert item;
    }
    static String createDocument(){
		String htmlMailStr = '<html><head><meta http-equiv="Content-Type" content="text/html charset=utf-8"></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;" class=""><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em; font-family: "Meiryo UI"; font-size: 14px;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class=""><table cellpadding="0" cellspacing="0" width="700" class="" style="font-family: arial;"><tbody class=""><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif";"><div class="" style="margin: 0px;"><span class="" style="font-family: -webkit-system-font, "Helvetica Neue", Helvetica, sans-serif;"><b class="">件名:&nbsp;</b></span><span class="" style="font-family: -webkit-system-font, "Helvetica Neue", Helvetica, sans-serif;"><b class="">Expedia - New Booking</b><br class=""></span></div><br class=""><div class=""><font face="arial" size="-1" class="">NOTICE: The following notice is for hotel partners only. All other vendors (including Activity Service Providers) please disregard.<br class=""><b class="">HOTEL RESERVATION CONFIRMATIONS: Please provide booking confirmation code.</b><br class="">1. Enter confirmation code at&nbsp;<a href="http://www.%20expediapartnercentral.com/" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;">www.expediapartnercentral.com&nbsp;</a><a class="" style="color: rgb(0, 102, 153);">:::OR::: 2. REPLY to this email and INCLUDE the confirmation code<br class="">3. Email reservation id and confirmation code to&nbsp;</a><a href="mailto:booknotif@expedia.com" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;">booknotif@expedia.com</a>&nbsp;:::OR::: 4. Fax this page with the confirmation code to (702) 939-2697<br class=""><br class=""><basefont face="Arial, Helvetica, Sans Serif" class=""></font></div><table cellpadding="0" cellspacing="0" width="700" class=""><tbody class=""><tr valign="top" class=""></tr></tbody></table><table cellpadding="0" cellspacing="0" width="700" class=""><tbody class=""><tr class=""><td class="pageNotificationType" style="font-size: 20px; font-family: Arial; font-weight: bold; line-height: 30px; color: rgb(255, 153, 51); width: 210px;">New Reservation</td><td colspan="2" class="" style="font-size: 13px;"></td></tr><tr class=""><td rowspan="4" align="left" class="" style="font-size: 13px;"><img src="http://www.everestadmintools.com/pubspec/Images/Header/logo_expedia.png" alt="Expedia Logo" class="" norescale="true" style="max-width: inherit;"></td><td class="pageHeading" style="font-size: 16px; font-family: Arial; font-weight: bold; line-height: 30px;">Jinya Ryokan</td><td rowspan="4" align="right" class="" style="font-size: 13px;"><img src="http://www.everestadmintools.com/pubspec/Images/Header/logo_lps.png" alt="Expedia Lodging Partner Services Logo" class="" norescale="true" style="max-width: inherit;"></td></tr><tr class=""><td class="" style="font-size: 13px;">Hadano,Kanagawa-ken,JPN</td></tr><tr class=""><td class="" style="font-size: 13px;">Attn: Dual Notification</td></tr><tr class=""><td class="" style="font-size: 13px;"><b class="">PLEASE NOTE: This fax may be a duplicate of an electronic notification already reflected in your system. Please verify before making any changes.</b></td></tr></tbody></table><font face="arial" size="-1" class=""><br class=""><table cellpadding="0" cellspacing="0" width="700" class=""><tbody class=""><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif";"><table cellpadding="10" cellspacing="0" width="700" class="" style="border-top-left-radius: 5em; border-top-right-radius: 5em; border-bottom-right-radius: 5em; border-bottom-left-radius: 5em; background-color: rgb(0, 51, 102); color: rgb(0, 51, 102);"><tbody class=""><tr class=""><td class="fontPaymentExpediaCollect" colspan="3" align="center" style="font-size: 18px; font-family: Arial; font-weight: bold; line-height: 30px; color: rgb(255, 255, 255);">Guest has PRE-PAID Expedia</td></tr></tbody></table></td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif"; height: 10px;"></td></tr><tr class=""><td colspan="3" align="LEFT" class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif";"><b class="">Travel arrangements provided through Expedia</b></td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif"; height: 20px;"></td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif"; width: 210px;"><b class="">Reservation ID:&nbsp;</b><a href="https://he.expediapartnercentral.com/HotelExtranet/DetailedReservation.htm?reservationID=539268586&amp;tab=Reservations&amp;htid=4736323" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;">5392</a>4174555</td><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif"; width: 210px;"><b class="">Guest:&nbsp;</b>Kyuri Kim</td><td align="right" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; width: 280px;">Booked on: June 20 2015 07:39PST</td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; width: 210px;"></td><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; width: 210px;">81 (080) 9201333</td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; width: 210px;"></td><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; width: 210px;"></td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; height: 11px;"></td></tr><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';">Room Type Code: 200124419</td></tr><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';"><table cellpadding="0" cellspacing="0" class=""><tbody class=""><tr class=""><td class="" style="font-size: 13px;">Room Type Name:</td><td class="" style="font-size: 13px; width: 4px;"></td><td class="" style="font-size: 13px;">Japanese style room - Breakfast included</td></tr></tbody></table></td></tr><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';">Pricing Model: Occupancy Based Pricing</td></tr><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';">Payment Instructions: Expedia collects payment from traveler: Hotel invoices Expedia.</td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; height: 11px;"></td></tr><tr class=""><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';"><table cellpadding="0" cellspacing="0" width="700" class=""><tbody class=""><tr valign="bottom" class=""><td class="" style="font-size: 13px;">Check-In</td><td class="" style="font-size: 13px;">Check-Out</td><td class="" style="font-size: 13px;">Adults</td><td class="" style="font-size: 13px;">Kids/Ages</td><td class="" style="font-size: 13px;">Room Nights</td><td class="" style="font-size: 13px;">Hotel Conf</td></tr><tr valign="top" class=""><td class="" style="font-size: 13px;">June 13 2015</td><td class="" style="font-size: 13px;">June 15 2015</td><td class="" style="font-size: 13px;">2</td><td class="" style="font-size: 13px;">0</td><td class="" style="font-size: 13px;">2</td></tr><tr valign="top" class=""><td class="" style="font-size: 13px;">June 13 2015</td><td class="" style="font-size: 13px;">June 15 2015</td><td class="" style="font-size: 13px;">2</td><td class="" style="font-size: 13px;">0</td><td class="" style="font-size: 13px;">2</td></tr></tbody></table></td></tr></tbody></table></font></td></tr></tbody></table><table cellpadding="0" cellspacing="0" width="700" class=""><tbody class=""><tr valign="bottom" class="" style="font-family: arial; font-size: small; line-height: 1.5;"><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';"><b class="">Special Request</b></td></tr><tr valign="BOTTOM" class="" style="font-family: arial; font-size: small; line-height: 1.5;"><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';">1 Japanese futon , Non-Smoking</td></tr><tr class="" style="font-family: arial; font-size: small; line-height: 1.5;"><td class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\'; height: 11px;"></td></tr><tr class="" style="font-family: arial; font-size: small; line-height: 1.5;"><td colspan="3" class="" style="font-size: 13px; font-family: Arial, Helvetica, \'Sans Serif\';"><table cellpadding="0" cellspacing="0" width="100%" class=""><tbody class=""><tr valign="top" class=""><td class="" style="font-size: 13px;"><table class=""><tbody class=""><tr class=""><td colspan="7" class="" style="font-size: 13px;"><b class="">Daily Rate - 28,636 JPY</b></td></tr><tr class=""><td class="" style="font-size: 13px;">Sat, June 13</td><td class="" style="font-size: 13px;"></td></tr><tr class=""><td colspan="8" class="" style="font-size: 13px;"><table cellpadding="0" cellspacing="0" width="420" class=""><tbody class=""><tr class=""><td class="" style="font-size: 13px; width: 189px;">Rate Code: 203922480</td><td class="" style="font-size: 13px; width: 42px;"></td><td class="" style="font-size: 13px; width: 189px;"></td></tr></tbody></table></td></tr></tbody></table></td><td align="right" class="" style="font-size: 13px;"><table cellspacing="0" cellpadding="0" class=""><tbody class=""><tr class=""><td class="" style="font-size: 13px; height: 11px;"></td></tr><tr class=""><td align="right" class="" style="font-size: 13px;">Extra Person:</td><td align="right" class="" style="font-size: 13px;">0 JPY</td></tr><tr class=""><td align="right" class="" style="font-size: 13px;">Taxes:</td><td align="right" class="" style="font-size: 13px;">5,384 JPY</td></tr><tr class=""><td align="right" class="" style="font-size: 13px;">Extra Charges:</td><td align="right" class="" style="font-size: 13px;">0 JPY</td></tr><tr class=""><td align="right" class="" style="font-size: 13px;"><b class="">Total Cost:&nbsp;</b></td><td align="right" class="" style="font-size: 13px;"><b class="">34,020 JPY</b></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr class="" style="font-family: arial; font-size: small; line-height: 1.5;"></tr></tbody></table><table width="700" class="" style="font-family: arial;"><tbody class=""><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif";"><hr class=""></td></tr><tr class=""><td align="CENTER" class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(255, 153, 51); font-weight: bold;">DO NOT DISCLOSE CONTRACTED RATES TO GUESTS</td></tr><tr class=""><td align="CENTER" class="pageFooter" style="font-size: 13px; font-family: Arial;"><a href="https://he.expediapartnercentral.com/HotelExtranet/DetailedReservation.htm?reservationID=539268586&amp;tab=Reservations&amp;htid=4736323" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;"><b class="">View or confirm the reservation</b></a>&nbsp;at&nbsp;<a href="http://expediapartnercentral.com/" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;">ExpediaPartnerCentral.com</a></td></tr><tr class=""><td class="" style="font-size: 13px; font-family: Arial, Helvetica, "Sans Serif";"><hr class=""><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em; font-family: "Meiryo UI"; font-size: 14px; line-height: 21px;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><div class="" style="word-wrap: break-word; -webkit-line-break: after-white-space; position: static !important;"><div class="" style="position: static !important;"><blockquote type="cite" class="" style="margin-top: 0px; margin-bottom: 0px; margin-left: 0.5em;"><div class="" style="position: static !important;"><font face="arial" size="-1" class=""><table width="700" class=""><tbody class=""><tr class=""><td align="left" colspan="4" class="fontFooter2" style="font-size: 11px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(102, 102, 102);"><b class="">You may contact us at any time</b>&nbsp;by phone 332986517, by email&nbsp;<a href="mailto:assistanceJP@expedia.com" class="" style="color: rgb(0, 102, 153); text-decoration: none !important;">assistanceJP@expedia.com</a>, or by fax 1 (702) 9392697</td></tr><tr class=""><td class="fontFooter2" style="font-size: 11px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(102, 102, 102);">Report Date: June 11 2015 07:39PST</td><td class="fontFooter2" style="font-size: 11px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(102, 102, 102);">Hotel Code: 4736323</td><td class="fontFooter2" style="font-size: 11px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(102, 102, 102);">Chain Code: Not Applicable</td><td class="fontFooter2" style="font-size: 11px; font-family: Arial, Helvetica, "Sans Serif"; color: rgb(102, 102, 102);">Brand Code: Not Applicable</td></tr></tbody></table></font></div></blockquote></div></div></div></blockquote></div></div></div></blockquote></div></div></div></blockquote></div></div></div></blockquote></td></tr></tbody></table></div></blockquote></div></div></div></blockquote></div></div></div></blockquote></div></div></div></blockquote></div></div></div></blockquote><div class=""><br class=""></div></body></html>';

String documentFile = '<root>														'+
'	<EMAIL_TEMPLATE>                                                                                        '+
'		<EMAIL_HEAD>                                                                                    '+
'			<HTML_TEM>                                                                              '+
'			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  '+
'			【宿泊施設名】：元湯陣屋                                                                '+
'			【宿泊施設コード】：01                                                                '+
'			【旅行会社名】：Expedia                                                                 '+
'			■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  '+
'			====================＜$$__データ種別__$$＞====================                        '+
'			受付時間：$$__受付時間__$$                                                              '+
'			予約Ｎｏ：$$__予約Ｎｏ__$$                                                              '+
'			                                                                                        '+
'			【宿泊代表者氏名】$$__宿泊代表者氏名__$$                                                '+
'			【電話番号】$$__電話番号__$$                                                            '+
'			【メールアドレス】$$__メール__$$                                                        '+
'			【住所】$$__住所__$$                                                                    '+
'			                                                                                        '+
'			○チェックイン日時：$$__チェックイン日時__$$                                            '+
'			○泊数　　　　　　：$$__泊数__$$泊                                                      '+
'			○部屋数　　　　　：$$__部屋数__$$部屋                                                  '+
'			○部屋タイプコード：$$__部屋タイプコード__$$                                            '+
'			○部屋タイプ　　　：$$__部屋タイプ__$$                                                  '+
'			○ご要望・ご質問　：$$__ご要望・ご質問__$$                                              '+
'			○料金区分　　　　：$$__料金区分__$$                                                    '+
'			○支払方法　　　　：$$__支払方法__$$                                                    '+
'			■料金明細■                                                                            '+
'			-----------------------------------------------------------                             '+
'			</HTML_TEM>                                                                             '+
'		</EMAIL_HEAD>                                                                                   '+
'		<EMAIL_DETAIL>                                                                                  '+
'			<HTML_HEAD>                                                                             '+
'				■$_$部屋目                                                                     '+
'			</HTML_HEAD>                                                                            '+
'			<HTML_TEM>                                                                              '+
'	            $$__Check-In__$$                                                                            '+
'	            $$__大人__$$                                                                                '+
'	            $$__小人__$$                                                                                '+
'	            $$__20__$$円×$$__21__$$＝$$__22__$$                                                        '+
'	            $$__24__$$                                                                                  '+
'	            ----------------------------------------                                                    '+
'            </HTML_TEM>                                                                                        '+
'		</EMAIL_DETAIL>                                                                                 '+
'		<EMAIL_END>                                                                                     '+
'			<HTML_TEM>                                                                              '+
'			【小計金額】　$$__小計金額__$$                                                          '+
'			【消費税】$$__消費税__$$                                                                '+
'			----------------------------------------                                                '+
'			【合計金額】　$$__合計金額__$$                                                          '+
'			-----------------------------------------------------------                             '+
'			</HTML_TEM>                                                                             '+
'		</EMAIL_END>                                                                                    '+
'	</EMAIL_TEMPLATE>                                                                                       '+
'	<!-- HTML書式から指定書式メール電文変換条件指定、これから各AGTのHTMLの書式により、定義を行う -->        '+
'	<EMIAL_DATA>                                                                                            '+
'	  	<EMAIL_HEAD>                                                                                    '+
'	  		<HTML_BEG>Travel arrangements provided through Expedia</HTML_BEG>                       '+
'	  		<HTML_DETAIL>                                                                           '+
'		        <HTML_TAG>New Booking</HTML_TAG>                                                        '+
'		        <DETAIL_IDX>$$__データ種別__$$</DETAIL_IDX>                                           '+
'		        <HTML_VALUE>新規予約メール</HTML_VALUE>                                                 '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG >Reservation ID</HTML_TAG>                                                    '+
'		        <HTML_BEG>:</HTML_BEG>                                                                  '+
'		        <DETAIL_IDX>$$__予約Ｎｏ__$$</DETAIL_IDX>                                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG >Guest</HTML_TAG>                                                             '+
'		        <HTML_BEG>:</HTML_BEG>                                                                  '+
'		        <DETAIL_IDX>$$__宿泊代表者氏名__$$</DETAIL_IDX>                                         '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG type="vertical">Guest</HTML_TAG>                                              '+
'		        <DETAIL_IDX>$$__電話番号__$$</DETAIL_IDX>                                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG >Booked on</HTML_TAG>                                                         '+
'		        <HTML_BEG>:</HTML_BEG>                                                                  '+
'		        <DETAIL_IDX type="datetime">$$__受付時間__$$</DETAIL_IDX>                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG  type="moreTd" skiptd="1">Room Type Name</HTML_TAG>                           '+
'		        <DETAIL_IDX>$$__部屋タイプ__$$</DETAIL_IDX>                                             '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG>Room Type Code</HTML_TAG>                                                     '+
'		        <HTML_BEG>:</HTML_BEG>                                                                  '+
'		        <DETAIL_IDX>$$__部屋タイプコード__$$</DETAIL_IDX>                                       '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		    	<HTML_TAG>Pricing Model</HTML_TAG>                                                      '+
'		    	<HTML_BEG>:</HTML_BEG>                                                                  '+
'				<HTML_FORMAT>Occupancy Based Pricing</HTML_FORMAT>                              '+
'				<HTML_VALUE>RoomRate</HTML_VALUE>                                               '+
'		    	<DETAIL_IDX>$$__料金区分__$$</DETAIL_IDX>                                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG type="moreTd">Payment Instructions</HTML_TAG>                                 '+
'		    </HTML_DETAIL>                                                                              '+
'		</EMAIL_HEAD>                                                                                   '+
'		<EMAIL_DETAIL detailidx="$$__部屋数__$$">                                                       '+
'			<HTML_BEG>Check-In</HTML_BEG>                                                           '+
'			<DETAIL_IDX template="部屋料金：$$__部屋料金__$$">$$__24__$$</DETAIL_IDX>               '+
'	        <HTML_DETAIL>                                                                                   '+
'	            <HTML_TAG type="loopDate" >Check-In</HTML_TAG>                                              '+
'	            <HTML_FORMAT>([a-zA-Z]+) [\\d]{2} [\\d]{4}</HTML_FORMAT>                                      '+
'	            <DETAIL_IDX>$$__Check-In__$$</DETAIL_IDX>                                                   '+
'	            <DETAIL_IDX template="MIN">$$__チェックイン日時__$$</DETAIL_IDX>                            '+
'	        </HTML_DETAIL>                                                                                  '+
'	        <!--                                                                                            '+
'	        <HTML_DETAIL>                                                                                   '+
'	            <HTML_TAG>Check-Out</HTML_TAG>                                                              '+
'	        </HTML_DETAIL>                                                                                  '+
'	         -->                                                                                            '+
'	        <HTML_DETAIL>                                                                                   '+
'	            <HTML_TAG>Adults</HTML_TAG>                                                                 '+
'	            <DETAIL_IDX template="【大人】:$_$名">$$__大人__$$</DETAIL_IDX>                             '+
'	        </HTML_DETAIL>                                                                                  '+
'	        <!--                                                                                            '+
'	        <HTML_DETAIL>                                                                                   '+
'	            <HTML_TAG>Kids/Ages</HTML_TAG>                                                              '+
'	            <DETAIL_IDX template="小人:$_$">$$__小人__$$</DETAIL_IDX>                                   '+
'	        </HTML_DETAIL>                                                                                  '+
'	         -->                                                                                            '+
'	        <HTML_DETAIL>                                                                                   '+
'	            <HTML_TAG type="loop">Room Nights</HTML_TAG>                                                '+
'	            <DETAIL_IDX>25</DETAIL_IDX>                                                                 '+
'	            <DETAIL_IDX template="MAX">$$__泊数__$$</DETAIL_IDX>                                        '+
'	        </HTML_DETAIL>                                                                                  '+
'		 </EMAIL_DETAIL>                                                                                '+
'		<EMAIL_FOOT>                                                                                    '+
'			<HTML_BEG>Travel arrangements provided through Expedia</HTML_BEG>                       '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG type="vertical">Special Request</HTML_TAG>                                    '+
'		        <DETAIL_IDX>$$__ご要望・ご質問__$$</DETAIL_IDX>                                         '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG>Daily Rate</HTML_TAG>                                                         '+
'		        <HTML_BEG>- </HTML_BEG>                                                                 '+
'		        <DETAIL_IDX>$$__小計金額__$$</DETAIL_IDX>                                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG>Rate Code</HTML_TAG>                                                          '+
'		        <HTML_BEG>:</HTML_BEG>                                                                  '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG type="moreTd">Total Cost</HTML_TAG>                                           '+
'		        <DETAIL_IDX>$$__合計金額__$$</DETAIL_IDX>                                               '+
'		        <DETAIL_IDX>$$__部屋料金__$$</DETAIL_IDX>                                               '+
'		    </HTML_DETAIL>                                                                              '+
'		    <HTML_DETAIL>                                                                               '+
'		        <HTML_TAG type="moreTd">Taxes</HTML_TAG>                                                '+
'		        <DETAIL_IDX>$$__消費税__$$</DETAIL_IDX>                                                 '+
'		    </HTML_DETAIL>                                                                              '+
'		</EMAIL_FOOT>                                                                                   '+
'	</EMIAL_DATA>                                                                                           '+
'</root>';

// ドキュメントを作成する
		Document item = new Document();
		item.Name = 'EmailTemplateForExpedia';
		item.DeveloperName = item.Name;
		item.FolderId = UserInfo.getUserId();
		item.Body = Blob.valueOf(documentFile);
		insert item;
    	return htmlMailStr;
    }
	private static void insertConfigDoc() {
     	String mailServiceAddress = 'bookingemail@0-12sqgik8q15k082q6bbk2iju37he3qbf8fk3q4qgxm4alhmw6l.d-dbjcea2.na14.apex.salesforce.com';
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailImportServiceConfig';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	String mapString = '<?xml version="1.0" encoding="UTF-8"?><root><COMMON><LEADINTERVAL>60</LEADINTERVAL><LEADDELETEVAL>-14</LEADDELETEVAL><AGTS><AGT NMKEY="Expedia" template="EmailTemplateForExpedia">28</AGT><AGT NMKEY="予約プロ" template="EmailTemplateForYoyakuPro">88</AGT><AGT NMKEY="ｅ宿" template="EmailTemplateForEsyoku">55</AGT>        </AGTS>        <MAIL_ADDRESS_MATCH>        <RULE MAILADDRESS="'+mailServiceAddress+'">02</RULE>        </MAIL_ADDRESS_MATCH></COMMON><SHOP><SHOPCODE>02</SHOPCODE><APPCONFIG><UCACTISSYNC>TRUE</UCACTISSYNC><ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN><ROOMSORT>DESC</ROOMSORT> <DEFAULTVALUES>  <APIFIELDNAME></APIFIELDNAME>     <APIFIELDVALUE></APIFIELDVALUE>    </DEFAULTVALUES></APPCONFIG><ACCOUNTCONFIG><NYUUTOUACCOUNT></NYUUTOUACCOUNT><SERVICEACCOUNT></SERVICEACCOUNT></ACCOUNTCONFIG> <PLANCODE_CONVERT><AGT NAME="XXXXXXX"><CONVERT><AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE><SFPLANNO>YYYYYYYY</SFPLANNO></CONVERT></AGT></PLANCODE_CONVERT><CONTACT_INFO_PARSE><PARSE_LOGIC_INFO AGTCODE=""><KEYWORD>携帯電話;Mobile Phone Number</KEYWORD><FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT><TOFIELD>Contact.Phone</TOFIELD><EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO><PARSE_LOGIC_INFO AGTCODE=""><KEYWORD>誕生日;Birthday</KEYWORD><FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT><TOFIELD>Contact.Birthday</TOFIELD><EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO></CONTACT_INFO_PARSE><!-- 事前決済区分とAGTコードにより、指定の会計商品を取り込み --><PAYMENT_CONVERTS><!-- 引額(ポイント・補助金)金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する --><POINT_CONVERT PAYKBN="3"><!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント--></POINT_CONVERT><POINT_CONVERT PAYKBN="2"><!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント--></POINT_CONVERT><!-- 事前決済金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する --><PAYMENT_CONVERT PAYKBN="2">          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント--></PAYMENT_CONVERT>     </PAYMENT_CONVERTS><!-- 事前支払方法キーワード定義 --><PRE_PAYMENT_DEF>   <!-- XMLに類語変換機能タグ XML_VAL:XMLから出力の支払方法、--><CREDIT>一括精算,パッケージ予約</CREDIT><!-- 支払方法タグに該当キーワードを含めすると、お客様請求金額は売掛明細として、見積明細に反映する --><CRAD>事前カード決済</CRAD></PRE_PAYMENT_DEF></SHOP></root>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;	
	}
}