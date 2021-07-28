public with sharing class EmailMessageToLeadImpl implements Messaging.InboundEmailHandler{
	private CommLogUtils log;
	private static final string CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG = '予約取込NG';
	public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'Name','Body','ParentId'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Attachment.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2017/02/24 Field Security Check END by wx
     	log = new CommLogUtils('EmailMessageToLeadImpl',true); 
     	log.write_method_start('EMAIL IMPORT');
     	String mailAdds;
		String htmlBody = email.htmlBody;
		Boolean isHtmlFlag = false;
		// 2016/08/01 HTML（Expedia)レイアウトの解析と取り込み by shuu BEGIN
		EmailHtmlMessageParse html;
		if ( !CommUtils.isBlank(htmlBody) && htmlBody.contains('<table')) {
			isHtmlFlag = true;
		}
     	Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		String emailBody = email.plainTextBody;
		
		// 2016/08/01 HTML（Expedia)レイアウトの解析と取り込み by shuu END
		list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
		EmailMessageToLeadHelp.AgtInfo currAgt = null;
		CooperationResult__c coo = new CooperationResult__c(
				//FunctionType__c = 'メール取込',
				FunctionType__c = CommConst.COOP_FUNTYPE_EMAIL,
				Status__c = 'メール取込待'
		);
		insert coo;
//System.debug(loggingLevel.INFO, 'newCoop='+coo.Id);
		setSendMailAddress(coo);
		// 取得のメール本文は連携結果に格納する、取込エラー発生すると、該当ファイルは残るまま
		Attachment mailAttachment = null;
		try {			
			// メール本文は添付ファイルとして、登録する
			Blob attBlog = Blob.valueOf(emailBody);
			mailAttachment = new Attachment(
				ParentId = coo.id,
				Name = 'MAIL_IMP_' + System.now().format('yyyyMMddHHmmssSSSS') + '_' + CommUtils.getGUID() + '.txt',
				//ContentType = 'text/xml',
				Body = attBlog
			);
			insert mailAttachment;
		} catch (Exception e) {
			// メール送信エラーをもどる
			// 処理結果の通知先の情報設定
			error(coo,String.valueOf(e));
		}
		
		//AGT コードを取得
		for (EmailMessageToLeadHelp.AgtInfo agtInf : agtLst) {
			if (emailBody.containsIgnoreCase(agtInf.agtNm)) {
				currAgt = agtInf;
				break;
			}
		}
		// 機能対応対象外 // TODO
		if (currAgt == null) {
			//定数
			error(coo,'AGT関連定義情報が見つかりません。');
			return result;
		}
		try {
			if ( !CommUtils.isBlank(emailBody) && isHtmlFlag) {
				html = new EmailHtmlMessageParse(currAgt);
				emailBody = html.exportEamil(htmlBody);
				currAgt.emailTemplate = CommUtils.isBlank(currAgt.extendTemplate) ? EmailMessageToLeadHelp.getCommConfig().htmlCommonTemplate : CommUtils.nullToBlank(currAgt.extendTemplate);
				//system.debug(logginglevel.info,'emailBody:::' + emailBody);
			}
			String fileName = mailAttachment.Name;
			log.write_log('取込AGT基本情報：'+ currAgt);
			// 取込異常の場合、メール送信して、報告する	
	        EmailMessageToLeadProcess e = new EmailMessageToLeadProcess(currAgt);
	        //if (isHtmlFlag) e.setHtmlBody(htmlBody);  
	        // メールテンプレート読み込み
			// メール内容により、取込用のXMLファイルを作成する
			String emailToXml = e.parseMailToXml(emailBody);
			log.write_log('XMLBODY：['+emailBody+']');
			// メールから店舗コード情報を取得する
			String mailAddress = envelope.toAddress;
			String shopCd = EmailMessageToLeadHelp.getCommConfig().mailMatchMap.get(mailAddress);
			log.write_log('店舗コード：['+shopCd+']へ取込実施');
			// XML TO SALESFORCE
			EmailMessageToLeadSync leadInfoToSfCtrl = new EmailMessageToLeadSync(e);
			EmailMessageToLeadParser parseXmlCtrl = new EmailMessageToLeadParser();	
			log.write_log('XMLBODY：['+emailToXml+']');
			EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo = parseXmlCtrl.parse(emailToXml,shopCd);	
			EmailMessageToLeadSync.BI_EMAIL_SyncResult syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,shopCd);
			log.write_log(leadInfoToSfCtrl.mLogUtils.getAllLog());
			log.write_log('XMLファイル'+fileName+'を取込終了');
			if(syncResult.result == EmailMessageToLeadSync.BI_EMAIL_Result.OK){
				if(!CommUtils.isBlank(syncResult.sfdcId)){
					fileName = mailAttachment.Name.substringBeforeLast('_') + '_' + bookingInfo.DataID.substringAfter('_') +'.xml';
					log.write_log('XMLファイル'+fileName+'を予約インデックスにアップロード開始');
					// 取込みXMLファイルを作成を行う
					Attachment newAttachment = mailAttachment.clone();
					newAttachment.ParentId = syncResult.sfdcId;
					newAttachment.body = Blob.valueOf(emailToXml);
					newAttachment.Name = fileName;
					insert newAttachment;
					// DEBUG MODEの場合、該当XMLファイルを削除なし
					if (!EmailMessageToLeadHelp.getCommConfig().bIsDebug) {
						// 2017/04/13 Sobject Security Check BEGIN
						if (CommSecurityUtils.isDeleteable(Attachment.getSObjectType())) {
						// 2017/04/13 Sobject Security Check END
						delete mailAttachment;
						// 2017/04/13 Sobject Security Check BEGIN
						}
						// 2017/04/13 Sobject Security Check END
					}
					log.write_log('XMLファイル'+fileName+'を予約インデックスにアップロード終了');
				}
				coo.Status__c = 'メール取込済';
				coo.ErrorContent__c = '';
				coo.ProcessLog__c = CommLogUtils.removeOverLogString(log.getAllLog());
			}else {
				log.write_log('処理エラーが発生しました。');
				error(coo,result.message);
			}
			coo.ShopCode__c = shopCd;
			update coo;
			log.write_log(leadInfoToSfCtrl.mLogUtils.getAllLog());
			log.write_method_end();
		}catch (Exception ex) {
			error(coo,String.valueOf(ex));
			if (EmailMessageToLeadHelp.getCommConfig().bIsDebug) throw ex;
		}
		return result;
     }
     private void setSendMailAddress(CooperationResult__c coop) {
		// メール送信
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if (CommUtils.isBlank(mailAdds)) mailAdds=UserInfo.getUserEmail();
		String[] toAddresses = mailAdds.split(',');
		coop.MailSendAddress1__c = toAddresses[0];
		if (toAddresses.size() > 1) coop.MailSendAddress2__c = toAddresses[1];
		if (toAddresses.size() > 2) coop.MailSendAddress3__c = toAddresses[2];
		if (toAddresses.size() > 3) coop.MailSendAddress4__c = toAddresses[3];
		if (toAddresses.size() > 4) coop.MailSendAddress5__c = toAddresses[4];
	}
	private void error(CooperationResult__c coo,String errorMessage){
		log.write_method_start('error');
		//定数
		coo.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_IMPORT_NG;
		log.write_error('lead load  error ===' + errorMessage);
		errorMessage = CommLogUtils.removeOverLogString(errorMessage,255);
		coo.Status__c = 'メール取込NG';
		coo.ErrorContent__c = errorMessage;
		coo.ErrorCount__c = 99;
		setSendMailAddress(coo);
		coo.ProcessLog__c = removeOverLogString(log.getAllLog());
		update coo;
		log.write_method_end();
	}
	/**
	* ログは最大格納値を超えると、最後から格納する
	**/
	private String removeOverLogString(String log) {
		return CommLogUtils.removeOverLogString(log);
	}
}