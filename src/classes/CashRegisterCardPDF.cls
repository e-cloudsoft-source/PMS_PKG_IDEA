/*********************************************
* CashRegisterCardPDF
* 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応
* 2017/02/20 レジカード一括印刷機能対応
* 2018/05/11 複数店舗を選択表示できる機能対応
* 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応)
* 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応
* 2019/10/30 レジカード8のカスタマイズ機能の改善
*********************************************/
public with sharing class CashRegisterCardPDF {
    
    // 定数定義
    private static final List<String> available1 = new String[]{'ホームページを見て','旅行代理店','広告を見て'};   
    private static final List<String> available2 = new String[]{'過去に利用した','知人の紹介','その他'};   
    private static final List<String> pointInfo1 = new List<String>{'誕生祝い','結婚記念日','他の記念日　　　　(　　　　　　)'};
    private static final List<String> pointInfo2 = new List<String>{'家族旅行','ビジネス','觀光','その他'};

    // 利用日
    public String usedDate{get; private set;}   
    // 表示情報
    public List<String> getPointInfo1() {return pointInfo1;}
    public List<String> getPointInfo2() {return pointInfo2;}
    public List<String> getAvailable1() {return available1;}
    public List<String> getAvailable2() {return available2;}
    // PDFページ毎の明細情報を格納用
    //public List<OnePage> allPageList{get; private set;} 
    // 2017/04/05 署名機能対応 zyz BEGIN
    //private Id yadochouId;
    public Id yadochouId {get;set;}
    // 2017/09/06 署名欄署名対応 zyz BEGIN
    public String customizeHtml{get;set;}       // カスタマイズHTML情報
    public Boolean signaType{get{return CommConst.APPOTION_CARREG_SING_TYPE == CommConst.APPOTION_CARREG_SING_TYPE_DR;}}  // 署名欄直接署名できる方法タイプ
    // 2017/09/06 署名欄署名対応 zyz END
    // 2017/04/05 署名機能対応 zyz END
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
    private static final Boolean contactNullCanInsFlg = CommDefine__c.getOrgDefaults().CashRegNullContactCanInsFlg__c;
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
    // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
    public Boolean signaTypePage{get{return CommConst.APPOTION_CARREG_SING_TYPE == CommConst.APPOTION_CARREG_SING_TYPE_DRPAGE;}}  // 全ページ直接署名＞＞画像保存
    public String image{get;private set;}	// logo转换的图片
    public Boolean pageSignaTureFlg{get;private set;}	// ページ署名字段是否有值
    public Boolean SignaTureFlg{get;private set;}	// 署名字段是否有值
    public Integer pageSize{get;private set;}	// 分页数目，最后一页不集计
    // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
    // 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz BEGIN
    public Boolean planFlg{get;private set;}		// プラン名
    public Boolean clearnessFlg{get;private set;}	// 予約明細
    // 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz END
    // 2018/12/25 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
    public Map<String,List<String>> splitsMap;
    // 2018/12/25 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
    // 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz BEGIN
    public Boolean printFlg{get;private set;}		// 打印纸张的固定第二页显示的控制开关
    // 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz END
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    public String CashLogoStr{get; private set;}
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
    // ページ繊維用定数
	private static final Map<String, String> pageMap;
	// ページ毎明細件数情報を格納
	private static final Map<String, Integer> pageMaxMap;
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	private static final String CONST_PDF4 = '4';
	//2017/03/09 レジカード５新規追加（海栄館用）zyz BEGIN
	private static final String CONST_PDF5 = '5';
	//2017/03/09 レジカード５新規追加（海栄館用）zyz END
	// 2017/10/19 新規レイアウトを作成 zyz BEGIN
	private static final String CONST_PDF6 = '6';
	// 2017/10/19 新規レイアウトを作成 zyz END
	// 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
	private static final String CONST_PDF7 = '7';
	// 2018/03/05 PDF7横向的A5纸张 zyz END
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
	private static final String CONST_PDF8 = '8';
	// 签名页面专用
	private static final Map<String, String> pageSignMap;
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	// 2017/02/20 レジカード一括印刷機能対応 END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	// public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG && CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH END
	static {
		pageMap = new Map<String,String>{
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
			CONST_PDF8=>'CashRegisterCardPDF_8',
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
			// 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
			CONST_PDF7=>'CashRegisterCardPDF_7',
			// 2018/03/05 PDF7横向的A5纸张 zyz END
			// 2017/10/19 新規レイアウトを作成 zyz BEGIN
			CONST_PDF6=>'CashRegisterCardPDF_6',
			// 2017/10/19 新規レイアウトを作成 zyz END
			//2017/03/09 レジカード５新規追加（海栄館用）zyz BEGIN
			CONST_PDF5=>'CashRegisterCardPDF_5',
			//2017/03/09 レジカード５新規追加（海栄館用 zyz END
			// 新宿帳（金額あり、なし）切替
			CONST_PDF4=>'CashRegisterCardPDF_4',
			// 線なし共通用レイアウト
			'3'=>'CashRegisterCardPDF_3',
			// 共通用レイアウト
			'2'=>'CashRegisterCardPDF_2',
			// JINYA会社DefaultPDF専用ページ
			'1'=>'CashRegisterCardPDF'};
		pageMaxMap = new Map<String,Integer>{
			// 新宿帳（金額あり、なし）切替
			CONST_PDF4=>5,
			// 線なし共通用レイアウト
			'3'=>9,
			// 共通用レイアウト
			'2'=>9,
			// JINYA会社DefaultPDF専用ページ
			'1'=> 7};
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
		pageSignMap = new Map<String,String>{
			'4'=>'CashRegisterCardPDF4Sign',
			'5'=>'CashRegisterCardPDF5Sign',
			'7'=>'CashRegisterCardPDF7Sign',
			'8'=>'CashRegisterCardPDF8Sign'};
		// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	}
	
    // インスタンス化
    public CashRegisterCardPDF(ApexPages.StandardController controller){
        // 宿帳ＩＤ
        yadochouId = controller.getId();
		// 金額表示・なしチェックを行う
        isShowPrice = ApexPages.currentPage().getParameters().containsKey('smy');
    }
    
	public boolean isShowPrice {get; private set;}
    public String numberFormat{get{return CommBaseCtrl.getNumberFormat();}}
    public String currencySybmol{get{return CommBaseCtrl.getCurrencySybmol();}}
    private String switchCode;
    public void pdf4Init() {
    	switchCode = CONST_PDF4;
    	pdfInit();
    }
    
    // 2017/02/20 レジカード一括印刷機能対応 BEGIN
    // 複数情報ページを一括格納する
    public transient List<OneCard> bulkAllPageList{get;private set;}
    // 宿帳と宿帳明細情報を格納する
    private List<ContactItem> getContactItems(Yadochou__c yadochou) {
    	List<ContactItem> contactItems = new List<ContactItem>();
		// 代表者情報は宿帳に設定する
	    if (yadochou.Field15__c != null) {
	    	Guestbookcustomer__c newItem = new Guestbookcustomer__c(Customer__r = yadochou.Field15__r);
	        // 存在している宿帳明細情報を設定する
	        contactItems.add(new ContactItem(newItem,contactItems.size()+1));
	    // 2018/12/15 レジカード改善 BY zyz BEGIN
		} else if (contactNullCanInsFlg) {
			contactItems.add(new ContactItem(new Guestbookcustomer__c(),contactItems.size()+1));
		}
		// 2018/12/15 レジカード改善 BY zyz END
		for(Guestbookcustomer__c guest : yadochou.guestbooknameE3VR__r) {
			// 存在している宿帳明細情報を設定する
			contactItems.add(new ContactItem(guest,contactItems.size()+1));
		}
		return contactItems;
    }
    // 2017/02/20 レジカード一括印刷機能対応 END
    
    public void pdfInit() {
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
                // 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz END
                // 2017/09/06 署名欄署名対応 zyz BEGIN
                // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
                //signaType = (CommConst.APPOTION_CARREG_SING_TYPE == CommConst.APPOTION_CARREG_SING_TYPE_DR);
                pageSignaTureFlg = false;
                SignaTureFlg = false;
                // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
                Integer customizeLins = 0;   // お客様明細行数情報を記録する
                customizeHtml = null;           // レジカードのか下部情報をカスタマイズ情報を格納する
                // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
                splitsMap = new Map<String,List<String>>();
                // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
                // 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz BEGIN
                planFlg = false;
                clearnessFlg = false;
                // 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz END
                // 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz BEGIN
                printFlg = false;
                // 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz END
                Dom.XmlNode cusDefRoot = shopRoot.getChildElement('YADOTYO_CUSTOME_DEF', null);
                // カスタマイズ存在の場合
                if(cusDefRoot != null){
                    // 空欄のイメージURL
                    //String imgUrl = ReportXmlParserHelper.BLANK_IMG_URL;
                    // 初期化
                    customizeHtml = '';
                    // お客様明細行数カスタマイズ情報
                	Dom.XmlNode cLinesField = cusDefRoot.getChildElement('LINE_NUMBER', null);
                	if(cLinesField !=null) customizeLins = CommUtils.nullToIntZero(CommUtils.nullToBlank(cLinesField.getText()));
                	// 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz BEGIN
                	// プラン名
                	Dom.XmlNode planField = cusDefRoot.getChildElement('PLANINFO_NOSHOW_FLG', null);
                	if(planField !=null) planFlg = boolean.valueOf(CommUtils.nullToBlank(planField.getText()));
                	// 予約明細
                	Dom.XmlNode clearnessField = cusDefRoot.getChildElement('ESTITEM_NOSHOW_FLG', null);
                	if(clearnessField !=null) clearnessFlg = boolean.valueOf(CommUtils.nullToBlank(clearnessField.getText()));
                	// 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz END
                	// 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz BEGIN
                	Dom.XmlNode printField = cusDefRoot.getChildElement('ROOMMEMO_NOPRINT_FLG', null);
                	if(printField !=null) printFlg = boolean.valueOf(CommUtils.nullToBlank(printField.getText()));
                	// 2019/06/15 レジカードのタイプ４には客室担当用のページが２ページ目に非表示できる機能対応 BY zyz END
                	// ページ定義情報
                	//Dom.XmlNode pageFormatField = cusDefRoot.getChildElement('PAGE_FORMAT', null);
                	//if (pageFormatField != null) pageformat = ReportXmlParserHelper.getPdfPagePaperSize(CommUtils.nullToBlank(pageFormatField.getText()));
                	// カスタムHTML情報読み込みする
                	Dom.XmlNode rowsNode = cusDefRoot.getChildElement('ROWS', null);
                	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
                	//customizeHtml = ReportXmlParserHelper.convertXmlTagToHtml(rowsNode);
                	ReportXmlParserHelper.HtmlTemplate htmlInfo = ReportXmlParserHelper.convertXmlTagToHtmlTemplate(rowsNode);
                	customizeHtml = htmlInfo.parseHtml;
                	splitsMap = htmlInfo.splitMap;
                	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
                }
                // 2017/08/30 XML定义显示修正 zyz END
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
                // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
                //String shopCode = Apexpages.currentpage().getparameters().get('cardCd');
                List<String> shopCode = new List<String>();
                String pShopCode = Apexpages.currentpage().getparameters().get('cardCd');
                if (!CommUtils.isBlank(pShopCode)) shopCode.addAll(CommUtils.nullToBlank(pShopCode).split(','));
                // 2018/05/11 複数店舗を選択表示できる機能対応 END
                // 2018/12/15 レジカード改善 BY zyz BEGIN
                String guestStr = ' From guestbooknameE3VR__r ';
                if(!contactNullCanInsFlg) guestStr += ' where Customer__c != null ';
                guestStr += ' Order by Name) ';
                // 2018/12/15 レジカード改善 BY zyz END
                String queryStr = 'select '+
                	 // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
                    'Field15__c,Signature__c,PageSignature__c,Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c, '+
                     // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
                    // お客様情報
                    'Field15__r.Birthdate, '+
                    'Field15__r.Phone, Field15__r.Fax, Field15__r.gender__c,Field15__r.Age__c, '+
                    'Field15__r.Name,Field15__r.email, Field15__r.MailingPostalCode, Field15__r.Katakana__c, '+
                    'Field15__r.MailingStreet, Field15__r.MailingState, Field15__r.MailingCountry, Field15__r.MailingCity,  '+
                    // 予約情報[夕食時間]/[部屋]/朝食時間/到着時刻/出発時刻/
                    'Field1__r.Field293__c, Field1__r.Rroom__r.name, Field1__r.Morningtime__c, '+
                    'Field1__r.Field4__c, Field1__r.Field3__c, '+
                    // プラン/お客様ステータス
                    'Field1__r.Field310__r.Name,Field1__r.Field298__c '+
                    // 予約インデックス情報
                    ',Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c '+
                    // 宿帳明細情報を取得する
					',(Select Customer__r.Phone, Customer__r.Fax, Customer__r.gender__c,Customer__r.Age__c,Customer__r.Birthdate, '+
					' Customer__r.Name, Customer__r.MailingPostalCode,Customer__r.Katakana__c,Customer__r.email,Customer__r.Title, '+
                    ' Customer__r.MailingStreet, Customer__r.MailingState, Customer__r.MailingCountry, Customer__r.MailingCity  '+
                    // 2018/12/15 レジカード改善 BY zyz BEGIN
                    //' From guestbooknameE3VR__r where Customer__c != null Order by Name) '+
                    guestStr + 
                    // 2018/12/15 レジカード改善 BY zyz END
                    'from Yadochou__c ';
                Integer cancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
                // レジカード一括印刷
		        // 2018/11/30 レジカード一括印刷機能追加 zyz BEGIN
		        if (yadoIdLst != null) {
		        	queryStr += ' where id in :yadoIdLst ';
		        } else if (isBlukProcessFlg) {
		        // 2018/11/30 レジカード一括印刷機能追加 zyz END
                        queryStr += ' Where DAY_ONLY(convertTimezone(Field1__r.EntryTime__c)) = :workDate And Field1__r.CancelBool__c != :cancelFlg ';
						//if (!CommUtils.isBlank(shopCode)) queryStr +=' And (Field1__r.Rroom__r.ShopInfoRef__r.ShopCode__c  =:shopCode or Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode)';
						// 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
						//if (!CommUtils.isBlank(shopCode)) queryStr +=' And Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode';
						if (!shopCode.isEmpty()) queryStr +=' And Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c  =:shopCode';
						// 2018/05/11 複数店舗を選択表示できる機能対応 END
						// 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz BEGIN
						if (!CommUtils.isBlank(cardPrintlit)) queryStr += ' AND (' + cardPrintlit + ')';
						// 2017/04/17 レジカード一括印刷機能のデータ抽出条件を指定できるように改善対応 zyz END
                } else {
                        queryStr += ' where id = :yadochouId ';
                }
                queryStr += ' Order By Field1__r.Rroom__r.Seq__c,Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c';
                /*
        // 宿帳Footer関連予約情報[夕食時間]/[部屋]/出発時刻/朝食時間
        List<Yadochou__c> yadochous = [select
                                Field15__c,
                                // お客様情報
                                Field15__r.Birthdate,
                                Field15__r.Phone, Field15__r.Fax, Field15__r.gender__c,Field15__r.Age__c,
                                Field15__r.Name,Field15__r.email, Field15__r.MailingPostalCode, Field15__r.Katakana__c,
                                Field15__r.MailingStreet, Field15__r.MailingState, Field15__r.MailingCountry, Field15__r.MailingCity, 
                                // 予約情報[夕食時間]/[部屋]/朝食時間/到着時刻/出発時刻/
                                Field1__r.Field293__c, Field1__r.Rroom__r.name, Field1__r.Morningtime__c,
                                Field1__r.Field4__c, Field1__r.Field3__c,
                                // プラン
                                Field1__r.Field310__r.Name,
                                // 予約インデックス情報
                                Field1__r.LeadIndexRef__c, Field1__r.LeadIndexSubId__c, Field1__r.RoomGroupNo__c
                                
                                from Yadochou__c where id = :yadochouId];
        // 宿帳に表示する明細データを取得する
        List<ContactItem> contactItems = new List<ContactItem>();
        if (!yadochous.isEmpty()) {
        	Yadochou__c yadochou = yadochous[0];
	        if (switchCode != '4') {
	        	footer = new FooterInfo(yadochou);
	        } else {
				processForSwitchCd4(yadochou);
	        }
	        // 代表者情報は宿帳に設定する
	        if (yadochou.Field15__c != null) {
	            Guestbookcustomer__c newItem = new Guestbookcustomer__c(Customer__r = yadochou.Field15__r);
	            // 存在している宿帳明細情報を設定する
	            contactItems.add(new ContactItem(newItem,contactItems.size()+1));
	        }
	        for(Guestbookcustomer__c guest : [
	                select 
	                // お客様情報
	                Customer__r.Phone, Customer__r.Fax, Customer__r.gender__c,Customer__r.Age__c,Customer__r.Birthdate,
	                Customer__r.Name, Customer__r.MailingPostalCode,Customer__r.Katakana__c,Customer__r.email,
	                Customer__r.MailingStreet, Customer__r.MailingState, Customer__r.MailingCountry, Customer__r.MailingCity 
	                from Guestbookcustomer__c 
	                where GuestbookNmae__c = :yadochouId and Customer__c != null
	                Order by Name]) {
	            // 存在している宿帳明細情報を設定する
	            contactItems.add(new ContactItem(guest,contactItems.size()+1));
	        }
        }*/
        List<Yadochou__c> yadochous = DataBase.query(queryStr);
		// 取得の宿帳情報を各ページ変数に格納する　
		if (switchCode == CONST_PDF4) {
			processForSwitchCd4(yadochous);
		} else {
			footerMap = new map<Id, FooterInfo>();
			// フッター情報を設定する
			for (Yadochou__c yadochou : yadochous) {
				footerMap.put(yadochou.id, new FooterInfo(yadochou));
			}
		}
		// 該当宿帳に関連のお客様情報を取得、格納する
		map<id,List<ContactItem>> contactItemsMap = new map<Id, list<ContactItem>>();
		for (Yadochou__c yadochou : yadochous) {
			contactItemsMap.put(yadochou.id, getContactItems(yadochou));
		}
		// 2017/02/20 レジカード一括印刷機能対応 END
        // 利用日                          
        usedDate = (DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0))).format('yyyy年MM月dd日');
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
        bulkAllPageList = new list<OneCard>();
        for (Yadochou__c yadochou : yadochous) {
        	Id yadoId = yadochou.Id;
        	Id leadId = yadochou.Field1__c;
	        // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
	        String[] pageSignaStrs ;
	        //if (signaTypePage) {
            if (!isBlukProcessFlg) {
            	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
            	/*
                String spcode = yadochou.Field1__r.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c;
                // 2018/05/11 複数店舗を選択表示できる機能対応 BEGIN
                //if (CommUtils.isBlank(spcode)) spcode = shopCode;
                if (CommUtils.isBlank(spcode)) spcode = (shopCode.isEmpty() ? '' : shopCode[0]);
                // 2018/05/11 複数店舗を選択表示できる機能対応 END
                if (CommUtils.isBlank(spcode)) spcode = UserUtil.CurrentUser.ShopCode__c;
                */
                // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
                // 該当店舗のロゴファイルはBase64に変換する
                decodedURLBlob(spcode);
            }
		    if (signaTypePage) {
		    	if (!CommUtils.isBlank(yadochou.Signature__c)) SignaTureFlg = true;
                // サイン画像情報が存在する場合
                if (!CommUtils.isBlank(yadochou.PageSignature__c)) {
                    pageSignaTureFlg = true;
                    String pageSignaStr = yadochou.PageSignature__c;
                    if (!CommUtils.isBlank(pageSignaStr)) pageSignaStrs = pageSignaStr.split(',');
        	   }
        	}
        	// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
        	List<ContactItem> contactItems = contactItemsMap.get(yadoId);
        	if (contactItems == null) contactItems = new List<ContactItem>();
	        // 改ページ処理機能初期化
	        OneCard wkOneCard= new OneCard();
	        // 会ページフラグを設定する
	        if (bulkAllPageList.isEmpty()) wkOneCard.isFirstPage = true;
	        if (switchCode == CONST_PDF4) {
	    		// メモ情報を設定する
	System.debug(loggingLevel.info, 'extInfMap='+extInfMap);
	    		wkOneCard.addMemoInfo(extInfMap.get(leadId));
	    		// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
	    		wkOneCard.addlayoutInfo(layoutCardMap.get(leadId));
	    		// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
	        }
	        List<OnePage> allPageList = wkOneCard.allPageList;
	        bulkAllPageList.add(wkOneCard);
        // 2017/02/20 レジカード一括印刷機能対応 END
	        Integer breakNum = (pageMaxMap.get(CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE) == null)
	        								? pageMaxMap.get('1')
	        								: pageMaxMap.get(CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE);
                // 2017/08/30 XML定义显示修正 zyz BEGIN
                if (customizeLins > 0 && switchCode == CONST_PDF4 && customizeHtml != null) breakNum = customizeLins;
                // 2017/08/30 XML定义显示修正 zyz END
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
	                // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
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
	                // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
	                // 2017/02/20 レジカード一括印刷機能対応 BEGIN
	                //if (allPageList.size() == 1) onePg.isFirstRow = true;
	                if (switchCode == CONST_PDF4) {
	                	onePg.addFooter4(fotter4Map.get(yadoId));
	                	onePg.addEstItem(estitemsMap.get(yadoId));
	                } else {
	                	onePg.addFooter(yadochou);
	                }
	                // 2017/02/20 レジカード一括印刷機能対応 END
	            } else {
	                OnePage onePg = allPageList[allPageList.size() - 1];
	                onePg.addItem(contactItems[index]);
	            }
	        }
	        // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
            if (contactItems.size() == 0 && contactNullCanInsFlg) {
            	OnePage onePgNull = new OnePage();
                if (switchCode == CONST_PDF4) {
                	onePgNull.addFooter4(fotter4Map.get(yadoId));
                	onePgNull.addEstItem(estitemsMap.get(yadoId));
                } else {
                	onePgNull.addFooter(yadochou);
                }
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
        
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
        }
        // 2017/02/20 レジカード一括印刷機能対応 END
    }
    // レジカードコード４の場合、個別処理の追加
    private void processForSwitchCd4(Yadochou__c yadochou) {
		processForSwitchCd4(new list<Yadochou__c>{yadochou});
	}
    private void processForSwitchCd4(List<Yadochou__c> yadochous) {
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
    	// 指定の予約の同じグループの部屋数
    	//footer4 = new Footer4Info(yadochou);
		//Lead__c keyLead = yadochou.Field1__r;
		// 各宿帳にFooter情報を格納する
		fotter4Map = new map<id, Footer4Info>();
		estitemsMap = new map<id, List<EstItem>>();
		// 2017/02/20 レジカード一括印刷機能対応 END
		// 小数点定義情報
		Integer pointlen = CommUtils.getPointLen();
		
    	// 指定の予約の同じ部屋のN泊の予約情報を取得する
    	List<Lead__c> existLeads = [select id, Name,EntryTime__c,Departure__c, Field3__C, Field4__c ,Morimongn__c,
    							// 2017/02/20 レジカード一括印刷機能対応 BEGIN
    							LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,
    							// 2017/02/20 レジカード一括印刷機能対応 END
    							// 2019/07/30 軽減税率機能対応 WGCH BEGIN
								refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c,
								// 2019/07/30 軽減税率機能対応 WGCH END
    							(	Select ActionType__c,PaymentType__c,Total__c,ProductName__c,X2_1__c,UnitPriceDefKbCal__c ,
    									UnitPrice__c, TaxRate__c, ServiceRate__c,Amount__c,
    									SpTotal__c, SpecialTax__c
    									// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    									, ParentBookingItemRef__c
    									// 2019/07/30 軽減税率機能対応 WGCH END
    									// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
    									,refBooking__c ,OptionPlanKey__c
    									// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    								From BookingEstimateItemFgKu__r 
    								// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    								// where ParentBookingItemRef__c = null
    								// And (ActionType__c != :CommConst.PROD_ACTION_TYPE_PY AND ActionType__c != :CommConst.PROD_ACTION_TYPE_AR)
     								where (ActionType__c != :CommConst.PROD_ACTION_TYPE_PY AND ActionType__c != :CommConst.PROD_ACTION_TYPE_AR)
     								// 2019/07/30 軽減税率機能対応 WGCH END
     								// 2017/12/13 見積明細非表示機能対応 WGCH BEGIN
    								And InvoiceNoShowFlg__c = false
    								// 2017/12/13 見積明細非表示機能対応 WGCH END
    									order by RowNo__c, Name) 
    							from Lead__c 
    							where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
    								// 2017/02/20 レジカード一括印刷機能対応 BEGIN
									//And LeadIndexSubId__c = :keyLead.LeadIndexSubId__c 
									//And LeadIndexRef__c = :keyLead.LeadIndexRef__c
									//And RoomGroupNo__c = :keyLead.RoomGroupNo__c
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
	    	// 到着日と泊数を取得する
			footer4.entryDate = leads[0].EntryTime__c.format('yyyy年MM月dd日');
			footer4.stayDays = leads[0].EntryTime__c.date().daysBetween(leads[leads.size()-1].Departure__c.date());
	        footer4.ciTime = firstLead.EntryTime__c.format(CommBaseCtrl.getDateFormat()) + ' ' + CommUtils.nullToBlank(firstLead.Field4__c);
	        footer4.coTime = endLead.Departure__c.format(CommBaseCtrl.getDateFormat()) + ' ' + CommUtils.nullToBlank(endLead.Field3__c);
	        // 利用金額
	        Decimal locUsedAmout = 0;
	        // 特別税
			Decimal locAmoutSpecialIncTax = 0;
			// 出力明細格納
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	        //estItems = new List<EstItem>();
	        List<EstItem> estItems = new List<EstItem>();
	        estitemsMap.put(yadochou.id, estItems);
	        // 2017/02/20 レジカード一括印刷機能対応 END
	        // 見積明細最大表示行数
	        Integer maxShowLines = 4;
	        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        List<BookingEstimateItem__c> bookEstLst = new List<BookingEstimateItem__c>();
	        for (Lead__c lead : leads) {
	        	if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
	        	bookEstLst.addAll(lead.BookingEstimateItemFgKu__r);
	        }
	        Map<String, List<BookingEstimateItem__c>> bookEstLstMap = new Map<String, List<BookingEstimateItem__c>>();
	        CommLogicProcess.OptionPlanInfo optionItem = null;
	        // 2020/05/29 bug fixed 6453 WGCH BEGIN
	        if(CommConst.REDUCED_TAXRATE_FLG && CommConst.OPTION_MODE == CommConst.OPTION_MODE_ON){
	        // 2020/05/29 bug fixed 6453 WGCH END
	        	optionItem = CommLogicProcess.getOptionPlanInfo(bookEstLst);
	        	for(BookingEstimateItem__c s : optionItem.nwBookingEstimateLst){
	        		if(!bookEstLstMap.containskey(s.refBooking__c)) bookEstLstMap.put(s.refBooking__c, new List<BookingEstimateItem__c>());
	        		bookEstLstMap.get(s.refBooking__c).add(s);
	        	}
	        }
	        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
	        map<string,CommLogicProcess.HotelTaxDefineInfo> hotelTaxMap = CommLogicProcess.getHotelTaxDefInstance();
	        Map<String, CommUtils.ProductInfo> planHeaderMap = new Map<String, CommUtils.ProductInfo>();
	        if(isReducedTaxFlg){
	        	for (Lead__c lead : leads) {
	        		if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
	        		String shopCd = CommUtils.nullToBlank(lead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
	        		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        		// for (BookingEstimateItem__c sobj : lead.BookingEstimateItemFgKu__r) {
	        		List<BookingEstimateItem__c> wkBookEstLst = lead.BookingEstimateItemFgKu__r;
	        		if(bookEstLstMap.containskey(lead.Id)){
	        			wkBookEstLst = bookEstLstMap.get(lead.Id);
	        		}
	        		for (BookingEstimateItem__c sobj : wkBookEstLst) {
	        		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	        			if(CommUtils.isBlank(sobj.ParentBookingItemRef__c)) continue;
	        			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        			if(optionItem != null){
	        				if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(sobj.ParentBookingItemRef__c)) continue;
	        				if(optionItem.planHeaderKeyMap.containsKey(sobj.ParentBookingItemRef__c)){
	        					String planHeaderNumKey = optionItem.planHeaderKeyMap.get(sobj.ParentBookingItemRef__c);
	        					sobj.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
	        				}
	        			}
	        			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	        			// 数量
			            Decimal qty = CommUtils.nullToZero(sobj.Amount__c);
			            // 合成明细Key
			            String key = sobj.ParentBookingItemRef__c;
			            CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c));
			            CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCd), CommUtils.nullToBlank(sobj.ActionType__c), CommUtils.nullToZero(sobj.UnitPrice__c), qty, sobj.TaxRate__c, sobj.ServiceRate__c, priceInfo, hotelTaxMap);
			            // 重置最新的PriceInfo
			            priceInfo = hotelTaxItem.priceInfo;
			            // planHeader 数据集合
			            if(!planHeaderMap.containsKey(key)) planHeaderMap.put(key, new CommUtils.ProductInfo(CommUtils.nullToIntZero(sobj.UnitPriceDefKbCal__c)));
			            CommUtils.ProductInfo headerPriceInfo = planHeaderMap.get(key);
			            // planHeader 数据合计
			            headerPriceInfo.getAddPriceInfo(priceInfo);
	        		}
	        	}
	        }
	        // 2019/07/30 軽減税率機能対応 WGCH END
			// 食数集計/見積合計金額集計	
	        for (Lead__c lead : leads) {
	        	// 食数集計
	        	footer4.dinnerNums += CommUtils.nullToZero(lead.Morimongn__c);
	        	// 見積金額合計
	        	if (lead.BookingEstimateItemFgKu__r.isEmpty()) continue;
	        	// 
	        	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	        	String shopCd = CommUtils.nullToBlank(lead.refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c);
	        	// 2019/07/30 軽減税率機能対応 WGCH END
	        	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        	// for (BookingEstimateItem__c estItem: lead.BookingEstimateItemFgKu__r) {
	        	List<BookingEstimateItem__c> wkBookEstLst = lead.BookingEstimateItemFgKu__r;
        		if(bookEstLstMap.containskey(lead.Id)){
        			wkBookEstLst = bookEstLstMap.get(lead.Id);
        		}
        		for (BookingEstimateItem__c estItem: wkBookEstLst) {
        		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	        		// 特別税も含め、総利用金額-支払金額
	        		Decimal usedAmout = CommUtils.nullToZero(estItem.SpTotal__c);
	        		/*
	        		// 明細は前受金（返金）以外、支払情報の場合,減産、その以外、加算
	        		if (estItem.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
	        			locUsedAmout -= usedAmout;
	        		} else if (estItem.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
	        			locUsedAmout -= math.abs(usedAmout);
	        		} else {
	        		*/
	        		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	        		if(!CommUtils.isBlank(estItem.ParentBookingItemRef__c)) continue;
	        		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	        		if(optionItem != null){
	        			if(!optionItem.planEstIdSet.isEmpty() && !optionItem.planEstIdSet.contains(estItem.Id)) continue;
	        			if(optionItem.planHeaderKeyMap.containsKey(estItem.Id)){
	        				String planHeaderNumKey = optionItem.planHeaderKeyMap.get(estItem.Id);
	        				// 2020/05/29 レジカードの合計金額不正BUGFIX WGCH BEGIN
	        				// 重置合计金额
	        				Decimal wkUsedAmout = CommUtils.nullToZero(estItem.Amount__c) == 0 ? usedAmout : usedAmout / CommUtils.nullToZero(estItem.Amount__c);
	        				usedAmout = wkUsedAmout * CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
	        				estItem.SpTotal__c = usedAmout;
	        				// 2020/05/29 レジカードの合計金額不正BUGFIX WGCH END
	        				estItem.Amount__c = CommUtils.nullToZero(optionItem.planHeaderNumMap.get(planHeaderNumKey));
	        				estItem.SpecialTax__c = CommUtils.nullToZero(optionItem.planHeaderTaxMap.get(planHeaderNumKey));
	        			}
		        	}
	        		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	        		Decimal unitPriceEnd = 0;
	        		Decimal unitNumsEnd = 0;
	        		Decimal dTotalEnd = 0;
	        		if (isReducedTaxFlg) {
	        			// 数量
			            Decimal qty = CommUtils.nullToZero(estItem.Amount__c);
	        			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(estItem.UnitPriceDefKbCal__c));
			            CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(CommUtils.nullToBlank(shopCd), CommUtils.nullToBlank(estItem.ActionType__c), CommUtils.nullToZero(estItem.UnitPrice__c), qty, estItem.TaxRate__c, estItem.ServiceRate__c, priceInfo, hotelTaxMap);
			            // 重置最新的PriceInfo
			            priceInfo = hotelTaxItem.priceInfo;
	        			if(planHeaderMap != null && planHeaderMap.containsKey(estItem.Id)) {
	        				priceInfo = planHeaderMap.get(estItem.Id);
	        			}
	        			unitPriceEnd = priceInfo.unitPriceTax;
	        			unitNumsEnd = CommUtils.nullToZero(estItem.Amount__c);
	        			// 合計金額から宿泊税をは外す[表示要合計金額 = 合計金額ー宿泊税]
	        			dTotalEnd = unitPriceEnd * unitNumsEnd;
	        			// 特別税も含め、総利用金額-支払金額 - 重置
	        			usedAmout = (unitPriceEnd * unitNumsEnd + CommUtils.nullToZero(estItem.SpecialTax__c));
	        		}
	        		// 2019/07/30 軽減税率機能対応 WGCH END
	        		locUsedAmout += usedAmout;
	        		//}
	        		// 特別税を合計する
	        		locAmoutSpecialIncTax += CommUtils.nullToZero(estItem.SpecialTax__c);
	        		// 表示明細に追加する
	        		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	        		// if (estItems.size() < maxShowLines ) estItems.add(new EstItem(estItem, pointlen));
	        		if (estItems.size() < maxShowLines ){
	        			EstItem item = new EstItem(estItem, pointlen);
	        			if(isReducedTaxFlg){
	        				item.unitPrice = unitPriceEnd;
	        				item.unitNums = unitNumsEnd;
	        				item.dTotal = dTotalEnd;
	        			}
	        			estItems.add(item);
	        		}
	        		// 2019/07/30 軽減税率機能対応 WGCH END
	        	}
	        }
	        footer4.estimateTotal = locUsedAmout;
	        
			if (estItems.size() < maxShowLines ) {
				if (locAmoutSpecialIncTax > 0) {
					// 宿泊税情報
		            BookingEstimateItem__c item = new BookingEstimateItem__c(
		               X2_1__c = '宿泊税',
		               ProductName__c = '宿泊税',
		               Amount__c = 1,
		               SpTotal__c = locAmoutSpecialIncTax,     // 宿泊税総金額表示するため、仮に設定を行う
		               UnitPrice__c = locAmoutSpecialIncTax
		            );
		            estItems.add(new EstItem(item, pointlen));
				}
			}
			Integer dumyLines = maxShowLines - estItems.size();
			if ( dumyLines > 0  ) {
				for (Integer i = 0; i < dumyLines; i++) {
					estItems.add(new EstItem(new BookingEstimateItem__c(), pointlen));
				}
			}
        }
		// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 BEGIN
		// 2017/02/20 レジカード一括印刷機能対応 BEGIN
		//autoPrintFieldToPdf(keyLead.Id);
		autoPrintFieldToPdf(yLeadIdsLst);
		// 2017/02/20 レジカード一括印刷機能対応 END
		// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 END
    }
    
    /**
    * コード設定により、ページ遷移処理を行う
    **/
    public PageReference switchPdf() {
    	// 元の引渡し情報を取得する
    	Map<String, String> paramMap = ApexPages.currentPage().getParameters();
		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN

		// 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
        PageReference pr;
        // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ BEGIN
		// 一括印刷フラグ
		Boolean isBlukProcessFlg = (ApexPages.currentPage().getParameters().containsKey('cardDate'));
		// レジカードコード７
		String pgCode = CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;
		Boolean isCode7Flg = ( pgCode == '7');
		// 共通定義「ページ毎に２室レジカード出力フラグ」はTRUE
		Boolean dupPrintFlg = CommDefine__c.getOrgDefaults().CashRegisterBulkFlg__c;
		if (isBlukProcessFlg && isCode7Flg && dupPrintFlg) {
			paramMap.put('dup','1');
			pgCode = '6';
		}
        //String pageUrl = 	(pageMap.get(CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE) == null )
        //							? pageMap.get('1') 
        //							: pageMap.get(CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE);
        String pageUrl = 	(pageMap.get(pgCode) == null )
        							? pageMap.get('1') 
        							: pageMap.get(pgCode);
        // 2018/09/28 １ページは複数印刷できるように改善対応(レジカード7対応) WSQ END
		//pr = new PageReference('/apex/' + pageUrl + '?id='+yadochouId);
		String urlStr = '/apex/' + pageUrl;
		if (!CommUtils.isBlank(yadochouId)) urlStr += '?id='+yadochouId;
		pr = new PageReference(urlStr);
		
		pr.getParameters().putAll(paramMap);
        pr.setRedirect(true);
        return pr;
    }
    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
    public PageReference switchSign() {
    	// 元の引渡し情報を取得する
    	Map<String, String> paramMap = ApexPages.currentPage().getParameters();
        PageReference pr;
		String pgCode = CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;
        String pageUrl = 	(pageSignMap.get(pgCode) == null )
        							? 'CashRegisterCardPDFSwitch'
        							: pageSignMap.get(pgCode);
		String urlStr = '/apex/' + pageUrl;
		if (!CommUtils.isBlank(yadochouId)) urlStr += '?id='+yadochouId;
		pr = new PageReference(urlStr);
		
		pr.getParameters().putAll(paramMap);
        pr.setRedirect(true);
        return pr;
    }
    // 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
    /**
    * レポートロゴ取得する
    **/
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    /*public ReportLogo__c getReportInfo() {
        return CommRepUtils.getReportTitleInfo();
    }*/
    public ReportLogo__c ReportInfo{get;set;}
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
    
    /**
    * １ページに表示情報を格納する
    **/
    // 2017/02/20 レジカード一括印刷機能対応 BEGIN
    //public List<EstItem> estItems{get; set;}
    // 2017/02/20 レジカード一括印刷機能対応 END
    public class EstItem{
    	public EstItem (BookingEstimateItem__c s, Integer pointlen) {
			if (s.Id != null || !CommUtils.isBLank(s.ProductName__c)) {
				// 会計商品名
				productNm = (CommUtils.isBlank(s.ProductName__c) ? s.X2_1__c : s.ProductName__c);
				productNm = CommRepUtils.getPdfMaxShowStringNew(productNm, 1, 32);
	            // Ver4.54       2014/08/05  E-CLOUD     過去の合計計算不具合修正           
	            CommUtils.ProductInfo proc = new CommUtils.ProductInfo(CommUtils.nullToIntZero(s.UnitPriceDefKbCal__c),pointlen);
	            // 単価（サービス料込、税込）計算を行う
	            proc.process(s.UnitPrice__c, 1, s.TaxRate__c, s.ServiceRate__c);
	           	unitPrice = proc.unitPriceTax;
	           	unitNums = CommUtils.nullToZero(s.Amount__c);
	            // 合計金額から宿泊税をは外す[表示要合計金額 = 合計金額ー宿泊税]
	            dTotal = CommUtils.nullToZero(s.SpTotal__c) - CommUtils.nullToZero(s.SpecialTax__c);
	            
	            isDtShowFlg = true;
			} else {
				productNm = '';
				unitPrice = null;
				unitNums = null;
				dTotal = 0;
				isDtShowFlg = false;
			}
    	}
    	public String productNm{get; set;}
    	public Decimal unitNums{get; set;}
    	public Decimal unitPrice{get; set;}
    	public Decimal dTotal{get; set;}
        public boolean isDtShowFlg{get; set;}
    }
    // １部屋の全てやど宿帳情報を格納する
    public class OneCard {
    	public OneCard() {
    		allPageList = new list<OnePage>();	
    	}
    	public Boolean isFirstPage{get;set;}
    	public list<OnePage> allPageList{get;private set;}
       	public ExtendMemoInfo extInf{get; private set;}
       	public void addMemoInfo(ExtendMemoInfo pInf) {
       		extInf = (pInf == null ? new ExtendMemoInfo() : pInf);
       	}
       	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
       	public layoutInfo layoutCardlst{get; private set;} // 自定义数据
        public void addlayoutInfo(layoutInfo card) {
            layoutCardlst = (card == null ? new layoutInfo() : card);
        }
        // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
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
        // 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
        // 截取后保存的图片
    	public String signaImg{get;private set;}
    	// 一括印刷无签名图片控制flg
    	public Boolean isSignaImg{get;private set;}
    	// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
        // 現在表示してページ数
        public Integer currPages{get;set;}
        public Boolean isFirstPage{get{
            return currPages == 1;
        }}
        // １ページ表示用データを格納
        public List<ContactItem> onePageList{get; private set;}
        
        // 2017/02/20 レジカード一括印刷機能対応 BEGIN
        // 該当レジカードに印刷用フッター情報を格納する
       	public FooterInfo footer{get;private set;}
       	public void addFooter(Yadochou__c s) {
       		footer = new FooterInfo(s);
       	}
       	public Footer4Info footer4{get; private set;}
       	public void addFooter4(Footer4Info pFooter) {
       		footer4 = pFooter == null ? new Footer4Info() : pFooter;
       	}
     	// 該当部屋の利用明細情報を格納する
       	public List<EstItem> estItems{get; private set;}
       	public void addEstItem(List<EstItem> pest) {
       		if (pest == null) estItems = new list<EstItem>();
       		else estItems = pest;
       	}
       	public Boolean isFirstRow{get;set;}
		// 2017/02/20 レジカード一括印刷機能対応 END
    }
    // 2017/02/20 レジカード一括印刷機能対応 BEGIN
    // map<宿帳ID,該当宿帳フォルダ情報>
    private map<Id,FooterInfo> footerMap{get; private set;}
    //public FooterInfo footer{get; private set;}
    // 2017/02/20 レジカード一括印刷機能対応 END
    public class FooterInfo {
        public FooterInfo(Yadochou__c s) {
            roomNm = CommUtils.nullToBlank(s.Field1__r.Rroom__r.name);
            checkInTime = CommUtils.nullToBlank(s.Field1__r.Field4__c);
            checkinStatff = Userinfo.getLastname() + ' ' + Userinfo.getFirstName();
            String[] nights = CommUtils.nullToBlank(s.Field1__r.Field293__c).split(':');
            if (nights.size() == 2) {
                nightHour = nights[0];
                nightMinute = nights[1];
            } else {
                nightHour = '　';
                nightMinute = '　';
            }
            String[] morning = CommUtils.nullToBlank(s.Field1__r.Morningtime__c).split(':');
            if (morning.size() == 2) {
                moringHour = morning[0];
                moringMinute = morning[1];
            } else {
                moringHour = '　';
                moringMinute = '　';
            }
            String[] checkout = CommUtils.nullToBlank(s.Field1__r.Field3__c).split(':');
            if (checkout.size() == 2) {
                checkoutHour = checkout[0];
                checkoutMinute = checkout[1];
            } else {
                checkoutHour = '　';
                checkoutMinute = '　';
            }
        }
        //public Yadochou__c s{get; private set;}
        public String roomNm{get; private set;}
        //  お着き時刻
        public String checkInTime{get; private set;}
        // お着き案內者
        public String checkinStatff{get; private set;}
        // 夕食
        public String nightHour{get; private set;}
        public String nightMinute{get; private set;}
        // 朝食
        public String moringHour{get; private set;}
        public String moringMinute{get; private set;}
        // 出発
        //public String checkoutTime{get; private set;}
        public String checkoutHour{get; private set;}
        public String checkoutMinute{get; private set;}
    }
    // 2017/02/20 レジカード一括印刷機能対応 BEGIN
    // map<宿帳ID,フォルダ情報>
	private map<Id, Footer4Info> fotter4Map{get; private set;}
	private map<Id, List<EstItem>> estitemsMap{get; private set;}
    //public Footer4Info footer4{get; private set;}
    // 2017/02/20 レジカード一括印刷機能対応 END
	public class Footer4Info {
		public Footer4Info(){}
    	public Footer4Info(Yadochou__c s) {
    		planName = CommRepUtils.getPdfMaxShowStringNew(s.Field1__r.Field310__r.Name,1,32);
    		roomName = CommRepUtils.getPdfMaxShowStringNew(s.Field1__r.Rroom__r.Name,1,8);
    		//2017/04/27 署名機能追加　by zyz BEGIN
    		signa = s;
    		//2017/04/27 署名機能追加　by zyz END
    		if (CommUtils.isBlank(roomName)) roomName = '　　　';
    		stayDays = 0;
    		dinnerNums = estimateTotal = 0;
    	}
	    public String planName{get; private set;}
	    public String roomName{get; private set;}		// 部屋名「指定の予約の部屋名
	    public String entryDate{get; private set;}		// 到着日
	    public Integer stayDays{get; private set;}		// 泊数
	    public Decimal dinnerNums{get; private set;}	// 食数
	    public String ciTime{get; private set;}			// 到着時刻
	    public String coTime{get; private set;}			// 出発時刻
	    public Decimal estimateTotal{get; private set;}	// 見積金額合計
	    //2017/04/27 署名機能追加　by zyz BEGIN
	    public Yadochou__c signa{get; private set;}
	    //2017/04/27 署名機能追加　by zyz END
    }
    
    public class ContactItem {
        // 明細番号
        public Integer rowNo{get; private set;}
        // ご芳名
        public String guestName{get; private set;}
        // ひらがな、
        public String hiragana{get; private set;}
        // 年齡
        public Decimal age{get; private set;}
        public String birthDate{get; private set;}
        public String birthDate2{get; private set;}
        // ご住所
        public String address1{get; private set;}
        public String address2{get; private set;}
        public String address{get; private set;}
        // 連絡電話
        public String phone{get; private set;}
        // 郵便番号
        public String post{get;private set;}
        // 性別
        public String gender{get; private set;}
        // E-mail
        public String email{get;private set;}
        public boolean isFirstShow {get; private set;}
        
        public ContactItem(Guestbookcustomer__c gobj, Integer index) {
            birthDate2 = Label.MSG_012_0107;
            rowNo = index;
            if (index == null) return;
            //if (index ==1) isFirstShow = true;
            isFirstShow = false;
            guestName = CommRepUtils.getPdfMaxShowStringNew(gobj.Customer__r.name,1,13);
            hiragana = CommRepUtils.getPdfMaxShowStringNew(CommUtils.nullToBlank(gobj.Customer__r.Katakana__c),2,13);
            // hiragana = CommUtils.nullToBlank(gobj.Customer__r.Katakana__c);
            age =  CommUtils.nullToZero(gobj.Customer__r.Age__c);
            phone = gobj.Customer__r.Phone;
            post = gobj.Customer__r.MailingPostalCode;
            gender = gobj.Customer__r.gender__c;
            email = gobj.Customer__r.Email;
            address1 = CommUtils.nullToBlank(gobj.Customer__r.MailingCountry) + '　' 
                            + CommUtils.nullToBlank(gobj.Customer__r.MailingState) + '　'  
                            + CommUtils.nullToBlank(gobj.Customer__r.MailingCity) ;
            address1 = address1.deleteWhitespace();
            if (address1.length() > 28) address1 = address1.substring(0,28);
            address2 = CommUtils.nullToBlank(gobj.Customer__r.MailingStreet);
            address2 = address2.deleteWhitespace();
            if (address2.length() > 28) address2 = address2.substring(0,28);
            //address = address1 + address2;
            //if (address.length() > 28) address = address.substring(0,28);
            Date bday = gobj.Customer__r.Birthdate;
            if (bday != null) birthDate = DateTime.newInstance(bday.year(),bday.month(),bday.day()).format(CommBaseCtrl.getDateFormat());
			// 2017/02/28  日本語英語切替誕生日表示機能対応 BEGIN zyz
			Boolean jsLangFlg = CommBaseCtrl.getLocalIsJapanese();
            if (bday != null) {
            	if (!jsLangFlg){
            		birthDate2 = DateTime.newInstance(bday.year(),bday.month(),bday.day()).format(CommBaseCtrl.getDateFormat());
            	} else {
            		birthDate2 = DateTime.newInstance(bday.year(),bday.month(),bday.day()).format('yyyy年MM月dd日');
            	}
            }
			// 2017/02/28  日本語英語切替誕生日表示機能対応 END zyz
        }
    }
    // 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
    private Boolean alwaysTitleFlg = false;
    // 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
	// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 BEGIN
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	//private void autoPrintFieldToPdf(Id leadId) {
	private void autoPrintFieldToPdf(List<Id> leadIds) {
	// 2017/02/20 レジカード一括印刷機能対応 END
		// XMLに定義の項目からPDFへ設定を行う
		String docName = 'CashRegisterCardPdfConfig';
		String shopCode =  '';
		//CommXmlUtils.parseXmlDoc(docName, shopCode);

		Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCode);
		// 客室係自動印字情報を初期化する
		// 2017/02/20 レジカード一括印刷機能対応 BEGIN
		//extInf = new ExtendMemoInfo();
		extInfMap = new map<id,ExtendMemoInfo>();
		// 2017/02/20 レジカード一括印刷機能対応 END
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
			//if(leadFields != null) getDataSource(leadFields,leadId,DATASOURCE_TYPE.LEAD,extInf);
			//if(yadochouFields != null) getDataSource(yadochouFields,leadId,DATASOURCE_TYPE.YADOCHOU,extInf);
			if(leadFields != null) getDataSource(leadFields,leadIds,DATASOURCE_TYPE.LEAD,extInfMap);
			if(yadochouFields != null) getDataSource(yadochouFields,leadIds,DATASOURCE_TYPE.YADOCHOU,extInfMap);
			// 2017/02/20 レジカード一括印刷機能対応 END
		}  
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
		// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
		// 处理数据值
		layoutCardMap = new map<id,layoutInfo>();
		getmizeHtml(leadIds,customizeHtml,layoutCardMap);
		// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
	}
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	//private void getDataSource(Dom.XmlNode dataSourceFields,Id leadId,DATASOURCE_TYPE sobjType,ExtendMemoInfo extInf){
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
			//Sobject sobj = null;
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			map<id,sobject> existLinkInfoMap = new map<id, sobject>();
			// 2017/02/20 レジカード一括印刷機能対応 END
			if(sobjType == DATASOURCE_TYPE.LEAD){
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				//String queryWhere = 'Where Id =: leadId';
				String queryWhere = 'Where Id =: pLeadIds';
				// 2017/02/20 レジカード一括印刷機能対応 END
				String queryStr = ' Select '+ queryLeadStr + ' From Lead__c ' + queryWhere;
System.debug(loggingLevel.info, 'queryStr='+queryStr);
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
				//String queryWhere = 'Where Field1__c =: leadId ';
				String queryWhere = 'Where Field1__c =: pLeadIds ';
				if (!queryLeadStr.toLowerCase().contains('field1__c')) queryLeadStr += ',Field1__c ';
				// 2017/02/20 レジカード一括印刷機能対応 END
				// 2017/03/24 レジカード一括印刷メモ機能対応 zyz BEGIN
				//String queryStr = ' Select '+ queryLeadStr + ' From Yadochou__c ' + queryWhere + ' limit 1';
				String queryStr = ' Select '+ queryLeadStr + ' From Yadochou__c ' + queryWhere;
				// 2017/03/24 レジカード一括印刷メモ機能対応 zyz END
				// YADOCHOUからXMLに定義しているAPIから情報を取得する
				List<Yadochou__c> yadochous = Database.query(queryStr);
				if (yadochous.isEmpty()) return;
				// Yadochou__c 
				// 2017/02/20 レジカード一括印刷機能対応 BEGIN
				//sobj = yadochous[0];
				for (Yadochou__c yado : yadochous) {
					if (!existLinkInfoMap.containsKey(yado.Field1__c)) existLinkInfoMap.put(yado.Field1__c, yado);
				}
				// 2017/02/20 レジカード一括印刷機能対応 END
			}
			// 処理対象外の場合
			// 2017/02/20 レジカード一括印刷機能対応 BEGIN
			//if (sobj == null) return;
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
						//String fieldVal = CommUtils.nullToBlank(sobj.get(apiStr));
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
							//if(refObj == null) continue;
							//String fieldVal = CommUtils.nullToBlank(refObj.get(childApis[1]));
							//if(!CommUtils.isBlank(fieldVal)) extInf.memoList.addAll(getSplitMemoInfo(memoDefMap.get(apiStr), fieldVal));
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
		Integer intMaxCharLen = 50;
		Integer intMaxRows = 10;
		String splitKey = ':::_:::';
		// Removes HTML markup from the input string and returns the plain text.
		fieldVal = fieldVal.stripHtmlTags();
		String val = apiLabel + fieldVal;
		val = CommRepUtils.getPdfMaxShowStringNew(val, intMaxRows, intMaxCharLen, splitKey);
		return val.split(splitKey);
	}
	// 客室係自動印字情報を格納する
	// 2017/02/20 レジカード一括印刷機能対応 BEGIN
	//public ExtendMemoInfo extInf{get; private set;}
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
	@TestVisible
	enum DATASOURCE_TYPE{LEAD,YADOCHOU}
	// 2017/02/03 レジカードの客室係記入ページのメモ欄へ自動印字機能対応 END
	// 2017/04/05 署名機能対応 zyz BEGIN
	@remoteAction
	public static void refreshsignatureInfo (Id yadoId,String png){
		// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
		try{
			if (!CommUtils.isBlank(yadoId)){
				List<Yadochou__c> queryyados = [select Id,Name,Field1__c,Field15__c,Field11__c,Field12__c,Signature__c,Field13__c,LeadIndexId__c from Yadochou__c where Id =: yadoId];
				if (!queryyados.isEmpty()) {
					queryyados[0].Signature__c = png;
					// 2019/02/28 BY 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 zyz BEGIN 
					checkInLead(queryyados[0].Field1__c);
					// 2019/02/28 BY 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 zyz END 
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
	// 2017/04/05 署名機能対応 zyz END
	// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
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
					checkInLead(queryyados[0].Field1__c);
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
        //reporLogotURL = 'https://c.na52.content.force.com/servlet/servlet.ImageServer?id=015d0000000G4fq&oid=00Dd0000000dBJC&lastMod=1330026235000';
        if (!CommUtils.isBlank(reporLogotURL)) {
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
//System.debug(loggingLevel.info,'image' +  EncodingUtil.base64Encode(b));
	}
	// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
	// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz BEGIN
	private String converTitleToValue(String fieldTitle,String fieldVal){
		// 不为空直接返回
		if (!CommUtils.isBlank(fieldVal)) return fieldVal;
		// title存在的情况下
		if (alwaysTitleFlg && !CommUtils.isBlank(fieldTitle) && fieldTitle != ':') return '';
		return null;
	}
	// 2018/04/09 レジカードのメモ欄に印字の定義をした項目は項目名だけは表示できるように改善 zyz END
	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
	// 予約のHTML作成内容集合
	public map<id,layoutInfo> layoutCardMap{get; private set;}
	class layoutInfo {
		public String autoHtml{get;set;} // 自定义的字符串
		public layoutInfo() {
		}
	}
	private void getmizeHtml(list<Id> pLeadIds, String autoStr,map<id,layoutInfo> autoInfMap){
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
			queryApiStr = queryApiStr.removeEnd(',');
			String queryWhere = 'Where Field1__c =: pLeadIds ';
			if (!queryApiStr.toLowerCase().contains('field1__c')) queryApiStr += ',Field1__c ';
			String queryStr = ' Select '+ queryApiStr + ' From Yadochou__c ' + queryWhere;
			List<Yadochou__c> yadochous = Database.query(queryStr);
			if (yadochous.isEmpty()) return;
			for(Yadochou__c yadochouStr: yadochous){
				layoutInfo lay = new layoutInfo();
				lay.autoHtml = autoStr;
				for(String api : apiDupSet){
					// 获取定义字段对应值
			    	String valueStr = CommUtils.nullToBlank(CommUtils.getFielValue(yadochouStr,api));
			    	// 替换显示的值
			    	list<String> apilst = splitsMap.get('$$_'+api+'_$$');
			    	if(!splitsMap.containsKey('$$_'+api+'_$$')) lay.autoHtml = lay.autoHtml.Replace('$$_' +api+'_$$' ,valueStr);
			    	else {
			    		list<String> vallst = getSplitMemoInfo('',valueStr);
			    		for(Integer i=0;i <apilst.size();i++){
			    			String valSplitStr = '';
			    			if(i < vallst.size()) valSplitStr = vallst[i];
			    			lay.autoHtml = lay.autoHtml.Replace('$$_' +api+'_$$_'+i ,valSplitStr);
			    		}
			    	}
				}
				if (!autoInfMap.containsKey(yadochouStr.Field1__c)) autoInfMap.put(yadochouStr.Field1__c, new layoutInfo());
				autoInfMap.put(yadochouStr.Field1__c, lay);
			}
		} catch(Exception e){}
	}
	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
	// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz BEGIN 
	public static void checkInLead(String checkLeadId){
		// ID存在　かつ　保存の際に自動チェックインを行う
		if(!CommUtils.isBlank(checkLeadId) && CommConst.APPOTION_CARREGISTSAVE_CHECKIN_MESSAGE){
			list<Lead__c> qLead = [select Id,Name,Field298__c from Lead__c where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG And Id=:checkLeadId And 
                                    // 2019/05/31 JINYABUG-1768 bug fix by zy BEGIN
                                    //Field298__c != :CommConst.LEAD_GUEST_ST_CI
                                    Field298__c = ''
                                    ];
                                    // 2019/05/31 JINYABUG-1768 bug fix by zy END
			if (!qLead.isEmpty()) {
				qLead[0].Field298__c = CommConst.LEAD_GUEST_ST_CI;
				update qLead[0];
			}
		}
	}
	// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz END 
}