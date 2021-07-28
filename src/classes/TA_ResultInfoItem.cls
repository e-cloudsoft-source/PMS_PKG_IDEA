public with sharing class TA_ResultInfoItem {
	public TA_ResultInfoItem(Dom.XMLNode commRes) {
		Dom.XMLNode codeField = commRes.getChildElement('Code', null);
		Dom.XMLNode errorMessageField = commRes.getChildElement('ErrorMessage', null);
		if (codeField != null) failureReason = CommUtils.nullToBlank(codeField.getText());
		if (errorMessageField != null) errorDescription= CommUtils.nullToBlank(errorMessageField.getText());
	}
	public TA_ResultInfoItem() {}
	public void setIsSuccess() { failureReason = '0000'; }
    public String failureReason{get;set;}
    public String errorDescription{get;set;}
    public Boolean isSuccess{get{return failureReason == '0000';}}
    public override string toString() {
    	return (CommUtils.nullToblank('failureReason:' +failureReason + ' errorDescription:' + errorDescription));
    }
    public void setFail(String errMsg) {
    	failureReason = 'UNKNOWN';
    	errorDescription = CommUtils.nullToBlank(errMsg).stripHtmlTags();
    }
}