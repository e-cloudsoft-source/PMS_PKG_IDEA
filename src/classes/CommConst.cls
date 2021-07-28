public class CommConst {

	// トリガー
	public Enum TriggerMethod {IsInsert, IsUpdate, IsDelete, IsUnDelete}

	/*************************
	* 会計画面に利用している定数
	*************************/
	// 取引種別
	public static final String ACC_TRADE_NORMAL = '00';   // 売上（通常）
	public static final String ACC_TRADE_VOID = '30';   // ＶＯＩＤ
	// 会計支払方式
	// 2013/05/10 予約金選択肢追加する
	public static final String MEDIA_TYPE_01 = Label.CONST_012_0438;//'預り／現計';
	public static final String MEDIA_TYPE_CD_01 = '01';
	public static final String MEDIA_TYPE_02 = Label.CONST_012_0439;//'ｸﾚ計・掛計等';
	public static final String MEDIA_TYPE_CD_02 = '02';
	public static final String MEDIA_TYPE_03 = Label.CONST_012_0440;//'掛計';
	public static final String MEDIA_TYPE_CD_03 = '03';
	public static final String MEDIA_TYPE_11 = Label.CONST_012_0441;//'クーポン';
	public static final String MEDIA_TYPE_CD_11 = '11';
	public static final String MEDIA_TYPE_12 = Label.CONST_012_0442;//'値引・割引券';
	public static final String MEDIA_TYPE_CD_12 = '12';
	public static final String MEDIA_TYPE_21 = Label.CONST_012_0443;//'予約金';
	public static final String MEDIA_TYPE_CD_21 = '21';
	
	public static List<Selectoption> getPayMentTypeOptLst() {
		List<Selectoption> optLst = new List<Selectoption>();
		optLst.add(new SelectOption(MEDIA_TYPE_CD_01,MEDIA_TYPE_01));
		optLst.add(new SelectOption(MEDIA_TYPE_CD_02,MEDIA_TYPE_02));
		optLst.add(new SelectOption(MEDIA_TYPE_CD_03,MEDIA_TYPE_03));
		optLst.add(new SelectOption(MEDIA_TYPE_CD_11,MEDIA_TYPE_11));
		optLst.add(new SelectOption(MEDIA_TYPE_CD_12,MEDIA_TYPE_12));
		if (APPOTION_ISSHOW_MEIDA_SUBSCRIPTION) {
		optLst.add(new SelectOption(MEDIA_TYPE_CD_21,MEDIA_TYPE_21));
		}
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
		list<SelectOption> custPayLst = BillSimpleHelp.getCustPayList();
		optLst.addAll(custPayLst);
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
		return optLst;
	}
	public static String getPaymentTypeLabelByKey(String key) {
		if (key == MEDIA_TYPE_CD_01) return MEDIA_TYPE_01;
		else if (key == MEDIA_TYPE_CD_02) return MEDIA_TYPE_02;
		else if (key == MEDIA_TYPE_CD_03) return MEDIA_TYPE_03;
		else if (key == MEDIA_TYPE_CD_11) return MEDIA_TYPE_11;
		else if (key == MEDIA_TYPE_CD_12) return MEDIA_TYPE_12;
		else if (key == MEDIA_TYPE_CD_21) return MEDIA_TYPE_21;
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
		else {
		    String ret = BillSimpleHelp.getMediaLabelByCode(key);
		    return (CommUtils.isBlank(ret) ? null : ret);
		}
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
		return null;
	}
	// 2017/04/11 POS会計データの会計人數は関連予約、会計の人數を連携する、しない処理対応 BEGIN
	// POS人數はご予約人數へ連動フラグ
	public static final boolean POSDATAISSYNCFLG = CommDefine__c.getOrgDefaults().PosDataStayPersonsSyncLeadFlg__c == null ? false : CommDefine__c.getOrgDefaults().PosDataStayPersonsSyncLeadFlg__c;
	// 2017/04/11 POS会計データの会計人數は関連予約、会計の人數を連携する、しない処理対応 END
	/*************************
	* メディア名からメディアコードを取得処理
	*************************/
	public static String getMediaCodeByMediaName(String nm) {
		if (nm == CommConst.MEDIA_TYPE_01) return CommConst.MEDIA_TYPE_CD_01;
		else if (nm == CommConst.MEDIA_TYPE_02) return CommConst.MEDIA_TYPE_CD_02;
		else if (nm == CommConst.MEDIA_TYPE_03) return CommConst.MEDIA_TYPE_CD_03;
		else if (nm == CommConst.MEDIA_TYPE_11) return CommConst.MEDIA_TYPE_CD_11;
		else if (nm == CommConst.MEDIA_TYPE_12) return CommConst.MEDIA_TYPE_CD_12;
		else if (nm == CommConst.MEDIA_TYPE_21) return CommConst.MEDIA_TYPE_CD_21;
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 BEGIN
		else {
		    return BillSimpleHelp.getMediaCodeByName(nm);
		}
		// 2018/04/11 支払メデイア種別はカスタマイズできるように対応 END
		return '';
	}
	// 2014.10.13 会計処理種別定数
	public static final String ACC_DATATYPE_DEPOSIT = '入金';
	public static final String ACC_DATATYPE_PAYMENT = '出金';
    /*************************
    * 会計商品マスた関連定数
    *************************/
    // 商品処理種別：前受付金(AdvancesReceived)
    public static final String PROD_ACTION_TYPE_AR = '前受付金';
    public static final String PROD_ACTION_TYPE_RP = '室料';
    public static final String PROD_ACTION_TYPE_PL = 'プラン';
    public static final String PROD_ACTION_TYPE_MO = '朝食';
    public static final String PROD_ACTION_TYPE_NO = '非表示';
    public static final String PROD_ACTION_TYPE_PY = '支払';	// 該当種別商品は支払情報として、利用する
    public static final String PROD_ACTION_TYPE_SR = 'サービス料';
	// 宿泊税
	// 宿泊料金1人1泊  １万円以上１万５千円未満の宿泊　１００円 １万５千円以上の宿泊　２００円*/
	public static final Integer ROOM_TAX_MONEY_LEV1 = 10000;
	public static final Integer ROOM_TAX_MONEY_LEV2 = 15000;
	// 支払種別:
	public static final String PROD_PAY_TYPE_CASH = '現金';
	public static final String PROD_PAY_TYPE_CARD = 'カード';
	public static final String PROD_PAY_TYPE_URKK = '売掛金';
	public static final String PROD_PAY_TYPE_KUPO = 'クーポン';
	public static final String PROD_PAY_TYPE_DIS_RATE = '割引';
	public static final String PROD_PAY_TYPE_DIS_PRICE = '値引';
    public static final String PROD_PAY_TYPE_YOYK = '予約金';
	public static final String PROD_PAY_TYPE_ADD_RATE = '割増';
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	// 軽減税率フラグ
	public static final Boolean REDUCED_TAXRATE_FLG{get{ return CommDefine__c.getOrgDefaults().ReducedTaxRateFlg__c == null ? false : CommDefine__c.getOrgDefaults().ReducedTaxRateFlg__c;}}
	// PDFプラン展開表示FLG
	public static final Boolean PDF_PLAN_BRK_SHOW_FLG{get{ return CommDefine__c.getOrgDefaults().PDFPlanBrkIsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().PDFPlanBrkIsShowFlg__c;}}
	// 軽減税率フラグ -> PDFプラン展開表示FLG
	public static final Boolean REDUCED_PDF_PLAN_BRK_SHOW_FLG{get{ return REDUCED_TAXRATE_FLG && PDF_PLAN_BRK_SHOW_FLG;}}
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	// 軽減税率のプラン金額が明細別計算フラグ
	public static final Boolean PLAN_BRKTOHEADER_CAL_FLG{get{
		// 2019/11/11 BUGFIEX修正 WGCH BEGIN
		return CommDefine__c.getOrgDefaults().ReducedTaxPlanDetailCalFlg__c == null ? false : (REDUCED_PDF_PLAN_BRK_SHOW_FLG || (REDUCED_TAXRATE_FLG && CommDefine__c.getOrgDefaults().ReducedTaxPlanDetailCalFlg__c));
		// 2019/11/11 BUGFIEX修正 WGCH END
	}}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
	public static final String  ROW_HIDE_CONST = '0';
	// 軽減税率、PDF(0% )対象隠すFLG
	public static final Boolean ROW_HIDE_NOTAX_FLG{get{
		return ROW_HIDE_MODE.Size() == 0 ? false : (ROW_HIDE_MODE[0] == ROW_HIDE_CONST);
	}}
	// 軽減税率、PDF値引隠すFLG
	public static final Boolean ROW_HIDE_DIS_FLG{get{
		return ROW_HIDE_MODE.Size() <= 1 ? false : (ROW_HIDE_MODE[1] == ROW_HIDE_CONST);
	}}
	// 軽減税率、PDF合計隠すFLG
	public static final Boolean ROW_HIDE_SUM_FLG{get{
		return ROW_HIDE_MODE.Size() <= 2 ? false : (ROW_HIDE_MODE[2] == ROW_HIDE_CONST);
	}}
	// 軽減税率PDF非表示の行モード
	public static final List<String> ROW_HIDE_MODE{get{
		return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ReducedTaxRowIsHideMode__c).split(',');
	}}
	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH END
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	public static final String REDUCED_TAXRATE_MIN_MODE = '1'; // 8%优先按分「从小税种优先按分」
	public static final String REDUCED_TAXRATE_MAX_MODE = '2'; // 10%优先按分「从大税种优先按分」
	// 軽減税率、割合モード
	public static final String REDUCED_TAXRATE_PRO_MODE{get{
		 return CommDefine__c.getOrgDefaults().ReducedTaxProportionMode__c == null ? '0' : CommDefine__c.getOrgDefaults().ReducedTaxProportionMode__c;
	}}
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH BEGIN
	// 会計書、請求書マージ機能フラグ
	public static final Boolean ACCOUNT_PDFMERGE_FLG{get{ return CommDefine__c.getOrgDefaults().AccountPdfBulkMergeFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountPdfBulkMergeFlg__c;}}
	// 2019/10/30 会計書、請求書のマージ機能対応 WGCH END
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH BEGIN
	public static final String ACCOUNT_RECEIPTDATE_0 = '0'; // 会計日時の日付で設定する（デフォルト値）
	public static final String ACCOUNT_RECEIPTDATE_1 = '1'; // 売上日の日付で設定する
	public static final String ACCOUNT_RECEIPTDATE_2 = '2'; // 到着日の日付で設定する
	public static final String ACCOUNT_RECEIPTDATE_3 = '3'; // 出発日の日付で設定する
	// 2016/01/12 領収書日付デフォルト値設定制御変更「TRUE:（デフォルト値）」
	public static final Boolean ACCOUNT_RECEIPTDATE_DEF_FLG{get{ return CommDefine__c.getOrgDefaults().AccountReceiptDateDefValSetFlg__c == null ? true : CommDefine__c.getOrgDefaults().AccountReceiptDateDefValSetFlg__c;}}
	// 会計の領収証日付値の自動設定制御モード
	public static final String ACCOUNT_RECEIPTDATE_MODE{get{
		String accReceiptDateMode = CommDefine__c.getOrgDefaults().AccountReceiptDateDefValSetMode__c;
		if(accReceiptDateMode == '1') return ACCOUNT_RECEIPTDATE_2; // 到着日の日付で設定する
		else if(accReceiptDateMode == '2') return ACCOUNT_RECEIPTDATE_3; // 出発日の日付で設定する
		else { // 0/其它 原功能（デフォルト値）
			if(ACCOUNT_RECEIPTDATE_DEF_FLG) return ACCOUNT_RECEIPTDATE_0; // 会計日時の日付で設定する
			else return ACCOUNT_RECEIPTDATE_1; // 売上日の日付で設定する
		}
	}}
	// 2019/11/30 会計の領収証日付値の自動設定制御モード機能対応 WGCH END
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	public static final String COM_CUTOFFDAY{get{ return CommDefine__c.getOrgDefaults().AccountAcountCutoffDay__c == null ? '' : CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountAcountCutoffDay__c);}}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH BEGIN
	public static final Boolean ACC_PLAN_EDIT_FLG{get{ return CommDefine__c.getOrgDefaults().AccountIsPlanEditFLG__c == null ? false : CommDefine__c.getOrgDefaults().AccountIsPlanEditFLG__c;}}
	// 2019/12/30 会計機能、会計画面でプランの内訳を編集出来るように WGCH END
	// 2019/12/30 FREEEAPI连携機能 WGCH BEGIN
	// 事業所名(屋号)
	public static final String DISNAME{get{ return FreeeSeting__c.getOrgDefaults().DisplayName__c == null ? '' : FreeeSeting__c.getOrgDefaults().DisplayName__c;}}
	// 認証プロバイダをURL 接尾辞
	public static final String CALLBACK{get{ return FreeeSeting__c.getOrgDefaults().DeveloperName__c == null ? '' : FreeeSeting__c.getOrgDefaults().DeveloperName__c;}}
	// スケジュール指定処理月
	public static final Integer OFFSETVAL{get{ return FreeeSeting__c.getOrgDefaults().OffsetVal__c == null ? 0 : Integer.valueOf(FreeeSeting__c.getOrgDefaults().OffsetVal__c);}}
	// 店舗コード
	public static final Set<String> SHOPCODESET{get{
		Set<String> spcdSet = new Set<String>();
		if(FreeeSeting__c.getOrgDefaults().ShopCode__c != null){
			for(String spcd : CommUtils.nullToBlank(FreeeSeting__c.getOrgDefaults().ShopCode__c).split(',')){
				if(!CommUtils.isBlank(spcd)) spcdSet.add(CommUtils.nullToBlank(spcd));
			}
		}
		return spcdSet;
	}}
	// 2019/12/30 FREEEAPI连携機能 WGCH END
	// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
	public static final String PLAN_PRD_PREX_NUM = 'P';
	public static final String PLAN_BATHTAXAUTOSET_1 = '1'; // 元共通定義「入湯税自動入力モード」設定有効（デフォルト値）
	public static final String PLAN_BATHTAXAUTOSET_2 = '2'; // プラン別入湯税商品を紐付連泊の場合、泊目別に入湯税を自動設定する
	public static final String PLAN_BATHTAXAUTOSET_3 = '3'; // プラン別入湯税商品を紐付連泊の場合纏めて１泊目に入湯税を設定するモード
	public static Boolean accRenpakuBathAutoSetFlg{get{return (CommDefine__c.getOrgDefaults().AccountRenpakuBathTaxAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountRenpakuBathTaxAutoSetupFlg__c);}}
	public static final String PLAN_BATHTAXAUTOSET_MODE{get{
		// 入湯税自動入力モード切换
		String pBathTaxAutoSetMode = CommDefine__c.getOrgDefaults().AccountBathTaxAutoSetupFlg2__c;
		// 入湯税自動入力モード切换:2; プランに紐付く入湯税設定により、見積明細、会計明細にプラン登録に従って、入湯税明細を自動入力する
		if(pBathTaxAutoSetMode == PLAN_BATHTAXAUTOSET_2){
			// TRUE：自動入力の入湯税は日ごとに振り分ける
			if(accRenpakuBathAutoSetFlg) return PLAN_BATHTAXAUTOSET_2; // PLAN连泊分别設定する
			// FALSE：自動入力の入湯税は1泊目に集める（デフォルト値）
			else return PLAN_BATHTAXAUTOSET_3; // PLAN连泊合并1泊設定する
		} else {
			// 共有定義「入湯税自動入力フラグ」設定により、入湯税自動入力（デフォルト値）
			return PLAN_BATHTAXAUTOSET_1; // 原功能
		}
	}}
	// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 BEGIN by zh
    public static Boolean ACCOUNT_STAMPISSHOW_FLG {get{
        return CommDefine__c.getOrgDefaults().AccReportStampIsShowFlg__c == null ? true : CommDefine__c.getOrgDefaults().AccReportStampIsShowFlg__c;
    }}
    // 2018/04/27 会計書ハンコ表示・非表示機能対応 END by zh
    // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
    public static Integer ROOM_TYPE_SELECT_MODE {get{
        return CommDefine__c.getOrgDefaults().RoomIndicatorRoomTypeSelectFlg__c == null ? 0 : CommDefine__c.getOrgDefaults().RoomIndicatorRoomTypeSelectFlg__c.intValue();
    }}
    // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
    // 2019/10/30 会計書の領収書点線の位置固定フラグ WSQ BEGIN
    public static final Boolean ACCOUNT_SPLITLINE_FLG {get{
    	return CommDefine__c.getOrgDefaults().AccountSplitLineFixFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountSplitLineFixFlg__c;
    }}
    // 2019/10/30 会計書の領収書点線の位置固定フラグ WSQ END
    // 請求書ハンコ表示・非表示
    public static Boolean Bill_STAMPISSHOW_FLG {get{
        return CommDefine__c.getOrgDefaults().BillReportStampIsShowFlg__c == null ? true : CommDefine__c.getOrgDefaults().BillReportStampIsShowFlg__c;
    }}
    // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH BEGIN
    // 請求書領収書表示・非表示
    public static Boolean Bill_RCPTISSHOW_FLG {get{
        return CommDefine__c.getOrgDefaults().BillReportReceiptIsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().BillReportReceiptIsShowFlg__c;
    }}
    // 2018/12/15 請求書-領収書新規レイアウトを追加 WGCH END
    // 2019/04/30 請求書の送付表新規作成 BY zyz BEGIN
    // 請求書の送付表表示・非表示
    public static Boolean Bill_LETTER_FLG {get{
        return CommDefine__c.getOrgDefaults().BillLetterIsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().BillLetterIsShowFlg__c;
    }}
    // 2019/04/30 請求書の送付表新規作成 BY zyz END
    // 会計書の店舗切替を保存FLG
    public static Boolean ACC_SPCDSAVE_FLG {get{
        return CommDefine__c.getOrgDefaults().AccountPrintSpCdSaveFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountPrintSpCdSaveFlg__c;
    }}
    // 2017/10/09 会計商品並び順カスタマイズできるように改善対応 BEGIN
    public static String PROD_SORT_KEY{get{ 
        String key = CommDefine__c.getOrgDefaults().ProductSortKey__c;
        if (CommUtils.isBlank(key)) key = 'Field4__c,OP__c, Field3__c';
        return key;
    }}
    // 2017/10/09 会計商品並び順カスタマイズできるように改善対応 END
    // 2017/11/14 店舗別会計商品検索区分
    public static Boolean PROD_SHOPSEARCH_DIV_ISALL {get{
        String div = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ShopAccountSearchDiv__c); 
        return (div == PROD_SHOPSEARCH_DIV_ALL);
    }}
    public static Boolean PROD_SHOPSEARCH_DIV_ISNOR {get{
        String div = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ShopAccountSearchDiv__c); 
        return (div == PROD_SHOPSEARCH_DIV_NOR);
    }}
    public static Boolean PROD_SHOPSEARCH_DIV_ISPAY {get{
        String div = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ShopAccountSearchDiv__c); 
        return (div == PROD_SHOPSEARCH_DIV_PAY);
    }}
    // 店舗別会計商品するがどう
    public static Boolean PROD_SHOPSEARCH_DIV_IS {get{
        return (PROD_SHOPSEARCH_DIV_ISNOR || PROD_SHOPSEARCH_DIV_ISALL || PROD_SHOPSEARCH_DIV_ISPAY);
    }}
    private static final String PROD_SHOPSEARCH_DIV_ALL = '1';   // 全て会計商品
    private static final String PROD_SHOPSEARCH_DIV_NOR = '2';   // 「通常、プラン、室料、朝食、夕食、サービス料」商品
    private static final String PROD_SHOPSEARCH_DIV_PAY = '3';   // 「前受付金、支払」商品
    /*************************
    * 予約ステータス
    *************************/
    public static final String LEAD_ST_CHECKING='確認中';
    public static final String LEAD_ST_CHECKED='確定';
    public static final String LEAD_ST_TENTAIVE='仮予約';
    public static final STRING LEAD_ST_ENKAIBOOK = '会場おさえ';
    public static final String LEAD_ST_NOSHOW = 'NO SHOW';
    public static final String LEAD_ST_CANCEL = 'キャンセル';
    public static final String LEAD_ST_DELETE = '削除';
    public static final String LEAD_ST_CANDEL_WAIT='キャンセルまち';
    public static final Integer LEAD_ST_CANCEL_FLG = 1;
	public static final String LEADINDEX_ST_NORMAL = '通常';
    /*************************
    * お客様ステータス
    *************************/
    public static final String LEAD_GUEST_ST_CI = 'チェックイン完';
    public static final String LEAD_GUEST_ST_CO = 'チェックアウト完';
    public static final String LEAD_GUEST_ST_OUT = '外出中';
    public static final String LEAD_GUEST_ST_BATH = '入浴中';
    /*************************
    * お部屋ステータス
    *************************/
    public static final String LEAD_ROOM_ST_UNCLEAN = '未清掃';
	public static final String LEAD_ROOM_ST_CLEANED = '清掃済';
	// 2018/10/11 未清掃保持フラグ
	public static boolean LEAD_ROOM_ST_ISKEEPCLEANFLG{get{return CommDefine__c.getOrgDefaults().IsNoCleanKeepFlag__c == null ? false : CommDefine__c.getOrgDefaults().IsNoCleanKeepFlag__c;}}
    /*************************
    * 部屋タイプ処理種別
    *************************/
    public static final String ROOMTYPE_NORMAL = '通常';
    public static final String ROOMTYPE_EB = 'E/B';

    /*************************
    * チェックイン時間・チェックアウト時間[2013/01/03 ADD]
    *************************/
    /*************************
    * チェックイン時間・チェックアウト時間[2013/01/03 ADD]
    *************************/
    public static String DEF_CHECKIN_TIME{get{
		Schema.DescribeFieldResult f = Schema.SObjectType.Lead__c.fields.Field4__c;
		List<Schema.PicklistEntry> plist = f.getPicklistValues();
		for (Schema.PicklistEntry p : plist) {
		  if (p.isActive() && p.isDefaultValue()) { return p.getValue(); }
		}
		return '15:00';
    }}
	public static String DEF_CHECKOT_TIME{get{
		Schema.DescribeFieldResult f = Schema.SObjectType.Lead__c.fields.Field3__c;
		List<Schema.PicklistEntry> plist = f.getPicklistValues();
		for (Schema.PicklistEntry p : plist) {
		  if (p.isActive() && p.isDefaultValue()) { return p.getValue(); }
		}
		return '11:00';
    }}
    public static Time defCheckInTime{get{
        String defCheckInTime = DEF_CHECKIN_TIME;
        // 2015/09/14 不具合対応 BEGIN 時刻処理は「：」で分ける確認する
        //Integer HH = Integer.valueOf(defCheckInTime.subString(0,2));
        //Integer MM = Integer.valueOf(defCheckInTime.subString(3,5));
        String[] hhmm = defCheckInTime.split(':');
        Integer HH = CommUtils.nullToIntZero(hhmm[0]);
        Integer MM = CommUtils.nullToIntZero(hhmm.size() > 1 ? hhmm[1] : '0');
        // 2015/09/14 不具合対応 END 時刻処理は「：」で分ける確認する
        return Time.newInstance(HH, MM, 0, 0);}
    }
    public static Time defCheckOtTime{get{
        String defCheckOtTime = CommConst.DEF_CHECKOT_TIME;
        // 2015/09/14 不具合対応 BEGIN 時刻処理は「：」で分ける確認する
        //Integer HH = Integer.valueOf(defCheckOtTime.subString(0,2));
        //Integer MM = Integer.valueOf(defCheckOtTime.subString(3,5));
        String[] hhmm = defCheckOtTime.split(':');
        Integer HH = CommUtils.nullToIntZero(hhmm[0]);
        Integer MM = CommUtils.nullToIntZero(hhmm.size() > 1 ? hhmm[1] : '0');
        // 2015/09/14 不具合対応 END 時刻処理は「：」で分ける確認する
        return Time.newInstance(HH, MM, 0, 0);}
    }
	// 日帰りの到着時刻[2013/12/10]
	public static String DEF_DAYUSE_CHECKIN_TIME {get{
		return CommDefine__c.getOrgDefaults().DayUseEntryTime__c == null ? '12:00' : CommDefine__c.getOrgDefaults().DayUseEntryTime__c;
	}}
	// 日帰りの日帰デフォルト滞在時間数
	public static Integer DEF_DAYUSE_STAY_HOURS {get{
		return CommDefine__c.getOrgDefaults().DayUseDefaultStayHours__c == null ? 2 : CommDefine__c.getOrgDefaults().DayUseDefaultStayHours__c.intvalue();
	}}
    /*************************
    * キャンセル料金計算区分関連
    *************************/
    public static String DEF_CANCEL_CALKBN {get{
    	return CommDefine__c.getOrgDefaults().StayCancelRuleKbn__c == null ? '1' : CommDefine__c.getOrgDefaults().StayCancelRuleKbn__c;
    }}
    // キャンセル料金は初日の手数料レートから計算する
    public static String DEF_CANCEL_CALKBN_FIRST = '1';
    /*************************
    * リアルAGT関連
    *************************/
    public static final String ACCOUNT_TYPE_TRAVEL = '旅行会社';
    /*************************
    * アプリ機能起動OPTION
    *************************/
    // App NameSpace
    public static String APPOTION_NAMESPACE{get{
    	return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AppNS__c);
    }}
    // E/B機能起動OPTION
    public static Boolean APPOPTION_ISUSR_EB{get{
        return CommDefine__c.getOrgDefaults().RoomUseEbFlg__c != true ? false : true;
    }}
    // 予約ポップのセミナー入力可・不可制御フラグ
    public static Boolean APPOTION_ISSHOW_SEMINAR{get{
        return CommDefine__c.getOrgDefaults().RoomTypeSeminarIsShow__c != true ? false : true;
    }}
    // 予約ポップの部屋項目表示・非表示制御フラグ
    public static Boolean APPOTION_ISSHOW_ROOM{get{
    	return CommDefine__c.getOrgDefaults().RoomTypeRoomIsShow__c != true ? false : true;
    }}
    // 連絡事項表示・非表示制御フラグ
    public static Boolean APPOTION_ISSHOW_MESSAGE{get{
        return CommDefine__c.getOrgDefaults().MessageIsShowFlg__c != true ? false : true;
    }}
    public static Boolean OLDDATE_ISSHOW_MESSAGE{get{
    	return CommDefine__c.getOrgDefaults().MessageOldDataIsShow__c!= true ? false : true;
    }}
    
	// 会計支払メディア種別（予約金）表示・非表示フラグ
	public static Boolean APPOTION_ISSHOW_MEIDA_SUBSCRIPTION{get{
        return CommDefine__c.getOrgDefaults().MediaTypeSubscriptionIsShowFlg__c != true ? false : true;
    }}
	
    public static String APPOPTION_ROOMTYPE_REPNM{get{
    	return CommDefine__c.getOrgDefaults().RoomTypeReport__c == null ? '$0001 客室タイプ別予約表' : CommDefine__c.getOrgDefaults().RoomTypeReport__c;
    }}
    public static String APPOPTION_RACERATE_REPNM{get{
    	return CommDefine__c.getOrgDefaults().RaceRateReport__c == null ? '$0011 ラックレート設定情報' : CommDefine__c.getOrgDefaults().RaceRateReport__c;
    }}
    // プラン商品コードの頭数字
    public static Integer APPOPTION_PLANPRODCD_PREFIX_NUM{get{
    	return CommDefine__c.getOrgDefaults().PlanProdCdPrefixNum__c == null ? 5 : CommDefine__c.getOrgDefaults().PlanProdCdPrefixNum__c.intValue();
    }}
    // POSレジ
    public static String APPOPTION_POST_REG{get{
    	return CommDefine__c.getOrgDefaults().Posreg__c == null ? '0' : CommDefine__c.getOrgDefaults().Posreg__c;
    }}
	// 施設コード
	public static String APPOPTION_FACILITY_CODE{get{
		return CommDefine__c.getOrgDefaults().FacilityCode__c == null ? '1' : CommDefine__c.getOrgDefaults().FacilityCode__c;
	}}
	// 過去日付で、予約ポップで予約登録可否フラグ[20130624]
	public static Boolean APPOTION_ROOMTYPE_INPUT_PASTDATA {get{
		return CommDefine__c.getOrgDefaults().RoomTypeInputPastData__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeInputPastData__c;
	}}
	// 
	public static Boolean APPOTION_ACCOUNTSPLIT_BKISHOW {get{
		return CommDefine__c.getOrgDefaults().AccountSplitFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountSplitFlg__c;
	}}
	//確認メッセージを表示・非表示
	public static Boolean APPOTION_CHECKIN_GROUPCONFIRM {get{
		return CommDefine__c.getOrgDefaults().RoomIndicatorGpCIMsgIsShow__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorGpCIMsgIsShow__c;
	}}
	public static Boolean APPOTION_CHECKIN_GROUPCLCONFIRM {get{
		return CommDefine__c.getOrgDefaults().RoomIndicatorGpCancelMsgIsShow__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorGpCancelMsgIsShow__c;
	}}
	// 親部屋集める/分割するフラグ
	// 1:親部屋集める   2:分割するフラグ
	public static Integer APPOTION_LEADSPLIT_DIV_CODE {get{
		return CommDefine__c.getOrgDefaults().LeadSplitDivCode__c == null ? 1 : CommDefine__c.getOrgDefaults().LeadSplitDivCode__c.intValue();		
	}}
	// レジカードコード/PDF出力区分コード
	// 1:5明細/1Page   2:7明細/1Page  3:7明細(no line)/1Page
	public static String APPOTION_CARREGISTSWITCH_DIV_CODE {get{
		return CommDefine__c.getOrgDefaults().CashRegisterSwitchCode__c == null ? '1' : CommDefine__c.getOrgDefaults().CashRegisterSwitchCode__c;		
	}}
	// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz BEGIN
	public static Boolean APPOTION_CARREGISTSAVE_CHECKIN_MESSAGE {get{
		return CommDefine__c.getOrgDefaults().CashRegSaveLeadCheckInFlg__c == null ? false : CommDefine__c.getOrgDefaults().CashRegSaveLeadCheckInFlg__c;		
	}}
	// 2019/02/28 宿帳でのチェックイン、宿帳記入後に「保存」押下すると、チェックイン完に変更されると便利 BY zyz END
	// 2017/09/08 レジカードサインタイプ追加
	/*サイン機能の利用タイプを定義する 
    1：別ウインドウにサインする（デフォルト値） 
    2：レジカード画面の署名欄に直接サインする*/
    public static final String APPOTION_CARREG_SING_TYPE_POPUP = '1';
    public static final String APPOTION_CARREG_SING_TYPE_DR = '2';
    public static final String APPOTION_CARREG_SING_TYPE_DRPAGE = '3';
    public static String APPOTION_CARREG_SING_TYPE{get{
        String singType = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().CashRegisterSignType__c);
        return (CommUtils.isBlank(singType) ? APPOTION_CARREG_SING_TYPE_POPUP : singType);
    }}
	// 親部屋集める/分割するフラグ 2:分割するフラグ
	public static final Integer APPOTION_LEADSPLIT_DIV_CODE_UNION = 1;
	public static final Integer APPOTION_LEADSPLIT_DIV_CODE_SPLIT = 2;
	// 予約から自動チェックインする場合、売上計上日設定区分
	public static String APPOTION_ACC_SALESDATE_DIV_CODE {get{
		return CommDefine__c.getOrgDefaults().AccountSaleDateSetupDiv__c == null ? APPOTION_ACC_SALESDATE_DIV_CODE_CI : CommDefine__c.getOrgDefaults().AccountSaleDateSetupDiv__c;
	}}
	// チエックイン日（到着日）で売上計上日に設定する
	public static final String APPOTION_ACC_SALESDATE_DIV_CODE_CI = '1';
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
	public static Boolean BOOKEST_USERDATE_FLG {get{
		return CommDefine__c.getOrgDefaults().BookEstUseDateSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().BookEstUseDateSetupFlg__c;
	}}
	// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
	// 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
	public static Boolean USERCONFIG_CHECKINDAY_FLG {get{
		return CommDefine__c.getOrgDefaults().CheckInDayUserConfigFlg__c == null ? false : CommDefine__c.getOrgDefaults().CheckInDayUserConfigFlg__c;
	}}
	// 2019/09/15 指定日自动记忆機能対応 WGCH END
	// 明細デフォルト行数
	public static String APPOTION_DETAIL_DEF_INPUTLINES {get{
		return CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().DetailsInputDefaultLines__c) == 0 ? '27' : CommDefine__c.getOrgDefaults().DetailsInputDefaultLines__c;
	}}
	// 予約ポップ営業ステータス
	public static String APPOTION_DEF_ROOMTYPE_SALESTATUS() {
		//通常:1
		return CommDefine__c.getOrgDefaults().RoomTypeSaleStatus__c == null ? Label.CONST_012_0473 : CommDefine__c.getOrgDefaults().RoomTypeSaleStatus__c;
	}
	// 内消費税の英語表示文言
	public static String APPOTION_PDF_TAXENGLISH_LABEL{get{
		return CommDefine__c.getOrgDefaults().EnglishTaxLabel__c == null ? 'Sales Tax&Hotel Tax' : CommDefine__c.getOrgDefaults().EnglishTaxLabel__c;
	}}
	// 店舗別プラン
	public static Boolean APPOTION_BI_SHOPPLAN_FLG {get{
		return CommDefine__c.getOrgDefaults().ShopPlanSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().ShopPlanSetupFlg__c;	
	}}
	// 予約人数と予約見積明細の数量連動制御フラグ
	public static Boolean APPOTION_LEAD_STAYPERSIONS_SYNCTO_ESTITEM_FLG {get{
		return CommDefine__c.getOrgDefaults().LeadStayPersonsIsSyncToEstitemFlg__c == null ? false : CommDefine__c.getOrgDefaults().LeadStayPersonsIsSyncToEstitemFlg__c;	
	}}
	// 会計書の領収書欄を表示する・しない選択できる制御フラグ
	public static Boolean APPOTION_RECEIPT_ISSHOW_FLG{get{
		return CommDefine__c.getOrgDefaults().AccountRecipteIsShow__c == null ? false : CommDefine__c.getOrgDefaults().AccountRecipteIsShow__c;
	}}
	// 予約ポップの新規予約ウインドウのバージョン値
	public static Integer APPOTION_NEWBOOKING_VER{get{
		return CommDefine__c.getOrgDefaults().RoomTypeNewBookingWinVersion__c == null ? 1 : CommDefine__c.getOrgDefaults().RoomTypeNewBookingWinVersion__c.intValue();
	}}
	// 2017/09/25 会計書一括ビル印刷の最大部屋数
	public static Integer APPOTION_PDF_PRINT_MAXROOMS{get{
        Integer mv = CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().AccountReportBulkPrintMaxRooms__c);
        return (mv < 1) ? 75 : mv;
	}}
	// 会計書、請求書明細表示順
	public static String APPOTION_ACCOUNT_SORT_VAL{get{
		return CommDefine__c.getOrgDefaults().AccountReportSortKbn__c == null ? APPOTION_ACCOUNT_SORT_USEDATE : CommDefine__c.getOrgDefaults().AccountReportSortKbn__c;
	}}
	public static final String APPOTION_ACCOUNT_SORT_ORG = '1';			// 会計書単位ー＞画面明細入力順
	public static final String APPOTION_ACCOUNT_SORT_USEDATE = '2';		// 利用日順
    // 2017/11/02 項目変更履歴作成フラグ
    public static Boolean APPOTION_ITEMHISTORY_CREATEFLG{get{
        return CommDefine__c.getOrgDefaults().ItemChangeHistoryAutoCreateFlg__c == null ? true : CommDefine__c.getOrgDefaults().ItemChangeHistoryAutoCreateFlg__c;
    }}
    // 2017/12/27 会計の非表示の合計金額設定不要
    public static final Boolean APPOTION_ACCOUNTNOSHOW_FLG = CommDefine__c.getOrgDefaults().AccountNoSetAmountWhenNoShow__c == null ? false : CommDefine__c.getOrgDefaults().AccountNoSetAmountWhenNoShow__c;
    // 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH BEGIN
    public static final String APPOTION_ACCOUNTNOSHOW_1 = '1'; // 会計の非表示の合計金額設定不要（デフォルト値）
	public static final String APPOTION_ACCOUNTNOSHOW_2 = '2'; // 非表示后、明细行合计金额不变、上面的合计金额把非表示的商品金额去掉
	// 会計の領収証日付値の自動設定制御モード
	public static final String APPOTION_ACCOUNTNOSHOW_MODE{get{
		String accNoSetAmountWhenNoShowMode = CommDefine__c.getOrgDefaults().AccountNoSetAmountWhenNoShowMode__c;
		if(accNoSetAmountWhenNoShowMode == '1') return APPOTION_ACCOUNTNOSHOW_1; // 会計の非表示の合計金額設定不要
		else if(accNoSetAmountWhenNoShowMode == '2') return APPOTION_ACCOUNTNOSHOW_2; // 非表示后、明细行合计金额不变、上面的合计金额把非表示的商品金额去掉
		else { // 其它 原功能（デフォルト値）
			return ACCOUNT_RECEIPTDATE_1; // 会計の非表示の合計金額設定不要
		}
	}}
    // 2020/01/30 非表示の一括解除、あるいは金額を0円にしない非表示設定の追加 WGCH END
    // 2019/03/31 日帰り時刻を表記 BY zyz BEGIN
    public static final Boolean APPOTION_APPLICATIONFORMTIME_FLG = CommDefine__c.getOrgDefaults().ApplicationFormTimeFlg__c == null ? false : CommDefine__c.getOrgDefaults().ApplicationFormTimeFlg__c;
    // 2019/03/31 日帰り時刻を表記 BY zyz END
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
    public static final Boolean APPOTION_APPLICATIONFORMSHOPLOGO_FLG = CommDefine__c.getOrgDefaults().ApplicationFormShopLogoFlg__c == null ? false : CommDefine__c.getOrgDefaults().ApplicationFormShopLogoFlg__c;
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
    /*************************
    * プラングループ室料関連
    *************************/
    public static String APPOPTION_ROOMPRICE_PRODNAME {get{
    	return CommUtils.isBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c) ? '室料' : CommDefine__c.getOrgDefaults().RoomPriceProdName__c;
    }}
    // 2018/04/03 プランBreakDown明細が室料が存在、かつ室料金額が０円の場合、ラックレートにより、金額設定しない、するフラグ
    // TRUE:設定しない、FALSE：設定する(デフォルト値)
    public static Boolean APPOPTION_ROOMPRICE_NOATSETUPFLG{get{
        return CommDefine__c.getOrgDefaults().ZeroRoomPriceAutoSetupFlg__c;
    }}
	/************************
	* レポート会計書定数取得
	************************/
	// RFMレポート名を取得する
	public static String APPOPTION_CUSTOMER_RANK_REPNM {get{
			return CommDefine__c.getOrgDefaults().CustomerRankKey__c == null ? '$3000 RFMランク別集計' : CommDefine__c.getOrgDefaults().CustomerRankKey__c;
	}}
	public static String APPOPTION_ACCOUNTPDF_FONT_COLOR {get{
			return CommDefine__c.getOrgDefaults().AccountReportFontColor__c == null ? 'gray' : CommDefine__c.getOrgDefaults().AccountReportFontColor__c;
	}}
	// 予定表Excel出力の折り返し文字数
	public static Integer APPOPTION_REPORT_LINE_SIZE{get{
		return CommDefine__c.getOrgDefaults().ReportKScheduleExcelLineSize__c == null ? 30 : CommDefine__c.getOrgDefaults().ReportKScheduleExcelLineSize__c.intValue();
	}}
	// 予定表Excel出力の料理情報出力モード 
	public static String APPOPTION_REPORT_FOOD_MODE{get{
		return CommDefine__c.getOrgDefaults().ReportKScheduleExcelFoodMode__c == null ? '1' : CommDefine__c.getOrgDefaults().ReportKScheduleExcelFoodMode__c;
	}}
	/************************
	* レポートＶＦの抽出条件取得
	************************/
	public static String getKScheduleReportWhere() {
		return CommDefine__c.getOrgDefaults().ReportKScheduleWhere__c == null ? null : CommDefine__c.getOrgDefaults().ReportKScheduleWhere__c;

	}
	/************************
	* 売上統計情報キー
	************************/
	// 売上統計_入湯統計
	public static Set<String> getAmountSumKeyBath1() {
		String keyStr = CommDefine__c.getOrgDefaults().AmountSumKeyBath1__c == null ? '' : CommDefine__c.getOrgDefaults().AmountSumKeyBath1__c;
		// [,]分割で、
		Set<String> keySet = new Set<String>();
		for (String key : keyStr.split(',')) {keySet.add(key);}
		return keySet;
	}
	// 売上統計_入浴統計
	public static Set<String> getAmountSumKeyBath2() {
		String keyStr = CommDefine__c.getOrgDefaults().AmountSumKeyBath2__c == null ? '' : CommDefine__c.getOrgDefaults().AmountSumKeyBath2__c;
		// [,]分割で、
		Set<String> keySet = new Set<String>();
		for (String key : keyStr.split(',')) {keySet.add(key);}
		return keySet;
	}
	// 売上統計_宿泊統計
	public static Set<String> getAmountSumKeyStay() {
		String keyStr = CommDefine__c.getOrgDefaults().AmountSumKeyStay__c == null ? '' : CommDefine__c.getOrgDefaults().AmountSumKeyStay__c;
		// [,]分割で、
		Set<String> keySet = new Set<String>();
		for (String key : keyStr.split(',')) {keySet.add(key);}
		return keySet;
	}
	// 売上統計_昼客室統計
	public static Set<String> getAmountSumKeyNoonStay() {
		String keyStr = CommDefine__c.getOrgDefaults().AmountSumKeyNoonStay__c == null ? '' : CommDefine__c.getOrgDefaults().AmountSumKeyNoonStay__c;
		// [,]分割で、
		Set<String> keySet = new Set<String>();
		for (String key : keyStr.split(',')) {keySet.add(key);}
		return keySet;
	}
	// 売上統計_夕客室統計
	public static Set<String> getAmountSumKeyNightStay() {
		String keyStr = CommDefine__c.getOrgDefaults().AmountSumKeyNightStay__c == null ? '' : CommDefine__c.getOrgDefaults().AmountSumKeyNightStay__c;
		// [,]分割で、
		Set<String> keySet = new Set<String>();
		for (String key : keyStr.split(',')) {keySet.add(key);}
		return keySet;
	}
	
	/************************
	* 予約人数初期値定義情報取得
	************************/
	public static Integer getBookingMansDef() {
		return CommDefine__c.getOrgDefaults().BookingMansDef__c == null ? 0 : CommDefine__c.getOrgDefaults().BookingMansDef__c.intValue();
	}
	public static Integer getBookingFemailsDef() {
		return CommDefine__c.getOrgDefaults().BookingFemailsDef__c == null ? 0 : CommDefine__c.getOrgDefaults().BookingFemailsDef__c.intValue();
	}
	public static Integer getBookingChildrenDef() {
		return CommDefine__c.getOrgDefaults().BookingChildrenDef__c == null ? 0 : CommDefine__c.getOrgDefaults().BookingChildrenDef__c.intValue();
	}
	public static Integer getBookingPeopleDef() {
		return getBookingMansDef() + getBookingFemailsDef() + getBookingChildrenDef();
	}
	
    // 商品単価定義区分
    // 1:税込、サービス料抜き
    public static final Integer APPOPTION_UTP_DEF_KB_OP1 = 1;
    // 2:税込、サービス料込
    public static final Integer APPOPTION_UTP_DEF_KB_OP2 = 2;
    // 3:税抜、サービス料抜き
    public static final Integer APPOPTION_UTP_DEF_KB_OP3 = 3;
    // 4:税抜、サービス料込
    public static final Integer APPOPTION_UTP_DEF_KB_OP4 = 4;
    public static Integer APPOPTION_UTP_DEF_KB{get{ 
    	return CommDefine__c.getInstance().UnitPriceDefKb__c == null ? APPOPTION_UTP_DEF_KB_OP2 : CommDefine__c.getInstance().UnitPriceDefKb__c.intValue();
    }}
    // 1:単価（税抜き）ベースで商品合計計算を行う
    public static Integer APPOPTION_UTP_DEF_KB_TY1 = 1;
    // 2:単価（税込）ベースで商品合計計算を行う
    public static Integer APPOPTION_UTP_DEF_KB_TY2 = 2;
    /*************************
    * 予約ポップ、残室限界値の設定、残室数はこの数により以下の場合、予約できないよう、制限を行う
    *************************/
    public static final Integer VACANT_MIN_ROOMS = 5;

    /*************************
    * バッチ処理ステータス定数
    *************************/
    // 0:未処理
    public static final String BAT_STATUS_NOSTART = '0';
    // 1:処理待
    //public static final String BAT_STATUS_WAIT = '1';
    // 2:処理中
    //public static final String BAT_STATUS_PROCESSING = '2';
    // 3:処理済(成功)
    public static final String BAT_STATUS_PROCESS_OK = '3';
    // 9:処理済(失敗)
    public static final String BAT_STATUS_PROCESS_NG = '9';

    /*************************
    * 部屋のタイプリスト：客室/広間/レストラン/その他/Time/宴会場
    *************************/
    public static final String ROOM_UseOfType_Guest = '客室';
	public static final String ROOM_UseOfType_PTY='宴会場';
	public static final String ROOM_UseOfType_Fiction='架空'; 
    /*************************
    * 部屋ステータス
    *************************/
    public static final String ROOM_ST_TYPE_BED = '故障';
    public static final String ROOM_ST_TYPE_BED_FIN = '修理済';
    public static final String ROOM_ST_TYPE_CLS = '清掃';
    
    /*************************
    * プラン関連定数
    *************************/ 
    //プラン名は空白です_
    public static final String PLAN_BLANK_NAME_PREFIX = Label.CONST_012_0481;
    
    /************************
    * 会計支払関連定数
    *************************/
    public static final String TTEND_EVENTSOURCE_BATCH = 'バッチ';
    /*************************
    * 仮のお客様情報を作成のKEY(ID__c)
    **************************/
    public static final String CONTACT_TEMP_ID = 'JINYA99999';
    /*************************
    * 連携結果関連定数
    *************************/   
	public static final String COOP_FUNTYPE_LEADIMP = '予約取込';
	public static final String COOP_FUNTYPE_STOCK = '在庫調整';
	public static final String COOP_FUNTYPE_OPPLOG = '操作ログ';
	public static final String COOP_FUNTYPE_EMAIL = 'メール取込';
	// 連携結果
	public static final String COOP_FUNTYPE_LEADIMP_NG = '予約取込NG';
	public static final String COOP_FUNTYPE_LEADIMP_WAIT = '予約取込待ち';
	public static final String COOP_FUNTYPE_LEADIMP_OK = '予約取込完了';
	public static final String COOP_FUNTYPE_STOCK_SYNCINIT = '未連携';
	public static final String COOP_FUNTYPE_STOCK_SYNCNG = '連携NG';
	public static final String COOP_FUNTYPE_STOCK_SYNCOUT = '連携不要';
	/************************
	* プラン自動添加なし標識用文字列キー
	*************************/
	// PlanDetailSyncInfo__c(見積明細、会計明細に該当フラグは項目に設定されている場合、該当プランのプラン明細は自動展開設定を行わない)
	public static final String CONST_PLANITEM_NOEXPAND = '-';
	
	/************************
	* チャターグループ名関連定数取得
	* 
	*************************/
	public static final String Coop_ChatterGroupNameType = '1';	// 連携結果通知用チャターグループ名種別
	public static final String Call_ChatterGroupNameType = '2';	// CTI機能通知用チャターグループ名種別
	public static final String Work_ChatterGroupNameType = '3'; // 勤怠修正グループ名定義
	public static final String Pcas_ChatterGroupNameType = '4'; // PCA連携出力グループ名定義
	public static final String PosI_ChatterGroupNameType = '5'; // POSインポートグループ名定義
	public static final String IOT_ChatterGroupNameType = '6'; // IOT通知グループ名定義
	public static final String KSCH_ChatterGroupNameType = '7';	// 予定表通知グループ名定義
	public static final String CO_ChatterGroupNameType = '8';	// 予約チェックアウト通知グループ名定義
	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
	public static final String TIER_ChatterGroupNameType = '9';	// ラックレート変更通知グループ名定義
	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz BEGIN
	public static final String WORK_ChatterCheckType = '10';	// 勤怠チェック通知グループ名定義
	// 2019/02/28 シフトで入っている時間の範囲しか勤怠打刻を認めない機能はある BY zyz END
	// 2019/05/10 指定期間を超える支払明細に対して、消込されない場合、エラーリストをChatterへポストする WSQ BEGIN
	public static final String PAY_ChatterCheckType = '11';	// 入金消込チェック通知グループ名定義
	// 2019/05/10 指定期間を超える支払明細に対して、消込されない場合、エラーリストをChatterへポストする WSQ END
	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
	public static final String CI_ChatterGroupNameType = '12';	// 予約チェックイン通知グループ名定義
	// 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
	public static List<String> GetChatterGroupNameByCode(String code) {
		if (CommUtils.isBlank(code)) code = Coop_ChatterGroupNameType;
		String chatterGroupNames = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().ChatterGroupName__c);
		if (CommUtils.isBlank(chatterGroupNames)) return new List<String>();
		// String[1:GP1,GP2][2:GP3,GP2]
		String[] chatterGroupNameTypes = chatterGroupNames.split(';');	// 連携結果、CTIなど別々通知先のグループ名定義　
		//map<string, List<String>> codeNamesMap = new map<String, list<string>>();
		List<String> chatterSendList = new List<String>();
		for (String chatterCdGps : chatterGroupNameTypes) {
			if (CommUtils.isBlank(chatterCdGps)) continue;
			// 1:GP1,GP2->[1][GP1,GP2] OR [GP1,GP2] -> [GP1,GP2] 
			String[] gps = chatterCdGps.split(':');
			String typeCd = Coop_ChatterGroupNameType;
			if (gps.size() > 1) typeCd = gps[0];
			if (code == typeCd) {
				String[] chatterGpNms = gps.size() > 1 ? gps[1].split(',') : gps[0].split(','); 
				chatterSendList.addAll(chatterGpNms);
			}
		}
		return chatterSendList;
	}
	// チャターポスト簡易メッセージフラグ
	public static final Boolean ChatterGroupSimpleMsgFlg = (CommDefine__c.getOrgDefaults().ChatterGroupSimpleMsgFlg__c == null ? false : CommDefine__c.getOrgDefaults().ChatterGroupSimpleMsgFlg__c);
	/************************
	* プラン自動添加なし標識用文字列キー
	*************************/
	public enum BI_PROCESS_TYPE{TL,TA,TR,JR,SFDC,WS}
	/************************
	* 六輝表示　非表示
	*************************/
	public static Boolean IsOrgRokuyoIsNoShow(){
		return  CommDefine__c.getOrgDefaults().RokuyoIsNoShow__c != true;
	}
	/************************
	* インポート機能の識別タイプキー
	*************************/
	public static final String SYNC_PROCESS_TYPE_TL = 'TL';
	public static final String SYNC_PROCESS_TYPE_TA = 'TA';
	public static final String SYNC_PROCESS_TYPE_TR = 'TR';
	public static final String SYNC_PROCESS_TYPE_JR = 'JR';
	/************************
	* 店舗ごとの予約・会計権限
	*************************/
	public static final Boolean ShopEditAuthCheckFlg =  (CommDefine__c.getOrgDefaults().AccountEditAuthCheckFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountEditAuthCheckFlg__c);
    /************************
    * チェックアウト通知関連共通定義
    *************************/
    public static final Boolean NOTIFY_CO_IS_SPEECHALERT = CommDefine__c.getOrgDefaults().CoSpeechAlertFlg__c == null ? false : CommDefine__c.getOrgDefaults().CoSpeechAlertFlg__c;
	public static final Boolean NOTIFY_CO_IS_CHATTERPOST = CommDefine__c.getOrgDefaults().CoMessageToChatterFlg__c == null ? false : CommDefine__c.getOrgDefaults().CoMessageToChatterFlg__c;
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz BEGIN
    /************************
    * チェックイン通知関連共通定義
    *************************/
    public static final Boolean NOTIFY_CI_IS_SPEECHALERT = CommDefine__c.getOrgDefaults().CiSpeechAlertFlg__c == null ? false : CommDefine__c.getOrgDefaults().CiSpeechAlertFlg__c;
	public static final Boolean NOTIFY_CI_IS_CHATTERPOST = CommDefine__c.getOrgDefaults().CiMessageToChatterFlg__c == null ? false : CommDefine__c.getOrgDefaults().CiMessageToChatterFlg__c;
    // 2019/10/15 チェックイン時に自動音声で通知 BY zyz END
    /************************
    * Labelメッセージ関連処理キー
    *************************/
    public static final String LABEL_MSG_REPKEY1 = 'XXXXXX';
    /************************
    * 在庫管理関連定数
    *************************/
    public static Boolean STOCK_CREATE_NOFITYDATA_FLG{get{
        return (CommDefine__c.getOrgDefaults().StockDataCreateFlg__c == null ? true : CommDefine__c.getOrgDefaults().StockDataCreateFlg__c);
    }}
    /************************
    * 仕入明細表示・非表示
    *************************/
    public static Boolean PURCHASE_DETAIL_FLG {get{
    	return CommDefine__c.getOrgDefaults().PurchaseDetailIsShowFlg__c == null ? false : CommDefine__c.getOrgDefaults().PurchaseDetailIsShowFlg__c;
    }}
    /************************
    * 仕入明細、会計明細、注文（受注）に従って、商品単位に在庫管理する・しないフラグ 
    * TRUE：該当機能が有効 
    * FALSE:該当機能が無効（デフォルト）
    *************************/
    public static Boolean STOCKSYNC_ISACTIVE_FLG {get{
    	return CommDefine__c.getOrgDefaults().StockSyncIsActiveFlg__c == null ? false : CommDefine__c.getOrgDefaults().StockSyncIsActiveFlg__c;
    }}
    /************************
    * ルームインジケータ関連定数
    *************************/
    // ルームインジケータ表示最大文字数
    public static final Integer ROOM_INFO_MAX_SIZE = CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c == null ? 4 : (CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue() < 4 ? 4 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoMaxLength__c.intValue());
	// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
	// 販売
	public static final String STOCK_SET_SALE = '1';
	// 止
	public static final String STOCK_SET_STOP = '2';
	// 2018/12/15 在庫調整と販売状態管理 by zy END
    /************************
    * 注文関連定数
    *************************/
    // 注文ステータス
    // キャンセル
    public static final String ORDER_STATUS_CANCEL = 'キャンセル';
    // 2018/12/30 部屋自動割当機能AI対応 by zy BEGIN
    // 部屋自動割当機能制御フラグ
    public static boolean  ROOM_ASSIGN_FLG{get{
    	return CommDefine__c.getOrgDefaults().QQNRoomAssignFlag__c == null ? false : CommDefine__c.getOrgDefaults().QQNRoomAssignFlag__c;
    }}
    // 2018/12/30 部屋自動割当機能AI対応 by zy END
    // 2019/04/15 宿屋EXPOの棚卸について by zy BEGIN
    // 棚卸し機能を使用する・使用しないフラグ
    public static boolean  PROD_INVENTORY_FLG{get{
        return CommDefine__c.getOrgDefaults().InventorySaveFlg__c == null ? false : CommDefine__c.getOrgDefaults().InventorySaveFlg__c;
    }}
    // 2019/04/15 宿屋EXPOの棚卸について by zy END
    // 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy BEGIN
    public static boolean  BILL_ALLLEADPDF_FLG{get{
        return CommDefine__c.getOrgDefaults().BillPdfFlag__c == null ? false : CommDefine__c.getOrgDefaults().BillPdfFlag__c;
    }}
    // 2019/04/30 チェックインをかけなくても請求書が１枚に印刷されるようにご希望です by zy END
    // 2019/05/10 SF本番のURL ADD WSQ BEGIN
    public static final String SF_PROR_BASEURL='https://login.salesforce.com';
    // 2019/05/10 SF本番のURL ADD WSQ BEGIN
    // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy BEGIN
    public static boolean LEAD_AUTO_CREATE_BOOKINGEST{get{
        return CommDefine__c.getOrgDefaults().AutoCreateBookingEstFlg__c == null ? false : CommDefine__c.getOrgDefaults().AutoCreateBookingEstFlg__c;}set;}
    // 2019/06/14 ご予約内にある「プラン」という項目を入力すると予約見積明細にもこのプランが登録されますが、こちらを登録しない設定にしたいです。 by zy END
    public static boolean AUTO_ALARM_FLG{get{
        return CommDefine__c.getOrgDefaults().AutoAlarmFlg__c == null ? false : CommDefine__c.getOrgDefaults().AutoAlarmFlg__c;}set;}
    // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz BEGIN
	public static Boolean APPOTION_OUT_GROUPCONFIRM {get{
		return CommDefine__c.getOrgDefaults().RoomIndicatorGpOIMsgIsShow__c == null ? false : CommDefine__c.getOrgDefaults().RoomIndicatorGpOIMsgIsShow__c;
	}}
    // 2019/07/15 多泊の場合、外出の場合、多泊の予約に同じ状態を更新する BY zyz END
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
	public static String READ_ONLY_MODE_ROOMINDICATOR = 'ROOM';
    public static String READ_ONLY_MODE_ROOMSCHEDULE = 'TIMETABLE';
    public static String READ_ONLY_MODE_TASK = 'TASK';
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	// 2019/08/15 会計書1枚目に合計が出る対応 BY zyz BEGIN
    public static String APPOPTION_ACCOUNTPDF_POSITION {get{
    	return CommDefine__c.getOrgDefaults().AccountSetTotalPosition__c == null ? '1' : CommDefine__c.getOrgDefaults().AccountSetTotalPosition__c;
    }}
    // 2019/08/15 会計書1枚目に合計が出る対応 BY zyz END
    // 2019/09/23 ご予約の請求先自動設定フラグ BY WSQ
    public static boolean  LEAD_REFACCOUNT_AUTOSETUP_FLG{get{
        return CommDefine__c.getOrgDefaults().LeadRefAccountAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().LeadRefAccountAutoSetupFlg__c;
    }}
    // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz BEGIN
    public static boolean  ACCOUNT_PRODNM_FLG{get{
        return CommDefine__c.getOrgDefaults().AccountProdNmReturnFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccountProdNmReturnFlg__c;
    }}
    // 2019/09/30 請求書で印刷した際に、商品名が折り返し出力できるように改善対応 zyz END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public static boolean  RESPECT_ISSHOW_FLG{get{
        return CommDefine__c.getOrgDefaults().RespectIsShowFlg__c == null ? true : CommDefine__c.getOrgDefaults().RespectIsShowFlg__c;
    }}
    // 敬称リストを返却する
    public static List<Selectoption> RESPECT_OPTIONS{get{
    	List<Selectoption> mrTypeLst = new List<Selectoption>();
		Schema.DescribeFieldResult fieldResult = Lead__c.RespectLst__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   	for( Schema.PicklistEntry f : ple) {
           mrTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   	}
	   	return mrTypeLst;
    }}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz BEGIN
    public static boolean LEAD_RECEIPTDATE_FLG{get{
        return CommDefine__c.getOrgDefaults().BookingReceiptDateDefaultInfo__c == null ? false : CommDefine__c.getOrgDefaults().BookingReceiptDateDefaultInfo__c;
    }}
    // 2019/10/30 見積の発行日付のデフォルト値を制御フラグ BY zyz END
	// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
	public static boolean BOOKING_FLEX_SEL_ROOM_FLG{get{
		return CommDefine__c.getOrgDefaults().BookingAppSwitchCode__c == '4';
	}}
	// 2019/11/15 一括予約画面の部屋直接選択 by zy END
	// 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz BEGIN
    public static boolean APPOTION_TITLE_NAME_FLG{get{return CommDefine__c.getOrgDefaults().ReportPdfTitleAutoBreakFlg__c == null ? false : CommDefine__c.getOrgDefaults().ReportPdfTitleAutoBreakFlg__c;}}
	// 2020/01/30 宛名が一定文字数を超えた場合に自動改行する BY zyz END
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    public static boolean APPOTION_CARREGISTER_LOGO_FLG{get{
    	return (
    		// コードが３の場合、ログ出力がないため、店舗選択機能不要
    		(APPOTION_CARREGISTSWITCH_DIV_CODE =='3') ? false :
    		(CommDefine__c.getOrgDefaults().CashRegisterLogo__c == null ? false : CommDefine__c.getOrgDefaults().CashRegisterLogo__c)
    		);
    }}
	// 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	// 2020/03/31 会計ロック機能 by zy BEGIN
	public final static String RSVACCOUNT_TYPE_INVALID = '0';	// 機能無効
	public final static String RSVACCOUNT_TYPE_LAST = '1';	// 最終泊ロック
	public final static String RSVACCOUNT_TYPE_EVERY = '2';	// 毎泊ロック
	public static String RSVACCOUNT_LOCK_TYPE {get{
		return CommDefine__c.getOrgDefaults().RsvLockType__c == null ? RSVACCOUNT_TYPE_INVALID : CommDefine__c.getOrgDefaults().RsvLockType__c;
    }}
	// 2020/03/31 会計ロック機能 by zy END
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN	
	public boolean APPOTION_BASE_PLAN_FLG{get{return CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c;}}
	// 2020/04/03 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	// オプション商品設定フラグ
	public final static String OPTION_MODE_OFF = '0';	// 機能無効
	public final static String OPTION_MODE_ON = '1';	// 機能有効
	public static String OPTION_MODE {get{
		return CommDefine__c.getOrgDefaults().OptionPlanSetMode__c == null ? OPTION_MODE_OFF : CommDefine__c.getOrgDefaults().OptionPlanSetMode__c;
    }}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
    public static boolean RACKRATE_PLAN_FLG{get{
        return false;
	}}
	// 2021/04/30 新規追加
	// 予約ポップラックレート設定[プラン]有効フラグ
	public static boolean RACKRATE_BASEPLAN_FLG {get{ 
		return CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c;
	}}
	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
	// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz BEGIN
    public static boolean LEAD_BOOKING_LAYOUT_FLG{get{
        String layoutCode = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().BookingReportLayoutCode__c); 
        return (layoutCode == '1');
    }}
	// 2020/06/30 見積書のレイアウトは請求書のレイアウトに統一に改善対応 BY zyz END
	// 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH BEGIN
	public final static String SHOP_DEFCODESET_MODE_0 = '0';	// 機能無効
	public final static String SHOP_DEFCODESET_MODE_1 = '1';	// 予約の部屋タイプに紐づいた店舗ロゴを表示する
	public final static String SHOP_DEFCODESET_MODE_2 = '2';	// ユーザの所属店舗ロゴを表示する
	public static String SHOP_DEFCODESET_MODE {get{
		return CommDefine__c.getOrgDefaults().ShopDefaultCodeSetMode__c == null ? SHOP_DEFCODESET_MODE_0 : CommDefine__c.getOrgDefaults().ShopDefaultCodeSetMode__c;
    }}
    // 2020/06/30 ユーザの所属店舗かご予約の部屋タイプに紐づく店舗対応 WGCH END
    // 2021/03/05 50001エラー修正 by zy BEGIN
    public  static Integer CLEAN_KEEP_BEFORE_DAYLEN{get{
    	return CommDefine__c.getOrgDefaults().NoCleanKeepDays__c == null ? 15 : CommUtils.nullToIntZero(CommDefine__c.getOrgDefaults().NoCleanKeepDays__c);
    }}
    // 2021/03/05 50001エラー修正 by zy END
    // 2021/04/30 ラックレート(ベースプラン別)機能有効 BY zyz BEGIN
    // TODO:追加开关
	public static Boolean RACKRATE_BASEPLAN {get{
		return CommDefine__c.getOrgDefaults().RaceRateImportByBasePlanFlg__c == null ? false : CommDefine__c.getOrgDefaults().RaceRateImportByBasePlanFlg__c;
    }}
    // 2021/04/30 ラックレート(ベースプラン別)機能有効 BY zyz END
    // 2021/06/31 #JP10243　対応　by zy BEGIN
    public static final String REALAGT_LAYOUT_ORG = '1';
    public static final String REALAGT_LAYOUT_SALE = '2';
    public static String REAL_AGT_LAYOUTPAGE_MODE {get{
		return CommDefine__c.getOrgDefaults().RoomTypeRealAgtPageMode__c == null ? REALAGT_LAYOUT_ORG : CommDefine__c.getOrgDefaults().RoomTypeRealAgtPageMode__c;
    }}
	// 2021/06/31 #JP10243　対応　by zy END
}