/**********************************
* 会計編集機能(BillInput_Ctrl)
* 2012/10/03 プラン明細表示機能改造
* 2012/10/04 商品単価定義にて、金額計算方法対応
* 2014/07/17 クポン機能対応
* 2014/08/05 過去の合計計算不具合修正
* 2014/09/15 数量小数点機能対応
* 2014/09/19 金額小数点機能対応（NO403）
* 2015/01/12 Copon複数入力可能対応
* 2015/06/16 お客様項目を自動設定機能対応
* 2015/10/25 会計明細は同じ会計商品を切替する場合、明細金額を自動設定不具合修正
* 2018/03/12 連泊コメント同期機能対応
* 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善
***********************************/
public with sharing class BillInput_Ctrl extends CommBaseCtrl{

	/***************************
	* 定数定義を行う
	****************************/
    // 画面データ処理ステータス変数
    private Enum PAGE_STATUS {INS,UPD,SEL,UPDSPEC}
	private static final Integer TTEND_INPUT_MAX_ROWS = 3;
	//private static final Integer TRAN1_INPUT_MAX_ROWS = 27;
	private static final Integer TRAN1_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 27 
    													: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
    // メディア種別コード：12 DEL(共通CommConstに集中)
    private static final String MediaTypeDisCount = CommConst.MEDIA_TYPE_CD_12;
   	// 会計種別：プラン
	public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
	// 並び替え機能、プラン表示機能制御
	private final String DETAIL_SORT_DIV_PLANTOP = '2';
	private final String DetailSortDiv = CommUtils.isBlank(CommDefine__c.getOrgDefaults().AccountDetailSortCode__c) 
										? '1' 
										: CommDefine__c.getOrgDefaults().AccountDetailSortCode__c;
	/***************************
	* 変数定義を行う
	****************************/
	public PageInfo oPage{get; private set;}
	
    // 予約基本情報
    private Lead__c oLeadSobj{get; private set;}
	// 会計基本情報
	public AccountAcount__c oAcountSobj{get; private set;}
	// 支払い方法
    public List<TTendItem> oTTendSobjLst{get; private set;}
	// 会計明細
    public List<TranItem> oTranSobjLst{get; private set;}
    // 会計明細Footer
    public TranFooter oTranFooter{get; private set;}    
	// 会計支払Footer
	public TTendFooter oTttendFooter{get; private set;}
	
	// 2013/07/16 会計明細の並び替え機能追加
	public String sortField{get;set;}
	public List<Selectoption> sortFieldOpts{get; private set;}
	public String sortOrder{get;set;}
	// 2013/10/20 会計宛名、請求書宛名、但し書き内容選択リスト設定を行う
	//public List<Selectoption> accountNameOpts{get; private set;}
	//public List<Selectoption> accountProvisoOpts{get; private set;}
	//public String accountNames{get; private set;}
	//public String accountProvisos{get; private set;}
	/***************************
	* 変数定義を行う
	****************************/
    // 税金率選択リスト
	//public List<Selectoption> taxRateOptionLst{get; private set;}
	// メディア種別選択リスト
	public List<Selectoption> mediaTypeOptionLst{get; private set;}
    // 画面制御関連変数
    // 遷移先からパラメータ情報を格納する
    private Map<String,String> paramMap;
	private ApexPages.StandardController ctrl;
	// 会計書のコメントの表示できる最大文字列
	public String commentMaxStrSize{get{
		// 会計情報がすでに存在する場合、該当会計に格納の店舗コードで、関連のコメントの制御情報を取得する
		String shopCd = UserUtil.CurrentUser.ShopCode__c;
		String fcCode = ShopInfoUtil.getShopFacilityCode(shopCd);
		Integer maxLen = CommRepUtils.getPdfMaxShowStringNum(fcCode);
		return (maxLen == 0 ? '255': String.valueOf(maxLen));
	}}
// 2017/07/10 ログ出力機能を追加する BEGIN
	// 処理単位のログ記述する
	private CommLogUtils serverlog = new CommLogUtils('BillInput_Ctrl', true, true);
	private String localIp;
// 2017/07/10 ログ出力機能を追加する END
	public BillInput_Ctrl(ApexPages.StandardController controller) {
		ctrl = controller;
	}
	/**
	* 初期化処理を行う
	**/
	private void initInfo(AccountAcount__c standObj) {
        // 格納用クラスの初期化を行う
        oPage = new PageInfo();
        // 戻るページ維持する
        paramMap = Apexpages.currentPage().getParameters();
// 2017/07/10 ログ出力機能を追加する BEGIN
		localIp = CommUtils.nullToBlank(paramMap.get('ip'));
// 2017/07/10 ログ出力機能を追加する END
        // データは新規の場合
        if (standObj.Id == null) {
            // 新規表示用情報を設定する
            oPage.dataStatus = PAGE_STATUS.INS;
            // 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
            if(isAccountSyncCommentFlg) getOneRoomAcc(standObj);
            // 2018/03/12 連泊コメント同期機能対応 WGCH END
            oAcountSobj = standObj.clone(true,true);

            // 扱い者初期値設定を行う
            /* 2012/08/21 該当設定は廃止
			List<Worker__c> workerLst = [select id, name from Worker__c where name = :userInfo.getName()];
			if (!workerLst.isEmpty()) oAcountSobj.Field146__c = workerLst[0].Id;*/
			// 当日分の売り上げ日のデータ存在チェック、ない場合、自動当日の売り上げデータを作成する
			/* 2013/05/10 自動売上設定が封印する
			String todayDt = DateTime.now().format('yyyyMMdd');
			List<RsvAccount__c> rsvAccLst = [select id from RsvAccount__c where name = :todayDt for update];
			if (rsvAccLst.isEmpty()) {
				RsvAccount__c newItem = new RsvAccount__c(name = todayDt);
				insert newItem;
				oAcountSobj.frs__c = newItem.Id;
			} else {
				oAcountSobj.frs__c = rsvAccLst[0].Id;
			}*/
        }
        // データはすでに存在の場合
        else {
            // 既存の件名明細データを取得する
            if (!refreshAccoutAcountInfo(standObj.Id)) return;
            // 画面編集フラグを設定する
            oPage.dataStatus = PAGE_STATUS.UPD;
            // 並べ順初期値設定を行う
			if (!CommUtils.isBlank(oAcountSobj.DetailSortBy__c)) {
				String sortKey = oAcountSobj.DetailSortBy__c;
				Integer idx = sortKey.indexOf(' ');
				if (idx > 0) {
					sortField = sortKey.substring(0, idx);
					sortOrder = sortKey.substring(idx+1);
				}
			}
			if(CommUtils.isBlank(oAcountSobj.AccountName__c)){
				oAcountSobj.AccountName__c = oAcountSobj.ContactName__c;
			}
			if(CommUtils.isBlank(oAcountSobj.AccountReceiptName__c)){
				oAcountSobj.AccountReceiptName__c = oAcountSobj.BillingCal__c;
			}
        }
        // 2015/06/16 お客様項目を自動設定の対応 BEING
        autoSetupAccField(oAcountSobj);
        // 関連情報を設定を行う
        refreshTTendInfo(oAcountSobj.frs__c, oAcountSobj.Id);
        refreshTran1Info(oAcountSobj.frs__c, oAcountSobj.Id);
        
        // 選択リスト初期かを行う
		//taxRateOptionLst = new List<Selectoption>();
		//Schema.DescribeFieldResult fieldResult = Jinyaconnect__c.TaxType__c.getDescribe();
		//List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();     
		//for( Schema.PicklistEntry f : ple) taxRateOptionLst.add(new SelectOption(f.getValue(),f.getLabel()));

		// メディア種別選択リスト初期値設定する(仮)
		mediaTypeOptionLst = CommConst.getPayMentTypeOptLst();
		
		// 2013/07/16 会計明細並び替え機能追加 BEGIN
		sortFieldOpts = new List<Selectoption>();
		//商品コード順
		sortFieldOpts.add(new SelectOption('Field7__r.Field3__c',Label.CONST_006_0410));
		//カテゴリコード
		sortFieldOpts.add(new SelectOption('Field25__r.Field1__c',Label.CONST_006_0411));
		//ABC順
		sortFieldOpts.add(new SelectOption('Field7__r.Name',Label.CONST_006_0412));
		// 
		//sortOrderOpts = new List<Selectoption>();
		//sortOrderOpts.add(new SelectOption('asc','昇順'));
		//sortOrderOpts.add(new SelectOption('desc','降順'));
		// 2014/04/04 売上計上日初期化
		oAcountSobj.SalesDate__c = oAcountSobj.frs__c == null ? Date.today() : oAcountSobj.frs__r.Salesday__c;
		// 2014/04/29 領収書日付
		if (oAcountSobj.AccountReceiptDate__c == null ) {
			oAcountSobj.AccountReceiptDate__c = oAcountSobj.SalesDate__c;
		}
		// 2013/07/16 会計明細並び替え機能追加 END
		/*
		mediaTypeOptionLst = new List<Selectoption>();
		mediaTypeOptionLst.add(new SelectOption('01',MediaCdName.get('01')));
		mediaTypeOptionLst.add(new SelectOption('02',MediaCdName.get('02')));
		mediaTypeOptionLst.add(new SelectOption('03',MediaCdName.get('03')));
//		mediaTypeOptionLst.add(new SelectOption('04','Edy支払'));
//		mediaTypeOptionLst.add(new SelectOption('05','社内使用(従食)'));
//		mediaTypeOptionLst.add(new SelectOption('06','キャッシュバック支払'));
//		mediaTypeOptionLst.add(new SelectOption('07','Suica 支払'));
		mediaTypeOptionLst.add(new SelectOption('11',MediaCdName.get('11')));
		mediaTypeOptionLst.add(new SelectOption(MediaTypeDisCount,MediaCdName.get(MediaTypeDisCount)));
		*/
	}

	/**
	* VOID
	**/
	public Pagereference voidProcess () {
		// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'Field39__c','SumSrvPriceIncTax__c','sumTax__c','Field114__c','field116__c','Discount__c',
	    										'AmoutSpecialPrice__c','TaxRate__c','SalesDate__c','AccountReceiptDate__c','AccountReceiptName__c',
	 											'AccountName__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountAcount__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return null;
	    }
	    //System.debug(logginglevel.info,'Field Security Check:::[187-195]:::>>Pass');
	    // 2017/02/21 Field Security Check End
        // 最新情報取得、設定を行う
        refreshAccoutAcountInfo(((AccountAcount__c)ctrl.getRecord()).Id);
        
		// 既にVOIDの場合、再VOIDできませんチェックを行う
		if (oAcountSobj.Field39__c == CommConst.ACC_TRADE_VOID) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
            //既にVOID処理済みため、再VOID処理することができません。
		      Label.MSG_006_0313));
            return null;
		}
		// VOID機能実施を行う
        // 取引種別:30 ＶＯＩＤ
        oAcountSobj.Field39__c = CommConst.ACC_TRADE_VOID;
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
        try {
			update oAcountSobj;
		} catch (Exception e) {
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
            return null;
		}
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
		// TODO ＶＯＩＤレシートＮｏ．->設定？いつ？
        // 詳細画面へ戻る
        return gotoAccountsDetailPg();
	}
	/**
	* VOID機能取消を行う
	**/
	public Pagereference voidProcessCancel() {
        // 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'Field39__c','SumSrvPriceExcTax__c','Field116__c','sumTax__c','Field114__c',
	    										'Discount__c','AmoutSpecialPrice__c','TaxRate__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountAcount__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return null;
	    }
	    // 2017/02/21 Field Security Check End
	    //System.debug(logginglevel.info,'Field Security Check:::[220-227]:::>>Pass');
        // 最新情報取得、設定を行う
        refreshAccoutAcountInfo(((AccountAcount__c)ctrl.getRecord()).Id);
        
        if (oAcountSobj.Field39__c != CommConst.ACC_TRADE_VOID) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
            //VOID処理をされてない為、VOID取り消し処理ができません。
              Label.MSG_006_0314));
            return null;
        }
        // 取引種別:00 売上（通常）
        oAcountSobj.Field39__c = CommConst.ACC_TRADE_NORMAL;
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
        try {
			update oAcountSobj;
		} catch (Exception e) {
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
            return null;
		}
        // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
        
        // 詳細画面へ戻る
        return gotoAccountsDetailPg();
	}
	// 会計詳細画面へ戻る
	public Pagereference gotoAccountsDetailPg() {
		return new Pagereference('/' + ctrl.getRecord().id);
	}

	private static final String TTendSel = CommSqlUtils.generateQueryString('TTend__c'); //'Select CardTypeLst__c ,CouponTypeLst__c, noneaccount__c, Taxfee__c, Taishou__c, RelAccount__c, POSNo__c, OutSideAccount__c, Field9__c, Field8__c, Field7__c, Field6__c, Field5__c, Field4__c, Field3__c, Field35__c, Field34__c, Field33__c, Field32__c, Field31__c, Field30__c, Field2__c, Field29__c, Field28__c, Field27__c, Field26__c, Field25__c, Field24__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c, Field19__c, Field18__c, Field17__c, Field16__c, Field15__c, Field14__c, Field13__c, Field10__c, SystemModstamp, Name, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Id, CreatedDate, CreatedById From TTend__c ';
	private static final String TranSel = 'Select UnitPriceDefKbCal__c, NoShowRequestFlg__c,PlanDetailSyncInfo__c,TaxRate__c,ServiceRate__c,SpecialTax__c,InvoiceNoShowFlg__c,ActionType__c, Field7__r.Name, rtaxsts__c, profitt__c, profitnonetax__c, profit__c, noneaccount__c, inside__c, guestRoom__c, freetotal3__c, freetotal2__c, freetotal1__c, freeprice__c, freecost__c, VoidReceiptNo__c, TankawithoutTax__c, Tankanonetax__c, TableNo__c, Subprice__c, Seq__c, RowNo__c, RelAccount__c, POSNo__c, OPcode__c, GoukeinoneTax__c, Genkaritsu__c, Field9__c, Field8__c, Field7__c, Field6__c, Field5__c, Field52__c, Field51__c, Field50__c, Field4__c, Field49__c, Field48__c, Field47__c, Field46__c, Field45__c, Field44__c, Field43__c, Field42__c, Field41__c, Field40__c, Field3__c, Field39__c, Field38__c, Field37__c, Field36__c, Field35__c, Field34__c, Field33__c, Field32__c, Field31__c, Field30__c, Field2__c, Field29__c, Field28__c, Field27__c, Field26__c, Field25__c, Field24__c, Field23__c, Field22__c, Field21__c, Field20__c, Field1__c,    Field1__r.Name    ,Field19__c, Field18__c, Field17__c, Field16__c, Field15__c, Field14__c, Field13__c, Field12__c, Field11__c, Field10__c, DivisionNameI__c, Categorya__c, Category__c, CategoryItem__c, Accountoutside__c,  Name From Tran1__c ';
	/**
	* 最新会計情報を取得する
	* billId: 会計ID
	**/
	private Boolean refreshAccoutAcountInfo(Id billId) {
		if (billId == null) return false;
		// 最新情報を取得する
		List<AccountAcount__c> billList = [
		  Select relaccount__c, frs__c, comment__c, TeaTimeFlag__c, Target__c, TableNo__c, Seq__c, Relreserve__c, 
		      PlanNo__c, POSNo__c, OutSideAccount__c, Field99__c, Field98__c, Field97__c, Field96__c, Field95__c, 
		      Field94__c, Field93__c, Field92__c, Field91__c, Field90__c, Field89__c, Field88__c, Field87__c, 
		      Field86__c, Field85__c, Field84__c, Field83__c, Field82__c, Field81__c, Field80__c, Field7__c, 
		      Field79__c, Field78__c, Field77__c, Field76__c, Field75__c, Field74__c, Field73__c, Field72__c, 
		      Field71__c, Field70__c, Field69__c, Field68__c, Field67__c, Field66__c, Field65__c, Field64__c, 
		      Field63__c, Field62__c, Field61__c, Field60__c, Field59__c, Field58__c, Field57__c, Field56__c, 
		      Field55__c, Field54__c, Field53__c, Field52__c, Field51__c, Field50__c, Field49__c, Field48__c, 
		      Field45__c, Field44__c, Field43__c, Field42__c, Field40__c, Field39__c, Field159__c, Field158__c, 
		      Field157__c, Field156__c, Field155__c, Field154__c, Field152__c, Field151__c, Field150__c, 
		      Field149__c, Field148__c, Field147__c, Field146__c, Field145__c, Field143__c, Field142__c, 
		      Field141__c, Field140__c, Field139__c, Field138__c, Field137__c, Field136__c, Field135__c, 
		      Field134__c, Field133__c, Field132__c, Field131__c, Field130__c, Field129__c, Field128__c, 
		      Field127__c, Field126__c, Field125__c, Field124__c, Field123__c, Field122__c, Field121__c, 
		      Field120__c, Field119__c, Field118__c, Field117__c, Field116__c, Field115__c, Field114__c, 
		      Field113__c, Field112__c, Field111__c, Field110__c, Field109__c, Field108__c, Field107__c, 
		      Field106__c, Field105__c, Field104__c, Field103__c, Field102__c, Field101__c, Field100__c, 
		      ContactName__c,BillingCal__c, AccountLanguage__c ,
		      DivisionName__c, Name, SumSrvPriceIncTax__c, SumSrvPriceExcTax__c,AmoutSpecialPrice__c,
		      LastModifiedDate, LastModifiedById, TaxRate__c,
		      Relreserve__r.Name,Relreserve__r.refTypeOfRooms__c,
		      Relreserve__r.StayPersons__c,Relreserve__r.Rroom__c, Discount__c,
		      PaymentFlg__c,relaccount__r.Account.Name, AccountedFlgCal__c,DetailSortBy__c,relaccount__r.Name, relaccount__r.AccountId,
		      AccountName__c,AccountReceiptName__c,AccountProviso__c,AccountReceiptDate__c,
		      frs__r.Salesday__c,SalesDate__c,CouponReturnFlg__c
		      // 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		      ,Relreserve__r.LeadIndexRef__c, Relreserve__r.LeadIndexSubId__c, Relreserve__r.RoomGroupNo__c
		      // 2018/03/12 連泊コメント同期機能対応 WGCH END
		  From AccountAcount__c where id = :billId];
		if (billList.isEmpty()) return false;
		// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		if(isAccountSyncCommentFlg) getOneRoomAcc(billList[0]);
		// 2018/03/12 連泊コメント同期機能対応 WGCH END
		oAcountSobj = billList[0];
		return true;
	}
	public class Option {
		public Option (String value, String label) {
			this.value = value;
			this.label = label;
		}
		public String value{get;set;}
		public String label{get;set;}
	}
	public String getAccountNames() {
		List<Option> accountNamsLst = new List<Option>();
		if (!CommUtils.isBlank(oAcountSobj.relaccount__r.Account.Name))
		accountNamsLst.add(new Option(oAcountSobj.relaccount__r.Account.Name,oAcountSobj.relaccount__r.Account.Name));
		if (!CommUtils.isBlank(oAcountSobj.relaccount__r.Name))
		accountNamsLst.add(new Option(oAcountSobj.relaccount__r.Name,oAcountSobj.relaccount__r.Name));
		if (!CommUtils.isBlank(oAcountSobj.Relreserve__r.Name))
		// 2013/10/28 会計編集の「会計書宛名、領収書宛名」の選択リスト内容を追加
		accountNamsLst.add(new Option(oAcountSobj.Relreserve__r.Name,oAcountSobj.Relreserve__r.Name));
		return JSON.serialize(accountNamsLst);
	}
	public String getAccountProvisos() {
		List<Option> accountProvisoLst = new List<Option>(); 
    	String provisoStr = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountProviso__c);
    	String[] provisoArray = provisoStr.split(',');
    	for (String key : provisoArray) {
    		if (!CommUtils.isBlank(key)) accountProvisoLst.add(new Option(key, key));
    	}
    	return JSON.serialize(accountProvisoLst);
	}
	/**
	* 予約情報を取得を行います 1会計→1日予約対応する
	**//*
	private Lead__c getLeadInfo() {
		// 到着日（連泊場合：）→チェックイン日に設定を行う
		// TODO: 深夜チェックに関して（２４：００すぎ）、チェック日の設定に関して、次のVERSIONに対応
		List<Lead__c> leadInfoLst = [select EntryTime__c from Lead__c where id = :oAcountSobj.Relreserve__c limit 1];
		// 必ず存在ですね、
		if (leadInfoLst.isEmpty()) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '予約情報を登録されないため、会計情報を登録できません。'));
			return null;
		}
		return leadInfoLst[0];
	}*/

	private Boolean preAmoutTran1Info() {
		
		return true;
	}
	/**
	* 会計支払金額再計算を行う
	**/
	public Pagereference calPaymentInfo() {
		amoutTran1Info();
		return null;
	}
	// 会計明細金額合計計算を行う
	private Boolean amoutTran1Info() {
		// 有効性チェックを行う
		if (!preAmoutTran1Info()) return false;
		// 既存支払い明細合計情報をクリアする
		oTranFooter.clear();
		// 会計のHeader消費税RESETする、会計商品の明細情報により、再設定を行う
		oAcountSobj.TaxRate__c = 0;
		// 単価計算共通クラス初期化
		// 2014/08/05 過去の合計計算不具合修正 BEGIN
		//CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
		// 2014/08/05 過去の合計計算不具合修正 END
		// 会計明細金額を再計算を行う
		for (TranItem obj: oTranSobjLst) {
			// 無効のデータをクリアを行う
			if (!obj.isValidata) {
				obj.clear();
				continue;
			}
			// 請求書非表示の場合、統計対象外になる
			if (obj.sobj.InvoiceNoShowFlg__c) continue;
			// 合計金額計算を行う
			// 2014/08/05 過去の合計計算不具合修正
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero( obj.sobj.UnitPriceDefKbCal__c ));
			// 単価と数量はNULLの場合、
			Decimal unitPrice = CommUtils.nullToZero(obj.sobj.Field20__c);  // <-税金含め単価です
			Decimal qty = CommUtils.nullToZero(obj.sobj.Field21__c);
/* 20121005修正を行う（商品単価多目意味機能対応） */
            priceInfo.process(unitPrice , qty , obj.sobj.TaxRate__c, obj.sobj.ServiceRate__c);
            // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
// 2013/07/22 税抜き＝単価（税抜き、サービス料抜き）＋サービス琉金（税抜き）
            obj.amoutExcTax = priceInfo.priceExcTax;
            // サービス料金（税込）
            obj.servicePriceIncTax = priceInfo.priceService;
            // 合計金額(税込)
            obj.amoutIncTax = priceInfo.priceIncTax;
			// 2012/10/17 宿泊税の計算機能を追加する
			// 設定されている商品は室料場合、宿泊税計算を行う
			if (obj.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
				// 単価価額(税抜) + サビース料金(税抜)で計算結果を取得する[数量固定１で計算を行う]
				priceInfo.process(unitPrice , 1, obj.sobj.TaxRate__c, obj.sobj.ServiceRate__c);
				// 2013/07/22 税抜き＝単価（税抜き、サービス料抜き）＋サービス琉金（税抜き）
				//Decimal roomPrice = priceInfo.priceExcTax + priceInfo.priceServiceExcTax;
				Decimal roomPrice = priceInfo.priceExcTax;
				// 特別税計算を行う
				// 2014/07/10 宿泊税自動計算機能は外す
				//if (obj.sobj.SpecialTax__c == null) obj.sobj.SpecialTax__c = priceInfo.specialTaxCal(roomPrice) * qty;
			}
			// 宿泊税値合計値に追加する
			obj.amoutIncTax += CommUtils.nullToZero(obj.sobj.SpecialTax__c);
			
			// 該当会計の消費税率項目はNULLの場合、消費税明細項目から消費税率設定ヲ行う
			if (CommUtils.nullToZero(oAcountSobj.TaxRate__c) == 0) {
				Decimal itemTaxRate = CommUtils.nullToZero(obj.sobj.TaxRate__c);
				if ( itemTaxRate > 0 ) oAcountSobj.TaxRate__c = itemTaxRate;
			}
/*
			// 合計金額(税込)
			obj.amoutIncTax = CommUtils.RoundProcess((unitPrice * qty), 0);
			// 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
			obj.amoutExcTax = CommUtils.CalExcTaxPrice(obj.amoutIncTax, obj.sobj.TaxRate__c, 0, RoundingMode.CEILING);
//            obj.amoutExcTax = CommUtils.CalExcTaxPrice(obj.amoutIncTax, obj.sobj.TaxRate__c, 0);
            // サービス料金（税込）
            obj.servicePriceIncTax = CommUtils.RoundProcess(obj.amoutIncTax * (CommUtils.nullToZero(obj.sobj.ServiceRate__c) / 100), 0);
            // サービス料金（税抜）
//            obj.servicePrice = CommUtils.RoundProcess(obj.amoutExcTax * (CommUtils.nullToZero(obj.sobj.ServiceRate__c) / 100), 0);
			// 合計金額(税込)：合計金額（税抜）をベースとして、サービス料を計算した後、サービス料を含む合計金額を計算
//			obj.amoutIncTax = CommUtils.CalIncTaxPrice((obj.amoutExcTax + obj.servicePrice),obj.sobj.TaxRate__c,0) 
//                              + obj.sobj.SpecialTax__c ;
//            obj.amoutIncTax = obj.amoutIncTax + CommUtils.CalIncTaxPrice(obj.servicePrice,obj.sobj.TaxRate__c,0) + obj.sobj.SpecialTax__c ;
            // 税込合計金額再計算を行う（商品合計金額＋サービス料金（税込）+特別税）
            obj.amoutIncTax = obj.amoutIncTax + obj.servicePriceIncTax + obj.sobj.SpecialTax__c;
*/
            // 商品処理種別は前受付金の場合、合計処理対象外：
// 2013/01/15 Comment
//            if (obj.sobj.ActionType__c != CommConst.PROD_ACTION_TYPE_AR) {
				// 支払明細合計計算を行う
				oTranFooter.add(obj);
//            }
		}
		// 会計支払情報を設定をを行う
		if (!syncPriceToTtend(oTranFooter)) {
			return false;
		}
		// 会計明細から会計へ売り上げ金額を設定を行う
		syncPriceToAccount(oTranFooter, oTttendFooter);
		return true;
	}

	/**
	* 支払情報設定する前の有効性チェック
	**/
	private Boolean chkSyncPriceToTtend() {

		// 各行目に設定する前の事前クリア処理
		for (TTendItem item: oTTendSobjLst) {
			// メディア毎の消費税金額は先に全部クリアを行う
			item.sobj.Field25__c = null;
			// 預かり金額と支払金額差計算を行う
			if (item.isCanEdit) {
				// 預り金を未登録して、金券存在する場合、金券の金額を自動計算を行って、設定を行う[未登録：設定値なし　OR　設定値は０場合]
				if(CommUtils.isBlank(item.sobj.Field19__c) || CommUtils.nullToZero(item.sobj.Field19__c) == 0)
				    item.sobj.Field19__c = String.valueOf(CommUtils.nullToZero(item.sobj.Field16__c) * CommUtils.nullToZero(item.sobj.Field17__c));
				// 釣銭（差額）金額クリアする
				item.sobj.Field21__c = null;
				item.sobj.Field20__c = null;
			} else {
				// 既存情報をクリアする
				item.clear();
			}
		}
		
		/* 2013/12/02 メディア種別を重複チェックを外す
		// 支払種別は重複設定が不可チェックを追加する
		Set<String> mediaTypeSet = new Set<String>();
		// メディア種別設定、預かり金額が未設定のデータが２件以上存在すると、エラーチェックを行う
		Integer noSetupMediaCnt = 0;

		for (TTendItem item: oTTendSobjLst) {
			if (item.isCanEdit) {
				if (mediaTypeSet.contains(item.sobj.Field2__c)) {
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'メディア種別を重複指定することができません'));
					return false;
				}
				mediaTypeSet.add(item.sobj.Field2__c);
				// 預かり金額設定ないデータ存在場合
				if (!item.isPaymented) {
					noSetupMediaCnt++;
				}
			}
		} */
		/*
		if (noSetupMediaCnt > 1) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '預かり金額未設定のメディアは２種類以上するため、金額の自動設定ができなかった'));
			return false;
		}*/
		
		return true;
	}

	// 会計明細から会計支払へ設定を行う
	private Boolean syncPriceToTtend (TranFooter pTranFooter) {
		// 既に入力した金額に対して、自動設定必要かどうか、判断する
		//Decimal paymentMoney = 0;
		// 合計値格納クラスをクリアする
		oTttendFooter.clear();

		// Tメディア毎の消費税金額と設定
		// TODO: メディア毎の消費税金額とならないですけれど、会計明細の各商品ごとの消費税金額を積み上げ集計した消費税の金額と考えて頂けませんか、この金額をメディア毎消費税額項目に設定する、会計明細の商品には、たとえば、消費税５％、８％、非課税の混在となる可能性がありますので、今回のバージョンでは、たとえば、最大３つのレコードが会計支払レコードに存在すれば、このうちどれか一つのレコードのみにメディア毎消費税額が設定されていればよいということにしましょう、メディアごとに消費税を分割するのはあまり意味がないと考えております、矛盾がおきなければよいけれど、
        Boolean mediaTaxSetupOverFlg = false;

		// 事前チェック呼び出しを行う
		if (!chkSyncPriceToTtend()) {
			return false;
		}

		// 2013/05/16 金額計算ロジック再計算
		// クーポンは最優先に総金額から減算する、
		// 請求金額は＜＝０の場合、請求金額は０になる、
		// 結果は＞０の場合、割引金額を減算を行う
		// 割引金額金額引いて、請求金額は＜０，エラー表示、
		// 結果は >= 0の場合、続いて処理を行う、
		// 顧客さんから支払い金額は順番で　
		// 前受金減算を行う、その後、入力順で金額計算を行う
		// 2013/10/29 支払方法は一つ方法のみの場合、該当金額は自動クリアする
		// 2014/07/17 クポン機能対応
		Integer payTypes = 0;
		for (TTendItem item: oTTendSobjLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
				payTypes++;
			}
		}
		
		// 入力した各メディア種別の預かり金額情報を統計を行う
		// 注意：該当処理は単純のメディア種別の預かり金額統計を行う
		// 支払情報は１行のみの場合、金額は自動クリア、設定を行う
		TTendFooter ttendSummry = new TTendFooter();
		for (TTendItem item: oTTendSobjLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
				if (payTypes < 2) {
					// クーポン利用の返金 && 支払Mediaはクーポンの場合、クリアを行わない
					if (!(oAcountSobj.CouponReturnFlg__c && item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11)) 
					item.sobj.Field19__c = null;
				}
				// 既存の見積もり明細金額はクリア
                ttendSummry.add(item);
			}
		}
						
		// 総金額から割引金額の減算を行う
		Decimal remaindPayMoney = pTranFooter.amoutPriceIncTax - ttendSummry.amoutDiscountPrice;
		if (remaindPayMoney < 0) {
			//全額値引き以上の値引き金額が入力不可
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_006_0315));
			return false;
		} else {
			// 割引の支払金額は同額金額に設定する
			setSamePaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_12}, oTTendSobjLst);
			// 請求金額は０円の場合
			if (remaindPayMoney == 0) {
				// クーポンを設定する場合、利用できないチェックを行う
				if (ttendSummry.amoutCouponPrice != 0) {
					//全額値引き場合、クーポンを利用できません
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_006_0316));
					return false;
				} else {
	            	// 割引以外の支払種別は全部自動クリアする
					clearPaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_12}, oTTendSobjLst);
				}
			} 
			// 残り請求金額は存在する場合
			else {
				// 割引金額からまだ支払金額が存在する場合
				// クーポン値から減算を行う
				Decimal orgRemaindPayMoney = remaindPayMoney;
				remaindPayMoney = remaindPayMoney - ttendSummry.amoutCouponPrice;
				// クーポンは最優先に総金額から減算する、
				if (remaindPayMoney <= 0) {
					// クーポン >= 請求総金額の場合
					for (TTendItem item: oTTendSobjLst) {
						// メディア種別選択する場合:<-該当行目
						if (item.isCanEdit) {
							// クーポンの場合、
							if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11) {
								// 該当クーポンの設定値は設定する
                				//item.sobj.Field20__c = item.sobj.Field19__c;
                				Decimal payedCopon = CommUtils.nullToZero(item.sobj.Field19__c);
                				// 全額支払い場合【支払べき金額は該当行に預かり金額により、大きくの場合、預かり金額は全部支払金額として、設定する】
                				if (orgRemaindPayMoney >= payedCopon) {
                					item.sobj.Field20__c = item.sobj.Field19__c;				// 支払金額
                					item.sobj.Field21__c = null;								// 釣銭（差額）金額
                				} 
                				// 預かり金額は残り支払金額により、大きくの場合、クポン返金フラグにより、お釣り金額設定を行う
                				else {
									if (oAcountSobj.CouponReturnFlg__c) {
	                					// 金券単価と金券枚数が設定されている場合、該当金額を使う
	                					//item.sobj.Field19__c = String.valueOf(orgTmpMoney);
	                					// 上記の金額を設定されてない　AND　預かり金額設定されている場合、該当金額はそのまま預かり金額に設定する
	                					item.sobj.Field20__c = String.valueOf(orgRemaindPayMoney < 0 ? 0 : orgRemaindPayMoney);	// 支払金額
		                				// 釣銭（差額）金額 = 預かり　金額 - 支払　金額
		                				item.sobj.Field21__c = String.valueOf(CommUtils.nullToZero(item.sobj.Field19__c) - CommUtils.nullToZero(item.sobj.Field20__c));
	                				} else {
	                					item.sobj.Field20__c = String.valueOf(orgRemaindPayMoney < 0 ? 0 : orgRemaindPayMoney);	// 支払金額
	                					item.sobj.Field21__c = null;								// 釣銭（差額）金額
	                				}
                				}
                				orgRemaindPayMoney = orgRemaindPayMoney - payedCopon;
                				/*
                				// クーポン利用の返金が必要の場合
                				if (oAcountSobj.CouponReturnFlg__c) {
                					// 金券単価と金券枚数が設定されている場合、該当金額を使う
                					//item.sobj.Field19__c = String.valueOf(orgTmpMoney);
                					// 上記の金額を設定されてない　AND　預かり金額設定されている場合、該当金額はそのまま預かり金額に設定する
                					item.sobj.Field20__c = String.valueOf(orgRemaindPayMoney);	// 支払金額
	                				// 釣銭（差額）金額 = 預かり　金額 - 支払　金額
	                				item.sobj.Field21__c = String.valueOf(CommUtils.nullToZero(item.sobj.Field19__c) - CommUtils.nullToZero(item.sobj.Field20__c));
                				} else {
                					item.sobj.Field20__c = String.valueOf(orgRemaindPayMoney);	// 支払金額
                					item.sobj.Field21__c = null;								// 釣銭（差額）金額
                				}*/
							}
						}	
					}
					// 割引とクーポン以外の支払いは全部自動クリアする
					clearPaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_11,CommConst.MEDIA_TYPE_CD_12}, oTTendSobjLst);
				} else {
					// クポンの支払金額は同額金額に設定する
					setSamePaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_11}, oTTendSobjLst);
					
					// 支払金額は残っている場合、予約金で優先計算を行う
					// その後、普通の支払手段で計算を行う
					orgRemaindPayMoney = remaindPayMoney;
					// 予約金存在する場合,予約金減算を行う
					remaindPayMoney = remaindPayMoney - ttendSummry.amoutSubscriptionPrice;
					// 残り金額なし場合、お釣り金額設定、以外の項目は
					if (remaindPayMoney <= 0) {
						for (TTendItem item: oTTendSobjLst) {
							// メディア種別選択する場合:<-該当行目
							if (item.isCanEdit) {
								// 予約金の場合、
								if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_21) {
									// 該当クーポンの設定値は設定する
	                				item.sobj.Field20__c = String.valueOf(orgRemaindPayMoney);
	                				item.sobj.Field21__c = String.valueOf(CommUtils.nullToZero(item.sobj.Field19__c) - CommUtils.nullToZero(item.sobj.Field20__c));
								}
							}	
						}
						// 割引とクーポン以外の支払いは全部自動クリアする
						clearPaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_11,CommConst.MEDIA_TYPE_CD_12,CommConst.MEDIA_TYPE_CD_21}, oTTendSobjLst);
						
					} else {
						// 予約金全額設定を行う
						setSamePaymentInfo(new Set<String>{CommConst.MEDIA_TYPE_CD_21}, oTTendSobjLst);
						// 前受金の金額から減算を行う[2013/06/03仕様により、前受金は参照のみ、実際の金額入力は必ず（会計支払）で再入力が必要です]
						//remaindPayMoney = remaindPayMoney - pTranFooter.amoutAdvancesReceived;
						
						// 予約金以外の金額自動設定を行う
						// 釣銭（差額）金額[remaindPayMoney]
						Decimal calMoney = 0;
						Boolean changeSetupOverFlg = false;
						
						for (TTendItem item: oTTendSobjLst) {
							
							// 割引、クーポン、予約金場合、処理SKIP
							if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11 ||
								item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_12 ||
								item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_21 ) continue;
									
							// 支払いデータ入力あり場合
							if (item.isPaymented) {
									
								// 該当行目に既に支払金額
								Decimal rowPayment = CommUtils.nullToZero(item.sobj.Field19__c);
								//					 CommUtils.nullToZero(item.sobj.Field15__c);
								// 顧客から実際支払金額を計算を行う
								//calMoney += rowPayment;
								
								// 釣銭（差額）金額設置えを行う
								if (rowPayment == remaindPayMoney && !changeSetupOverFlg) {
			                        // 支払い金額設定を行う
			                        item.sobj.Field20__c = String.valueOf(rowPayment);
			                        // 釣銭（差額）金額
			                        item.sobj.Field21__c = null;
			                        // 支払残り金額
			                        remaindPayMoney = 0;
			                        // 釣銭（差額）金額一回だけ設定する
			                        changeSetupOverFlg = true;
								} else if (rowPayment > remaindPayMoney && !changeSetupOverFlg) {
			                        // 支払い金額設定を行う
			                        item.sobj.Field20__c = String.valueOf(remaindPayMoney);
									//if(!changeSetupOverFlg) {
									// 釣銭（差額）金額
									item.sobj.Field21__c = String.valueOf(rowPayment - remaindPayMoney);
									// 支払残り金額
									remaindPayMoney = 0;
									// 釣銭（差額）金額一回だけ設定する
									changeSetupOverFlg = true;
									//}
								} else if (changeSetupOverFlg){
					                // 既存情報をクリアする
					                item.clear();
								} else {
			                        // 支払い金額設定を行う
			                        item.sobj.Field20__c = String.valueOf(rowPayment);
			                        item.sobj.Field21__c = null;
			                        // 支払残り金額
			                        remaindPayMoney = remaindPayMoney - CommUtils.nullToZero(item.sobj.Field20__c);
								}
							}
						}
						
						//  未支払金額が存在、あづかり金額は未入力の支払方法存在場合、該当金額は該当支払方法に自動設定を行う
						if (remaindPayMoney > 0) {
							for (TTendItem item: oTTendSobjLst) {
								/*
								// 割引、クーポン、予約金場合、処理SKIP
								if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11 ||
									item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_12 ||
									item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_21 ) continue;
								*/		
								// 支払いデータ入力あり場合
								if (item.isAutoSetupPayment) {
									// 預かり　金額
									item.sobj.Field19__c = String.valueOf(remaindPayMoney);
									// 支払い金額
									item.sobj.Field20__c = String.valueOf(remaindPayMoney);
									// お釣り金額なし
									item.sobj.Field21__c = null;
									
									remaindPayMoney = 0; 
									
									break;
									
								}
							}
						} // End If (remaindPayMoney > 0) 
					}
				}
			}
		}
	
		// クーポン利用の返金=TRUE && 支払Mediaは一つ && メディア種別　はクーポンの場合、クーポン金額に残り金額に加算する
		if (remaindPayMoney > 0 && payTypes < 2 && oAcountSobj.CouponReturnFlg__c) {
			for (TTendItem item: oTTendSobjLst) {
				// メディア種別選択する場合:<-該当行目
				if (item.isCanEdit) {
					// クーポンの場合、
					if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11) {
							// 預かり　金額
							item.sobj.Field19__c = String.valueOf(CommUtils.nullToZero(item.sobj.Field19__c) + remaindPayMoney);
							// 支払い金額
							item.sobj.Field20__c = item.sobj.Field19__c;
							// お釣り金額なし
							item.sobj.Field21__c = null;
							// 残り金額はクリアする
							remaindPayMoney = 0;
					}
				}
			}
		}
		//if (remaindPayMoney != 0) {
		if (remaindPayMoney > 0) {
			//未支払い金額が存在してため、会計支払のメディア種別など設定を再確認お願いします
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_006_0317));
			return false;
		}
	
		for (TTendItem item: oTTendSobjLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
                oTttendFooter.add(item);
			}
		}
//System.debug('pTranFooter:::' + pTranFooter);		
//System.debug('oTttendFooter:::' + oTttendFooter);	
		// 2013/05/10 不具合対応：会計新規登録して、支払金額入力なし、会計確認ボタンクリックするして、「会計確認」ボタンクリックして、会計登録すると、消費税計算を行わなかった
		// 消費税の計算箇所を移動して、上記支払計算金額は全部自動計算終わる後、消費税計算を行う
		// 消費税計算を行う
		// Summary Tax 
		Decimal locAmoutIncTaxprice = pTranFooter.amoutPriceIncTaxByTax
                  	- CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice);
        // 支払総金額 － 割引金額
        Decimal locAmoutSalesPrice =  oTttendFooter.amoutSalesPrice 
        			- CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice);
		//Decimal taxRate = CommUtils.getTaxRate(Date.today());
		Decimal taxRate = CommUtils.nullToZero(oAcountSobj.TaxRate__c);
		// 2014/07/02 USD機能対応
		Integer pointLen = CommUtils.getPointLen();
		//Decimal taxSum = locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), 0) : 0;
		Decimal taxSum = locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0;
		Decimal remainTax = taxSum;
		Integer maxIndex = 0;
		Decimal maxMoney = 0;
		for (TTendItem item: oTTendSobjLst) {
		/*	if (!mediaTaxSetupOverFlg && item.isPaymented) {
				
				item.sobj.Field25__c = String.valueOf(pTranFooter.amoutPriceIncTax 
					- pTranFooter.amoutPriceExcTax
					- pTranFooter.amoutServicePrice
					- pTranFooter.amoutSpecialTax
					);
				if (pTranFooter.amoutPriceIncTaxByTax > 0 ) {
					Decimal locAmoutIncTaxprice = pTranFooter.amoutPriceIncTaxByTax
                               - CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice);
					Decimal taxRate = CommUtils.getTaxRate(Date.today());
					item.sobj.Field25__c = String.valueOf(locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), 0) : 0);
				} else {
					item.sobj.Field25__c = '0';
				}
			    mediaTaxSetupOverFlg = true;
			    break;
			}*/
			if(item.isPaymented){
				
				//System.debug('remaindPayMoney:::' + remaindPayMoney);
				//System.debug('item.sobj.Field2__c:::' + item.sobj.Field2__c);
				
				if(item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_12){
					item.sobj.Field25__c = '0';
					continue;
				}
				
				// メデイア種別毎に、消費税金額計算を行う
				// 支払金額/総金額 * 消費税総金額　（小数切り捨て）
				Decimal paymentMoney = CommUtils.nullToZero(item.sobj.Field20__c);
				// 2014/07/02 USD機能対応
				//Decimal amoutTax = locAmoutSalesPrice > 0 ? CommUtils.RoundProcess((paymentMoney /locAmoutSalesPrice)*taxSum,0,RoundingMode.FLOOR) : 0;
				Decimal amoutTax = locAmoutSalesPrice > 0 ? CommUtils.RoundProcess((paymentMoney /locAmoutSalesPrice)*taxSum,pointLen,RoundingMode.FLOOR) : 0;
/*
System.debug('paymentMoney:'+paymentMoney);
System.debug('locAmoutSalesPrice:'+locAmoutSalesPrice);
SYstem.debug('taxSum:::' + taxSum);
System.debug((paymentMoney /locAmoutSalesPrice)*taxSum);
System.debug('amoutTax::'+amoutTax);
*/
				if (paymentMoney > maxMoney) {
					maxIndex = item.index;
					maxMoney = paymentMoney;
				}
				remainTax = remainTax - amoutTax;
				// 消費税金額設定を行う
				item.sobj.Field25__c =  String.valueOf( amoutTax);
			}
		}
//SYstem.debug('remainTax:::' + remainTax);
		if (remainTax != 0) {
			oTTendSobjLst[maxIndex].sobj.Field25__c = String.valueOf(CommUtils.nullToZero(oTTendSobjLst[maxIndex].sobj.Field25__c) + remainTax);
		}
		
		// 予約金設定金額は前受金に加算を行う
		//ttendSummry.amoutSumscriptionSummary = pTranFooter.amoutAdvancesReceived + ttendSummry.amoutSubscriptionPrice;
		//pTranFooter.amoutAdvancesReceived += ttendSummry.amoutSubscriptionPrice;
        return true;
	}
	/**
	* paymentCdSet:クリア対象外
	* tTendLst:会計支払
	**/
	private void clearPaymentInfo(Set<String> paymentCdSet, List<TTendItem> tTendLst) {
		for (TTendItem item: tTendLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
				// media種別は含めないと、支払金額：０になる、預かり金額＝釣銭（差額）金額同じ金額を設定する
                if (!paymentCdSet.contains(item.sobj.Field2__c)) {
                	item.sobj.Field20__c = null;
                	item.sobj.Field21__c = item.sobj.Field19__c;
                }
			}
		}
	}
	/**
	* 支払金額は預かり金額の同一金額を設定を行う
	**/
	private void setSamePaymentInfo (Set<String> paymentCdSet, List<TTendItem> tTendLst) {
		for (TTendItem item: tTendLst) {
			// メディア種別選択する場合:<-該当行目
			if (item.isCanEdit) {
				// media種別は含めないと、支払金額：０になる、預かり金額＝釣銭（差額）金額同じ金額を設定する
                if (paymentCdSet.contains(item.sobj.Field2__c)) {
                	item.sobj.Field20__c = item.sobj.Field19__c;
                	item.sobj.Field21__c = null;
                }
			}
		}
	}
	// 会計明細から会計へ売り上げ金額を設定を行う
	private void syncPriceToAccount (TranFooter pTranFooter, TTendFooter pTttendFooter) {
		// 売上計4（税込）金額:Field116__c  ->値引き存在と関係なし、実際の商品の売上を合計で設定する
		oAcountSobj.Field116__c = String.valueOf(pTranFooter.amoutPriceIncTax);
		// 売上計3（税抜）金額:Field114__c
//		oAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceExcTax + pTranFooter.amoutServicePrice);
//		oAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceExcTax);
        // サービス料金(税込)
        oAcountSobj.SumSrvPriceIncTax__c = pTranFooter.amoutServicePriceIncTax;
		// サービス料金(税抜)
		oAcountSobj.SumSrvPriceExcTax__c = pTranFooter.amoutServicePrice;
		// 宿泊税
		oAcountSobj.AmoutSpecialPrice__c = pTranFooter.amoutSpecialTax;
		// 割引金額（税込）
		oAcountSobj.Discount__c = pTttendFooter.amoutDiscountPrice;
		
		// 消費税計算、会計の消費税項目に設定を行う
        if ( pTranFooter.amoutPriceIncTaxByTax > 0 ) {
        	// 割引金額から減らいて、残りの合計金額は消費税を計算を行う
			Decimal locAmoutIncTaxprice = pTranFooter.amoutPriceIncTaxByTax
	                   					- CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice);
	        // 計算用消費税率取得：会計日の消費税率を取得する
			//Decimal taxRate = CommUtils.getTaxRate(Date.today());
			Decimal taxRate = CommUtils.nullToZero(oAcountSobj.TaxRate__c);
            // 消費税計算を行う
            Integer pointLen = CommUtils.getPointLen();
            oAcountSobj.sumTax__c = (locAmoutIncTaxprice > 0 ? CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
        } else {
            oAcountSobj.sumTax__c = 0;
        }

        // 売上計3（税抜）金額:Field114__c
        oAcountSobj.Field114__c = String.valueOf(pTranFooter.amoutPriceIncTax - oAcountSobj.sumTax__c);
	}

	/**
	* 最新会計支払情報を取得する
	* salesId: 売上ID
	* billId: 会計ID
	**/
	private Boolean refreshTTendInfo(Id salesId, Id billId) {
		
//		oTTendSobjLst = new List<TTend__c>();
        oTTendSobjLst = new List<TTendItem>();
        oTttendFooter = new TTendFooter();

		// 入力欄初期化する
		if (salesId != null && billId != null) {
			String queryStr = TTendSel + ' Where RelAccount__c = :salesId';
			if (!CommUtils.isBlank(billId)) queryStr+= ' And Field1__c = :billId Order By Name';
			for (TTend__c sobj: DataBase.query(queryStr)) {
				TTendItem newItem = new TTendItem(sobj, oTTendSobjLst.size());
				oTTendSobjLst.add(newItem);	
				// 合計情報を設定を行う
				oTttendFooter.add(newItem);
			}
		}
		
		if (oTTendSobjLst.size() < TTEND_INPUT_MAX_ROWS) {
			Integer appendRsSize = TTEND_INPUT_MAX_ROWS - oTTendSobjLst.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				TTendItem newItem = new TTendItem(new TTend__c(RelAccount__c = salesId), oTTendSobjLst.size());
				// 支払データが未登録場合、第一行目の支払方法は自動設定を行う[現金]
				if (i == 0 && appendRsSize == TTEND_INPUT_MAX_ROWS) newItem.sobj.Field2__c = CommConst.MEDIA_TYPE_CD_01; //'01';
				oTTendSobjLst.add(newItem);
			}
		}
		return true;
	}

	/**
	* 会計明細：並び替え機能対応
	* 2013/07/16 ADD
	**/
	public void sortTranRsList () {
		// 並び替え更新を行う
		refreshTran1Info(oAcountSobj.frs__c, oAcountSobj.Id);
	}
	/**
	* 最新会計明細情報を取得する
	* salesId: 売上ID
	* billId: 会計ID
	**/
	private Boolean refreshTran1Info(Id salesId, Id billId) {
		
//		oTranSobjLst = new List<Tran1__c>();
        oTranSobjLst = new List<TranItem>();
		oTranFooter = new TranFooter();
		
		if (salesId != null && billId != null) {
			String queryStr = TranSel + ' Where RelAccount__c = :salesId';
//			if (!CommUtils.isBlank(billId)) queryStr+= ' And Field1__c = :billId ';
			queryStr+= ' And Field1__c = :billId ';
// 20121002 ADD
queryStr += ' And ParentTran1Ref__c = null ' ;
// 2013/07/16 ADD
			// 並び替え条件を設定場合
			List<Tran1__c> planTranList = null;
			if (!CommUtils.isBlank(sortField)) {
				// プランは個別表示制御の場合[常に明細の上に表示]
				if (DetailSortDiv == DETAIL_SORT_DIV_PLANTOP) {
				// プラン個別抽出を行う
				String queryStr2 = queryStr;
				queryStr2 += ' And ActionType__c = \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
				queryStr2 += ' Order By Field7__r.Field3__c ';	 
				for (Tran1__c sobj: DataBase.query(queryStr2)) {
					sobj.PlanDetailSyncInfo__c = null;
					TranItem item = new TranItem(sobj, oTranSobjLst.size());
				    oTranSobjLst.add(item);
					//oTranSobjLst.add(sobj);
					// 合計情報を設定する
					oTranFooter.add(item);
				}
			// プラン以外の明細
queryStr += ' And ActionType__c != \'' + String.escapeSingleQuotes(CommConst.PROD_ACTION_TYPE_PL) + '\'';
				}
queryStr += ' Order By ' + String.escapeSingleQuotes(sortField) + ' ' +  String.escapeSingleQuotes(sortOrder);	   
			} else {
queryStr += ' Order By RowNo__c,name ';
			}
			for (Tran1__c sobj: DataBase.query(queryStr)) {
				// 2013/01/28 ADD *重要* [既存のプラン明細連携情報は再表示する場合、必ずクリアする]
				sobj.PlanDetailSyncInfo__c = null;
				TranItem item = new TranItem(sobj, oTranSobjLst.size());
			    oTranSobjLst.add(item);
				//oTranSobjLst.add(sobj);
				// 合計情報を設定する
				oTranFooter.add(item);
			}
		}
		if (oTranSobjLst.size() < TRAN1_INPUT_DEF_ROWS) {
			Integer appendRsSize = TRAN1_INPUT_DEF_ROWS - oTranSobjLst.size();
			// 2行目まで設定を行う
			for (Integer i = 0; i < appendRsSize; i++) {
				oTranSobjLst.add(new TranItem(new Tran1__c(RelAccount__c = salesId),oTranSobjLst.size()));
			}
		}
		
		// 会計情報を連携を行う
		//syncPriceToTtend(oTranFooter);
		//syncPriceToAccount(oTranFooter);
		return true;
	}
	
	public void initAction() {
		// 初期表示用データを設定する
		this.initInfo((AccountAcount__c)ctrl.getRecord());
	}
    /**
    * キャセンル画面に遷移する
    **/ 
    public Pagereference gotoCancel() {
        String retUrl = paramMap.get('retURL');
        if (!CommUtils.isBlank(retUrl)) {
            PageReference pageRef = new PageReference(retUrl);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
	/*
	public Boolean isShowAddItemBtnFlg{get{
		if (oTranSobjLst.size() > TRAN1_INPUT_MAX_ROWS) return false;
		return true;
	}}*/
	public Pagereference addTran1Item() {
		TranItem newItem = new TranItem(new Tran1__c(RelAccount__c = oAcountSobj.frs__c), oTranSobjLst.size());
		// 無効なデータの消費税とサービス料０からNULLに設定する
		for (TranItem item : oTranSobjLst) {
			if (CommUtils.isBlank(item.productNm)) {
				if (item.sobj.TaxRate__c == 0) item.sobj.TaxRate__c = null;
				if (item.sobj.ServiceRate__c == 0) item.sobj.ServiceRate__c = null;
			}
		}
		oTranSobjLst.add(newItem);
		return null;
	}
	// 支払い方法は一行目を追加する
	public Pagereference addTtendItem() {
		//oTTendSobjLst.add()
		TTendItem newItem = new TTendItem(new TTend__c(RelAccount__c = oAcountSobj.frs__c), oTTendSobjLst.size());
		oTTendSobjLst.add(newItem);
		return null;
	}
	// 会計情報新規作成
	public Pagereference insertData() {
// 2017/07/10 ログ出力機能を追加する BEGIN
serverlog.clear();
serverlog.write_method_start('新規');
// 2017/07/10 ログ出力機能を追加する END
		try {
			// Field Security Check
			List<String> chkFields = new List<String>{'PaymentFlg__c','SalesDate__c'
														,'AccountLanguage__c','Relreserve__c','relaccount__c','Field150__c'
														,'AccountName__c','AccountReceiptName__c','AccountReceiptDate__c','comment__c'
														,'AccountProviso__c','Field57__c','Field66__c','Field67__c','Field68__c'
														,'CouponReturnFlg__c'};
			Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountAcount__c.fields.getMap();
			if (!CommSecurityUtils.isCanCreateable(chkFields, m)) {
				return null;
			}

			insert preUpdateAccountInf(oAcountSobj);
			// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
			if(isAccountSyncCommentFlg) upOneRoomAcc(oAcountSobj);
			// 2018/03/12 連泊コメント同期機能対応 WGCH END
	    	// 画面編集フラグを設定する
	   		oPage.dataStatus = PAGE_STATUS.UPD;
	    	// 最新インサート情報を取得する
	    	refreshAccoutAcountInfo(oAcountSobj.id);
		} catch (Exception e) {
			String msg = e.getMessage();
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
			if (!msg.contains(Label.MSG_006_0459)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
		}
// 2017/07/10 ログ出力機能を追加する BEGIN
serverlog.write_method_end();
writeLogToDb(serverlog.getAllLog(), oAcountSobj.Id);
// 2017/07/10 ログ出力機能を追加する END
	    return null;
	}
	// プラン関連の商品明細を取得する
	// accId:会計ID/会計商品（プラン）ID
	@RemoteAction
	public static List<PlanDetail> getAccountMstLstByPlan(String tranId, String accId, String planId) {
		// 会計IDが存在する場合、既に登録された登録情報から情報を展開する
		// 会計IDが非存在場合、
		List<PlanDetail> rsLst = new List<PlanDetail>();
		if (CommUtils.isBlank(accId)) {
	        for (PlanDetail__c pd : [select AccountMasterRef__r.name, Price__c from PlanDetail__c where PlanProdcut__c = :planId]) {
                PlanDetail item = new PlanDetail();
                item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
                item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
                item.sobjId = pd.Id;
                rsLst.add(item);
	        }
		} else {
            for (Tran1__c tr : [select Field5__c, Field20__c from Tran1__c where ParentTran1Ref__c = :tranId And Field1__c = :accId ]) {
                PlanDetail item = new PlanDetail();
                item.prodName = CommUtils.nullToBlank(tr.Field5__c);
                item.prodPrice = CommUtils.nullToZero(tr.Field20__c).format();
                item.sobjId = tr.Id;
                rsLst.add(item);
            }
		}
		return rsLst;
	}
	// プラン明細情報を維持する
	public class PlanDetail {
		public String prodName{get; set;}
		public String prodPrice{get; set;}
		public String sobjId{get;set;}
	}
	
	/**
	* 会計商品情報を取得
	**/
	@remoteAction
	public static ProductItemUtils.ProductItem getProductItemInfo(String prodCode) {
		return ProductItemUtils.getSingProdcutItemByCode(prodCode);
	}
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode);
	}
	/**
	* お客様情報を自動設定を行う
	**/
	private void autoSetupAccField(AccountAcount__c pAcountSobj) {
		// 2015/07/16 お客様情報の自動設定機能 BEGIN
		// 予約あり、お客様項目を設定されないの場合、自動的にお客様項目に設定を行う
		if (pAcountSobj.relaccount__c == null || pAcountSobj.Relreserve__c != null) {
			// 予約情報が存在、お客様名を未設定の場合、自動設定を行う
			List<Lead__c> leads = [select Id, Name, Relcontact__c from Lead__c where id = :pAcountSobj.Relreserve__c];
			if (!leads.isEmpty()) {
				pAcountSobj.relaccount__c = leads[0].Relcontact__c;
			}
		}
	}
	/**
	* 集計対象になるため、デフォルト設定設定を行う
	**/
	private AccountAcount__c preUpdateAccountInf(AccountAcount__c pAcountSobj) {
// 2017/07/10 ログ出力機能を追加する BEGIN
serverlog.write_log('*****サーバー側の処理履歴*****');
serverlog.write_log('設備IP:::::' + localIp);
serverlog.write_log('利用日モード：'+ CommDefine__c.getOrgDefaults().AccountUseDateMode__c);
// 2017/07/10 ログ出力機能を追加する END
		// 2015/07/16 お客様情報の自動設定機能 BEGIN
		autoSetupAccField(pAcountSobj);
		// 2015/07/16 お客様情報の自動設定機能 END
		// 売上計上日設定存在チェックを行う
		if (pAcountSobj.frs__c == null || pAcountSobj.frs__r.Salesday__c != pAcountSobj.SalesDate__c) {
			// 売上の情報を再設定を行う
			String salesName = (DateTime.newInstance(pAcountSobj.SalesDate__c.year(),pAcountSobj.SalesDate__c.month(),pAcountSobj.SalesDate__c.day())).format('yyyyMMdd');
			List<RsvAccount__c> rsvLst = [select id from RsvAccount__c where name = :salesName limit 1];
			RsvAccount__c salesSobj = null;
			if (rsvLst.isEmpty()) {
				salesSobj = new RsvAccount__c(Name = salesName);
				upsert salesSobj Name;
serverlog.write_log('関連売上：' + salesSobj);
			} else  {
				salesSobj = rsvLst[0];
			}
			pAcountSobj.frs__c = salesSobj.Id;
		}
		// 取引種別:00 売上(通常)
		pAcountSobj.Field39__c = CommConst.ACC_TRADE_NORMAL;
		// ＶＯＩＤレシートＮｏ．
		pAcountSobj.Field40__c = '';
		// 売上計3（内税抜き）金額
		//pAcountSobj.Field114__c ->会計明細から自動設定を行う
		// POSNo.
		pAcountSobj.POSNo__c = CommUtils.getPosNoByComdefine();
		// TODO：営業日付 ←　チェックイン日付で設定を行う　
		pAcountSobj.Field141__c = CommUtils.getBusinessDay();
		// 会計日時: TODO->原システム確認要
		pAcountSobj.Field53__c = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
		// 会計人数
		pAcountSobj.Field57__c = String.valueOf(
									CommUtils.nullToZero(pAcountSobj.Field66__c) +
									CommUtils.nullToZero(pAcountSobj.Field67__c) +
									CommUtils.nullToZero(pAcountSobj.Field68__c));
		//pAcountSobj.Field57__c = String.valueOf(CommUtils.)
		// 請求額 = 売上計4（内税込み）金額　ー　割引額　ー　予約金 - クーポン
		pAcountSobj.Field126__c = String.valueOf(
									CommUtils.nullToZero(oTttendFooter.amoutSalesPrice)
									- CommUtils.nullToZero(oTttendFooter.amoutDiscountPrice)
									- CommUtils.nullToZero(oTttendFooter.amoutSubscriptionPrice) 
									- CommUtils.nullToZero(oTttendFooter.amoutCouponPayPrice) 
									-
									CommUtils.nullToZero(oTranFooter.amoutAdvancesReceived)
									);
		// 2014/02/25 並べ替え項目設定情報は非保存に変更する BEGIN
		/*
		// 2013/10/14 並べ順設定情報は会計にコピーする
		if (CommUtils.isBlank(sortField)) pAcountSobj.DetailSortBy__c = null;
		else pAcountSobj.DetailSortBy__c = sortField + ' ' +  sortOrder;
		*/
		pAcountSobj.DetailSortBy__c = null;
		// END
		// 2015/02_24 新会計フラグはFALSEに設定する（旧会計メニューから情報を変更されると、再OPENすると、旧会計レイアウトで処理する
		// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する BEGIN
		//pAcountSobj.IsNewLayout__c = false;
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
		/*
		if (isFromOrderFlg != true) pAcountSobj.IsNewLayout__c = false;
		*/
		if (isFromOrderFlg != true && isCustomMediaTypeFlg != true) pAcountSobj.IsNewLayout__c = false;
		else if(isCustomMediaTypeFlg) pAcountSobj.IsNewLayout__c = true;
		// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH END
		else {
		    pAcountSobj.IsNewLayout__c = true;
		    // 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う BEGIN
		    String defShopCd = UserUtil.CurrentUser.ShopCode__c;
		    if (defShopCd != orderShopCd) {
		        List<String> shopCodes = new List<String>{orderShopCd};
		        Map<String,ShopInformation__c> shops = ShopInfoUtil.getShopInfoMap(shopCodes);
		        if (shops.containsKey(orderShopCd)) {
		            ShopInformation__c shop = shops.get(orderShopCd);
		            pAcountSobj.ShopSeq__c = shop.Seq__c; 
		            pAcountSobj.ShopCode__c = CommUtils.nullToBlank(shop.ShopCode__c); 
		            pAcountSobj.ShopName__c = CommUtils.nullToBlank(shop.Name); 
		        }
		    }
		    // 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う END
		}
		// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する END
		return pAcountSobj;
	}
	// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH BEGIN
	private boolean isCustomMediaTypeFlg=false;
	public void setCustomMediaTypeFlg() {
		isCustomMediaTypeFlg = true;
	}
	// 2017/11/27 簡易会計の支払メディアをカスタマイズできるように改善 WGCH END
	// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する BEGIN
	private boolean isFromOrderFlg=false;
	// 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う BEGIN
	private String orderShopCd = '';
	// 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う END
	public void setOrderFlg(String shopCode) {
		isFromOrderFlg = true;
		// 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う BEGIN
		orderShopCd = shopCode;
		// 2017/07/05 現在ログインユーザの店舗は引き渡す店舗コードが一致しない場合、個別設定処理を行う END
	}
	// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する END
	private List<TTend__c> preUpdateTtendInfo (List<TTend__c> pTtendList) {
		// 集計対象条件
		// Field35__c = "00" && Field4__c = "1" && Field5__c ="1" && Field1__r.Field40__c ="" && Field29__c <> 0
		// 処理　種別１:Field4__c ->1
		// 処理　種別２:Field5__c ->1
		// 営業日付
		String strBusinessDay = CommUtils.getBusinessDay();
		for (TTend__c sobj: pTtendList) {
			sobj.Field4__c = '1';
			sobj.Field5__c = '1';
			//2017/07/03 簡易会計posNo追加　by zy BEGIN
			if (CommUtils.isBlank(sobj.POSNo__c))
			sobj.POSNo__c = CommUtils.getPosNoByComdefine();
			//2017/07/03 簡易会計posNo追加　by zy END
//			sobj.Field34__c = strBusinessDay;
			// メディア名称設定を行う
			//if (!CommUtils.isBlank(sobj.Field2__c)) sobj.Field3__c = MediaCdName.get(sobj.Field2__c);
			if (!CommUtils.isBlank(sobj.Field2__c)) sobj.Field3__c = CommConst.getPaymentTypeLabelByKey(sobj.Field2__c);
			/*
			// メディア毎消費税額(支払金額（税金含め）から消費税を計算を行う)
			if (!CommUtils.isBlank(sobj.Field20__c)) sobj.Field25__c = String.valueOf(
			 CommUtils.CalTaxByPriceIncTax(Decimal.valueOf(sobj.Field20__c), obj.sobj.TaxRate__c, 0
			 );*/
		}
		return pTtendList;
	}
	private List<Tran1__c> preUpdateTran1Info (List<Tran1__c> pTranList) {
		// if ( Field44__c = "00" && (Field39__c <> 0 || CONTAINS( Field5__c , "●") ) && ( Field2__c ="M" || Field2__c ="P" || Field2__c ="R") && Field3__c = "1" && Field4__c ="1" && Field22__c <> "+000" && VoidReceiptNo__c ="0" && noneaccount__c = false , 1, 0)
		// 商品種別:Field2__c
		// 処理種別１:Field3__c
		// 処理種別２:Field4__c
		// 残数量:Field22__c
		// TODO: 営業日付
		// 会計商品から商品種別を取得を行う
		Set<Id> prodcutIdSet = new Set<Id>();
		for (Tran1__c sobj: pTranList) {
			prodcutIdSet.add(sobj.Field7__c);
		}
		Map<Id, AccountMaster__c> productMap = new Map<Id, AccountMaster__c>([select SCP_5__c from AccountMaster__c where id in :prodcutIdSet]);

//		String strBusinessDay = CommUtils.getBusinessDay();
		for (Tran1__c sobj: pTranList) {
			// 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
			if (productMap.containsKey(sobj.Field7__c)) {
				// TODO 現状のシステムを一回確認必要
				String scpCode = productMap.get(sobj.Field7__c).SCP_5__c;
                sobj.Field2__c = (scpCode == '0') ? 'M' : 'P';
			}
			// 処理種別１
			sobj.Field3__c = '1';
			// 処理種別２
			sobj.Field4__c = '1';
			// 残数量
			sobj.Field22__c = sobj.Field21__c;
			// 営業日付
//			sobj.Field45__c = strBusinessDay;
			// POSNo.
			sobj.POSNo__c = CommUtils.getPosNoByComdefine();
			// 消費税　種別(消費税＝０の場合、非課税/)
			sobj.Field27__c = (sobj.TaxRate__c == 0 ? '2' : '1');
		}
		return pTranList;
	}

	public Pagereference upsertData() {
		
		// 最新入力情報にて、最新合計情報を再計算を行う
		if (!this.amoutTran1Info()) {
            return null;
		}
// 2017/07/10 ログ出力機能を追加する BEGIN
serverlog.clear();
serverlog.write_method_start('更新');
// 2017/07/10 ログ出力機能を追加する END
		try {
//System.debug('------- oAcountSobj ----' + oAcountSobj);
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(TTend__c.getSObjectType())) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
		// 更新処理を行う
		upsert preUpdateAccountInf(oAcountSobj);
		// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
		if(isAccountSyncCommentFlg) upOneRoomAcc(oAcountSobj);
		// 2018/03/12 連泊コメント同期機能対応 WGCH END
		// 最新IDを取得する
		List<TTend__c> updTtendList = new List<TTend__c>();
		List<TTend__c> delTtendList = new List<TTend__c>();
		for (TTendItem obj: oTTendSobjLst) {
			if (CommUtils.isBlank(obj.sobj.Field2__c)) {
				if (obj.sobj.id != null) delTtendList.add(obj.sobj);
				continue;
			}
serverlog.write_log('会計支払：['+obj.index+']行目:' + obj.sobj);
			obj.sobj.Field1__c = oAcountSobj.Id;
			//if(obj.sobj.RelAccount__c == null) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			if(obj.sobj.RelAccount__c != oAcountSobj.frs__c) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			updTtendList.add(obj.sobj);
		}
		// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する BEGIN
		if(!isFromOrderFlg)
		upsert preUpdateTtendInfo(updTtendList);
serverlog.write_log('*****新規/更新会計支払い件数['+updTtendList.size()+']*****');
		// 2017/05/23 オーダーエントリから呼出、個別処理フラグ設定する END
		if (!delTtendList.isEmpty()) delete delTtendList;

		List<Tran1__c> updTranList = new List<Tran1__c>();
		List<Tran1__c> delTranList = new List<Tran1__c>();
		for (TranItem obj: oTranSobjLst) {
			//if (CommUtils.isBlank(obj.sobj.Field25__c) || CommUtils.isBlank(obj.sobj.Field26__c)) continue;
			// 商品登録と、有効なデータで登録する
			if (!obj.isValidata) {
                if (obj.sobj.Id != null) delTranList.add(obj.sobj);
                continue;
			}
			// 2013/01/23 会計明細データを更新する、元のデータを削除されていない対応
			/*
			else {
				// 新規の商品の切り替え場合
				if(CommUtils.isBlank(obj.tranId) && obj.sobj.Id != null) {
					delTranList.add(obj.sobj);
					// 新規登録のプラン情報
					obj.sobj = obj.sobj.clone(false,true);
					//obj.sobj = new TranItem(newSobj, obj.index);
				}
			}*/
			obj.sobj.Field1__c = oAcountSobj.Id;
			//if(obj.sobj.RelAccount__c == null) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			if(obj.sobj.RelAccount__c != oAcountSobj.frs__c) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			// 関連項目を自動設定をを行う
			// 商品名称（または券名称）
			//if (CommUtils.isBlank(obj.sobj.Field5__c))  obj.sobj.Field5__c = obj.productNm;
			obj.sobj.Field5__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
			// 2015/10/25 該当明細の商品はプラン　かつ　参照している商品は同じ　かつ　クリアされている場合、既存のプランの情報を削除する
			if (obj.isPlanProduct &&
				CommUtils.isBlank(obj.tranId) &&
				obj.sobj.Id != null) {
				// 既存のプランとプラン明細情報を削除して、新子見積もり明細を新規作成を行う
				Tran1__c planItemClone = obj.sobj.clone(false, true);
				delTranList.add(obj.sobj);
				updTranList.add(planItemClone);
				continue;
			}
serverlog.write_log('会計明細：['+obj.rowNo+']行目:' + obj.sobj);
			// 2015/10/25 END
			updTranList.add(obj.sobj);
		}
serverlog.write_log('*****新規/更新会計明細件数['+updTranList.size()+']*****');
serverlog.write_log('*****削除会計明細件数['+delTranList.size()+']*****');
		upsert preUpdateTran1Info(updTranList);
		if (!delTranList.isEmpty()) delete delTranList;
// 2017/07/10 ログ出力機能を追加する BEGIN
serverlog.write_method_end();
writeLogToDb(serverlog.getAllLog(), oAcountSobj.Id);
// 2017/07/10 ログ出力機能を追加する END
        Pagereference pg = new Pagereference('/' + oAcountSobj.id);
        pg.setRedirect(true);
		return pg;
		
		} catch (Exception e) {
			String msg = e.getMessage();
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
			if (!msg.contains(Label.MSG_006_0459)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
			// 2020/03/30 会計ロック　by　zy BEGIN
			if (isFromOrderFlg) {
				//if (msg.contains(Label.MSG_006_0459)) throw new CommException(Label.MSG_006_0459);
				throw new CommException(CommUtils.getFieldValidationMessage(msg));
			}
			// 2020/03/30 会計ロック　by　zy END
			// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
			return null;
		}
	}

	public class PageInfo {
		// 画面データステータス維持する
		public PAGE_STATUS dataStatus{get;private set;}
        public Boolean isIns{get{return dataStatus == PAGE_STATUS.INS;}}
        public Boolean isUpd{get{return dataStatus == PAGE_STATUS.UPD;}}
        public Boolean isSel{get{return dataStatus == PAGE_STATUS.SEL;}}

	}
	// 会計支払
	public class TTendItem {
		public TTendItem(TTend__c o, Integer rsIndex) {
			sobj = o;
			index = rsIndex;
		}
		public void clear() {
			// メディア種別
			sobj.Field2__c = null;
			// カード種別
			sobj.CardTypeLst__c = null;
			// 金券種別
			sobj.CouponTypeLst__c = null;
			// 金券単価
			sobj.Field16__c = null;
			// 金券枚数
			sobj.Field17__c = null;
			// 預かり　金額
			sobj.Field19__c = null;
			// 値割引対象額
			sobj.Field15__c = null;
			// 支払　金額
			sobj.Field20__c = null;
			// 釣銭（差額）金額
			sobj.Field21__c = null;
			// メディア毎消費税額
			sobj.Field25__c = null;
		}
		public Integer index{get; private set;}
		public TTend__c sobj{get;set;}
		/*
		public Boolean isValidata{get{
			return true;
		}}*/
		public Boolean isCanEdit{get{
			return (!CommUtils.isBlank(sobj.Field2__c));
		}}
		// 顧客から支払金額を入力されたの場合
		public Boolean isPaymented{get{
			return (isCanEdit && ((CommUtils.nullToZero(sobj.Field19__c) !=0) ||
								  (CommUtils.nullToZero(sobj.Field15__c) !=0)));
		}}
		// 支払　金額 自動設定必要場合
		public Boolean isAutoSetupPayment{get{
			// 預かり金額 + 値割引対象額 -> 支払　金額
			return (isCanEdit && ((CommUtils.nullToZero(sobj.Field19__c) ==0) &&
								  (CommUtils.nullToZero(sobj.Field15__c) ==0)));
		}}
		public Boolean isExist{get{return (sobj.id != null);}}
	}
	// 会計支払合計情報を格納する
	public class TTendFooter {
		public TTendFooter() {
			this.clear();
		}
		// 割引値の合計
		public Decimal amoutDiscountPrice{get; private set;}
		// クーポン金額合計
		public Decimal amoutCouponPrice{get; private set;}
		public Decimal amoutCouponPayPrice{get; private set;}
		// 予約金金額合計
		public Decimal amoutSubscriptionPrice{get; private set;}
		// 予約金 & 前受金合計値情報格納
		//public Decimal amoutSumscriptionSummary{get;set;}
		// 預かり金額の合計
		public Decimal amoutPaymentPrice{get; private set;}
		// 支払金額の合計:預かり金額の中から、会計に使用された金額を処理する。
		public Decimal amoutSalesPrice{get; private set;}
		// 釣銭（差額）金額合計
		public Decimal amoutChangePrice{get; private set;}
		
        public void add(TTendItem item) {
        	if (!item.isCanEdit) return;
        	// 割引値の合計
            if (item.sobj.Field2__c == MediaTypeDisCount) amoutDiscountPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // 予約金の合計
            else if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_21) amoutSubscriptionPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // クーポン金額合計
            else if (item.sobj.Field2__c == CommConst.MEDIA_TYPE_CD_11) {
            	amoutCouponPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            	amoutCouponPayPrice += CommUtils.nullToZero(item.sobj.Field20__c);
            }
            // 預かり金額の合計
            amoutPaymentPrice += CommUtils.nullToZero(item.sobj.Field19__c);
            // 支払金額の合計
            amoutSalesPrice += CommUtils.nullToZero(item.sobj.Field20__c);
            // 釣銭（差額）金額合計
            amoutChangePrice += CommUtils.nullToZero(item.sobj.Field21__c);
        }
        public void clear() {
            amoutDiscountPrice = 0;
            amoutPaymentPrice = 0;
            amoutSalesPrice = 0;
            amoutChangePrice = 0;
            amoutCouponPrice = 0;
            amoutCouponPayPrice = 0;
            amoutSubscriptionPrice = 0;
            //amoutSumscriptionSummary = 0;
        }
	}
	// 会計明細
	public class TranItem {
		public TranItem(Tran1__c s, Integer rsIndex) {
			sobj = s;
			index = rsIndex;
			rowNo = Integer.valueOf(s.RowNo__c) > 0 ? Integer.valueOf(s.RowNo__c) : rsIndex+1;
			// 2014/09/09 RowNoの自動再設定
			s.RowNo__c = rsIndex+1;
            amoutIncTax = CommUtils.isBlank(s.Field23__c) ? 0 : Decimal.valueOf(s.Field23__c);
            amoutExcTax = s.GoukeinoneTax__c == null ? 0 : s.GoukeinoneTax__c;
            productNm = CommUtils.isBlank(sobj.Field5__c) ? s.Field7__r.Name : sobj.Field5__c;
            orgProductNm = s.Field7__r.Name;
            isPlanProduct = false;
		    tranId = sobj.Id;
		    accRefId = sobj.Field1__c;
		    
		    // 2014/09/15 数量小数点機能対応
		    // 数量情報が存在するば場合、小数部右側に表示する０は外す対応
		    if (!Commutils.isBlank(sobj.Field21__c)) sobj.Field21__c = CommUtils.deleteRightZero(sobj.Field21__c);
		    // 2014/09/19 金額は小数０を非表示対応（NO403）
		    // 単価
		    if (!CommUtils.isBlank(sobj.Field20__c)) sobj.Field20__c = CommUtils.deleteRightZero(sobj.Field20__c, CommUtils.getPointLen());
		    // 特別税
		    strSpecialTax = CommUtils.deleteRightZero( CommUtils.nullToZero(sobj.SpecialTax__c).format(), CommUtils.getPointLen());
			
		}
		public void clear() {
			// 消費税
			sobj.TaxRate__c = null;
			// サービス料
			sobj.ServiceRate__c = null;
			// 特別税
			sobj.SpecialTax__c = null;
		}
		public Integer index{get; private set;}
		public Integer rowNo{get;set;}
		/*
		public Decimal taxRate{get; set{
			taxRate = value;
			// 消費税　種別
			sobj.Field27__c = (taxRate == 0 ? '2' : '1');
		}}*/
		public String productNm{get;set;}
		// 該当商品名は商品名変更ため、ダミ用変数
		public String orgProductNm{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別税
		public String strSpecialTax{get; set{
			strSpecialTax = value;
			sobj.SpecialTax__c = CommUtils.nullToZero(strSpecialTax);
		}}
		// 会計明細単位の合計金額（税抜）[サビース料抜き]
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (value !=null && String.valueOf(value) != sobj.Field23__c) sobj.Field23__c = String.valueOf(value);}}
		public Tran1__c sobj{get;set;}
		public Boolean isValidata{get{
            return (!CommUtils.isBlank(sobj.Field7__c) &&
                    !CommUtils.isBlank(sobj.Field20__c) &&
                    !CommUtils.isBlank(sobj.Field21__c));
		}}
		public Boolean isPlanProduct{get{return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);} set;}
		public String tranId{get; set;}
		public String accRefId{get ;set;}
	}
	/**
	* 支払合計値情報格納
	**/
	public class TranFooter {
		public TranFooter() {
            clear();
		}
		// 数量
		public Decimal unitNums{get; private set;}
		// 全会計明細合計金額（税抜き）->全サービス料/特別税含めない
		public Decimal amoutPriceExcTax{get; private set;}
		// 全会計明細合計金額（税含め）
		public Decimal amoutPriceIncTax{get; private set;}
		// 全消費税
		//public Decimal amoutSalesTax{get; private set;}
		// サービス料(税抜)
		public Decimal amoutServicePrice{get; private set;}
		// サービス料(税込)
		public Decimal amoutServicePriceIncTax{get;private set;}
		// 特別税合計
		public Decimal amoutSpecialTax{get; private set;}
		// 前受付金
		public Decimal amoutAdvancesReceived{get; private set;}

		// 消費税設定存在の明細の税込金額
		public Decimal amoutPriceIncTaxByTax{get;set;}
		
		// 会計明細積み上げ計算
		public void add(TranItem item) {
			// 請求書非表示の場合、集計対象外になる
			if (item.sobj.InvoiceNoShowFlg__c) return;
			// 商品は前受付金の場合
			if (item.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_AR) {
				amoutAdvancesReceived+= item.amoutIncTax;
                return;
			}
			unitNums += CommUtils.nullToZero(item.sobj.Field21__c);
			amoutPriceIncTax += CommUtils.nullToZero(item.sobj.Field23__c);
			amoutPriceExcTax += item.amoutExcTax == null ? 0 : item.amoutExcTax;
			amoutServicePriceIncTax += CommUtils.nullToZero(item.servicePriceIncTax);
			amoutServicePrice += CommUtils.CalExcTaxPrice(item.servicePriceIncTax, item.sobj.TaxRate__c, 0);
//            amoutServicePrice += CommUtils.nullToZero(item.servicePrice);
//            amoutServicePriceIncTax += CommUtils.CalIncTaxPrice(item.servicePrice, item.sobj.TaxRate__c, 0);

            amoutSpecialTax += CommUtils.nullToZero(item.sobj.SpecialTax__c);
			if (item.sobj.TaxRate__c > 0 ) {
				amoutPriceIncTaxByTax += CommUtils.nullToZero(item.sobj.Field23__c) - CommUtils.nullToZero(item.sobj.SpecialTax__c);
			}
		}
		public void clear() {
            unitNums = 0;
            amoutPriceExcTax = 0;
            amoutPriceIncTax = 0;
            amoutServicePrice = 0;
            amoutServicePriceIncTax = 0;
            amoutSpecialTax = 0;
            amoutAdvancesReceived = 0;
            amoutPriceIncTaxByTax = 0;
		}
	}
	// 2017/07/10 ログ出力機能を追加する BEGIN
	private static void writeLogToDb(String logMsg, Id accId) {
		try {
			BillSimpleInputCtrl.writeLogToDb(logMsg,accId);
		} catch(Exception e){
			String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
		}
	}
	// 2017/07/10 ログ出力機能を追加する END
	// 2018/03/12 連泊コメント同期機能対応 WGCH BEGIN
	private List<AccountAcount__c> accCommentLst{get;set;}
	public Boolean isAccountSyncCommentFlg = CommDefine__c.getOrgDefaults().AccountSyncCommentFlg__c;
	// 设置最新的comment__c数据
	private void upOneRoomAcc(AccountAcount__c acc){
		for(AccountAcount__c accObj : accCommentLst){
			accObj.comment__c = CommUtils.nullToBlank(acc.comment__c);
		}
		if(!accCommentLst.isEmpty()) upsert accCommentLst;
	}
	// 处理第一天的会计与当前会计的信息
	private void getOneRoomAcc(AccountAcount__c acc){
		accCommentLst = new List<AccountAcount__c>();
		// フラグ：True、「簡易会計、オーダーエンドりの無部屋データ」エラー修正by zy BEGIN
		if (acc.Relreserve__c != null) {
		// フラグ：True、「簡易会計、オーダーエンドりの無部屋データ」エラー修正by zy END
			// ONEROOMの識別キー
			List<AccountAcount__c> accBulkLst = [Select Id,comment__c From AccountAcount__c Where Relreserve__r.LeadIndexRef__c =: acc.Relreserve__r.LeadIndexRef__c 
														 And Relreserve__r.LeadIndexSubId__c =: acc.Relreserve__r.LeadIndexSubId__c 
														 And Relreserve__r.RoomGroupNo__c =: acc.Relreserve__r.RoomGroupNo__c  Order By Relreserve__r.EntryTime__c];
			for(Integer i = 0; i < accBulkLst.size(); i++){
				if(i == 0) acc.comment__c = CommUtils.nullToBlank(accBulkLst[i].comment__c);
				if(acc.Id != accBulkLst[i].Id) accCommentLst.add(accBulkLst[i].clone(true,true));
			}
		// フラグ：True、「簡易会計、オーダーエンドりの無部屋データ」エラー修正by zy BEGIN
		}
		// フラグ：True、「簡易会計、オーダーエンドりの無部屋データ」エラー修正by zy END
	}
	// 2018/03/12 連泊コメント同期機能対応 WGCH END
}