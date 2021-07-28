/*************************************
* アンケート表示機能
*
*************************************/
public with sharing class QuestionnaireCtrl {
	
	public QuestionnaireCtrl () {
		map<String,String> param = ApexPages.currentPage().getParameters();
		if (!param.containsKey('orgId')) {
			//必須なパラメータ情報を見つかりません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_012_0405));
			return;
		}
		//　アンケートから　OR 宿帳画面から引渡
		Id parId = Id.valueOf(param.get('orgId'));
		initPdfInfo(parId);
		// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		BEGIN
		initXmlDefine(param.get('lng'));
		// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		BEGIN
	}
	
   /**
    * レポートロゴ取得する
    **/
    public ReportLogo__c getReportInfo() {
    	// ユーザー所属する支店コードを取得、表示する
        return CommRepUtils.getReportTitleInfo();
    }
	//2016/11/25 TIMEZON fix BEGIN by zh
	public String dateFormat{get{return CommBaseCtrl.getDateFormat();}}
	//2016/11/25 TIMEZON fix END by zh
	public Lead__c leadInfo{get; private set;}
	public Contact contactInfo{get; private set;}
	private void initPdfInfo(Id objId) {
		// アンケート画面を開く場合
		if (objId.getSobjectType() == Customersurvey__c.SobjectType) {
			// ご宿泊日\部屋\■お名前\■メールアドレス
			List<Customersurvey__c> surveys = [select Reserved__c,Reserved__r.EntryTime__c, Reserved__r.Rroom__c, Reserved__r.Rroom__r.Name,
													Reserved__r.Relcontact__c,Reserved__r.Relcontact__r.email,Reserved__r.Relcontact__r.Name,
													anquete__c, anquete__r.email,anquete__r.Name
												from Customersurvey__c
												where id = :objId limit 1];
			if (surveys.isEmpty()) {
				//指定のアンケート情報を見つかりません。
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_012_0406));
				return;
			}
			Customersurvey__c survey = surveys[0];
			leadInfo = surveys[0].Reserved__r;
			leadInfo.Id = surveys[0].Reserved__c;
			if (survey.anquete__c != null) {
				contactInfo = survey.anquete__r;
				contactInfo.Id = survey.anquete__c;
			} else {
				contactInfo = survey.Reserved__r.Relcontact__r;
				contactInfo.Id = survey.Reserved__r.Relcontact__c;
			}
			
		} 
		// 宿帳画面を開く場合 
		else if (objId.getSobjectType() == Yadochou__c.SobjectType) {
			List<Yadochou__c> yadochous = [select Field1__c,Field1__r.EntryTime__c, Field1__r.Rroom__c, Field1__r.Rroom__r.Name,
													Field1__r.Relcontact__c,Field1__r.Relcontact__r.email,Field1__r.Relcontact__r.Name,
													Field15__c, Field15__r.email, Field15__r.Name
												from Yadochou__c
												where id = :objId limit 1];
			if (yadochous.isEmpty()) {
				//指定の宿帳情報を見つかりません。
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_012_0407));
				return;
			}
			Yadochou__c yadochou = yadochous[0];
			leadInfo = yadochou.Field1__r;
			leadInfo.Id = yadochou.Field1__c;
			if (yadochou.Field15__c != null) {
				contactInfo = yadochou.Field15__r;
				contactInfo.Id = yadochou.Field15__c;
			} else {
				contactInfo = yadochou.Field1__r.Relcontact__r;
				contactInfo.Id = yadochou.Field1__r.Relcontact__c;
			}
		} 
		else {
			//指定画面から該当ページを起動できません。
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_012_0408));
			return;
		}
		
	}
    public XmlInfo oXmlDef{get; private set;}
    private void initXmlDefine(String pLang) {
    	// カレントユーザーの店舗コードにより、定義のXML情報を取得する
    	String shopCode = UserUtil.CurrentUser.ShopCode__c;
    	Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('QuestionnaireConfigXml', shopCode);

		oXmlDef = new XmlInfo(targetNode, pLang);
    }
    @TestVisible 
   	class XmlInfo {
    	public XmlInfo( Dom.XmlNode targetNode, String lang) {
    		headerStr = new List<String>();
			managerStr = '';
    		switchLayout(lang);
    		// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz BEGIN
			paperSize = '8.27in 11.69in;';
			begKey = '';
			if (CommUtils.isBlank(lang)) lang = (CommBaseCtrl.getLocalIsJapanese() ? 'jp' : 'en');
    		// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz END
    		// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		BEGIN
    		Boolean isSetDefaultFlg = true;
    		if (!isNormalLayout) {
    			Dom.XMLNode mulitiField = targetNode.getChildElement('EXT_MULITI_LANG', null); 			
    			if (mulitiField != null) {
    				isSetDefaultFlg = false;
    				if (isJpLayout) {
						Dom.XMLNode jpField = mulitiField.getChildElement('JAPANESE', null);
						if (jpField != null) {
							Dom.XMLNode headerField = jpField.getChildElement('HEADER', null);
							Dom.XMLNode managerField = jpField.getChildElement('MANAGER_TITLE', null);
							if (managerField != null) managerStr = CommUtils.nullToBlank(managerField.getText()).escapeXml();
							if (headerField != null) {
								String locHeaderStr = CommUtils.nullToBlank(headerField.getText()).escapeXml();
								headerStr.addAll(locHeaderStr.split('\n'));
							}
						}
					} else if (isEnLayout) {
						Dom.XMLNode engField = mulitiField.getChildElement('ENGLISH', null);
						if (engField != null) {
							Dom.XMLNode headerField = engField.getChildElement('HEADER', null);
							Dom.XMLNode managerField = engField.getChildElement('MANAGER_TITLE', null);
							if (managerField != null) managerStr = CommUtils.nullToBlank(managerField.getText()).escapeXml();
							if (headerField != null) {
								String locHeaderStr = CommUtils.nullToBlank(headerField.getText()).escapeXml();
								headerStr.addAll(locHeaderStr.split('\n'));
							}
						}
					}
    			}// End mulitiField
    		}
    		if (isNormalLayout || isSetDefaultFlg) {
    			//for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
				Dom.XMLNode headerField = targetNode.getChildElement('HEADER', null);
				Dom.XMLNode managerField = targetNode.getChildElement('MANAGER_TITLE', null);
				if (managerField != null) managerStr = CommUtils.nullToBlank(managerField.getText()).escapeXml();
				if (headerField != null) {
					String locHeaderStr = CommUtils.nullToBlank(headerField.getText()).escapeXml();
					headerStr.addAll(locHeaderStr.split('\n'));
				}
    		}
    		// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		END
    		// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz BEGIN
    		Dom.XMLNode mulitiPage = targetNode.getChildElement('SURVEY_CUSTOME_DEF', null);
    		if(mulitiPage != null){
            	for (Dom.xmlNode rowNode : mulitiPage.getChildElements()){
            		String colTagNm = rowNode.getName();
            		if(colTagNm == 'BODY'){
	            		String LangStr = CommUtils.nullToBlank(rowNode.getAttribute('LANGUAGE',null)).toLowerCase();
	            		if( LangStr == lang || CommUtils.isBlank(begKey)){
	            			begKey = ReportXmlParserHelper.convertXmlTagToSurveys(rowNode);
	            		}
            		}
            		else if(colTagNm == 'PAPERSIZE'){
	        			String paperSizeText = CommUtils.nullToBlank(rowNode.getText());
	        			if(!CommUtils.isBlank(paperSizeText)) paperSize = ReportXmlParserHelper.getPdfPagePaperSize(paperSizeText);
            		}
            	}
    		}
    		// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz END
    	}
    	//public String headerStr{get; private set;}
    	public List<String> headerStr{get; private set;}
    	public String managerStr{get; private set;}
    	// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		BEGIN
    	private void switchLayout(String pLayoutCd) {
    		isNormalLayout = false;
    		isJpLayout = false;
    		isEnLayout = false;
    		if (CommUtils.isBlank(pLayoutCd)) isNormalLayout = true;
    		if (pLayoutCd == 'jp') isJpLayout = true;
    		if (pLayoutCd == 'en') isEnLayout = true;
    	}
    	public Boolean isNormalLayout{get;private set;}
    	public Boolean isJpLayout{get;private set;}
    	public Boolean isEnLayout{get;private set;}
    	// 2016/12/08	アンケートの出力言語を切替選択できる機能対応		END
    	// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz BEGIN
    	public String begKey{get;private set;}
    	public String paperSize{get;private set;}	    
    	// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz END
    }
}