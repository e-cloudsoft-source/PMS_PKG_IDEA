/**
* 会計書、請求書を自動作成、会計に紐付く格納する
**/
public with sharing class PdfAutoSaveUtil {
    public static final String isCallFromAutoPdfKey = '_autopdf';
    // 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
    // 会計書PDF複数保持フラグ
    private static final Boolean acctPdfDupVerFlg = CommDefine__c.getOrgDefaults().PdfGeneralFlgForAccountDupVer__c == null ? false : CommDefine__c.getOrgDefaults().PdfGeneralFlgForAccountDupVer__c;
    // 請求書PDF複数保持フラグ
    private static final Boolean billPdfDupVerFlg = CommDefine__c.getOrgDefaults().PdfGeneralFlgForBillDupVer__c == null ? false : CommDefine__c.getOrgDefaults().PdfGeneralFlgForBillDupVer__c;
    // 2019/09/23 PDF複数保持できるように改善対応 WSQ END
    // 会計書情報をPDF作成して、該当会計に紐付くする
    @future (callout=true)
    public static void syncAccountPdfToAtta(map<string,string> paramMap, Id accountId, String pageName) {

    	// 該当会計にPDF会計書を格納されれているがチェックする
		Boolean isGroupShowFlg = paramMap.get('g') == '1' ? true : false;	// 会計分割表示するがどうか判断フラグ　
		String groupNo = CommUtils.nullToBlank(paramMap.get('gno'));	// 分割NO
		String accountNmPlus = isGroupShowFlg ? groupNo+'_' : '';
    	List<AccountAcount__c> accCtrl = [select id, name from AccountAcount__c where id = :accountId];
		String fileName = Label.CONST_012_0510+'_'+accountNmPlus+accCtrl[0].Name;
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
		if (acctPdfDupVerFlg) fileName+= getRandomNum();
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ END
		// Call Pdf General
		autoGeneralPdf(fileName, pageName, accountId, paramMap);
		
    }
    // 2018/12/15 請求書の作成など自動繰返し機能 by zy BEGIN
    public static void syncBillPdfToAttachment(map<string,string> paramMap, Id accountId, String pageName) {
    	// 該当会計にPDF会計書を格納されれているがチェックする
    	List<AccountAcount__c> accCtrl = [select id, name,relaccount__r.name from AccountAcount__c where id = :accountId];
    	String fileName = accCtrl[0].relaccount__r.name + '_' + Label.CONST_012_0511 + '_' + accCtrl[0].Name;
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
		if (billPdfDupVerFlg) fileName+= getRandomNum();
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ END
		// Call Pdf General
		autoGeneralPdf(fileName, pageName, accountId, paramMap);
    }
    // 2018/12/15 請求書の作成など自動繰返し機能 by zy END
    // 請求書情報をPDF作成して、該当会計に紐付くする
    @future (callout=true)
    public static void syncBillPdfToAtta(map<string,string> paramMap, Id accountId, String pageName) {

    	// 該当請求書を格納されれているがチェックする
		Boolean isGroupShowFlg = paramMap.get('g') == '1' ? true : false;	// 会計分割表示するがどうか判断フラグ　
		String groupNo = CommUtils.nullToBlank(paramMap.get('gno'));	// 分割NO
		String accountNmPlus = isGroupShowFlg ? groupNo+'_' : '';
    	List<AccountAcount__c> accCtrl = [select id, name from AccountAcount__c where id = :accountId];
		String fileName = Label.CONST_012_0511+'_'+accountNmPlus+accCtrl[0].Name;
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
		if (billPdfDupVerFlg) fileName+= getRandomNum();
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ END
		// Call Pdf General
		autoGeneralPdf(fileName, pageName, accountId, paramMap);
    }
    // 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
    // 請求書情報をPDF作成して、該当予約に紐付くする
    public static void syncLeadPdfToAttachment(map<string,string> paramMap, Id leadId, String pageName) {
    	// 該当会計にPDF会計書を格納されれているがチェックする
		//String pageName = '/apex/LeadPDF';
    	List<Lead__c> accCtrl = [select id, No__c,relcontact__r.name from Lead__c where id = :leadId for update];
		String fileName = accCtrl[0].relcontact__r.name + '_' + Label.CONST_012_0511 + '_'+accCtrl[0].No__c;
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
		if (billPdfDupVerFlg) fileName+= getRandomNum();
		// 2019/09/23 PDF複数保持できるように改善対応 WSQ END
		// Call Pdf General
		autoGeneralPdf(fileName, pageName, leadId, paramMap);
    }
    // 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
    /* 2019/10/31 WSQ 該当機能利用不要ため、一時削除
    @future (callout=true)
    public static void syncLeadPdfToAtta(map<string,string> paramMap, Id leadId, String pageName) {

    	// 該当会計にPDF会計書を格納されれているがチェックする
		//String pageName = '/apex/LeadPDF';
    
    	List<Lead__c> accCtrl = [select id, No__c from Lead__c where id = :leadId for update];
		String fileName = '見積書_'+accCtrl[0].No__c;
	
		// Call Pdf General
		autoGeneralPdf(fileName, pageName, leadId, paramMap);
    }*/
    // 今回のPDF出力はFutureのPDF自動作成から呼出する・しない判断ロジック
    //public static boolean isCallFromAutoPdf(map<string,string> paramMap) {
    //	return (paramMap.containsKey('_autopdf'));
    //}
    // 共通定義により、PDF自動作成する、しない確認する[会計書]
    public static boolean isRunAutoPdfFutureForAccount() {
    	return (CommDefine__c.getOrgDefaults().PdfGeneralFlgForAccount__c);
    }
    // 共通定義により、PDF自動作成する、しない確認する[請求書]
    public static boolean isRunAutoPdfFutureForBill() {
    	return (CommDefine__c.getOrgDefaults().PdfGeneralFlgForBill__c);
    }
    // 共通定義により、PDF自動作成する、しない確認する[見積書]
    public static boolean isRunAutoPdfFutureForEst() {
    	//return (CommDefine__c.getOrgDefaults().PdfGeneralFlgForAccount__c);
    	return true;
    }
    
    private static void autoGeneralPdf(String fileName, String pageName, String accountId, map<string,string> paramMap) {
		// 2018/02/23 Security Check BEGIN
		List<String> insChkFields = new List<String>{'ParentId','ContentType','Body','name'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		// 2018/02/23 Security Check END
		// 2018/02/23 Security Check BEGIN
		List<String> ChkFields = new List<String>{'body'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(ChkFields, m)) {
			return;
		}
		// 2018/02/23 Security Check END
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		if(comDayItem.setComDay()){
			// 获取当前会计
			List<AccountAcount__c> accLst = [Select Id, SalesdayCal__c, ShopCode__c From AccountAcount__c Where Id =: accountId];
			for(AccountAcount__c acc : accLst){
				// 设定Error成功跳出不可以变更PDF
				if(CommLogicProcess.isAccLockFlg(acc, accAdminItem, comDayItem, true)) return;
			}
		}
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		// FutureからPDFを作成するとき、LOOP制御するため、パラメータはMAPに追加する
		map<string,string> newParMap = paramMap.clone();
		newParMap.put(isCallFromAutoPdfKey,'1');
    	PageReference pdf = new PageReference( pageName );
    	pdf.getParameters().putAll(newParMap);
		//pdf.setRedirect(true);
//System.debug(loggingLevel.info, '----- pdf INFO -----' + pdf);
//System.debug(loggingLevel.info, '----- pdf paramMap -----' + paramMap);
		// 2018/03/27 TestClass对应 WGCH BEGIN
		// Blob pageContent = pdf.getContentAsPDF();
		Blob pageContent = null;
		if (!Test.isRunningTest()){
		    pageContent = pdf.getContentAsPDF();
		} else{
			// テストクラスするため
		    pageContent = Blob.valueof('Some random String');
		}
		// 2018/03/27 TestClass对应 WGCH END
		// 存在ファイルをチェックする
		List<Attachment> attachment = [select ParentId, Name, ContentType from Attachment where ParentId = :accountId And Name = :fileName order by LastModifiedDate desc limit 1];
		if (attachment.isEmpty()) {
			Attachment attFile = new Attachment (
				name = fileName,
				ParentId = accountId,
				ContentType = 'application/pdf',
				Body = pageContent
			);
			insert attFile;
//System.debug(loggingLevel.info, 'attFile='+attFile.ID);
		} else {
			attachment[0].body = pageContent;
			update attachment;
//System.debug(loggingLevel.info, 'attachment='+attachment[0].ID);
		}

    }
    // 2019/09/23 PDF複数保持できるように改善対応 WSQ BEGIN
    private static string getRandomNum() {
    	return (System.now().format('_yyyyMMddHHmmssSSS'));
    }
    // 2019/09/23 PDF複数保持できるように改善対応 WSQ END
}