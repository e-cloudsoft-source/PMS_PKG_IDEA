public with sharing class PcaSyncCsvDownloadCtrl {
	/** File Attr Info */
	public String fileName{get; private set;}
	public String csvBody {get; private set;}
	/** Csv File Download */
	public PageReference downCsvFile() {
		String ids = System.currentPageReference().getParameters().get('rid');
		String userAgent = System.currentPageReference().getHeaders().get('USER-AGENT');
//System.debug(LoggingLevel.INFO, 'userAgent::::' + userAgent);
		Document downDoc = [select id, name, body from document where id =: ids];
		fileName = EncodingUtil.urlEncode(downDoc.Name, 'UTF-8');
		if (!userAgent.contains('MSIE'))fileName = EncodingUtil.urlDecode(fileName, 'ISO-8859-1');
		csvBody = downDoc.Body.toString();
		return null;
	}
}