public with sharing class WS_ResultInfo {
 	public boolean IsSuccess{get;set;}
 	public string ErrorCode{get;set;}
 	public string ErrorMessage{get;set;}   
 	public WS_ResultInfo() {
 		IsSuccess = true;	
 	}
 	public WS_ResultInfo(String errCode, String errMsg) {
 		IsSuccess = false;
 		ErrorCode = errCode;
 		ErrorMessage = errMsg;
 	}
 	// エラー情報はXML方式に変更を行う
 	public string toXml(){
 		String repXml = '<IsSuccess>'+String.valueOf(IsSuccess) + '</IsSuccess>';
 		if (!CommUtils.isBlank(ErrorCode)) repXml+= '<ErrorCode>'+ErrorCode.escapeXml()+'</ErrorCode>';
 		if (!CommUtils.isBlank(ErrorMessage)) repXml+= '<ErrorMessage>'+ErrorMessage.escapeXml()+'</ErrorMessage>';
 		return repXml;
 	}
}