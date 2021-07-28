/*********************************************
* CashRegisterCardExtPDF
* 2018/05/11 複数店舗を選択表示できる機能対応
* 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応)
* 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加
* 2019/10/30 レジカード8のカスタマイズ機能の改善
*********************************************/
public with sharing class CashRegisterCardExtPDF {
	// 利用日
	public String usedDate{get; private set;}
	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
    //private Id yadochouId;
    public Id yadochouId {get;set;}
    // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
	// 2017/05/25  レジカード５のとき、ご宿泊料金が非表示するポップアップが出ない不具合改修 zyz BEGIN
	public boolean isShowPrice {get; private set;}
	// 2017/05/25 レジカード５のとき、ご宿泊料金が非表示するポップアップが出ない不具合改修 zyz END
	// 2017/10/19 新規レイアウトを作成 zyz BEGIN
	public String pageformat{get; private set;} // ページの印刷サイズ（ich単位）
	// 2017/10/19 新規レイアウトを作成 zyz END
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
    private static final Boolean contactNullCanInsFlg = CommDefine__c.getOrgDefaults().CashRegNullContactCanInsFlg__c;
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
    public Boolean signaType{get{return CommConst.APPOTION_CARREG_SING_TYPE == CommConst.APPOTION_CARREG_SING_TYPE_DR;}}  // 署名欄直接署名できる方法タイプ
    public Boolean signaTypePage{get{return CommConst.APPOTION_CARREG_SING_TYPE == CommConst.APPOTION_CARREG_SING_TYPE_DRPAGE;}}  // 全ページ直接署名＞＞画像保存
    // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
    public Boolean isOngPagePrintDupRoom{get; private set;}//ページ毎に２室レジカード出力フラグ
    // 2018/11/09 印刷高さでページ間調整 zyz BEGIN
    public String pageSplitHeightStr{get;private set;} // ページ毎に２室レジカード出力height
    // 2018/11/09 印刷高さでページ間調整zyz END
    // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
    public String image{get;private set;}	// logo转换的图片
    public Boolean pageSignaTureFlg{get;private set;}	// ページ署名字段是否有值
    public Boolean SignaTureFlg{get;private set;}	// 署名字段是否有值
    public Integer pageSize{get;private set;}	// 分页数目，最后一页不集计
    // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
    private static String pageCode;
    // 2018/03/05 PDF7横向的A5纸张 zyz END
    // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
    public Boolean logoPosiShow{get;set;}
    public String imageUrl{get;set;}
    public String imageWidth{get;set;}
    public String imageheight{get;set;}
    private map<String,String> imageMap{get;set;}
    // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
    // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz BEGIN
    public String signaturestr{get;private set;}
    public Boolean signaShowFlg{get;private set;}
    // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz END
    // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
    private String customizeHtml{get;set;}
    private String headerHtml{get;set;}
    private String footerHtml{get;set;}
    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    // サインページから次のページへパラメータを引き渡しURL情報を格納
    public String CashLogoStr{get; private set;}
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	public CashRegisterCardExtPDF(ApexPages.StandardController controller){
		// 引き渡しパラメータ取得
		initPdf();
		//initInfoByUrlParameter();
		// 2017/05/25  レジカード５のとき、ご宿泊料金が非表示するポップアップが出ない不具合改修 zyz BEGIN
		// 金額表示・なしチェックを行う
		isShowPrice = ApexPages.currentPage().getParameters().containsKey('smy');
		// 2017/05/25  レジカード５のとき、ご宿泊料金が非表示するポップアップが出ない不具合改修 zyz END
	}
	/*private void initInfoByUrlParameter () {
        // 宿帳ＩＤ
        Map<String,String> param = ApexPages.currentPage().getParameters();
        String strYadochouId = CommUtils.nullToBlank(param.get('id'));
        if (!CommUtils.isBlank(strYadochouId)) {
        	yadochouId = Id.valueOf(strYadochouId);
        }
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
        // 一括印刷するがどうかフラグ
        Boolean isBlukProcessFlg = (ApexPages.currentPage().getParameters().containsKey('cardDate'));
        String workDateStr = ApexPages.currentPage().getParameters().get('cardDate');
        Date workDate = CommUtils.stringToDate(workDateStr);
        if (workDate == null && isBlukProcessFlg) {
        	throw new CommException('Not Validate Paramater!!!');
        }
        String shopCode = Apexpages.currentpage().getparameters().get('cardCd');
        // 2017/02/20 レジカード一括印刷機能対応 END
    }
    */
	/**
	* レポートロゴ取得する
	**/
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
	/*public ReportLogo__c getReportInfo() {
		// ユーザー所属する支店コードを取得、表示する
		return CommRepUtils.getReportTitleInfo();
	}*/
	public ReportLogo__c ReportInfo{get;set;}
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	//
	public String dateFormat{get{return CommBaseCtrl.getDateFormat();}}
	// 2017/01/05 金額小数点対応
    public String getNumberFormat() {
    	return CommUtils.getNumberFormat();
    }
    // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
    //public List<OneCard> bulkAllPageList{get;private set;}
    public List<List<OneCard>> bulkAllPageList{get;private set;}
    // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
    private List<ContactItem> getContactItems(Yadochou__c yadochou) {
    	List<ContactItem> contactItems = new List<ContactItem>();
		// 代表者情報は宿帳に設定する
	    if (yadochou.Field15__c != null) {
	    	Guestbookcustomer__c newItem = new Guestbookcustomer__c(Customer__r = yadochou.Field15__r);
	        // 存在している宿帳明細情報を設定する
	        contactItems.add(new ContactItem(newItem,contactItems.size()+1));
		}
		for(Guestbookcustomer__c guest : yadochou.guestbooknameE3VR__r) {
			// 存在している宿帳明細情報を設定する
			contactItems.add(new ContactItem(guest,contactItems.size()+1));
		}
		return contactItems;
    }
    // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
    // 签名页面启动
    public void initPdfSign() {
    	init(true);
    }
    // PDF启动
    public void initPdf() {
    	init(false);
    }
    public void init(Boolean logoInfoFlg) {
	//public void initPdf() {
	// 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
		// パラメータ取得
		// ===============================================================
        // 宿帳ＩＤ
        Map<String,String> param = ApexPages.currentPage().getParameters();
        String strYadochouId = CommUtils.nullToBlank(param.get('id'));
        if (!CommUtils.isBlank(strYadochouId)) {
        	yadochouId = Id.valueOf(strYadochouId);
        }
        // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
        pageSignaTureFlg = false;
        SignaTureFlg = false;
        // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
        // 一括印刷するがどうかフラグ
        Boolean isBlukProcessFlg = (ApexPages.currentPage().getParameters().containsKey('cardDate'));
        String workDateStr = ApexPages.currentPage().getParameters().get('cardDate');
        Date workDate = CommUtils.stringToDate(workDateStr);
        if (workDate == null && isBlukProcessFlg) {
        	throw new CommException('Not Validate Paramater!!!');
        }
        // 2018/11/30 レジカード一括印刷機能追加 zyz BEGIN
        String yadoIdStr = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('sid'));
        list<String> yadoIdLst = (CommUtils.isBlank(yadoIdStr) ? null : yadoIdStr.split(','));
        // 2018/11/30 レジカード一括印刷機能追加 zyz END
        // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
        String spcode = CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('shopcd'));
        // URLから店舗コードを引き渡す場合、次のページへ引き渡す
        CashLogoStr = CommUtils.isBlank(spcode) ? '' : ('&shopcd='+spcode);
        // 店舗コードが見引き渡す場合、ユーザ所属店舗コードで設定する
        if (CommUtils.isBlank(spcode)) spcode = CommUtils.nullToBlank(UserUtil.CurrentUser.ShopCode__c);
		// 店舗ロゴ情報を取得する
        ReportInfo =  CommRepUtils.getReportTitleInfo(spcode);
        // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
        // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) BEGIN
        pageCode = CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;
        isOngPagePrintDupRoom = false;
        if (param.containsKey('dup')) {
        	isOngPagePrintDupRoom = true;
        	pageCode = '6';
       	}
        // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) BEGIN
        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
        //String shopCode = Apexpages.currentpage().getparameters().get('cardCd');
        List<String> shopCode = new List<String>();
        String pShopCode = Apexpages.currentpage().getparameters().get('cardCd');
        if (!CommUtils.isBlank(pShopCode)) shopCode.addAll(CommUtils.nullToBlank(pShopCode).split(','));
        // 2018/05/11 複数店舗を選択表示できる機能対応 END
        // 2017/02/20 レジカード一括印刷機能対応 END
        // ===============================================================
        // 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz BEGIN
        String cardPrintlit = '';
        String docName = 'CashRegisterCardPdfConfig';
        String shopCd =  '';
        Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCd);
        Dom.XmlNode yadotyoCardPrint = shopRoot.getChildElement('YADOTYO_BULK_PDF', null);
        if (yadotyoCardPrint != null) {
            Dom.XmlNode cardPrint = yadotyoCardPrint.getChildElement('FILTER', null);
            if (cardPrint != null) {
                cardPrintlit = CommUtils.nullToBlank(cardPrint.getText());
            } 
        }
        // 2017/10/19 新規レイアウトを作成 zyz BEGIN
        // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
        if(pageCode == '7' || pageCode == '8') pageformat = '8.27in 5.83in;';
        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
        else pageformat = '5.83in 8.27in;';
        // 2018/03/05 PDF7横向的A5纸张 zyz END
        // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz BEGIN
        signaturestr = '';
        signaShowFlg = false;
        // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz END
        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
        logoPosiShow = false;
        imageUrl = '';
        imageWidth = '';
        imageheight = '';
        imageMap = new map<String,String>();
        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
        Dom.XmlNode stayCradFields = shopRoot.getChildElement('STAYCARD_6', null);
        if (stayCradFields != null) {
            Dom.XmlNode cardSize = stayCradFields.getChildElement('PAGESIZE', null);
            // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
            if (cardSize != null) pageformat = ReportXmlParserHelper.getPdfPagePaperSize(CommUtils.nullToBlank(cardSize.getText()));
            else if (cardSize != null && pageCode == '7') pageformat = ReportXmlParserHelper.getPdfPagePaperSizeTraverse(CommUtils.nullToBlank(cardSize.getText()),true);
            // 2018/03/05 PDF7横向的A5纸张 zyz END
            // 2018/11/09 印刷高さでページ間調整 zyz BEGIN
            Dom.XmlNode pageSplitHeight = stayCradFields.getChildElement('PAGESPLITHEIGHT', null);
            if(pageSplitHeight != null) pageSplitHeightStr = CommUtils.nullToBlank(pageSplitHeight.getText());
            // 2018/11/09 印刷高さでページ間調整 zyz END
            // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz BEGIN
            Dom.XmlNode signatureLayout = stayCradFields.getChildElement('CUSTOM_SIGNATURE', null);
            if(signatureLayout != null) {
            	signaShowFlg = true;
            	signaturestr = CommUtils.nullToBlank(signatureLayout.getText());
            }
            // 2019/03/15 レジカード6/７、署名欄内の文言をカスタマイズ機能追加 BY zyz END
            // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
            Dom.XmlNode logoPosition = stayCradFields.getChildElement('LOGO_POS_TOPLEFT_FLG', null);
            if(logoPosition != null) {
            	logoPosiShow = boolean.valueOf(CommUtils.nullToBlank(logoPosition.getText()));
            	if(logoPosiShow){
            		imageWidth = 'width : '+CommUtils.nullToBlank(logoPosition.getAttribute('WIDTH',null));
            		imageheight = 'height : '+(CommUtils.nullToblank(logoPosition.getAttribute('HEIGHT',null)) == '' ? '72px;' : CommUtils.nullToblank(logoPosition.getAttribute('HEIGHT',null)));
            	}
            }
            // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
        }
        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
        customizeHtml = '';
        headerHtml = '';
        footerHtml = '';
        Dom.XmlNode DefFields = shopRoot.getChildElement('STAYCARD_8', null);
        if (DefFields != null && pageCode == '8') {
            Dom.XmlNode cardSize = DefFields.getChildElement('PAGESIZE', null);
            if(cardSize != null){
            	Boolean cardFlg = boolean.valueOf(CommUtils.nullToBlank(cardSize.getAttribute('VERTICAL',null)));
            	if (!cardFlg) pageformat = ReportXmlParserHelper.getPdfPagePaperSizeTraverse(CommUtils.nullToBlank(cardSize.getText()),!cardFlg);
            	else pageformat = ReportXmlParserHelper.getPdfPagePaperSize(CommUtils.nullToBlank(cardSize.getText()));
            }
        	Dom.XmlNode rowsNode = DefFields.getChildElement('BODY', null);
        	if(rowsNode != null){
        		customizeHtml = ReportXmlParserHelper.convertXmlTagToString(rowsNode);
			}
			Dom.XmlNode headerNode = DefFields.getChildElement('HEADER', null);
			if(headerNode != null){
				headerHtml = ReportXmlParserHelper.convertXmlTagToString(headerNode);
			}
			Dom.XmlNode footerNode = DefFields.getChildElement('FOOTER', null);
			if(footerNode != null){
				footerHtml = ReportXmlParserHelper.convertXmlTagToString(footerNode);
			}
        }
        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
        // 2017/10/19 新規レイアウトを作成 zyz END
        // 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz END
        // 関連の予約情報を取得する
        String queryStr = 'select '+
            'Field15__c, '+
            // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
            'Signature__c,PageSignature__c,Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c, '+
            // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
            'RespectLstCal__c, ' +
            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
            // お客様情報
            'Field15__r.Birthdate, '+
            'Field15__r.Phone,Field15__r.MobilePhone, Field15__r.Fax, Field15__r.gender__c,Field15__r.Age__c, '+
            'Field15__r.Name,Field15__r.email, Field15__r.MailingPostalCode, Field15__r.Katakana__c, '+
            'Field15__r.MailingStreet, Field15__r.MailingState, Field15__r.MailingCountry, Field15__r.MailingCity,  '+
            // 2017/03/10 BEGIN zyz
            'Field15__r.WeddingAnniversary__c,Field15__r.Usage_Count__c,  ' +
            'Field15__r.Department,Field15__r.Title,  ' +
            // 取引先
            'Field15__r.Account.Name,Field15__r.Account.Phone,Field15__r.Account.Fax,  ' +
            'Field15__r.Account.BillingCountry,Field15__r.Account.BillingState,Field15__r.Account.BillingCity,Field15__r.Account.BillingStreet,Field15__r.Account.BillingPostalCode,   '+
            //予約情報
            'Field1__r.Mans__c, Field1__r.Femails__c, Field1__r.StayPersons__c,Field1__r.LeadReceiptDate__c,  ' + 
            //予約インデックス情報
            'Field1__r.LeadIndexRef__r.Nights__c, '+
            // 2017/03/10 END zyz
            // 予約情報[夕食時間]/[部屋]/朝食時間/到着時刻/出発時刻/
            'Field1__r.Field293__c, Field1__r.Rroom__r.name, Field1__r.Morningtime__c, '+
            'Field1__r.Field4__c, Field1__r.Field3__c, '+
            // プラン/お客様ステータス
            'Field1__r.Field310__r.Name,Field1__r.Field298__c '+
            // 予約インデックス情報
            ',Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c '+
            'from Yadochou__c ';
        Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        // 2018/11/30 レジカード一括印刷機能追加 zyz BEGIN
        if (yadoIdLst != null) {
        	queryStr += ' where id in :yadoIdLst ';
        } else if (isBlukProcessFlg) {
        // 2018/11/30 レジカード一括印刷機能追加 zyz END
                queryStr += ' Where DAY_ONLY(convertTimezone(Field1__r.EntryTime__c)) = :workDate And Field1__r.CancelBool__c != :cancelFlg ';
				// 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
				//if (!CommUtils.isBlank(shopCode)) queryStr +=' And (Field1__r.Rroom__r.ShopInfoRef__r.ShopCode__c  =:shopCode or Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode)';
                if (!shopCode.isEmpty()) queryStr +=' And (Field1__r.Rroom__r.ShopInfoRef__r.ShopCode__c  =:shopCode or Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode)';
                // 2018/05/11 複数店舗を選択表示できる機能対応 END
                // 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz BEGIN
                if (!CommUtils.isBlank(cardPrintlit)) queryStr += ' AND (' + cardPrintlit + ')';
                // 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz END
        } else {
                queryStr += ' where id = :yadochouId ';
        }
		queryStr += ' Order By Field1__r.Rroom__r.Seq__c,Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c'; 
		List<Yadochou__c> yadochous = DataBase.query(queryStr);
		processForSwitchCd4(yadochous);
    	map<id,List<ContactItem>> contactItemsMap = new map<Id, list<ContactItem>>();
		for (Yadochou__c yadochou : yadochous) {
			contactItemsMap.put(yadochou.id, getContactItems(yadochou));
		}
        // 利用日                          
        usedDate = (DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0))).format('yyyy年MM月dd日');
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
        //bulkAllPageList = new list<OneCard>();
        bulkAllPageList = new list<list<OneCard>>();
		// 1ページに複数レジカード情報を格納する
		Integer locMaxCardNum = isOngPagePrintDupRoom ? 2 : 1;
		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
        for (Yadochou__c yadochou : yadochous) {            
        	Id yadoId = yadochou.Id;
        	Id leadId = yadochou.Field1__c;
	        // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
	        String[] pageSignaStrs ;
	        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
	        // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
	        /*
	        if (!isBlukProcessFlg || logoPosiShow) {
	        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
		        String spcode = yadochou.Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c;
		        // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
		        //if (CommUtils.isBlank(spcode)) spcode = shopCode;
		        if (CommUtils.isBlank(spcode)) spcode = (shopCode.isEmpty() ? '' : shopCode[0]);
		        // 2018/05/11 複数店舗を選択表示できる機能対応 END
		        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
		        // if (CommUtils.isBlank(spcode)) spcode = UserUtil.CurrentUser.ShopCode__c;
		        if (CommUtils.isBlank(spcode) || !logoInfoFlg) spcode = UserUtil.CurrentUser.ShopCode__c;
		        // 該当店舗のロゴファイルはBase64に変換する
		        if(imageMap.containsKey(spcode)) {
		        	imageUrl = imageMap.get(spcode);
		        } else decodedURLBlob(spcode);
		        // decodedURLBlob(spcode);
		        // 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
		    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
	        }else{
	        	String userSpcode = UserUtil.CurrentUser.ShopCode__c;
		        if(imageMap.containsKey(userSpcode)) {
		        	imageUrl = imageMap.get(userSpcode);
		        } else decodedURLBlob(userSpcode);
	        }
	        */
	        if(imageMap.containsKey(spcode)) {
	        	imageUrl = imageMap.get(spcode);
	        } else decodedURLBlob(spcode);
	        // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	        // 2018/07/17 レジカードコード7の署名機能追加 zyz BEGIN
		    //if (signaTypePage) {
		    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		    // if (signaTypePage || pageCode == '7') {
		    if (signaTypePage || pageCode == '7' || pageCode == '8') {
		    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
		    // 2018/07/17 レジカードコード7の署名機能追加 zyz END
		    	if (!CommUtils.isBlank(yadochou.Signature__c)) SignaTureFlg = true;
		        // サイン画像情報が存在する場合
		        if (!CommUtils.isBlank(yadochou.PageSignature__c)) {
			        pageSignaTureFlg = true;
			        String pageSignaStr = yadochou.PageSignature__c;
			        if (!CommUtils.isBlank(pageSignaStr)) pageSignaStrs = pageSignaStr.split(',');
		        }
	        }
        	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
        	List<ContactItem> contactItems = contactItemsMap.get(yadoId);
        	if (contactItems == null) contactItems = new List<ContactItem>();
	        // 改ページ処理機能初期化
	        OneCard wkOneCard= new OneCard();

	        // 会ページフラグを設定する
	        if (bulkAllPageList.isEmpty()) wkOneCard.isFirstPage = true;
	        // 2018/11/09 印刷高さでページ間調整 zyz BEGIN
	        wkOneCard.isHeightPage = true;
	        // 2018/11/09 印刷高さでページ間調整 zyz END
	        wkOneCard.addMemoInfo(extInfMap.get(leadId));
	        // 2017/10/19 新規レイアウトを作成 zyz BEGIN
	        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
	        // wkOneCard.addCard(cardInfMap.get(leadId));
	        if(pageCode != '8') wkOneCard.addCard(cardInfMap.get(leadId));
	        // 2017/10/19 新規レイアウトを作成 zyz END
	        // 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz BEGIN
	        String logoStr = '<img src="'+imageUrl+'"  />';
	        if(logoInfoFlg) logoStr = '<img src="data:image/png;base64,'+image+'" />';
	        layoutInfo layInfo = layoutCardMap.get(leadId);
	        if(layInfo != null){
		        if(!CommUtils.isBlank(layInfo.headHtml)) layInfo.headHtml = layInfo.headHtml.Replace('$_LOGO_$' ,logoStr);
		        if(!CommUtils.isBlank(layInfo.footHtml)) layInfo.footHtml = layInfo.footHtml.Replace('$_LOGO_$' ,logoStr);
		        // wkOneCard.addlayoutInfo(layoutCardMap.get(leadId));
	        }
	        wkOneCard.addlayoutInfo(layInfo);
	        // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	        // 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz END
	        List<OnePage> allPageList = wkOneCard.allPageList;
		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
        	// 空白　または　２カードは設定されている場合
        	if (bulkAllPageList.isEmpty() || Math.mod(bulkAllPageList[bulkAllPageList.size()-1].size(), locMaxCardNum) == 0 ) {
        		List<OneCard> nwCard = new List<OneCard>();
        		// 2018/11/09 印刷高さでページ間調整 zyz BEGIN
        		wkOneCard.isHeightPage = false;
        		// 2018/11/09 印刷高さでページ間調整 zyz END
        		bulkAllPageList.add(nwCard);
        	}
	        //bulkAllPageList.add(wkOneCard);
	        bulkAllPageList[bulkAllPageList.size()-1].add(wkOneCard);
		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
        	// 2017/02/20 レジカード一括印刷機能対応 END
	        Integer breakNum = 1 ;
	        for (Integer index =0; index < contactItems.size(); index++) {
	            // 改ページ計算
	            Integer breakLine = index - (allPageList.isEmpty() ? 0 : 1) * breakNum - (allPageList.size() > 1 ? allPageList.size() -1 : 0 ) * breakNum;
	            // 改ページする場合
	            if (breakLine == 0) {
	                OnePage onePg = new OnePage();
	                contactItems[index].isFirstShow = true;
	                onePg.addItem(contactItems[index]);
	                allPageList.add(onePg);
	                // ページ数を設定する
	                // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
	                //onePg.currPages = allPageList.size();
	                pageSize = onePg.currPages = allPageList.size();
	                // 一笔宿帐下ページ署名字段内的所有图片
	                if(pageSignaStrs != null ) {
	                	if (pageSignaStrs.size() >= pageSize){
	                		onePg.signaImg = pageSignaStrs[pageSize - 1];
	                		// 一括印刷无签名图片控制flg
	                		onePg.isSignaImg = true;
	                	} else if(pageSignaStrs.size() < pageSize){
	                		pageSignaTureFlg = false;
	                		onePg.isSignaImg = false;
	                	}
	                }
	                // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
	                // 2017/02/20 レジカード一括印刷機能対応 BEGIN
	                if (allPageList.size() == 1) onePg.isFirstRow = true;
	                	onePg.addFooter4(fotter4Map.get(yadoId));
	                // 2017/02/20 レジカード一括印刷機能対応 END
	            } else {
	                OnePage onePg = allPageList[allPageList.size() - 1];
	                onePg.addItem(contactItems[index]);
	            }
	        }
	        // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
            if (contactItems.size() == 0 && contactNullCanInsFlg) {
            	OnePage onePgNull = new OnePage();
                onePgNull.addFooter4(fotter4Map.get(yadoId));
            	allPageList.add(onePgNull);
            }
            // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
	        // 最後のページの明細データ行数
	        if (allPageList.isEmpty()) {
	             OnePage dumyPage = new OnePage();
	             allPageList.add(dumyPage);
	        }
	        OnePage lastPage = allPageList[allPageList.size()-1];
	        // 明細行数確認する
	        if (lastPage.onePageList.size() < breakNum) {
	            Integer dumyLen =breakNum - lastPage.onePageList.size();
	            for (Integer i = 0; i < dumyLen; i++) {
	                ContactItem dumyItem = new ContactItem(new Guestbookcustomer__c(), null);
	                lastPage.addItem(dumyItem);
	            }
	        }
        }
	}
    private void processForSwitchCd4(List<Yadochou__c> yadochous) {
    	// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
    	//bulkAllPageList = new list<OneCard>();
    	bulkAllPageList = new list<List<OneCard>>();
    	// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ ED
    	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
     	Set<Id> leadIdxIdSet = new Set<Id>();
		Set<Id> leadSubIdxIdSet = new Set<Id>();
		Set<Decimal> leadGroupNoSet = new Set<Decimal>();
		list<id> yLeadIdsLst = new list<id>();
    	for(Yadochou__c yadochou : yadochous){ 
			Lead__c keyLead = yadochou.Field1__r;
			leadIdxIdSet.add(keyLead.LeadIndexRef__c);
			leadSubIdxIdSet.add(keyLead.LeadIndexSubId__c);
			leadGroupNoSet.add(keyLead.RoomGroupNo__c);
			yLeadIdsLst.add(keyLead.Id);
    	}
		// 各宿帳にFooter情報を格納する
		fotter4Map = new map<id, Footer4Info>();
		// 2017/02/20 レジカード一括印刷機能対応 END
    	// 指定の予約の同じ部屋のN泊の予約情報を取得する
    	List<Lead__c> existLeads = [select id, Name,EntryTime__c,Departure__c, Field3__C, Field4__c ,Morimongn__c,Mans__c,Femails__c,StayPersons__c,LeadReceiptDate__c,
    							// 2017/02/20 レジカード一括印刷機能対応 BEGIN
    							LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
    							// 2017/02/20 レジカード一括印刷機能対応 END
    							(	Select ActionType__c,PaymentType__c,Total__c,ProductName__c,X2_1__c,UnitPriceDefKbCal__c ,
    									UnitPrice__c, TaxRate__c, ServiceRate__c,Amount__c,
    									SpTotal__c, SpecialTax__c
    								From BookingEstimateItemFgKu__r 
    								where ParentBookingItemRef__c = null
    								And (ActionType__c != :CommConst.PROD_ACTION_TYPE_PY AND ActionType__c != :CommConst.PROD_ACTION_TYPE_AR)
    								// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
    								And InvoiceNoShowFlg__c = false
    								// 2017/12/13 見積明細非表示機能対応 WGCH END
    									order by RowNo__c, Name) 
    							from Lead__c 
    							where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
    								// 2017/02/20 レジカード一括印刷機能対応 BEGIN
									And LeadIndexRef__c = :leadIdxIdSet
									And LeadIndexSubId__c = :leadSubIdxIdSet
									And RoomGroupNo__c = :leadGroupNoSet
									// 2017/02/20 レジカード一括印刷機能対応 END
    								order by EntryTime__c asc ];
    	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
    	// 予約に関連のグループ情報を格納する
    	map<string, list<Lead__c>> groupLeadsMap = new map<string, list<lead__c>>();
    	for (Lead__c lead : existLeads) {
    		String groupKey = CommLogicProcess.getKeyOfSameGroupLead(lead.LeadIndexRef__c, lead.LeadIndexSubId__c, lead.RoomGroupNo__c);
    		if (!groupLeadsMap.containskey(groupKey)) groupLeadsMap.put(groupKey, new list<lead__c>());
    		groupLeadsMap.get(groupKey).add(lead);
    	}
    	// 各宿帳関連の予約グループ情報を取得する
    	for(Yadochou__c yadochou : yadochous){
    		Lead__c keyLead = yadochou.Field1__r;
    		String groupKey = CommLogicProcess.getKeyOfSameGroupLead(keyLead.LeadIndexRef__c, keyLead.LeadIndexSubId__c, keyLead.RoomGroupNo__c);
    		List<Lead__c> leads = groupLeadsMap.get(groupKey);
    		if (leads == null) continue;
    		// 該当宿帳のFooter情報を設定する
    		Footer4Info footer4 = new Footer4Info(yadochou);
    		fotter4Map.put(yadochou.id, footer4);
    	// 2017/02/20 レジカード一括印刷機能対応 END

	    	Lead__c firstLead = leads[0];
	    	lead__c endLead = leads[leads.size() - 1];
			//男性/女性 人員数
			footer4.manNum = Integer.valueOf(leads[0].Mans__c);
			footer4.femailNum = Integer.valueOf(leads[0].Femails__c);
			footer4.stayPersonNum = Integer.valueOf(leads[0].StayPersons__c);
			//発行日付/到着日と泊数を取得する
			footer4.LeadReceiptDate = leads[0].LeadReceiptDate__c;
			if(leads[0].LeadReceiptDate__c == null) footer4.LeadReceiptDate = Date.today();
			footer4.entryDate = leads[0].EntryTime__c.format('yyyy年MM月dd日');
			footer4.stayDays = leads[0].EntryTime__c.date().daysBetween(leads[leads.size()-1].Departure__c.date());
	        footer4.ciTime = firstLead.EntryTime__c.format(CommBaseCtrl.getDateFormat());
	        footer4.coTime = endLead.Departure__c.format(CommBaseCtrl.getDateFormat());
	        // 見積金額合計
	        Decimal locUsedAmout = 0;
			// 食数集計/見積合計金額集計	
	        for (Lead__c lead : leads) {
	        	// 食数集計
	        	footer4.dinnerNums += CommUtils.nullToZero(lead.Morimongn__c);
	        	// 見積金額合計
	        	if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
	        	// 
	        	for (BookingEstimateItem__c estItem: lead.BookingEstimateItemFgKu__r) {
	        		// 特別税も含め、総利用金額-支払金額
	        		Decimal usedAmout = CommUtils.nullToZero(estItem.SpTotal__c);
	        		locUsedAmout += usedAmout;
	        	}
	        }
	        footer4.estimateTotal = locUsedAmout;
		}
		// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 BEGIN
		autoPrintFieldToPdf(yLeadIdsLst);
		// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 END
	}
    public class OneCard {
    	public OneCard() {
    		allPageList = new list<OnePage>();	
    	}
    	public Boolean isFirstPage{get;set;}
    	// 2018/11/09 印刷高さでページ間調整 zyz BEGIN
    	public Boolean isHeightPage{get;set;}
    	// 2018/11/09 印刷高さでページ間調整 zyz END
    	public list<OnePage> allPageList{get;private set;}
       	public ExtendMemoInfo extInf{get; private set;}
       	public void addMemoInfo(ExtendMemoInfo pInf) {
       		extInf = (pInf == null ? new ExtendMemoInfo() : pInf);
       	}
       	// 2017/10/19 新規レイアウトを作成 zyz BEGIN
       	public StayCard cardInflst{get; private set;}
        public void addCard(StayCard card) {
            cardInflst = (card == null ? new StayCard() : card);
        }
        // 2017/10/19 新規レイアウトを作成 zyz END
       	// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz BEGIN
       	public layoutInfo layoutCardlst{get; private set;} // 自定义内容存放
        public void addlayoutInfo(layoutInfo card) {
            layoutCardlst = (card == null ? new layoutInfo() : card);
        }
        // 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz END
    }
    public class OnePage {

        public OnePage () {
            onePageList = new List<ContactItem>();
            currPages = 1;
        }
        // ページ内に追加するITEM
        public void addItem(ContactItem item) {
            onePageList.add(item);
        }
        // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
        // 截取后保存的图片
    	public String signaImg{get;private set;}
    	// 一括印刷无签名图片控制flg
    	public Boolean isSignaImg{get;private set;}
    	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
        // 現在表示してページ数
        public Integer currPages{get;set;}
        public Boolean isFirstPage{get{
            return currPages == 1;
        }}
        // １ページ表示用データを格納
        public List<ContactItem> onePageList{get; private set;}
        
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
       	public Footer4Info footer4{get; private set;}
       	public void addFooter4(Footer4Info pFooter) {
       		footer4 = pFooter == null ? new Footer4Info() : pFooter;
       	}
       	public Boolean isFirstRow{get;set;}
		// 2017/02/20 レジカード一括印刷機能対応 END
    }
    // 2017/02/20 レジカード一括印刷機能対応 BEGIN
    // map<宿帳ID,フォルダ情報>
	private map<Id, Footer4Info> fotter4Map{get; private set;}
    // 2017/02/20 レジカード一括印刷機能対応 END
	public class Footer4Info {
		public Footer4Info(){}
    	public Footer4Info(Yadochou__c s) {
    		//planName = CommRepUtils.getPdfMaxShowStringNew(s.Field1__r.Field310__r.Name,1,32);
    		roomName = CommRepUtils.getPdfMaxShowStringNew(s.Field1__r.Rroom__r.Name,1,14);
    		// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
    		signa = s;
    		// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
    		if (CommUtils.isBlank(roomName)) roomName = '　　　';
    		stayDays = 0;
    		dinnerNums = estimateTotal = 0;
            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
            Boolean RespectFlg = CommConst.RESPECT_ISSHOW_FLG;
            mrStr = '';
            if(RespectFlg) mrStr = CommUtils.nullToBlank(s.RespectLstCal__c);
            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    	}
	    //public String planName{get; private set;}
	    public String roomName{get; private set;}		// 部屋名「指定の予約の部屋名
	    public String entryDate{get; private set;}		// 到着日
	    public Integer stayDays{get; private set;}		// 泊数
	    public Decimal dinnerNums{get; private set;}	// 食数
	    public String ciTime{get; private set;}			// 到着時刻
	    public String coTime{get; private set;}			// 出発時刻
	    public Decimal estimateTotal{get; private set;}	// 見積金額合計
	    // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
	    public Yadochou__c signa{get; private set;}
	    // 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		public String mrStr{get; private set;}
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	    //男性/女性 人員数
		public Integer manNum{get; private set;}
		public Integer femailNum{get; private set;}
		// 人数
		public Integer stayPersonNum{get; private set;}
		//発行日付
		public Date LeadReceiptDate{get; private set;}
    }
    public class ContactItem {
        // 明細番号
        public Integer rowNo{get; private set;}
        // ご芳名
        public String guestName{get; private set;}
        // ひらがな、
        public String hiragana{get; private set;}
        public String birthDate{get; private set;}
        // 連絡電話
        public String phone{get; private set;}
        // 郵便番号
        public String post{get;private set;}
        // 性別
        public String gender{get; private set;}
        // E-mail
        public String email{get;private set;}
        // 2017/10/19 新規レイアウトを作成 zyz BEGIN
        public String emailAddress{get;private set;}
        // 年齡
        public Decimal age{get; private set;}
        // 住所
        public String address6{get; private set;}
        // 2017/10/19 新規レイアウトを作成 zyz END
        public boolean isFirstShow {get; private set;}
        // 2017/03/10 BEGIN zyz
        public String address1{get; private set;}
		public String address2{get; private set;}
		// 当館のご利用回数
		//public Boolean isUsageCount{get; private set;}
		public Decimal usageCount{get; private set;}
		//職業
		public String titleNM{get; private set;}
		//結婚記念日
		public Date weddingAnniversary{get; private set;}
		// 取引先 BEGIN zyz
		// 名称
		public String accountNM{get; private set;}
		//部署
		public String depart{get; private set;}
		//郵便番号
		public String accountPost{get; private set;}
		public String address3{get; private set;}
		public String address4{get; private set;}
		//電話
		public String accountPhone{get; private set;}
		//FAX
		public String fax{get; private set;}
		// 取引先 END zyz
		// 2017/03/10 END zyz
        
        public ContactItem(Guestbookcustomer__c gobj, Integer index) {
            rowNo = index;
            usageCount = -1;
            if (index == null) return;
            isFirstShow = false;
            guestName = CommRepUtils.getPdfMaxShowStringNew(gobj.Customer__r.name,2,24);
            hiragana = CommRepUtils.getPdfMaxShowStringNew(CommUtils.nullToBlank(gobj.Customer__r.Katakana__c),2,13);
            phone = gobj.Customer__r.Phone;
            // 携帯
            if (CommUtils.isBlank(phone)) phone = gobj.Customer__r.MobilePhone;
            post = gobj.Customer__r.MailingPostalCode;
            email = gobj.Customer__r.Email;
			// 取引先責任者ご住所 
			address1 = CommUtils.nullToBlank(gobj.Customer__r.MailingCountry) 
								+ CommUtils.nullToBlank(gobj.Customer__r.MailingState)  
								+ CommUtils.nullToBlank(gobj.Customer__r.MailingCity)
								+ CommUtils.nullToBlank(gobj.Customer__r.MailingStreet);
            // 2017/10/19 新規レイアウトを作成 zyz BEGIN
            // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
            Integer addressNum = 33;
            Integer emailUrlNum = 12;
            if(pageCode =='7') {
            	addressNum = 51;
            	emailUrlNum = 19;
            }
			address6 = CommRepUtils.getPdfMaxShowStringNew(address1,2,addressNum);
            emailAddress = CommRepUtils.getPdfMaxShowStringNew(email,2,emailUrlNum);
            // 2018/03/05 PDF7横向的A5纸张 zyz END
            // 年齡
            age =  CommUtils.nullToZero(gobj.Customer__r.Age__c);
            // 2017/10/19 新規レイアウトを作成 zyz END
            address1 = CommRepUtils.getPdfMaxShowStringNew(address1,2,20);
			// 取引先ご住所
			address3 = CommUtils.nullToBlank(gobj.Customer__r.Account.BillingCountry) 
								+ CommUtils.nullToBlank(gobj.Customer__r.Account.BillingState)
								+ CommUtils.nullToBlank(gobj.Customer__r.Account.BillingCity)
								+ CommUtils.nullToBlank(gobj.Customer__r.Account.BillingStreet);
			address3 = CommRepUtils.getPdfMaxShowStringNew(address3,2,31);
			// 取引先 BEGIN zyz
			//名称
			accountNM = CommRepUtils.getPdfMaxShowStringNew(gobj.Customer__r.Account.Name,2,19);
			//部署
			depart = CommRepUtils.getPdfMaxShowStringNew(gobj.Customer__r.Department,2,8);
			//郵便番号
			accountPost = gobj.Customer__r.Account.BillingPostalCode;
			//電話
			accountPhone = gobj.Customer__r.Account.Phone;
			//FAX
			fax = gobj.Customer__r.Account.Fax;
			// 取引先 END zyz
			// 当館のご利用回数対応
			//isUsageCount = true;
			usageCount =  CommUtils.nullToZero(gobj.Customer__r.Usage_Count__c);
			//性別選択リスト
			gender = gobj.Customer__r.gender__c;
			//職業
			titleNM = gobj.Customer__r.Title;
			//結婚記念日
			weddingAnniversary = gobj.Customer__r.WeddingAnniversary__c;
			//誕生日
            Date bday = gobj.Customer__r.Birthdate;
            if (bday != null) birthDate = DateTime.newInstance(bday.year(),bday.month(),bday.day()).format(getShortMDFormat());
        }
    }
    // 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
    private Boolean alwaysTitleFlg = false;
    // 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
	// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 BEGIN
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	private void autoPrintFieldToPdf(List<Id> leadIds) {
	// 2017/02/20 レジカード一括印刷機能対応 END
		// XMLに定義の項目からPDFへ設定を行う
		String docName = 'CashRegisterCardPdfConfig';
		String shopCode = '';

		Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCode);
		// 2017/02/20 レジカード一括印刷機能対応 BEGIN
		extInfMap = new map<id,ExtendMemoInfo>();
		// 2017/02/20 レジカード一括印刷機能対応 END
		// 客室係自動印字情報を初期化する
		Dom.XmlNode memoOutPutFields = shopRoot.getChildElement('MEMO_OUTPUTFIELD', null);
		if (memoOutPutFields != null) {
			// 予約
			Dom.XmlNode leadFields = memoOutPutFields.getChildElement('LEAD', null);
			// 宿帳
			Dom.XmlNode yadochouFields = memoOutPutFields.getChildElement('YADOCHOU', null);
			// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
			// 取得メモ内项目名是否表示控制
			String alwaysTitle = memoOutPutFields.getAttribute('ALWAYSTITLE',null);
			if (!CommUtils.isBlank(alwaysTitle)) alwaysTitleFlg = boolean.valueOf(alwaysTitle);
			// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			if(leadFields != null) getDataSource(leadFields,leadIds,DATASOURCE_TYPE.LEAD,extInfMap);
			if(yadochouFields != null) getDataSource(yadochouFields,leadIds,DATASOURCE_TYPE.YADOCHOU,extInfMap);
		}
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		if(pageCode != '8'){
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
			// 2017/10/19 新規レイアウトを作成 zyz BEGIN
			cardInfMap = new map<id,StayCard>();
			// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz BEGIN
			layoutCardMap = new map<id,layoutInfo>();
			// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz END
			Dom.XmlNode stayCradFields = shopRoot.getChildElement('STAYCARD_6', null);
			if (stayCradFields != null) {
				getStayCard(stayCradFields,leadIds,cardInfMap);
				// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz BEGIN
				Dom.XmlNode yadoCustomNode = stayCradFields.getChildElement('CUSTOM', null);
				if (yadoCustomNode != null)  getAutoLayout(leadIds,yadoCustomNode,layoutCardMap);
				// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz END
			}
			// 2017/10/19 新規レイアウトを作成 zyz END
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		}
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
		// 2017/02/20 レジカード一括印刷機能対応 BEGIN
		for (Id leadId : extInfMap.keySet()) {
			ExtendMemoInfo extInf = extInfMap.get(leadId);
		// 2017/02/20 レジカード一括印刷機能対応 END
			if (extInf.memoList.size() < 5) {
				Integer dumyLen = 5 - extInf.memoList.size();
				for (Integer i = 0; i < dumyLen; i++) {
					extInf.memoList.add('');
				}
			}
		// 2017/02/20 レジカード一括印刷機能対応 BEGIN
		}
		// 2017/02/20 レジカード一括印刷機能対応 END
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		// 处理数据值
		if(pageCode == '8'){
			layoutCardMap = new map<id,layoutInfo>();
			if(!CommUtils.isBlank(customizeHtml)) getmizeHtml(leadIds,customizeHtml,layoutCardMap,'body');
			if(!CommUtils.isBlank(headerHtml)) getmizeHtml(leadIds,headerHtml,layoutCardMap,'header');
			if(!CommUtils.isBlank(footerHtml)) getmizeHtml(leadIds,footerHtml,layoutCardMap,'footer');
		}
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	}
	// 2017/10/19 新規レイアウトを作成 zyz BEGIN
	private void getStayCard(Dom.XmlNode stayCardFields,list<Id> pLeadIds, map<id,StayCard> pcardInfMap){
		
		// API List
		set<String> apiset = new set<String>{'id'};
		String nationalityKey = 'NATIONALITY';
		String passportKey = 'PASSPORT';
		String arrivedFromKey = 'ARRIVEDFROM';
		String nextDestinationKey = 'NEXTDESTINATION';
		// map<xml tag key, api value>
		map<String, String> apiTagToApiMap = new map<String, String>();
		try{
			// リンク項目を取得する
			for (Dom.xmlNode rowNode : stayCardFields.getChildElements()){
				 Dom.xmlNode leadNode = rowNode.getChildElement('LEAD', null);
				 if (leadNode != null) {
				    String api = CommUtils.nullToBlank(leadNode.getText()).toLowerCase();
				    if (!CommUtils.isBlank(api)) apiset.add(api);
				    String tagNm = rowNode.getName();
				    apiTagToApiMap.put(tagNm, api);
				 }
			}
			// 個別定義情報ひ存在する場合
			if (apiset.isEmpty()) return;
			// 検索のSQLを作成する
			String queryLeadStr = '';
			for (String api : apiset) { queryLeadStr += (CommUtils.isBlank(queryLeadStr) ? '' : ',') + api; } 
			String queryWhere = 'Where Id =: pLeadIds';
			String queryStr = ' Select '+ queryLeadStr + ' From Lead__c ' + queryWhere;
System.debug(loggingLevel.info, 'queryStr='+queryStr);
			// LEADIDからXMLに定義しているAPIから情報を取得する
			List<Lead__c> leads = Database.query(queryStr);
			if (leads.isEmpty()) return;
			// 取得の予約情報を格納する
            map<id,sobject> existLinkInfoMap = new map<id, sobject>();
			for (Lead__c lead : leads) {
				existLinkInfoMap.put(lead.Id, lead);
			}
			// 処理対象外の場合
			if (existLinkInfoMap.isEmpty()) return;
			// 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
			Integer pageNumber = 12;
			if(pageCode =='7') pageNumber = 19;
			// 2018/03/05 PDF7横向的A5纸张 zyz END
			for (Id leadId : existLinkInfoMap.KeySet()) {
				// 関連の予約情報を取得する
				Sobject sobj = existLinkInfoMap.get(leadId);
				if (!pcardInfMap.containsKey(leadId)) pcardInfMap.put(leadId, new StayCard());
				StayCard cardInflst = pcardInfMap.get(leadId);
				
				for(String xmltag : apiTagToApiMap.keyset()){
				    String apiStr = apiTagToApiMap.get(xmltag);
				    // 获取XML定义为空，结束本次循环
				    if(CommUtils.isBlank(apiStr)) continue;
				    String fieldVal = '';
				    // 直接予約情報を参照する
					if(apiStr.contains('__r.')){
					    String[] childApis = apiStr.split('\\.');
					    if(childApis.size() != 2) continue;
					    Sobject refObj = sobj.getSobject(childApis[0]);
                        fieldVal = CommUtils.nullToBlank(refObj.get(childApis[1]));
					} else {
					    fieldVal = CommUtils.nullToBlank(sobj.get(apiStr));
					}
					if (CommUtils.isBlank(fieldVal)) continue;
                    // 2行12文字
                    // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
					//fieldVal = CommRepUtils.getPdfMaxShowStringNew(fieldVal,2,12);
					fieldVal = CommRepUtils.getPdfMaxShowStringNew(fieldVal,2,pageNumber);
					// 2018/03/05 PDF7横向的A5纸张 zyz END
					if(xmltag == nationalityKey)cardInflst.stayNationality = fieldVal;
					else if(xmltag == passportKey)cardInflst.stayPassport = fieldVal;
					else if(xmltag == arrivedFromKey)cardInflst.stayArrived = fieldVal;
					else if(xmltag == nextDestinationKey)cardInflst.stayNext = fieldVal;
				}
			}
		} catch(Exception e){}	
	}
	// 2017/10/19 新規レイアウトを作成 zyz END
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	private void getDataSource(Dom.XmlNode dataSourceFields,list<Id> pLeadIds,DATASOURCE_TYPE sobjType,map<id,ExtendMemoInfo> pExtInfMap){
	// 2017/02/20 レジカード一括印刷機能対応 END
		String queryLeadStr = '';
		// API List
		list<String> apiList = new list<String>();
		// Lable Map
		Map<String,String> memoDefMap = new Map<String,String>();
		try{
			// リンク項目を取得する
			String strMemoFields = CommUtils.nullToBlank(dataSourceFields.getText()); 
			String[] strMemoFieldsSplit = strMemoFields.split(',');
			for (String  memoInfo : strMemoFieldsSplit) {
				if (CommUtils.isBlank(memoInfo)) continue;
				String[] memoInfoSplit = memoInfo.split(':');
				if (memoInfoSplit.size() < 1) continue;
				// KEY: MEMOされる項目ＡＰＩ名、memoId繊維先のSalesforceID
				String key = CommUtils.nullToBlank(memoInfoSplit[0]);
				String memoLable = '';
				if (memoInfoSplit.size() >= 2) {
					memoLable = CommUtils.nullToBlank(memoInfoSplit[1]) + ':';
				}
				queryLeadStr += key + ',';
				apiList.add(key);
				memoDefMap.put(key, memoLable);
			}
			// 自動印字の項目を未定義の場合
			if (apiList.isEmpty()) return;
			queryLeadStr = queryLeadStr.removeEnd(',');
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			map<id,sobject> existLinkInfoMap = new map<id, sobject>();
			// 2017/02/20 レジカード一括印刷機能対応 END
			if(sobjType == DATASOURCE_TYPE.LEAD){
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				String queryWhere = 'Where Id =: pLeadIds';
				// 2017/02/20 レジカード一括印刷機能対応 END
				String queryStr = ' Select '+ queryLeadStr + ' From Lead__c ' + queryWhere;
				// LEADIDからXMLに定義しているAPIから情報を取得する
				List<Lead__c> leads = Database.query(queryStr);
				if (leads.isEmpty()) return;
				// 取得の予約情報を格納する
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				//sobj = leads[0];
				for (Lead__c lead : leads) {
					existLinkInfoMap.put(lead.Id, lead);
				}
				// 2017/02/20 レジカード一括印刷機能対応 END
			} else if(sobjType == DATASOURCE_TYPE.YADOCHOU) {
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				String queryWhere = 'Where Field1__c =: pLeadIds ';
				if (!queryLeadStr.toLowerCase().contains('field1__c')) queryLeadStr += ',Field1__c ';
				// 2017/02/20 レジカード一括印刷機能対応 END
				String queryStr = ' Select '+ queryLeadStr + ' From Yadochou__c ' + queryWhere;
				// YADOCHOUからXMLに定義しているAPIから情報を取得する
				List<Yadochou__c> yadochous = Database.query(queryStr);
				if (yadochous.isEmpty()) return;
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				for (Yadochou__c yado : yadochous) {
					if (!existLinkInfoMap.containsKey(yado.Field1__c)) existLinkInfoMap.put(yado.Field1__c, yado);
				}
				// 2017/02/20 レジカード一括印刷機能対応 END
			}
			// 処理対象外の場合
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			if (existLinkInfoMap.isEmpty()) return;
			for (Id leadId : existLinkInfoMap.KeySet()) {
				Sobject sobj = existLinkInfoMap.get(leadId);
				if (!pExtInfMap.containsKey(leadId)) pExtInfMap.put(leadId, new ExtendMemoInfo());
				ExtendMemoInfo extInf = pExtInfMap.get(leadId);
			// 2017/02/20 レジカード一括印刷機能対応 END
				// 各項目の定義情報を取得する
				for(String apiStr : apiList){
					// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
					String fieldVal = '';
					// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
					// 項目
					if(!apiStr.contains('__r.')){
						// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
						// String fieldVal = CommUtils.nullToBlank(sobj.get(apiStr));
						fieldVal = CommUtils.nullToBlank(sobj.get(apiStr));
						//if(!CommUtils.isBlank(fieldVal)) extInf.memoList.addAll(getSplitMemoInfo(memoDefMap.get(apiStr), fieldVal));
						// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
					} 
					// 参照項目
					else {
						String[] childApis = apiStr.split('\\.');
						if(childApis.size() == 2){
							Sobject refObj = sobj.getSobject(childApis[0]);
							// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
							if(refObj != null) {
								fieldVal = CommUtils.nullToBlank(refObj.get(childApis[1]));
							}
							// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
						}
					}
					// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
					fieldVal = converTitleToValue(memoDefMap.get(apiStr),fieldVal);
					//if(!CommUtils.isBlank(fieldVal)) extInf.memoList.addAll(getSplitMemoInfo(memoDefMap.get(apiStr), fieldVal));
					if(fieldVal != null) extInf.memoList.addAll(getSplitMemoInfo(memoDefMap.get(apiStr), fieldVal));
					// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
				}
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			}
			// 2017/02/20 レジカード一括印刷機能対応 END
		} catch(Exception e){}	
	}
	private String[] getSplitMemoInfo( String apiLabel,String fieldVal){
		// ths max string char size of very row 
		Integer intMaxCharLen = 14;
		Integer intMaxRows = 99;
		String splitKey = ':::_:::';
		// Removes HTML markup from the input string and returns the plain text.
		fieldVal = fieldVal.stripHtmlTags();
		String val = apiLabel + fieldVal;
		val = CommRepUtils.getPdfMaxShowStringNew(val, intMaxRows, intMaxCharLen, splitKey);
		return val.split(splitKey);
	}
	// 客室係自動印字情報を格納する
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	// map<予約ID，自動印字メモ情報>
	public map<id,ExtendMemoInfo> extInfMap{get; private set;}
	// 2017/02/20 レジカード一括印刷機能対応 END
	class ExtendMemoInfo {
		public ExtendMemoInfo() {
			memoList = new list<string>();
		}
		// String分割、大文字列は次の行に追加する
		public list<string> memoList{get;set;}
	}
	// 2017/10/19 新規レイアウトを作成 zyz BEGIN
	public map<id,StayCard> cardInfMap{get; private set;}
	class StayCard{
		public String stayNationality {get;set;}		//Nationality 国籍
		public String stayPassport {get;set;}			//Passport number
		public String stayArrived {get;set;}			//Arrived from 前泊地
		public String stayNext {get;set;}				//Next destination
		public StayCard(){
		}
	}
	// 2017/10/19 新規レイアウトを作成 zyz END
	@TestVisible
	enum DATASOURCE_TYPE{LEAD,YADOCHOU}
	// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 END
	public static String getShortMDFormat() {
		if (CommBaseCtrl.getLocalIsJapanese()) return 'MM月dd日';
		else return 'MM/dd';
	}
	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
	@remoteAction
	public static void refreshsignatureInfo (Id yadoId,String png){
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
		try{
			if (!CommUtils.isBlank(yadoId)){
				List<Yadochou__c> queryyados = [select Id,Name,Field1__c,Field15__c,Field11__c,Field12__c,Signature__c,Field13__c,LeadIndexId__c from Yadochou__c where Id =: yadoId];
				if (!queryyados.isEmpty()) {
					queryyados[0].Signature__c = png;
					// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz BEGIN 
					CashRegisterCardPDF.checkInLead(queryyados[0].Field1__c);
					// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz END 
					update queryyados[0];
				}
			}
		} catch(System.SObjectException e){
			String errMsg = e.getMessage();
			if(errMsg.contains(Label.MSG_006_0459)) {
				throw new CommException(Label.MSG_006_0459);
			}
			throw e;
		}
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	}
	@remoteAction
	public static void refreshCanvasInfo(Id yadoId, list<String> imgArr)  {
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
		try{
			if (!CommUtils.isBlank(yadoId)){
				String images = '';
				// 图片组成字符串用于保存
				for(string Str : imgArr){
					images += Str + ',';
				}
				// 去除末尾符号
				if (!CommUtils.isBlank(images)) images = images.removeEnd(',');
				List<Yadochou__c> queryyados = [select Id,Name,Field1__c,Field15__c,Field11__c,Field12__c,PageSignature__c,Field13__c,LeadIndexId__c from Yadochou__c where Id =: yadoId];
				if (!queryyados.isEmpty()) {
					queryyados[0].PageSignature__c = images;
					// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz BEGIN 
					CashRegisterCardPDF.checkInLead(queryyados[0].Field1__c);
					// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz END 
					update queryyados[0];
				}
			}
		} catch(exception e){
			String errMsg = e.getMessage();
			if(errMsg.contains(Label.MSG_006_0459)) {
				throw new CommException(Label.MSG_006_0459);
			}
			throw e;
		}
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	}
	// 获取logo图片转换base64格式
	private void decodedURLBlob(String spcode) {
		ReportLogo__c rePort = CommRepUtils.getReportTitleInfo(spcode);
		String reportLogo = rePort.ReportLogo__c;
		String reporLogotURL = CommUtils.nullToBlank(reportLogo).substringBetween( ' src="', '"' );
        // 转换成base64，显示图片
        if (!CommUtils.isBlank(reporLogotURL)) {
        	// 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz BEGIN
        	imageMap.put(spcode,reporLogotURL);
        	imageUrl = reporLogotURL;
        	// 2019/07/15 レジカード７ロゴが左上表示改善対応 BY zyz END
	        String decodedURL = reporLogotURL.unescapeHtml4();
	        // 2018/03/07 Security Check BEGIN
	        //PageReference page = new PageReference( decodedURL );
            URL imgUrl = new URL(reporLogotURL);
            String host = imgUrl.getHost();
            Integer startIdx = decodedURL.indexOf(host);
            String extUrl = 'https://'+host;
            decodedURL = decodedURL.substring(startIdx+host.length());
            PageReference page = new PageReference( extUrl  +decodedURL );
            // 2018/03/07 Security Check END
	        Blob b = page.getContent();
	        image = EncodingUtil.base64Encode(b);
        }
	}
	// 2017/10/23 全画面サイン、画像ファイルに保存の改善対応 zyz END
	// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
	private String converTitleToValue(String fieldTitle,String fieldVal){
		// 不为空直接返回
		if (!CommUtils.isBlank(fieldVal)) return fieldVal;
		// title存在的情况下
		if (alwaysTitleFlg && !CommUtils.isBlank(fieldTitle) && fieldTitle != ':') return '';
		return null;
	}
	// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
	// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz BEGIN
	// 予約のHTML作成内容集合
	public map<id,layoutInfo> layoutCardMap{get; private set;} 
	class layoutInfo {
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		public String autoHtml{get;set;}
		public String headHtml{get;set;}
		public String footHtml{get;set;}
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
		public layoutInfo() {
			layoutList = new list<trItem>();
		}
		public list<trItem> layoutList{get;set;}
		public void addTrItem(trItem items) {
			layoutList.add(items);
		}
	}
	// 自定义tr行数据
	class trItem {
		public list<tdItem> tdItemList{get;set;}
		public void addTdItem(tdItem items) {
			tdItemList.add(items);
		}
		public trItem(){
			tdItemList= new list<tdItem>();
		}
	}
	// 自定义td列数据
	class tdItem {
		public String valueStr {get;set;} // 自定义对应的值
		public String labelStr {get;set;} // 自定义对应的label
		public Integer rowIndex {get;set;}// 自定义数据对应位置，用于处理页面格线
		public Integer colIndex {get;set;}// 自定义数据的合并处理
		public tdItem(String val ,String lab,Integer rowNum,Integer colNum) {
			valueStr = val;
			labelStr = lab;
			rowIndex = rowNum;
			colIndex = colNum;
		}
	}
	private void getAutoLayout(list<Id> leadIds,Dom.XmlNode autoNode, map<id,layoutInfo> layInfMap){
		// 重复字段过滤
		set<String> apiDupSet = new set<String>();
		// layout存放
		map<Integer,map<String,String>> apiAutoAllMap = new map<Integer,map<String,String>>();
		// 按行定义存储
		map<Integer,list<String>> AutoMap = new map<Integer,list<String>>();
		// api
		String queryApis = '';
		Integer colNum = 0;
		try{
			for (Dom.xmlNode rowNode : autoNode.getChildElements()){
				list<String> newApi = new list<String>();
				map<String,String> apiAutoMap = new map<String,String>();
				for(Dom.xmlNode colNode : rowNode.getChildElements()){
					String[] rowLst = CommUtils.nullToBlank(colNode.getText()).split(':');
					if (rowLst.size() < 1) continue;
					String api = CommUtils.nullToBlank(rowLst[0]);
					String lab = '';
					if (rowLst.size() >= 2) {
						lab = CommUtils.nullToBlank(rowLst[1]) ;
					}
					newApi.add(api);
					apiAutoMap.put(api,lab);
					if (apiDupSet.contains(api) || CommUtils.isBlank(api)) continue;
					apiDupSet.add(api);
					queryApis += api+',';
				}
				if(colNum >= 3) break;
				colNum++;
				AutoMap.put(colNum,newApi);
				apiAutoAllMap.put(colNum,apiAutoMap);
			}
			// 检索字符去除末尾
			queryApis = queryApis.removeEnd(',');
			if (!queryApis.toLowerCase().contains('field1__c')) queryApis += ',Field1__c ';
			String queryWhere = 'Where Field1__c =: leadIds';
			String queryStr = ' Select '+ queryApis + ' From Yadochou__c ' + queryWhere;
			List<Yadochou__c> yados = Database.query(queryStr);
			if (yados.isEmpty()) return;
			for(Yadochou__c yadochouStr: yados){
				layoutInfo lay = new layoutInfo();
				trItem trlty = new trItem();
				// 值的长度限制
				Integer pageNumber = 12;
				if(pageCode =='7') pageNumber = 19;
				for(Integer nu : AutoMap.keySet()){
					list<String> newApilst = AutoMap.get(nu);
					map<String,string> newApiMap = apiAutoAllMap.get(nu);
					Integer row = 1;
					Integer col = newApilst.size();//33 51
					if(col == 1 && pageCode =='7') pageNumber = 50;
					else if(col == 1) pageNumber = 32;
					// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
					// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
					// Map<String, Schema.SObjectField> YadosMap = Schema.SObjectType.Yadochou__c.fields.getMap();
					// Map<String, Schema.SObjectField> LeadsMap = Schema.SObjectType.Lead__c.fields.getMap();
					// Map<String, Schema.SObjectField> ConsMap = Schema.SObjectType.Contact.fields.getMap();
					Map<String, Schema.DescribeFieldResult> YadosMap = CommSqlUtils.getAllFieldLst(Yadochou__c.sObjectType,false,true);
					Map<String, Schema.DescribeFieldResult> LeadsMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
					Map<String, Schema.DescribeFieldResult> ConsMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
					// 2020/01/30 新追加的字段自定义无效bug修改BY zyz END
					// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
					for(String api : newApilst){
						// 字段对应值和label获取
						// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
				    	// String valueStr = CommUtils.nullToBlank(CommUtils.getFielValue(yadochouStr,api));
						// 获取定义字段对应值
						String valueStr = '';
						if(!api.contains('__r.')){
							valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,YadosMap));
						}else if(api.toLowerCase().contains('field1__r')){
							valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,LeadsMap));
						}else if(api.toLowerCase().contains('field15__r')){
							valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,ConsMap));
						}
						// 2020/01/30 新追加的字段自定义无效bug修改BY zyz BEGIN
						// 特殊处理的地址字段
						if(api.toLowerCase().contains('mailingaddress') ) {
							Sobject con = yadochouStr.getSobject('field15__r');
							if(con != null){
							valueStr = CommUtils.nullToBlank(con.get('MailingCountry')) 
									+ CommUtils.nullToBlank(con.get('MailingState'))  
									+ CommUtils.nullToBlank(con.get('MailingCity'))
									+ CommUtils.nullToBlank(con.get('MailingStreet'));
							} else valueStr ='';
									
						} else if(api.toLowerCase().contains('OtherAddress')){
							Sobject con = yadochouStr.getSobject('field15__r');
							if(con != null) {
							valueStr = CommUtils.nullToBlank(con.get('othercountry')) 
									+ CommUtils.nullToBlank(con.get('otherstate'))  
									+ CommUtils.nullToBlank(con.get('othercity'))
									+ CommUtils.nullToBlank(con.get('otherstreet'));
							} else valueStr ='';
						}
						// 2020/01/30 新追加的字段自定义无效bug修改BY zyz END
				    	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
				    	String labelStr = CommUtils.nullToBlank(newApiMap.get(api));
				    	valueStr = CommRepUtils.getPdfMaxShowStringNew(valueStr,2,pageNumber);
				    	if(row < col){
							trlty.addTdItem(new TdItem(valueStr,labelStr,1,col));
							row++;
				    	}else{
							trlty.addTdItem(new TdItem(valueStr,labelStr,col,col));
							lay.addTrItem(trlty);
							trlty = new trItem();
							row = 1;
				    	}
					}
				}
				if (!layInfMap.containsKey(yadochouStr.Field1__c)) layInfMap.put(yadochouStr.Field1__c, new layoutInfo());
				layInfMap.put(yadochouStr.Field1__c, lay);
			}
		} catch(Exception e){}
	}
	// 2018/12/30 レジカード７、レイアウトもカスタマイズできるように改善 BY zyz END
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
	// PDF7页面自定义处理
	private void getmizeHtml(list<Id> pLeadIds, String autoStr,map<id,layoutInfo> autoInfMap, String htmlType){
		// API存放的Map
		map<String,String> apiMap = new map<String,String>();
		// 字段检索
		String queryApiStr = ' Id,';
		// api存放set
		set<String> apiDupSet = new set<String>();
		try{
			// 拆分 _$$ 
			String[] lst = autoStr.split('_\\$\\$');
			for(String s : lst){
				// 拆分 $$_
				String[] lit = s.split('\\$\\$_');
				if (lit.size() >= 2) {
					apiMap.put(lit[1],lit[1]);
					if (apiDupSet.contains(lit[1])) continue;
					apiDupSet.add(lit[1]);
					queryApiStr += lit[1]+',';
				}
			}
			// 地址的特殊处理
			set<String> addressSet = new set<String>{'field15__c','Field15__r.MailingCountry','Field15__r.MailingState','Field15__r.MailingCity','Field15__r.MailingStreet','Field15__r.othercountry','Field15__r.otherstate','Field15__r.othercity','Field15__r.otherstreet'};
			for(String ress : addressSet){
				if (apiDupSet.contains(ress)) continue;
				queryApiStr += ress +',';
			}
			queryApiStr = queryApiStr.removeEnd(',');
			String queryWhere = 'Where Field1__c =: pLeadIds ';
			if (!queryApiStr.toLowerCase().contains('field1__c')) queryApiStr += ',Field1__c ';
			String queryStr = ' Select '+ queryApiStr + ' From Yadochou__c ' + queryWhere;
			List<Yadochou__c> yadochous = Database.query(queryStr);
			if (yadochous.isEmpty()) return;
			// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
			// Map<String, Schema.SObjectField> YadosMap = Schema.SObjectType.Yadochou__c.fields.getMap();
			// Map<String, Schema.SObjectField> LeadsMap = Schema.SObjectType.Lead__c.fields.getMap();
			// Map<String, Schema.SObjectField> ConsMap = Schema.SObjectType.Contact.fields.getMap();
			Map<String, Schema.DescribeFieldResult> YadosMap = CommSqlUtils.getAllFieldLst(Yadochou__c.sObjectType,false,true);
			Map<String, Schema.DescribeFieldResult> LeadsMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
			Map<String, Schema.DescribeFieldResult> ConsMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
			// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz END
			for(Yadochou__c yadochouStr: yadochous){
				layoutInfo lay = new layoutInfo();
				if (autoInfMap.containsKey(yadochouStr.Field1__c)) lay = autoInfMap.get(yadochouStr.Field1__c);
				if(htmlType =='body') lay.autoHtml = autoStr;
				if(htmlType =='header') lay.headHtml = autoStr;
				if(htmlType =='footer') lay.footHtml = autoStr;
				for(String api : apiDupSet){
					// 获取定义字段对应值
					String valueStr = '';
					if(!api.contains('__r.')){
						valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,YadosMap));
					}else if(api.toLowerCase().contains('field1__r')){
						valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,LeadsMap));
					}else if(api.toLowerCase().contains('field15__r')){
						valueStr = CommUtils.nullToBlank(getFieldValue(yadochouStr,api,ConsMap));
					}
					// 特殊处理的地址字段
					
					if(api.toLowerCase().contains('mailingaddress') ) {
						Sobject con = yadochouStr.getSobject('field15__r');
						if(con != null){
						valueStr = CommUtils.nullToBlank(con.get('MailingCountry')) 
								+ CommUtils.nullToBlank(con.get('MailingState'))  
								+ CommUtils.nullToBlank(con.get('MailingCity'))
								+ CommUtils.nullToBlank(con.get('MailingStreet'));
						} else valueStr ='';
								
					} else if(api.toLowerCase().contains('OtherAddress')){
						Sobject con = yadochouStr.getSobject('field15__r');
						if(con != null) {
						valueStr = CommUtils.nullToBlank(con.get('othercountry')) 
								+ CommUtils.nullToBlank(con.get('otherstate'))  
								+ CommUtils.nullToBlank(con.get('othercity'))
								+ CommUtils.nullToBlank(con.get('otherstreet'));
						} else valueStr ='';
					}
			    	// 替换显示的值
					if(htmlType =='body') lay.autoHtml = lay.autoHtml.Replace('$$_' +api+'_$$' ,valueStr);
					if(htmlType =='header') lay.headHtml = lay.headHtml.Replace('$$_' +api+'_$$' ,valueStr);
					if(htmlType =='footer') lay.footHtml = lay.footHtml.Replace('$$_' +api+'_$$' ,valueStr);
				}
				lay.autoHtml = CommUtils.nullToBlank(lay.autoHtml).ReplaceAll('\\$_BR_\\$' ,'<br/>');
				lay.headHtml = CommUtils.nullToBlank(lay.headHtml).ReplaceAll('\\$_BR_\\$' ,'<br/>');
				lay.footHtml = CommUtils.nullToBlank(lay.footHtml).ReplaceAll('\\$_BR_\\$' ,'<br/>');
				if (!autoInfMap.containsKey(yadochouStr.Field1__c)) autoInfMap.put(yadochouStr.Field1__c, new layoutInfo());
				autoInfMap.put(yadochouStr.Field1__c, lay);
			}
		} catch(Exception e){}
	}
	// 获取字段的值
	// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
    // private static String getFieldValue(Sobject s, String api, Map<String, Schema.SObjectField> fieldsMap) {
    private static String getFieldValue(Sobject s, String api, Map<String, Schema.DescribeFieldResult> fieldsMap) {
    // 2020/01/30 新追加的字段自定义无效bug修改 BY zyz END
        if (s == null || CommUtils.isBlank(api)) return null;
        String ns = CommConst.APPOTION_NAMESPACE;
        api = CommUtils.nullToBlank(api).toLowerCase();
        String fieldVal = '';
        if(!api.contains('__r.')){
        	// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
        	/*
        	// 标准字段追加ps__
        	if(api.endsWith('__c') && !api.startsWith(ns)){
        		api = ns+api;
        	}
        	Schema.DescribeFieldResult sField = fieldsMap.get(api).getDescribe();*/
        	Schema.DescribeFieldResult sField = fieldsMap.get(api);
        	if(sField == null) return '';
        	// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz END
        	fieldVal = CommUtils.nullToBlank(s.get(api));
        	if(sField.getType() == Schema.DisplayType.DATE  && !CommUtils.isBlank(fieldVal)) {
        		Date val = CommUtils.stringToDate(fieldVal);
        		fieldVal = DateTime.newInstance(val.year(),val.month(),val.day()).format(CommBaseCtrl.getDateFormat());
        	}
        	else if(sField.getType() == Schema.DisplayType.TIME && !CommUtils.isBlank(fieldVal)) {
        		Time val = CommUtils.stringToTime(fieldVal);
	    		if (val != null) {
		    		DateTime ft = DateTime.newInstance(Date.today(), val);
		    		fieldVal = ft.format(CommBaseCtrl.getTimeFormat());
	    		}
        	}
	    	else if(sField.getType() == Schema.DisplayType.DATETIME && !CommUtils.isBlank(fieldVal)) {
	    		Datetime firstDate = (Datetime)s.get(api);
				fieldVal = firstDate.format(CommBaseCtrl.getDateTimeFormat());
	    	}
        	else if(sField.getType() == Schema.DisplayType.TEXTAREA && !CommUtils.isBlank(fieldVal)) {
				list<String> splitAreasLst = fieldVal.split('\n');
				String splitVal= '';
				for(String str : splitAreasLst){
					if(!CommUtils.isBlank(str)){
						splitVal += str + '<br/>';
					}
				}
				splitVal = splitVal.removeEnd('<br/>');
				fieldVal = splitVal;
        	}
            return CommUtils.nullToBlank(fieldVal);
        }else{
            String[] childApis = api.split('\\.');
            if(childApis.size() == 2){
                Sobject refObj = s.getSobject(childApis[0]);
                if(refObj == null) return null;
                // 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
        		/*// 标准字段追加ps__
        		String childApi = childApis[1];
        		if(childApi.endsWith('__c') && !childApi.startsWith(ns)){
        			childApi = ns+childApi;
        		}
        		Schema.DescribeFieldResult sField = fieldsMap.get(childApi).getDescribe();*/
        		Schema.DescribeFieldResult sField = fieldsMap.get(childApis[1]);
        		if(sField == null) return '';
				fieldVal = CommUtils.nullToBlank(refObj.get(childApis[1]));
				// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz END
	        	if(sField.getType() == Schema.DisplayType.DATE && !CommUtils.isBlank(fieldVal)) {
	        		Date val = CommUtils.stringToDate(fieldVal);
	        		fieldVal = DateTime.newInstance(val.year(),val.month(),val.day()).format(CommBaseCtrl.getDateFormat());
	        	}
		    	else if(sField.getType() == Schema.DisplayType.TIME && !CommUtils.isBlank(fieldVal)) {
		    		Time val = CommUtils.stringToTime(fieldVal);
		    		if (val != null) {
			    		DateTime ft = DateTime.newInstance(Date.today(), val);
			    		fieldVal = ft.format(CommBaseCtrl.getTimeFormat());
		    		}
		    	}
		    	else if(sField.getType() == Schema.DisplayType.DATETIME && !CommUtils.isBlank(fieldVal)) {
		    		// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz BEGIN
					Datetime firstDate = (Datetime)refObj.get(childApis[1]);
					// 2020/01/30 新追加的字段自定义无效bug修改 BY zyz END
					fieldVal = firstDate.format(CommBaseCtrl.getDateTimeFormat());
		    	}
	        	else if(sField.getType() == Schema.DisplayType.TEXTAREA && !CommUtils.isBlank(fieldVal)) {
					list<String> splitAreasLst = fieldVal.split('\n');
					String splitVal= '';
					for(String str : splitAreasLst){
						if(!CommUtils.isBlank(str)){
							splitVal += str + '<br/>';
						}
					}
					splitVal = splitVal.removeEnd('<br/>');
					fieldVal = splitVal;
	        	}
                return CommUtils.nullToBlank(fieldVal);
            }
        }
        return null;
    }
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
}