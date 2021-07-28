/**
* 予約情報通知機能戻る結果情報
* 該当処理で、予約情報単位で配列に格納する
* 2016/06/22 不整合の結果を戻る場合、回避処理　TAから戻る予約情報のBODY情報はタグ「TransactionInformationTag」がない場合、取得結果はNULLで設定する
**/
public with sharing class TA_BookingInfoOutputInfoItem {
    public TA_BookingInfoOutputInfoItem(String strXmlBody) {
    	bookingInfoList = new list<BookingInfo>();	
		// 200は任意の数値、Exceptionが発生する場合、該当文字列以内
		if (CommUtils.nullToBlank(strXmlBody).startsWithIgnoreCase('<?xml version="1.0" encoding="utf-8"?><Error><Code>')) {
	    	Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
			
			Dom.XmlNode root = doc.getRootElement();
			String rootNodeName = root.getName();
			if (rootNodeName == 'Error')  commonResponse = new TA_ResultInfoItem(root);
			return;
		} 
		/* 予約取得情報は不整合の場合、処理対象外にする BEGIN
		else {
			commonResponse = new TA_ResultInfoItem();
			commonResponse.setIsSuccess();
		}*/
		//substringBetween
		String TransactionInformationTag = strXmlBody.substringBetween('<TransactionInformation>','</TransactionInformation>');
		// 予約取得情報は不整合の場合、処理対象外にする
		// 2016/06/22 不整合の結果を戻る場合、回避処理 BEGIN
		commonResponse = new TA_ResultInfoItem();
		if (TransactionInformationTag == null) {
			commonResponse.setFail(strXmlBody);
			return;
		} else {
			commonResponse.setIsSuccess();
		}
		// 2016/06/22 不整合の結果を戻る場合、回避処理 END
    	String dataIdTag = CommUtils.nullToBlank(TransactionInformationTag.substringBetween('<DataID>','</DataID>'));
    	String endFlagTag = CommUtils.nullToBlank(TransactionInformationTag.substringBetween('<EndFlag>','</EndFlag>'));
    	if (!CommUtils.isBlank(dataIdTag)) dataId = dataIdTag;
    	if (!CommUtils.isBlank(endFlagTag)) endFlag = Boolean.valueOf(endFlagTag);
//System.debug(logginglevel.INFO, 'dataIdTag=' + dataIdTag);	
//System.debug(logginglevel.INFO, 'endFlagTag=' + endFlagTag);
//System.debug(logginglevel.INFO, 'TransactionInformationTag=' + TransactionInformationTag);	
    	Integer bodyFirstPos = strXmlBody.indexOf('<AllotmentBookingReport>');
    	Integer bodyLastPos = strXmlBody.lastIndexOf('</AllotmentBookingReport>');
    	// 2016/06/22 不整合の結果を戻る場合、回避処理 BEGIN
    	if (bodyFirstPos > 0 && bodyLastPos > 0) {
    	// 2016/06/22 不整合の結果を戻る場合、回避処理 END
    		String bodyXml = strXmlBody.substring(bodyFirstPos,bodyLastPos);
	    	String[] strBookinfLst = bodyXml.split('</AllotmentBookingReport>');
	    	for (String singBooking : strBookinfLst) {
	    		if (CommUtils.isBlank(singBooking)) continue;
	    		BookingInfo bookinf = new BookingInfo(singBooking+'</AllotmentBookingReport>');
				bookingInfoList.add(bookinf);
	    	}
    	}
    }
    // 該当連携のDataID
    public String dataId{get;set;}
    public Boolean endFlag{get;set;}
 	
 	public TA_ResultInfoItem commonResponse{get; private set;}
    // 連携XML情報格納
    public list<BookingInfo> bookingInfoList{get;set;}
    
	public class BookingInfo {
		public BookingInfo(String singBooking) {
			infoTravelXML = singBooking;
		}
		public String infoTravelXML{get;set;}
	}
}