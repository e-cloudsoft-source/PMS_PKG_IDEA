/**
* 予約ポップ：宿泊予約データ登録、在庫情報照会
* 2013/07/01 支店機能追加
* 2013/12/13 リアルＡＧＴ機能追加
* 2014/01/19 料金情報機能
* 2014/02/07 料金機能改善(料金表ボタン日、祝い日表示)
* 2014/02/16 休館機能設定
* 2014/05/19 プラングループ機能追加
* 2014/05/31 全館賃切設定機能追加
* 2014/06/10 プラングループ室料自動差し込み機能追加
* 2015/08/05 客室の販売数と残室数改善（部屋タイプの「集計対象外」をTRUEすると、集計対象外になる
* 2015/09/01 多店舗機能対応
* 2015/09/14 TL2WAY機能対応、TL側の販売先単位の残室数照会用画面
* 2015/10/02 TL2WAY残室照会機能の影響、プランの室料金自動設定機能は対応
* 2015/10/27 連絡事項共通化
* 2016/03/29 Tier機能はダミデータは取得表示対象外の対応
* 2016/04/22 六輝情報表示、非表示制御ロジック変更（日本語のみ表示ー＞共通定義により制御）
* 2016/08/01 リアルAGTの残室計算ロジック不具合修正（子取引先から利用室数が計算ロジック不正修正）
* 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応
* 2019/04/30 予約ポップの在庫設定(AGT)の変更機能
* 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定
* 2019/07/30 軽減税率機能対応
* 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能
* 2020/07/30 入湯税の自動入力機能について改善
* 2020/11/30 リアルAGT増返室ボタン機能新規追加
* 2021/03/16 最大部屋タイプ数表示制限機能追加
* 2021/05/31 年、月を変えた後に送信ボタンで更新がかかる機能対応
**/
public with sharing class RoomTypeInventory {
	// ご予約へ編集権限あり、なし
	public boolean isCanUpdateLead{get{return CommSecurityUtils.isCanUpdateLead();}}
	// 2017/01/26 連絡事項表示、非表示制御フラグ
	public boolean isShowMessageCompFlg{get{return !(CommDefine__c.getOrgDefaults().MessageShopCodeDivFlg__c && CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);}}
	// 画面レイアウト定数定義
	private static final String CONST_PAGELAYOUT_STOCK = '残室数';
	private static final String CONST_PAGELAYOUT_RAKURETO = 'ラックレート';
	private static final String CONST_PAGELAYOUT_TIERLST = 'ラックレート設定';
	private static final String CONST_PAGELAYOUT_TLSTATUS = '残室数[AGT]';
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
	private static final String CONST_PAGELAYOUT_BASEPLAN = 'ラックレート設定[プラン]';
	// baseplan数据对应数据是否为贩卖状态
	public transient Map<Date, Boolean> tierButtonInfoMap{get; private set;}
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
	// 画面入力用
	public Lead__c newLead{get;set;}			// 新規予約登録情報格納変数
	public Contact newContact{get;set;}			// 新規お客様情報を格納変数
	public RealAGT__c workSobj{get;set;}
	// 処理日付
	private Date processDay;
	// 処理年
	public Integer thisYear{get; set;}
	// 処理月
	public Integer thisMonth{get; set;}
	// 泊数
	public Integer staysNums{get;set;}
	// 部屋数
	public Integer bookingRooms{get;set;}
	// 部屋名
	public String roomName{get;set;}
	// お客様名
	public String contactName{get;set;}
	// 処理月・日数
	private Integer daysInMonth;
	// 表示の開始日
	private Date startDate;
	// 画面上に表示される予約一覧のヘッダー部
	public transient List<dispHeader> dispHeaders{get;set;}
	// 画面上に表示される予約一覧のデータ部
//	public List<dispRecord> dispRecords{get;set;}
	public transient Map<Id, dispRecord> dispRecordMap{get; private set;}
	// Hidden項目・到着日
	public String startDays{get;set;}
	// Hidden項目・部屋タイプ
	public Id roomType{get;set;}
	// 照会用レポートID情報を維持する
	public Id reportId{get; private set;}
	// 会計支払方法
	public List<Selectoption> paymentTypeLst{get; private set;}
	// 部屋タイプ表示リスト<SEQ順番>
	public transient List<TypeOfRooms__c> roomTypeLst{get; private set;}
	// 年度選択リスト[今日から前１０～未来10年]
	public List<SelectOption> yearList {get; private set;}
    // 各日に在庫部屋合計値
    //public Map<Integer, Decimal> sumRoomsMap{get; private set;}
    // 販売部屋合計値
    public transient Map<Integer, Decimal> usedRoomsMap{get; private set;}
    // 故障部屋数合計値
    public transient Map<Integer, Decimal> badRoomsMap{get; private set;}
    // 各日にE/B在庫情報合計値
    public transient Map<Integer, Decimal> sumEbRoomMap{get; private set;}
    // 2013/12/13 ＡＧＴへ提供部屋数
    // 販売部屋合計値「AGT格納」<AGTID+'_'+ROOMTYPEID, 部屋数>
    public transient Map<Id, TrvaleRecord> dispAgtRecordMap{get; private set;}
    // 販売部屋合計値「AGT格納」
    public transient Map<Integer, Decimal> usedAgtRoomsMap{get; private set;}
    // 販売部屋提供数「AGT格納」
    public transient Map<Integer, Decimal> mstAgtRoomsMap{get; private set;}
    // 2021/06/31 #JP10243　対応　by zy BEGIN
    // 販売部屋リアル「ＡＧＴ残室」
    public transient Map<Integer, Decimal> lastAgtRoomsMap{get; private set;}
    // 2021/06/31 #JP10243　対応　by zy END
    // 20120920元在庫数合計値格納する
    public Decimal sumDayMaxRooms{get; private set;}
    // Header色制御
    public transient Map<Integer, String> headerColorMap{get; private set;}
    // 詳細列のステータス制御変数定義
    public transient Map<Date, colStatus> colStatusMap{get; private set;}
    // 合計残室最小限制御数
    public Decimal minRooms{get; private set;}
    // E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}
	public Boolean isHaveSeminar{get; private set;}
	public Boolean isHaveRoom{get; private set;}
	// 六輝表示がどうか判断用 TRUE:表示
	public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
	// 2014/01/20 ADD
	// 人数リスト初期化設定
	public List<Selectoption> personsLst{get;set;}
	public List<Selectoption> tiersLst{get;set;}	// Tier List
	public List<Selectoption> planLst{get;set;}		// Plan List
	// ベースプラン情報の金額情報を格納する
	private Map<Id, Plan__c> basePlanPriceMap;
	public String planName{get; set;}				// 画面からプランを選べる、該当プランの名を格納する
	//2016/08/23 BEGIN
	public String planAccId{get;set;}
	public String servicePriceIncTax{get;set;}
	public String specialTax{get;set;}
	public String taxRate{get;set;}
	public boolean hadZeroFlag{get;set;}
	public String TaxNumberFormat{get{return CommUtils.getTaxNumberFormat();}}
	private map<String,AccountMaster__c> planToAccIdMap;
	private Set<Id> hadZeroPlanSet;
	//2016/08/23 END
	public Decimal planPrice{get; set;}				// 画面からプランを選べる、該当プランの総金額を格納する
	//public Decimal planRoomPrice{get; set;}			// 画面指定する室料情報
	public String actionModeType{get; set;}			// 残室数・ラクレット・ベースプランリスト・残室数（AGT)[TL]
	public String actionModeType_TlSub{get;set;}	// 残室数（AGT）の場合、子画面切替制御フラグ
	public String CONST_PAGELAYOUT_TLSTATUS_ROOMTYPE{get{return '1';}}	// 残室数（AGT)「TL」部屋タイプ別表示
	public String CONST_PAGELAYOUT_TLSTATUS_NETSALES{get{return '2';}}	// 残室数（AGT)「TL」販売先別表示
	// 料金情報格納用
	public transient Map<Id, Map<Date, Decimal>> raceRatePriceMap{get; private set;}
	// 部屋タイプ、日別のTIER情報を格納する
	public transient Map<Integer, String> tierHeaderInfoMap{get; private set;}
    // 休館情報を格納する
    //public transient Map<Integer,Boolean> restInfoMap{get; private set;}
    public transient Map<Integer,String> restInfoMap{get; private set;}
    // 2015/12/17 FIX BEGIN
    public transient Map<Integer,String> colorInfoMap{get; private set;}
    // 2015/12/17 FIX END
	// 2016/12/14 zyz CTI予約 BEGIN
	public String ctiContactInf {get; set;}
	// 2016/12/14 zyz CTI予約 END
    // 2016/08/03 多通貨対応 BEGIN
    public String currencyLabel {get{
    	String locCurrency = UserUtil.getDefaultCurrency();
    	if (locCurrency == 'JPY') return Label.MSG_003_0045 + ' ' +Label.MSG_003_004501;
    	else return Label.MSG_003_0045 + ' ' +locCurrency;
    }}
    // 2016/08/03 多通貨対応 END
	// 室料登録用商品情報を維持する
	private AccountMaster__c roomPriceInfo = null;
	// ラックレートレポート
	public Id raceRateReportId{get; private set;}
	// Calendar情報格納用
	public CalendarExtend calExt{get; private set;}
	// 開始日表示モード："1":毎月の１日から一月間データを表示する（Default値）/ "2":当日から一月間データを表示する
	private static final Boolean CONST_SHOW_START_TODAY = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomTypeStartDateMode__c) == '2' ? true :false;
	// 予約ポップの年月条件表示場所:"1":予約ポップ画面の右上に表示する (Default値) / "2":予約ポップ画面の左上に表示する
	public Boolean yearMonthRightPosition{get{ return (!CONST_SHOW_START_TODAY);}}
	// 2018/10/16 予約ポップの「月」の表示箇所を移動対応 zyz 
	public Boolean yearMonthLeftFlg{get{return CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomTypeDatePosition__c) == '2';}}
	// 2021/05/31 年、月を変えた後に送信ボタンで更新がかかる機能対応 WSQ BEGIN
	// TODO:共通定義パラメータを追加必要
	public Boolean yearMonthChangeEventByBtn{get{return CommDefine__c.getOrgDefaults().RoomTypeDateEventFlg__c == true;}}
	// 2021/05/31 年、月を変えた後に送信ボタンで更新がかかる機能対応 WSQ END
	// コンストラクタ
	public UserUtil.UserShopInfo userInf;
	// 販売ステータス[停止]
	public static final String SALES_STATUS_STOP = '2';
    // 2015/10/27 連絡事項共通化 BEGIN
    public String processDtStr{get{
    	return DateTime.newInstance(thisYear, thisMonth, 1).format('yyyyMM');
    }}
    // 2015/10/27 連絡事項共通化 END
    public boolean orgPopWindowFlag{get;private set;}
    // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
    public String planSyncInfo{get;private set;}
	// プラン明細map
	private map<String,List<PlanDetail__c>> planDetailMap;  
    // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
    // 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
    public Boolean isStockSyncIsMode{ get{ return (StockChangeHelpUtils.isStockSyncIsMode == StockChangeHelpUtils.STOCK_SYNC_MODE_0);} set;}
    // 2020/05/29 在庫計算ロジック改修 WGCH END
    // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
    private Integer CONST_MAX_ROOMTYPE = 50;
    // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
	public RoomTypeInventory() {
		// 2018/07/27 宿泊税計算 WGCH BEGIN
		hotelInfoJson = JSON.serialize(new HotelTaxDefineInfo());
		// 2018/07/27 宿泊税計算 WGCH END
		orgPopWindowFlag = false;
		userInf = UserUtil.CurrentUserInfo;
	   List<Report> rptLst = [Select Id, Name From Report where Name = :CommConst.APPOPTION_ROOMTYPE_REPNM];
	   if (!rptLst.isEmpty()) reportId = rptLst[0].Id;
	   List<Report> raceRateLst = [Select Id, Name From Report where Name = :CommConst.APPOPTION_RACERATE_REPNM];
	   if (!raceRateLst.isEmpty()) raceRateReportId = raceRateLst[0].Id;
	   // 20120920 ADD
       minRooms = CommConst.VACANT_MIN_ROOMS;
	   // 支払方法リスト初期化する[2012/08/22追加：予約から会計に自動作成する場合、自動的に支払側の支払データを作成する]
	   paymentTypeLst = new List<Selectoption>();
	   // 2016/08/15 見積明細登録できる機能対応 BEGIN
	   // プランコード->会計商品情報格納
	   planToAccIdMap = new Map<String,AccountMaster__c>();
	   // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
	   planDetailMap = new map<String,List<PlanDetail__c>>();
	   // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
	   // 室料＝０のプランIDリスト
	   hadZeroPlanSet = new Set<id>();
	   // 2016/08/15 見積明細登録できる機能対応 END
	   Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   }
	   // 2014/01/19 ADD
	   // 2015/09/18 DELETE
	   //isRaceRateFlg = false;	// 料金情報は初期非表示に設定する
	   persons = '2';		// TODO:Default人数は設定が必要
	   personsLst = new List<Selectoption>();
	   fieldResult = RackRateTable__c.Persons__c.getDescribe();
	   ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
           personsLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   }
	   tiersLst = new List<Selectoption>();
	   fieldResult = RackRateTable__c.Tier__c.getDescribe();
	   ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
           tiersLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   }
	   
	   // 2015/09/14 EDIT BEGIN ****************
	   //actionModeType = CONST_PAGELAYOUT_STOCK;
       // Cookieからレイアウトモードを取得する
	   CookieInf cookInf = getCookieInf();
	   // 画面モード初期値を設定する
       actionModeType = CommUtils.isBlank(cookInf.viewMode) ? CONST_PAGELAYOUT_STOCK : cookInf.viewMode;
       // 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
       if (actionModeType == CONST_PAGELAYOUT_STOCKSET && !isStockFunFlg) actionModeType = CONST_PAGELAYOUT_STOCK;
       // 2018/12/15 在庫調整と販売状態管理 by zy END
       actionModeType_TlSub = CommUtils.isBlank(cookInf.viewModeSub1) ? CONST_PAGELAYOUT_TLSTATUS_ROOMTYPE : cookInf.viewModeSub1;
       // 2015/09/14 EDIT END  ****************
       
       // ベースプラン情報を初期化する
	   planLst = new List<Selectoption>();
	   // 定数追加
	   //残室数
	   planLst.add(new Selectoption(CONST_PAGELAYOUT_STOCK, Label.CONST_003_0120));
	   //ラックレート
	   planLst.add(new Selectoption(CONST_PAGELAYOUT_RAKURETO, Label.CONST_003_0121));
	   // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
	   //ラックレート設定
	   planLst.add(new Selectoption(CONST_PAGELAYOUT_TIERLST, Label.CONST_003_0121_01));
	   // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
	   // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
	   if(isBasePlanLayputFlg) planLst.add(new Selectoption(CONST_PAGELAYOUT_BASEPLAN, CONST_PAGELAYOUT_BASEPLAN));
	   // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
	   // 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
	   if (isStockFunFlg) planLst.add(new Selectoption(CONST_PAGELAYOUT_STOCKSET, CONST_PAGELAYOUT_STOCKSET));
	   // 2018/12/15 在庫調整と販売状態管理 by zy END
	   // 2015/09/14 EDIT BEGIN
	   if (TL_ServiceConfigHelp.tlSyncIsOpen() || TA_ServiceConfigHelp.taSyncIsOpen() ) {
	   //残室数[AGT]
	   planLst.add(new Selectoption(CONST_PAGELAYOUT_TLSTATUS, Label.CONST_003_0122));
	   }
	   // 2015/09/14 EDIT END
	   // 室料自動設定用会計商品名を取得する
   	   String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
   	   // ベースプラン情報格納する
	   basePlanPriceMap = new Map<Id, Plan__c>();
	   // 2014/05/27 ベースプラン一覧を取得する
	   List<Plan__c> basePlans = [select id, Name,Price__c,PlanNo__c,ServiceRate__c,JmstRef__r.TaxRate__c,
                                    // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
                                    ShopInfoRef__r.ShopCode__c,
                                    // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
	                                // 室料(店舗名)」のように、室料を複数登録できるように改善対応 BEGIN
	   								//(Select AccountMasterRef__c,Price__c From PlanRef__r Where AccountMasterRef__r.Name = :roomPriceProdName And AccountMasterRef__r.ActionType__c =:CommConst.PROD_ACTION_TYPE_RP limit 1)  
	   								(Select AccountMasterRef__c,Price__c From PlanRef__r Where AccountMasterRef__r.ActionType__c =:CommConst.PROD_ACTION_TYPE_RP limit 1)  
	   								// 室料(店舗名)」のように、室料を複数登録できるように改善対応 END
	   								from Plan__c where BasePlanFlg__c = true And IsClosed__c != true order by Seq__c];
	   Map<String,String> planCodeMap = new Map<String,String>();
	   // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
	   Set<Id> planSet = new Set<Id>();
	   // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
	   for (Plan__c plan : basePlans) {
	   		//プラン
			planLst.add(new SelectOption(plan.Id,'['+ Label.CONST_003_0123 +']'+plan.Name));
			basePlanPriceMap.put(plan.Id, plan);
			if (!plan.PlanRef__r.isEmpty()) {
				for (PlanDetail__c pd : plan.PlanRef__r){
					if (pd.Price__c == 0){
					 	hadZeroPlanSet.add(plan.id);
					 	break;
					}
				}
			}
			planCodeMap.put('P' + plan.PlanNo__c,plan.Id);
	   }
	   // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	   // for (AccountMaster__c acc : [select Id,Field3__c,ServiceRate__c,TaxRateCal__c,SpecialTax__c from AccountMaster__c where Field3__c = :planCodeMap.keySet()]) {
	   for (AccountMaster__c acc : [select Id,Field3__c,ServiceRate__c,TaxRateCal__c,SpecialTax__c,Name,Field5__c,ActionType__c,PaymentType__c,DiscountRate__c,Field7__c,(Select Price__c, AccountMasterRef__r.ActionType__c, TaxRate__c, ServiceRate__c, AccountMasterRef__c, AccountMasterRef__r.Name, Id, Amount__c, OptionAccMstFLG__c From PlanProdcutRef__r) 
	   								// 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.PaymentType__c
	   								,PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.DiscountRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field7__c
	   								// 2020/07/30 入湯税の自動入力機能について改善 zyz END
	   								from AccountMaster__c where Field3__c = :planCodeMap.keySet()]) {
	   // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	   	 planToAccIdMap.put(planCodeMap.get(acc.Field3__c),acc);
	   	 // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
	   	 planSet.add(acc.Id);
	   	 // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
	   }
	   // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
	   for (PlanDetail__c pd : [select Id, AccountMasterRef__c, AccountMasterRef__r.Name, AccountMasterRef__r.ActionType__c,
        						AccountMasterRef__r.SCP_5__c, AccountMasterRef__r.TaxRateCal__c,
        						AccountMasterRef__r.PaymentType__c,		// 2015/02/09 支払種別コピー
        						AccountMasterRef__r.Field4__c,PlanRef__c,
                                AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, JmstRef__c,
                                ServiceRate__c, ProductNumber__c, PlanProdcut__c
                                from PlanDetail__c where PlanProdcut__c in :planSet]) {
       		if ( !planDetailMap.containsKey(pd.PlanProdcut__c)) planDetailMap.put(pd.PlanProdcut__c,new List<PlanDetail__c>());
       		planDetailMap.get(pd.PlanProdcut__c).add(pd);
       }
       // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
	   // 2015/10/02 BUG FIX BEGIN
	   // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
	   //initPlanInfo(actionModeType);
	   // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
	   // 2015/10/02 BUG FIX END
	   // アプリのE/B機能起動がどうかフラグを設定する
	   isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
	   isHaveSeminar = CommConst.APPOTION_ISSHOW_SEMINAR;
	   isHaveRoom = CommConst.APPOTION_ISSHOW_ROOM;
	   // 2013/06/30 部屋の支店選択リスト設定する
	   setInitBranShopLst();
	   
	   // 料金情報人数初期値設定を行う
	   persons = getDefPersons(branchShopNm);
	   // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
	   readRoomtypeDocInfo();
	   // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
	   // 2014/01/27 料金自動設定用商品情報を取得する
	   if (!CommUtils.isBlank(roomPriceProdName)) {
		   //List<AccountMaster__c> accMsts = [select Id, Name  From AccountMaster__c Where Name = :roomPriceProdName And ActionType__c =:CommConst.PROD_ACTION_TYPE_RP limit 1];
		   List<AccountMaster__c> accMsts = ProductItemUtils.getRoomRateProduct(roomPriceProdName);
		   if (!accMsts.isEmpty()) roomPriceInfo = accMsts[0];
	   }
	   // 部屋ステータス初期化
	   initRoomStatusList();
	   
	   // Calendar情報初期化
	   calExt = new CalendarExtend(true);
	   // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
	   filterBasePlan();
	   initPlanInfo(actionModeType);
	   // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
	   // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
	   planVipStr = '';
	   vipTypeLst = new List<String>();
	   planVipList = new List<SelectOption>();
	   getVipList();
	   pageInfoFlg = true;
	   // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
	}

   	// -------------------------------------------
   	// 各店舗の表示する項目情報を取得、格納を行う
    // -------------------------------------------
    private static final String LeadConstFields  = 'Name,Relcontact__c,refTypeOfRooms__c,EntryTime__c,Field4__c,Departure__c,Field3__c,StayPersons__c,SeminarOrderFlg__c,ExtraBedChk__c,Rroom__c,Field310__c,Field315__c,Field2__c,Segment__c,Comment3__c';
   	private Component.Apex.pageBlockSection parseFieldsXml(String pShopCode) {
   		
   		Component.Apex.pageBlockSection psection = new Component.Apex.pageBlockSection();
		psection.columns = 1;

   		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'RoomTypeInventoryLeadInputExtendFieldsXml'];
    	if (sr.isEmpty()) return psection;
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
    	
    	Dom.XmlNode targetNode, firstNode = null;
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode root = doc.getRootElement();
		for(Dom.XMLNode shop : root.getChildElements()) {
			// 各店舗情報はＸＭＬから取得する
			Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
			// 店舗コードを取得する
			String strShopCode = CommUtils.nullToBlank(shopcode.getText());
			if (firstNode == null) firstNode = shop;
			// ログインユーザの店舗コードと一致する場合
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		if (targetNode == null) return psection;
		
		// 画面に既存の予約項目重複処理
		List<String> constFieldsList = LeadConstFields.deleteWhitespace().split(',');
		Set<String> dupliateSet = new Set<String>(constFieldsList);
        // 列数定義タグ存在チェック[2016/07/06]
        Dom.XmlNode colnumsNode = targetNode.getChildElement('COLNUMS', null);
        if (colnumsNode != null) {
            psection.columns = CommUtils.nullToIntZero(colnumsNode.getText().deleteWhitespace());
        }
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		List<String> fieldsSplits = strFields.split(',');
		// 重複する項目は無くす
		List<String> extendFieldsLst = new List<String>();
		// 予約に固定使用する項目APIから無くす
		for (String extendField : fieldsSplits) {
			if (!dupliateSet.contains(extendField) ) extendFieldsLst.add(extendField);
		}
		// 2014/11/27 指定オブジェクトの項目情報は
		map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommUtils.getFieldMetaData(Lead__c.getSObjectType().getDescribe(),new set<String>(extendFieldsLst));
		
		for (String fieldKey : extendFieldsLst) {
			if (CommUtils.isBlank(fieldKey)) continue;
			Schema.DescribeFieldResult descField = modelDeafaultValuesMap.get(fieldKey);
			if (descField == null) continue;
			// Rich Text Area
			if (descField.getType() == Schema.DisplayType.TEXTAREA && descField.isHtmlFormatted()) {
				Component.Apex.InputTextArea inputField = new Component.Apex.InputTextArea();
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				inputField.styleClass='ckeditorClass';
				inputField.id = fieldKey;
				psection.childComponents.add(inputField);
			} else {
				Component.Apex.InputField inputField = new Component.Apex.InputField();
				inputField.expressions.value = '{!newLead.'+fieldKey+'}';
				psection.childComponents.add(inputField);
			}

		}	
		return psection;
		/*
		Dom.XmlNode linkFields = targetNode.getChildElement('LINKFIELD', null);
		Dom.XmlNode avgFields = targetNode.getChildElement('AGGREGATE', null);
		Dom.XmlNode hidFields = targetNode.getChildElement('HIDDENFIELD', null);
		Dom.XmlNode widthFields = targetNode.getChildElement('COLNUMSIZE', null);
		Dom.XmlNode styleFields = targetNode.getChildElement('COLNUMSTYLE', null);
		Dom.XmlNode dataTypeFields = targetNode.getChildElement('COLNUMTYPE', null);
		*/
   	}

	// 初期処理
	public void init(){
		// 初期情報を設定する
		doAction(null);
	}
	// 画面最新情報を表示する
	public void refreshNewInfo() {
		doAction(0);
	}
	// 残室数モード
	public Boolean isStockFlg{get{return actionModeType == CONST_PAGELAYOUT_STOCK;}}
	// ラクレットモード（2019/10/29 WSQ ADD)
	public Boolean isRakurateFlg{get{return actionModeType == CONST_PAGELAYOUT_RAKURETO;}}
	// 料金表と予約ポップ画面切替表示する // 2015/09/18 MODIFY
	public Boolean isRaceRateFlg{get{return !isStockFlg && !isTlSalesFlg;}}
	// 2020/04/30 予約ポップの残室数画面を改修 WGCH BEGIN
	public String isRaceRateComMode{get{return CommDefine__c.getOrgDefaults().RoomTypeShowPageMode__c == null ? '0' : CommDefine__c.getOrgDefaults().RoomTypeShowPageMode__c;}}
	public Boolean isRaceRateComFlg{get{return isRaceRateComMode == '1';}}
	// 2020/04/30 予約ポップの残室数画面を改修 WGCH END
	// 2015/09/14 EDIT BEGIN
	// TL側の販売状態表示フラグ
	public Boolean isTlSalesFlg{get{return actionModeType == CONST_PAGELAYOUT_TLSTATUS;}}
	public Boolean isSfRoomTypeLayout{get{return actionModeType_TlSub == CONST_PAGELAYOUT_TLSTATUS_ROOMTYPE;}}
	// 2015/09/14 EDIT END
	public void switchPage() {
		// 料金情報を取得する
		//isRaceRateFlg = (isRaceRateFlg == null ?  true : !isRaceRateFlg);
		// 2015/09/18 DELETE
		//isRaceRateFlg = ! (actionModeType == CONST_PAGELAYOUT_STOCK);
		// 2015/10/02 EDIT BEGIN
		/*
		if (!isPlanActionMode(actionModeType)) {
			planName = ''; // プラン名をクリアする（VF側、該当設定値により、予約新規の画面のプランに自動設定がどうか
			planPrice = 0;
		} else {
			planName = basePlanPriceMap.get(actionModeType).Name;	// VF画面から設定するプランIDにより、プラン名を設定する、
			planPrice = CommUtils.nullToZero(basePlanPriceMap.get(actionModeType).Price__c);
		}
		*/
		initPlanInfo(actionModeType);
		// 2015/10/02 EDIT END
		doAction(0);
	}
	private void initPlanInfo(String pActionModeType) {
		specialTax = '0';
		// 2021/06/31 #11821 bug fixed by zy BEGIN
		basePlanShopCode = '';
		// 2021/06/31 #11821 bug fixed by zy END
		if (!isPlanActionMode(pActionModeType)) {
			planName = ''; // プラン名をクリアする（VF側、該当設定値により、予約新規の画面のプランに自動設定がどうか
			planPrice = 0;
			planAccId = '';
			servicePriceIncTax = '0';
			taxRate = '0';
			hadZeroFlag = false;
		} else {
            // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
            Boolean isShowBasePlan = false;
            for (SelectOption s : filterPlanList) {
                if (s.getValue() == pActionModeType) {
                    isShowBasePlan = true;
                    break;
                }
            }
			// 2015/11/07 BUG FIX BEGIN
            //if (!basePlanPriceMap.containsKey(pActionModeType)) {
            if (!isShowBasePlan) {
		    // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
				actionModeType = CONST_PAGELAYOUT_STOCK;
			} else {
			// 2015/11/07 BUG FIX END	
                planName = basePlanPriceMap.get(pActionModeType).Name;	// VF画面から設定するプランIDにより、プラン名を設定する、
			    planPrice = CommUtils.nullToZero(basePlanPriceMap.get(pActionModeType).Price__c);
                // 2016/08/15 見積明細登録できる機能対応 BEGIN
				AccountMaster__c acc = planToAccIdMap.get(basePlanPriceMap.get(pActionModeType).id);
				planAccId = acc.id;
				hadZeroFlag = hadZeroPlanSet.contains(basePlanPriceMap.get(pActionModeType).id);
				servicePriceIncTax = basePlanPriceMap.get(pActionModeType).ServiceRate__c == null ? '0' : CommUtils.nullToBlank(CommUtils.nullToZero(basePlanPriceMap.get(pActionModeType).ServiceRate__c));
				taxRate = basePlanPriceMap.get(pActionModeType).JmstRef__c == null ? '0' : CommUtils.nullToBlank(CommUtils.nullToZero(basePlanPriceMap.get(pActionModeType).JmstRef__r.TaxRate__c));
                // 2016/08/15 見積明細登録できる機能対応 END
                // 2019/03/29 JINYABUG-1528 bug fix by zy BEGIN
                specialTax = Commutils.nullToZero(acc.SpecialTax__c).format().replaceAll(',','');
                // 2019/03/29 JINYABUG-1528 bug fix by zy END
                // 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY BEGIN
				String special = '_price_';
				if (planDetailMap.containsKey(planAccId)) {
					String syncInfo = '';
					// 2018/07/27 宿泊税計算 WGCH BEGIN
					// 2020/04/30 BUGFIX WGCH BEGIN
					// HotelTaxDefineInfo hotelInfo = (HotelTaxDefineInfo)JSON.deserialize(hotelInfoJson, HotelTaxDefineInfo.class);
					HotelTaxDefineInfo hotelInfo = new HotelTaxDefineInfo();
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
					ProductItemUtils.ProductItem proItem = new ProductItemUtils.ProductItem(acc, null, true);
					hotelInfo.gOptionMapInfo.put(acc.Id, proItem);
					// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
					// 2020/04/30 BUGFIX WGCH END
					// 2018/07/27 宿泊税計算 WGCH END
					
					for (PlanDetail__c pd : planDetailMap.get(planAccId)) {
						// 2018/07/27 宿泊税計算 WGCH BEGIN
						if(!hotelInfo.hotelTaxDefInstance.isEmpty() && pd.AccountMasterRef__r.ActionType__c == CommConst.PROD_ACTION_TYPE_RP){
							if(!hotelInfo.planItemPriceMap.containsKey(pd.PlanProdcut__c)) hotelInfo.planItemPriceMap.put(pd.PlanProdcut__c, new List<Map<String, Decimal>>());
							// 明细 -> 単価
							hotelInfo.planItemPriceMap.get(pd.PlanProdcut__c).add(new Map<String, Decimal>{ pd.Id => pd.Price__c});
						}
						// 2018/07/27 宿泊税計算 WGCH END
						// 2019/07/30 軽減税率機能対応 WGCH BEGIN
						if(!hotelInfo.planBrkInfoMap.containsKey(pd.PlanProdcut__c)) hotelInfo.planBrkInfoMap.put(pd.PlanProdcut__c, new List<PlanBrkInfo>());
						hotelInfo.planBrkInfoMap.get(pd.PlanProdcut__c).add(setPlanBrkInfo(pd));
						// 2019/07/30 軽減税率機能対応 WGCH END
						String priceTemp = CommUtils.deleteRightZero(CommUtils.nullToZero(pd.Price__c).format(), CommUtils.getPointLen());
						if (RackRateUtils.isRoomRateProduct(pd.AccountMasterRef__r)) {
							if (syncInfo.indexOf(special)< 0 && pd.Price__c == 0) priceTemp = special;
						}
						syncInfo += pd.id + ':' + priceTemp + ':' + pd.AccountMasterRef__c + ':' + pd.AccountMasterRef__r.Name +';';
					}
					// 2018/12/15 予約ポップから連泊作成の場合の見積もり料金が変わらない by zy BEGIN
					if (CommConst.APPOPTION_ROOMPRICE_NOATSETUPFLG) planSyncInfo = syncInfo;
					// 2018/12/15 予約ポップから連泊作成の場合の見積もり料金が変わらない by zy END
					// 2018/07/27 宿泊税計算 WGCH BEGIN
					hotelInfoJson = JSON.serialize(hotelInfo);
					// 2018/07/27 宿泊税計算 WGCH END
				}
				// 2018/05/11 ラックレート設定の自動なしの場合故障修正 by ZY END
			}
		}
	}
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	private PlanBrkInfo setPlanBrkInfo(PlanDetail__c sobj){
		PlanBrkInfo item = new PlanBrkInfo();
		item.unitPrice = CommUtils.nullToZero(sobj.Price__c);
		item.tax = CommUtils.nullToZero(sobj.TaxRate__c);
		item.serviceRate = CommUtils.nullToZero(sobj.ServiceRate__c);
		item.nums = 1;
		item.specialTax = 0;
		item.unitPriceKbn = '';
		item.productId = CommUtils.nullToBlank(sobj.AccountMasterRef__c);
		item.actionType = CommUtils.nullToBlank(sobj.AccountMasterRef__r.ActionType__c);
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		item.pdId = CommUtils.nullToBlank(sobj.Id);
		item.prodcutName = CommUtils.nullToBlank(sobj.AccountMasterRef__r.Name);
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		return item;
	}
	public class PlanBrkInfo{
		public PlanBrkInfo(){
			unitPrice = tax = serviceRate = nums = specialTax = 0;
			unitPriceKbn = productId = actionType = '';
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			pdId = prodcutName = '';
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		}
		public Decimal unitPrice{get;set;}
		public Decimal tax{get;set;}
		public Decimal serviceRate{get;set;}
		public Decimal nums{get;set;}
		public Decimal specialTax{get;set;}
		public String unitPriceKbn{get;set;}
		public String productId{get;set;}
		public String actionType{get;set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public String pdId{get;set;}
		public String prodcutName{get;set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	}
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 画面に選べるリストはベースプランがどうか判別用
	private Boolean isPlanActionMode (String pActionModeType) {
		// 2015/09/14 EDIT BEGIN
		//return !(pActionModeType == CONST_PAGELAYOUT_STOCK || pActionModeType == CONST_PAGELAYOUT_RAKURETO);
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
		// return !(pActionModeType == CONST_PAGELAYOUT_STOCK || pActionModeType == CONST_PAGELAYOUT_RAKURETO || pActionModeType == CONST_PAGELAYOUT_TLSTATUS || pActionModeType == CONST_PAGELAYOUT_TIERLST || pActionModeType == CONST_PAGELAYOUT_STOCKSET);
		return !(pActionModeType == CONST_PAGELAYOUT_STOCK || pActionModeType == CONST_PAGELAYOUT_RAKURETO || pActionModeType == CONST_PAGELAYOUT_TLSTATUS || pActionModeType == CONST_PAGELAYOUT_TIERLST || pActionModeType == CONST_PAGELAYOUT_STOCKSET || pActionModeType == CONST_PAGELAYOUT_BASEPLAN);
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		// 2015/09/14 EDIT END
	}
	
	// 画面表示処理ロジック
	private void doAction(Integer month){
		// 変数の初期化
		dispHeaders = new List<dispHeader>();
		newLead = new Lead__c();
		newContact = new Contact();

    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
    	// チェックイン時刻、チェックアウト時刻
    	newLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
    	newLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
		// 2016/12/14 zyz CTI予約 BEGIN
		String ctiContactId = Apexpages.currentpage().getparameters().get('contactid');
		String ctiContactNm = Apexpages.currentpage().getparameters().get('contactnm');
		ctiContactInf = CommUtils.isBlank(ctiContactId) ? '' : (ctiContactNm + '#' + ctiContactId);
        // 2016/12/14 zyz CTI予約 END*/
		// 初回表示時に、処理日付を現在の日付で設定
		if(month == null) {
			processDay = Date.today();
		}
		// 先月・来月ボタン押下時に、処理日付を変更する
		else if(month != null && thisYear != null && thisMonth != null) {
			processDay = Date.newinstance(thisYear, thisMonth, 1).addMonths(month);
		}
		// 保存ボタン押下後、処理日付を到着日の月を設定する
		else if(month == 0){}

		// 処理年の設定
		thisYear = processDay.year();
		// 処理月の設定
		thisMonth = processDay.month();
		// 処理月・日数の設定
		daysInMonth = Date.daysInMonth(thisYear, thisMonth);
		// データ表示の開始日設定を行う【当日は開始日として、データ表示したい場合】
		if (CONST_SHOW_START_TODAY) {
			// 指定の日付により
			Date todayDt = Date.today();//Date.newInstance(2014,5,31);
			if (startDate == null) startDate = todayDt;
			// 指定の年月と開始日の年月の月数差
			//startDate = startDate.addDays(CommUtils.nullToIntZero(month) * 30);
			Integer diffmonths = todayDt.monthsBetween(processDay);
			//Date orgStartDate = startDate.addDays();
			startDate = todayDt.addMonths(diffmonths);
			Date endDate = todayDt.addMonths(diffmonths == 0 ? 1 : diffmonths+1).addDays(-1);
			daysInMonth = startDate.daysBetween(endDate) + 1;
		} else {
			// 毎月の１日から予約情報を表示の設定
			startDate = Date.newinstance(thisYear, thisMonth, 1);
		}
		// 処理年、月にて、選択できる年選択リストを再設定を行う
		yearList = new List<SelectOption>();
        // 日単位の部屋残り合計する
        //sumRoomsMap = new Map<Integer, Decimal>();
        // 販売部屋合計値
        usedRoomsMap = new Map<Integer, Decimal>();
        // 故障部屋合計値
        badRoomsMap = new Map<Integer, Decimal>();
		// 日単位のE/B残り合計値
		sumEbRoomMap = new Map<Integer, Decimal>();
		// 日単位の全部部屋タイプの総部屋数
		sumDayMaxRooms = 0;
		// Header曜日の色制御設定
		headerColorMap = new Map<Integer, String>();
		// 詳細列のステータス制御変数定義
		colStatusMap = new Map<Date, colStatus>();
		// 2013/12/14 
		usedAgtRoomsMap = new Map<Integer, Decimal>();	
		mstAgtRoomsMap = new Map<Integer, Decimal>();
		// 2021/06/31 #JP10243　対応　by zy BEGIN
		lastAgtRoomsMap = new Map<Integer, Decimal>();
		// 2021/06/31 #JP10243　対応　by zy END
		Integer oldTenYears = processDay.addYears(-10).year();
		Integer newTenYears = processDay.addYears(10).year();
		for (Integer year = oldTenYears; year <=newTenYears; year++ ) {
			//年
			yearList.add(new SelectOption(String.valueof(year),String.valueof(year)+ Label.CONST_003_0124));
		}
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		mstMaxRoomsAllMap = new Map<Integer, Decimal>();
		// 2020/05/29 在庫計算ロジック改修 WGCH END
		// 画面上に表示される予約一覧のヘッダー部を構築する
		for(Integer i = 1; i <= daysInMonth; i ++){
			//Date tempDt = Date.newinstance(thisYear, thisMonth, i);
			Date tempDt = startDate.addDays(i-1);
			// 表示形式は「 日(曜日) 」
			String strYobi = getYobi(tempDt);
			//dispHeaders.add(new dispHeader(i, i+'(' + strYobi + ')', tempDt.format()));
			dispHeader header = new dispHeader(i, tempDt.day()+'(' + strYobi + ')', tempDt);
			dispHeaders.add(header);
			// 初期化を行う
			//sumRoomsMap.put(i, 0);
			usedRoomsMap.put(i, 0);
			badRoomsMap.put(i, 0);
			sumEbRoomMap.put(i, 0);
			// Header曜日の色を個別設定を行う
			String colColor = '';
			//土
			if (strYobi == Label.CONST_003_0125) colColor = '#ffff66';
			//日
            else if (strYobi == Label.CONST_003_0126) colColor = '#ff3366';
            // 2014/02/07 祝い日
            if (calExt.holidayMap.containsKey(tempDt)) {
            	colColor = '#ff3366';
            	header.holidayLab = calExt.holidayMap.get(tempDt);
            }
            headerColorMap.put(i, colColor);
            // 各列の制御情報を初期化する
            colStatusMap.put(tempDt, new colStatus(colColor));
            // 2013/12/14
            mstAgtRoomsMap.put(i, 0);
	    	// 2021/06/31 #JP10243　対応　by zy BEGIN
            lastAgtRoomsMap.put(i,0);
	    	// 2021/06/31 #JP10243　対応　by zy END
            usedAgtRoomsMap.put(i, 0);
            // 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
            if(!mstMaxRoomsAllMap.containsKey(i)) mstMaxRoomsAllMap.put(i, 0);
            // 2020/05/29 在庫計算ロジック改修 WGCH END
		}
		// 部屋タイプリストを取得する[通常だけ]
		//roomTypeLst = [select Id, Name, MaxRooms__c From TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL Order by Seq__c  limit 200];
		/*
		String typeOfRoomActType = CommConst.ROOMTYPE_NORMAL;
		String typeOfRoomQuery = ' select Id, Name, MaxRooms__c From TypeOfRooms__c where ActionType__c = :typeOfRoomActType '; //Order by Seq__c  limit 200';
		if (!CommUtils.isBlank(branchShopNm)) typeOfRoomQuery += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		typeOfRoomQuery += ' Order by Seq__c  limit 500 ';
		roomTypeLst = DataBase.query(typeOfRoomQuery);*/
		// 2015/09/01 多店舗機能対応 BEGIN
		// roomTypeLst = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        if (CommUtils.isBlank(branchShopNm) && userInf.isShopCodePlex) {
        	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
		// 为了判断是否超出，多查出一笔数据
            roomTypeLst = (new CommLogicProcess(CONST_MAX_ROOMTYPE + 1)).getTypeOfRooms(userInf.shops);
            // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
        }else {
        	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
		// 为了判断是否超出，多查出一笔数据
            roomTypeLst = (new CommLogicProcess(CONST_MAX_ROOMTYPE + 1)).getTypeOfRooms(branchShopNm);
            // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ ENND
        }
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
        if (roomTypeLst.size() > CONST_MAX_ROOMTYPE) {
        	roomTypeLst.remove(CONST_MAX_ROOMTYPE);
        	isOverRoomTypeLimitFlg = true;
        }
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
		// 2015/09/01 多店舗機能対応 END
		// データ表示開始日
		//Date conStartDate = Date.newInstance(thisYear, thisMonth, 1);
		Date conStartDate = startDate;
		// データ表示終了日
		//Date conEndDate = Date.newInstance(thisYear, thisMonth, daysInMonth);
		Date conEndDate = startDate.addDays(daysInMonth-1);
		// 重複判別用マップ<部屋タイプID、dispRecord>
		dispRecordMap = new Map<Id, dispRecord>();

		// 故障部屋統計を行う<RoomTypeId_DATE, BadRooms>
		// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
		//Map<String, Integer> badRoomMapInfo = this.queryBadRoomMap(conStartDate, conEndDate);
		Map<String, Integer> badRoomMapInfo = this.queryBadRoomMap(conStartDate, conEndDate, roomTypeLst);
		// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		Set<Id> typeIdSet = new Set<Id>();
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		sfStockInfoMap = new Map<String, AgtStockInfo>();
		agtStockInfoMap = new Map<String, AgtStockInfo>();
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		for (TypeOfRooms__c s: roomTypeLst) {
			for(Integer day = 1; day <= daysInMonth; day ++){
				//Date hibiDt = Date.newinstance(thisYear, thisMonth, day);
				Date hibiDt = startDate.addDays(day-1);
				String key = getRoomStockKey(s.Id, hibiDt);
				if (badRoomMapInfo.containsKey(key)) {
					// 日付単位の故障部屋数統計する
					badRoomsMap.put(day, badRoomsMap.get(day) + badRoomMapInfo.get(key));
				}
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
				// SF在库数信息·初始化处理
				setSfStockInfoMap(s.Id, hibiDt);
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
			}
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			typeIdSet.add(s.id);
			// 2018/12/15 在庫調整と販売状態管理 by zy END
		}
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		StockChangeHelpUtils stockHelp = new StockChangeHelpUtils();
		Map<String, GuestRoomStock__c> stockMap = actionModeType == CONST_PAGELAYOUT_STOCKSET ? stockHelp.getGuestRoomInfo(typeIdSet, colStatusMap.keySet()) : new Map<String, GuestRoomStock__c>();
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		// 功能有效设定 + 防止重复调用SQL
		if(isStockSyncIsMode){
			// 获取部屋在庫管理数据 KEY: 部屋タイプID_YYYY/MM/DD VAL: 部屋在庫管理数据SOBJ
			stockMap = stockHelp.getGuestRoomInfo(typeIdSet, colStatusMap.keySet());
		}
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		Map<String, Decimal> mstMaxRoomsMap = new Map<String, Decimal>();
		// 2020/06/30 予約ポップの店舗切替えに、下部のリアルAGT残室数が対応していない改善 WGCH BEGIN
		// if(agtMsgAllLst == null) agtMsgAllLst = getRealAgtData(conStartDate, conEndDate);
		// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
		agtMsgAllLst = getRealAgtData(conStartDate, conEndDate,typeIdSet);
		// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
		// 2020/06/30 予約ポップの店舗切替えに、下部のリアルAGT残室数が対応していない改善 WGCH END
		// 各旅行開始社、期間により、販売最大可能部屋数
		for (RealAGT__c rs : agtMsgAllLst) {
			// 最大販売できる部屋数
			Decimal mstMaxRooms = CommUtils.nullToZero(rs.AgtMaxRooms__c);
			for(Integer day = 1; day <= daysInMonth; day ++){
				Date hibiDt = startDate.addDays(day-1);
				// マスタデータの提供期間内の部屋数は統計を行う
				if (hibiDt < rs.StartDate__c || hibiDt > rs.EndDate__c) {
					mstMaxRooms = 0;
				}
				String key = rs.RoomTypeRel__c + '_' + hibiDt;
				if(!mstMaxRoomsMap.containsKey(key)) mstMaxRoomsMap.put(key, 0);
				Decimal wkMstMaxRooms = mstMaxRooms + mstMaxRoomsMap.get(key);
				mstMaxRoomsMap.put(key, wkMstMaxRooms);
			}
		} // End For リアルAGTMSTデータ
		// 2020/05/29 在庫計算ロジック改修 WGCH END
		// 部屋タイプで、販売できる最大部屋数を統計する
		//List<Id> roomTypeIdLst = new List<Id>();
		for (TypeOfRooms__c s: roomTypeLst) {
			//roomTypeIdLst.add(s.Id);
			Decimal intMaxRooms = CommUtils.nullToZero(s.MaxRooms__c);
			// 最大販売できる部屋数
			// 2015/08/05 集計対象外フラグを追加の対応：集計対象外のフラグはTRUEの場合、宿泊集計対象外になる BEGIN(if (!s.SumNotApplicableFlg__c)追加)
			if (!s.SumNotApplicableFlg__c) {
			sumDayMaxRooms += intMaxRooms;
			}
			// 2015/08/05 集計対象外フラグを追加の対応：集計対象外のフラグはTRUEの場合、宿泊集計対象外になる END
			// --------------------------
			// 表示用データの初期化設定
			// --------------------------
			// 部屋タイプの表示情報初期化
			dispRecord nwRec = new dispRecord();
			// 部屋タイプIDの設定
			nwRec.roomTypeId = s.Id;
			// 2018/03/15 多店舗対応 by zy BEGIN
			nwRec.shopId = s.ShopInfoRef__c;
			nwRec.shopCode =  s.ShopInfoRef__r.ShopCode__c;
			// 2018/03/15 多店舗対応 by zy END
			// 部屋タイプ名称の設定
			nwRec.roomTypeNm = s.Name;
			// 月間の在庫数初期化[最大使える部屋数]設定する
			for(Integer day = 1; day <= daysInMonth; day ++){
				//Date hibiDt = Date.newinstance(thisYear, thisMonth, day);
				Date hibiDt = startDate.addDays(day-1);
				// 故障部屋数取得、設定する
				String badKey = getRoomStockKey(s.Id, hibiDt);
				Integer badRooms = badRoomMapInfo.containsKey(badKey) ? badRoomMapInfo.get(badKey) : 0;
				// 全月分部屋在庫数初期化設定を行う
				// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
				String managerkey = getManagerKey(s.Id, hibiDt);
				GuestRoomStock__c stock = stockMap.get(managerkey);
				Decimal stockMaxRooms = stock == null ? 0 : CommUtils.nullToIntZero(stock.MaxRoomsCal__c);
				// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
				// Key: 房型Id+日期
				String key = nwRec.roomTypeId + '_' + hibiDt;
				// 最大提供房间数
				Decimal mstMaxRooms = mstMaxRoomsMap.containsKey(key) ? mstMaxRoomsMap.get(key) : 0;
				if(!mstMaxRoomsAllMap.containsKey(day)) mstMaxRoomsAllMap.put(day, 0);
				Decimal mstMaxRoomsAll = mstMaxRooms + mstMaxRoomsAllMap.get(day);
				mstMaxRoomsAllMap.put(day, mstMaxRoomsAll);
				// 2020/05/29 在庫計算ロジック改修 WGCH END
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
				if(isStockSyncIsMode){
					if(stock == null || stock.AGTChangeRoomsJSON__c == null){
						stockMaxRooms -= mstMaxRooms;
						// 重置最新值
						intMaxRooms = CommUtils.nullToZero(s.MaxRooms__c) - mstMaxRooms;
					}
				}
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
				if (stockMap.containsKey(managerkey)) {
					// 故障部屋计算
					GuestRoomInfo info = new GuestRoomInfo(new GuestRoomStock__c(QtyOfStock__c=(stockMaxRooms-badRooms),StockDate__c=hibiDt, SalesStatusLst__c = stock.SalesStatusLst__c),intMaxRooms - badRooms);
					// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
					// if(isStockSyncIsMode) info.stock.QtyOfStock__c -= mstMaxRooms;
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
					// 2020/05/29 在庫計算ロジック改修 WGCH END
					if (info.diffRoomInt == null) info.diffRoomInt = 0;
					info.diffRoomInt += CommUtils.nullToIntZero(badRooms);
					nwRec.roomList.add(info);
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
					// 部屋ID, 日期, 最大販売室数, 最大残室数
					setSfStockInfoMap(nwRec.roomTypeId, hibiDt, stockMaxRooms, info.stock.QtyOfStock__c);
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
				} else{
					GuestRoomInfo info = new GuestRoomInfo(new GuestRoomStock__c(QtyOfStock__c=(intMaxRooms-badRooms),StockDate__c=hibiDt));
					// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
					// if(isStockSyncIsMode) info.stock.QtyOfStock__c -= mstMaxRooms;
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
					// 2020/05/29 在庫計算ロジック改修 WGCH END
					if (info.diffRoomInt == null) info.diffRoomInt = 0;
					info.diffRoomInt += CommUtils.nullToIntZero(badRooms);
					nwRec.roomList.add(info);
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
					// 部屋ID, 日期, 最大販売室数, 最大残室数
					setSfStockInfoMap(nwRec.roomTypeId, hibiDt, intMaxRooms, info.stock.QtyOfStock__c);
					// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
				}
				// 2018/12/15 在庫調整と販売状態管理 by zy END
			}
			// 部屋タイプ単位の初期化
			dispRecordMap.put(s.Id, nwRec);
		}
		// 20120924 ADD
		this.setMessageItem(conStartDate);

		
		// ---------------------------
		// 有効な予約データ件数を統計する
		// ---------------------------
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
		String leadQuery = ' Select Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate, refTypeOfRooms__r.SumNotApplicableFlg__c sumNotAppFlg From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ';
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		if(isStockSyncIsMode) leadQuery += ' And AgtFlg__c = false ';
		// 2020/05/29 在庫計算ロジック改修 WGCH END
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			leadQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            leadQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 zy BEGIN
        if (!typeIdSet.isEmpty()) {
        	leadQuery += ' And refTypeOfRooms__c in :typeIdSet';
        }
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 zy END
		// 2015/09/01 多店舗機能対応 END
		leadQuery += 	 ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)),refTypeOfRooms__r.SumNotApplicableFlg__c ' +
						 ' Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)),refTypeOfRooms__r.SumNotApplicableFlg__c ';
//System.debug(loggingLevel.INFO, 'leadQuery:::' + leadQuery);
		for (AggregateResult ar : DataBase.query(leadQuery)) {			 
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 使える部屋数
        	Decimal userRoom = (Decimal)ar.get('usedRoom'); 
        	// 予約データの到着日から開始表示日の日付数
			Integer days = conStartDate.daysBetween(ciDate);
			// Head Index
			Integer headIdx = days + 1;
			// 販売部屋合計値
			// 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
			boolean sumNotAppFlg = (Boolean)ar.get('sumNotAppFlg');
			if (sumNotAppFlg == null || !sumNotAppFlg) {
				if (!usedRoomsMap.containsKey(headIdx)) usedRoomsMap.put(headIdx, userRoom);
				else usedRoomsMap.put(headIdx, (usedRoomsMap.get(headIdx) + userRoom));
			}
			// 2015/08/05 部屋タイプの集計対象外フラグの対応 END
			// 既に使用した部屋数を計算を行う
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			dispRecordMap.get(roomTypeId).roomList[days].stock.QtyOfStock__c = dispRecordMap.get(roomTypeId).roomList[days].stock.QtyOfStock__c - userRoom;
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			if (dispRecordMap.get(roomTypeId).roomList[days].qtyStock == null) dispRecordMap.get(roomTypeId).roomList[days].qtyStock = 0;
			dispRecordMap.get(roomTypeId).roomList[days].qtyStock = dispRecordMap.get(roomTypeId).roomList[days].qtyStock - CommUtils.nullToIntZero(userRoom);
			if (dispRecordMap.get(roomTypeId).roomList[days].diffRoomInt == null) dispRecordMap.get(roomTypeId).roomList[days].diffRoomInt = 0;
	        dispRecordMap.get(roomTypeId).roomList[days].diffRoomInt += CommUtils.nullToIntZero(userRoom);
	        // 2018/12/15 在庫調整と販売状態管理 by zy END
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			setSfStockInfoMap(roomTypeId, ciDate, null, dispRecordMap.get(roomTypeId).roomList[days].stock.QtyOfStock__c);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		} // End For(予約データ取得・在庫設定処理完了)
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END

		
		
		// 処理年と処理月でデータを抽出して、表示Listにプッシュする
		/*
		for(GuestRoomStock__c item : [select RoomTypeRef__c, RoomTypeRef__r.Name, StockDate__c, QtyOfStock__c  from GuestRoomStock__c
									where CALENDAR_YEAR(StockDate__c) = :thisYear and CALENDAR_MONTH(StockDate__c) = :thisMonth
									order by RoomTypeRef__r.Seq__c asc, StockDate__c asc]){*/
		/*
		for(GuestRoomStock__c item : [select RoomTypeRef__c, RoomTypeRef__r.Name, StockDate__c, QtyOfStock__c  from GuestRoomStock__c
		                              where StockDate__c >= :conStartDate And StockDate__c <= :conEndDate And RoomTypeRef__c in :roomTypeIdLst
		                              Order By StockDate__c asc ]) {
		    // 日付差計算
			Integer days = conStartDate.daysBetween(item.StockDate__c);
			// 部屋タイプがマップにすでに保存された場合
			if(dispRecordMap.containsKey(item.RoomTypeRef__c)){
				// レコードを該当部屋タイプに関連するリストに追加する
				//dispRecordMap.get(item.RoomTypeRef__c).roomList.add(item);
                // 実際の在庫情報更新を行う
                dispRecordMap.get(item.RoomTypeRef__c).roomList[days].QtyOfStock__c = item.QtyOfStock__c;
			}
			// 部屋タイプがマップにまだ保存されない場合
			else{
				dispRecord nwRec = new dispRecord();
				// 部屋タイプIDの設定
				nwRec.roomTypeId = item.RoomTypeRef__c;
				// 部屋タイプ名称の設定
				nwRec.roomTypeNm = item.RoomTypeRef__r.Name;
				// 全月分部屋在庫数初期化設定を行う
				//for(Integer j = 1; j < item.StockDate__c.day(); j ++){
				for(Integer j = 1; j <= daysInMonth; j ++){
					nwRec.roomList.add(new GuestRoomStock__c(QtyOfStock__c=0,StockDate__c=Date.newinstance(item.StockDate__c.year(), item.StockDate__c.month(), j)));
				}
				// 実際の在庫情報更新を行う
				//Integer days = conStartDate.daysBetween(item.StockDate__c);
				nwRec.roomList[days].QtyOfStock__c = item.QtyOfStock__c;
				// データをリストにいれる
				//nwRec.roomList.add(item);
				// マップに追加する
				dispRecordMap.put(item.RoomTypeRef__c, nwRec);
			}
			// 日単位の部屋数合計を行う
//			System.debug('days:' + days);
//			System.debug('sumRoomsMap:' + sumRoomsMap);
//			System.debug('sumRoomsMap.get(days):' + sumRoomsMap.get(days));
//			System.debug('item.QtyOfStock__c:' + item.QtyOfStock__c);
			sumRoomsMap.put(days+1, sumRoomsMap.get(days+1) + item.QtyOfStock__c);
		}*/
		// 2013/06/24 ADD PAST DATA CAN INPUT FLG
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		if (!CommConst.APPOTION_ROOMTYPE_INPUT_PASTDATA || isStockFlag ) {
		// 2018/12/15 在庫調整と販売状態管理 by zy END
			// 在庫合計値にて、各列の状態設定を行う
			for(Integer i = 1; i <= daysInMonth; i ++){
				//Date tempDt = Date.newinstance(thisYear, thisMonth, i);
				Date tempDt = startDate.addDays(i-1);
				// 2013/01/11 Add
				if (tempDt < Date.today()) {
					colStatusMap.get(tempDt).disable = true;
					continue;
				}
				// 2013/01/11 Delete
				/*
				// 残室合計値は最初限以下の場合、予約ポップ画面に設定不能
				if (sumRoomsMap.get(i) < minRooms) {
					colStatusMap.get(tempDt).disable = true;
				}*/
			}
		}
		/*
		// データが未存在する場合[部屋在庫情報存在する部屋タイプと実際の定義している部屋タイプ一致しない場合]
		if (dispRecordMap.size() != roomTypeLst.size()) {
			// 部屋タイプマスたに存在する部屋タイプにて、部屋在庫管理データを作成する
			for (TypeOfRooms__c s: roomTypeLst) {
				// 在庫データに既存の部屋タイプ処理スキップ
				if (dispRecordMap.containsKey(s.id)) continue;
				// 新規作成を行う
				dispRecord nwRec = new dispRecord();
                // 部屋タイプIDの設定
                nwRec.roomTypeId = s.id;
                // 部屋タイプ名称の設定
                nwRec.roomTypeNm = s.Name;
	            for(Integer j = 0; j < daysInMonth; j ++){
	                nwRec.roomList.add(new GuestRoomStock__c(QtyOfStock__c=0,StockDate__c=conStartDate.addDays(j)));
	            }
	            dispRecordMap.put(s.id, nwRec);
			}
		}*/

		// E/B情報を取得、設定をおこなう
		// 予約データからE/B予約情報を統計する
        // 通常の部屋タイプ関連の予約データを取得する(部屋タイプ設定済み　AND E/Bフラウを設定されている場合)
        if (isHaveEbInfo) {
            setEbInfo(conStartDate, conEndDate);
        }
        // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
        Map<String, BasePlanDetail__c> BasePlanMapInfo = new Map<String, BasePlanDetail__c>();
		map<Date,String> TierMap = new map<Date,String>();
		vipTypeLst = new List<String>();
		planVipList = new List<SelectOption>();
		// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz BEGIN
		getVipList();
		isPlanActionFlg = false;
		// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz END
        if(isBasePlanLayputFlg && (isPlanActionMode(actionModeType) || isBasePlanFlg)){
	        // 获取baseplan数据
	    	baseplanLst = getBasePlans();
	    	// 每页显示10笔数据
	    	// 页面显示数据数量
	    	/* TODO:数量如果通过自定义 */
	    	Integer pageInt = 10;
	    	if(pageInfoFlg) pageCtrl = new PaginationUtil(baseplanLst , pageInt);
	    	// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz BEGIN
	    	if(isPlanActionMode(actionModeType) || isBasePlanFlg) isPlanActionFlg = true;
	    	// getVipList();
	    	// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz END
	    	// 获取baseplan的明细map
	    	BasePlanMapInfo = this.queryBasePlanMap(conStartDate, conEndDate, baseplanLst);
	    	// 处理tier的key:baseplanId_会员种别
	    	String valKey = ActionModeType +'_'+planVipStr;
	    	// 每一天对应的tier
	    	if (tierVipMap.containsKey(valKey)) TierMap = tierVipMap.get(valKey);
        }
        // 料金表情報を表示する場合 
        // 料金情報を取得、設定を行う
        // queryRaceRateInfo(conStartDate, conEndDate);
		queryRaceRateInfo(conStartDate, conEndDate, TierMap);
        // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
        // queryRaceRatePlanInfo(conStartDate, conEndDate, TierMap);
        // 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
        // baseplan页面数据处理
        if(isBasePlanLayputFlg && (isPlanActionMode(actionModeType) || isBasePlanFlg)) getPlanSetInfo(BasePlanMapInfo);
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
        // 予約ポップ（残室数）のみ、リアルAGT情報を取得する
        if (isStockFlg) {
			// リアルＡＧＴ関連処理
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			// getRealAgtInfo(conStartDate, conEndDate);
			if(isStockSyncIsMode) getRealAgtInfo(conStartDate, conEndDate, stockMap);
			else getRealAgtInfo(conStartDate, conEndDate);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
        }
        // 休館情報を表示する
        queryRestHotelInfo(conStartDate, conEndDate);
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
        // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
        // TIER　XMLの設定フィルドー
        // processTierXmlSetting();
        processTierXmlSetting(TierMap);
        // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
        // TL側の販売状態の照会
        if (isTlSalesFlg)  { 	
	        try {
	        	// TL側に残室数情報取得機能呼出
	        	isStockTlSalesInfoNoErrFlg = getTlSalesInfo(conStartDate, conEndDate);
	        	if (isSfRoomTypeLayout || !isHaveTlSaleInfo) {
	        		RoomTypeInventory2WayHelp help = new RoomTypeInventory2WayHelp();
	        		taSaleInfo = help.getTaSalesInfo(conStartDate, conEndDate, branchShopLst, branchShopNm);
	        	}
	        } catch (Exception e) {
	        	isStockTlSalesInfoNoErrFlg = false;
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
	        }
        }
 		// 選択値はCOOKIEへ反映する
 		CookieInf inf = new CookieInf(actionModeType);
 		inf.viewModeSub1 = actionModeType_TlSub;
        setCookieInf(inf);
        // 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz BEGIN
        getDefLead();
        // 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz END
	}
	// TA残室数情報格納
	public transient List<RoomTypeInventory2WayHelp.ShopInfo> taSaleInfo{get; private set;}
	// TA残室情報存在するがどうか判定する
	public boolean isHaveTaSaleInfo{get{
		return (taSaleInfo != null && taSaleInfo.size() > 0);
	}}
	// TL残室情報存在するがどうか判定する
	public Boolean isHaveTlSaleInfo{get{
		return (showShopList != null && showShopList.size() > 0);
	}}
	/**
	*　料金表関連デイフォル値
	**/
	private String getDefPersons(String shopCd) {
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).PeopleDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTablePeopleDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).PeopleDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTablePeopleDefault__c );
		}
	}
	private String getDefTier(String shopCd) {
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
	}
	public String persons{get;set;}				// 画面人数->画面指定の人数を格納する
	/**
	* 料金表情報を取得する
	**/
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
	// private void queryRaceRateInfo (Date stDate, Date edDat) {
	private void queryRaceRateInfo (Date stDate, Date edDat,map<Date,String> teMap ) {
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END

		// 設定情報格納用クラス初期化する
		tierInfo = new TierSetupInfo();
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		detailTierMap = new Map<String, String>();
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
		tierButtonInfoMap = new map<Date,Boolean>();
		String basePlanIdStr = '';
		// 2021/06/31 #11821 bug fixed by zy BEGIN
		// デフォルト店舗コード
		basePlanShopCode = branchShopNm;
		// 2021/06/31 #11821 bug fixed by zy END
		if (isPlanActionMode(actionModeType)) {
			basePlanIdStr = basePlanPriceMap.get(actionModeType).Id;
			// 2021/06/31 #11821 bug fixed by zy BEGIN
			// 該当「ベースプラン」の店舗コード設定
			basePlanShopCode =  basePlanPriceMap.get(actionModeType).ShopInfoRef__r.ShopCode__c;
			// 2021/06/31 #11821 bug fixed by zy END
		}
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		// Tier初期値設定する
		// 2021/06/31 #11821 bug fixed by zy BEGIN
		// デフォルトTier取得する
		// String defaultTier = getDefTier(branchShopNm);
		String defaultTier = getDefTier(basePlanShopCode);
		// 2021/06/31 #11821 bug fixed by zy END
		// TierのHeader情報格納初期化
		tierHeaderInfoMap = new Map<Integer, String>();
		for(Integer day = 1; day <= daysInMonth; day ++){
			tierHeaderInfoMap.put(day, defaultTier);
		}
		// 初期値情報を設定する
		raceRatePriceMap = new Map<Id, Map<Date, Decimal>>();
		for (TypeOfRooms__c s: roomTypeLst) {
			// 部屋タイプ単位の初期化定義
			raceRatePriceMap.put(s.Id, new Map<Date, Decimal>());
			// 部屋タイプの日付単位の料金情報を
			Map<Date, Decimal> monthPriceMap = raceRatePriceMap.get(s.Id);
			// 月間の料金表情報初期化処理
			for(Integer day = 1; day <= daysInMonth; day ++){
				//Date hibiDt = Date.newinstance(thisYear, thisMonth, day);
				Date hibiDt = startDate.addDays(day-1);
				monthPriceMap.put(hibiDt, 0);
			}
		}

		//　基本情報を取得する
		Set<Id> typeOfRoomIdSet = raceRatePriceMap.keySet();
		// 月の初日を設定する
		//Date firstDayOfMonth = Date.newinstance(thisYear, thisMonth, 1);
		// 日単位のTIER設定情報を取得する
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c,SearchKey__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		// 2015/09/01 多店舗機能対応 BEGIN
		// 2021/06/31 #11821 bug fixed by zy BEGIN
		// デフォルト店舗コードあり
		if (!CommUtils.isBlank(basePlanShopCode)) {
			queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :basePlanShopCode ';
		// 2021/06/31 #11821 bug fixed by zy END
		} else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
		// 日付・支店単位の設定情報を取得する
		// ShopId + '_' + Date/ Tier
		Map<String, String> setupTierMap = new Map<String, String>();
		for (RackRateTableDetail__c item : DataBase.query(queryRRDetailString)) {
			String key = CommUtils.nullToBlank(item.ShopInfoRef__c) + '_' + item.PriceSetupDate__c;
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			detailTierMap.put(item.SearchKey__c,item.Tier__c);
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
			// 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 BEGIN
			// 存在しているゴミデータを回避するため、検索キーをチェックを追加する
			String searchKey = CommUtils.nullToBlank(item.SearchKey__c);
			if (!CommUtils.isBlank(searchKey) && searchKey != key) continue;
			// 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 END
			setupTierMap.put(key, item.Tier__c);
			// 2021/06/31 #11937 bug fixed by zy BEGIN
			// 当前「ラックレート明細」所属店铺code与当前店铺Code不一致，不覆盖当日默认Tier
			if (CommUtils.nullToBlank(item.ShopInfoRef__r.ShopCode__c) != basePlanShopCode) {
				continue;
			}
			// 2021/06/31 #11937 bug fixed by zy END
			Integer diffDays = startDate.daysBetween(item.PriceSetupDate__c);
			tierHeaderInfoMap.put(diffDays+1, CommUtils.nullToBlank(item.Tier__c));
		}
		// 残室数照会画面の場合、その後の処理は中止
		// 2020/04/30 予約ポップの残室数画面を改修 WGCH BEGIN
		// if (!isRaceRateFlg) return ;
		if (!isRaceRateFlg && !isRaceRateComFlg) return ;
		// 2020/04/30 予約ポップの残室数画面を改修 WGCH END
		//persons
		// 部屋タイプ
		//String queryRaceRateHeader = CommSqlUtils.generateQueryString('RackRateTable__c');
		String queryRaceRateHeader = ' SELECT SearchKey__c, RoomTypeRel__r.ShopInfoRef__c, RoomTypeRel__c, Persons__c, Price__c, Tier__c From RackRateTable__c ';
		String queryRaceRateString = queryRaceRateHeader + ' Where Persons__c = :persons And RoomTypeRel__c in :typeOfRoomIdSet ';
		// 部屋タイプID/ 金額
		//Map<String, RackRateTable__c> priceMap = new Map<String, RackRateTable__c>();
		// 部屋タイプID/ Map<日付, 金額>
		raceRateMstMap = new Map<String, Decimal>();
		// ベースプランから設定する場合、ベースプランの金額＋Tierの金額と合わせて、画面に表示する[basePlanPrice]
		// ベースプランの中に、室料のプラン明細が非存在する場合、プラン金額のみ画面に表示する
		Boolean isAddRoomPrice = false;		// 室料はプラン金額に加算するがどうか判別フラグ
		Decimal basePlanPrice = 0;			// プランの金額
		// プアン選べる場合
		if (isPlanActionMode(actionModeType)) {
			 Plan__c planSobj = basePlanPriceMap.get(actionModeType);	// 画面から選べるプラン情報を取得する
			 isAddRoomPrice = (!planSobj.PlanRef__r.isEmpty());			// 室料のプラン明細あり・なし判別フラグ
			 basePlanPrice = CommUtils.nullToZero(planSobj.Price__c);	// プランの金額を取得する
		}
		// プラン明細に室料ありプランを表示する場合
		// 部屋タイプ毎、日単位の料金情報を初期化する
//System.debug(LoggingLevel.INFO, 'queryRaceRateString:' + queryRaceRateString);
		for (RackRateTable__c raceRate : DataBase.query(queryRaceRateString)) {
			// ベースプランから設定する場合、ベースプランの金額＋Tierの金額と合わせて、画面に表示する[basePlanPrice]
			if (isAddRoomPrice || !isPlanActionMode(actionModeType)) {
				raceRateMstMap.put(raceRate.SearchKey__c, CommUtils.nullToZero(raceRate.Price__c) + basePlanPrice);
			} else {
				// プランの価額を表示する【室料項目が非存在する場合、画面にプラン金額のみ表示する】
				raceRateMstMap.put(raceRate.SearchKey__c, basePlanPrice);
			}
		}
		// 全部屋タイプ情報配列
		for (TypeOfRooms__c s: roomTypeLst) {
			// 2021/06/31 #11937 bug fixed by zy BEGIN
			String typeDefTier = null;
			// ALL店舗の場合
			if (CommUtils.isBlank(basePlanShopCode)) {
				// 該当部屋タイプの店舗のデフォルト「TIER」を設定する
				typeDefTier = getDefTier(s.ShopInfoRef__r.ShopCode__c);
			}
			// 2021/06/31 #11937 bug fixed by zy END
			// 部屋タイプの月間の料金情報
			Map<Date, Decimal> monthPriceMap = raceRatePriceMap.get(s.Id);
			for(Integer day = 1; day <= daysInMonth; day ++){
				// 曜日
				//Date hibiDt = Date.newinstance(thisYear, thisMonth, day);
				Date hibiDt = startDate.addDays(day-1);
				// 該当部屋タイプに、TIER個別指定する
				String key = CommUtils.nullToBlank(s.ShopInfoRef__c) + '_' + hibiDt;
				// 2021/06/31 #11937 bug fixed by zy BEGIN
				String tier = defaultTier;
				// ALL店舗と「部屋タイプ」下Tierありの場合
				if (CommUtils.isBlank(basePlanShopCode) && !CommUtils.isBlank(typeDefTier)) {
					tier = defaultTier;
				}
				// 2021/06/31 #11937 bug fixed by zy END
				// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
				//String tierkey = basePlanIdStr + '_' + hibiDt;
				tierButtonInfoMap.put(hibiDt,false);
				if (!CommUtils.isBlank(basePlanIdStr) && teMap.containsKey(hibiDt)) {
					String[] splitLst = teMap.get(hibiDt).split('_');
					Boolean btnFlg = false;
					if(splitLst.size() == 2){
						tier = splitLst[1];
						btnFlg = splitLst[0] =='2' ? true : false;
					}
					tierButtonInfoMap.put(hibiDt,btnFlg);
					Integer diffDays = startDate.daysBetween(hibiDt);
					tierHeaderInfoMap.put(diffDays+1, tier);
				}else
				// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
				if (setupTierMap.containsKey(key)) {
					tier = setupTierMap.get(key);
					// 該当TIERの料金設定内容を取得する
					// 2021/06/31 #11937 bug fixed by zy BEGIN
					// ALL店舗の場合
					if (CommUtils.isBlank(basePlanShopCode)) {
						String tierDetailKey = key + '_' + s.id;
						// 別店舗のTier（レックレート設定表示用）を設定する
						if (!detailTierMap.containskey(tierDetailKey)) {
							detailTierMap.put(tierDetailKey,tier);
						}
					}
					// 2021/06/31 #11937 bug fixed by zy END
				}
				// Tier + "_" + 人数 + "_" + 部屋タイプID
				String raceRateKey = tier + '_' + s.Id + '_' + persons;
				// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
				String raceRatePlanKey = '';
				if(!CommUtils.isBlank(basePlanIdStr)) raceRatePlanKey = tier + '_' + s.Id + '_' + persons + '_' + basePlanIdStr;
				if(!CommUtils.isBlank(raceRatePlanKey) && raceRateMstMap.containsKey(raceRatePlanKey) && CommConst.RACKRATE_BASEPLAN){
					Decimal price = raceRateMstMap.get(raceRatePlanKey);
					monthPriceMap.put(hibiDt, price);
				} else
				// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
				if (raceRateMstMap.containsKey(raceRateKey)) {
					Decimal price = raceRateMstMap.get(raceRateKey);
					monthPriceMap.put(hibiDt, price);
				}
			}
		}
	}
	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz BEGIN
	public Boolean rackRatePlanFlg{get{ return CommConst.RACKRATE_PLAN_FLG;}set;}
	public transient Map<Id, Map<Date, Boolean>> raceRatePlanMap {get;set;}
	// 处理连携上传的房型贩卖定义
	private void queryRaceRatePlanInfo (Date stDate, Date edDat,map<Date,String> teMap ) {
		// 設定情報格納用クラス初期化する
		detailTierMap = new Map<String, String>();
		String basePlanIdStr = '';
		if (isPlanActionMode(actionModeType)) basePlanIdStr = basePlanPriceMap.get(actionModeType).Id;
		// Tier初期値設定する
		String defaultTier = getDefTier(branchShopNm);
		// 初期値情報を設定する
		raceRatePlanMap = new Map<Id, Map<Date, Boolean>>();
		for (TypeOfRooms__c s: roomTypeLst) {
			// 部屋タイプ単位の初期化定義
			raceRatePlanMap.put(s.Id, new Map<Date, Boolean>());
			// 部屋タイプの日付単位の料金情報を
			Map<Date, Boolean> monthPlanMap = raceRatePlanMap.get(s.Id);
			// 月間の料金表情報初期化処理
			for(Integer day = 1; day <= daysInMonth; day ++){
				Date hibiDt = startDate.addDays(day-1);
				monthPlanMap.put(hibiDt, true);
			}
		}

		//　基本情報を取得する
		Set<Id> typeOfRoomIdSet = raceRatePlanMap.keySet();
		// 月の初日を設定する
		// 日単位のTIER設定情報を取得する
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c,SearchKey__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
		// 日付・支店単位の設定情報を取得する
		// ShopId + '_' + Date/ Tier
		Map<String, String> setupTierMap = new Map<String, String>();
		for (RackRateTableDetail__c item : DataBase.query(queryRRDetailString)) {
			String key = CommUtils.nullToBlank(item.ShopInfoRef__c) + '_' + item.PriceSetupDate__c;
			detailTierMap.put(item.SearchKey__c,item.Tier__c);
			// 存在しているゴミデータを回避するため、検索キーをチェックを追加する
			String searchKey = CommUtils.nullToBlank(item.SearchKey__c);
			if (!CommUtils.isBlank(searchKey) && searchKey != key) continue;
			setupTierMap.put(key, item.Tier__c);
			
			Integer diffDays = startDate.daysBetween(item.PriceSetupDate__c);
		}
		// 残室数照会画面の場合、その後の処理は中止
		if ((!isRaceRateFlg && !isRaceRateComFlg) || !rackRatePlanFlg) {
			RaceRatePlanSet();
			return ;
		}
		//persons
		// 部屋タイプ
		String queryRaceRateHeader = ' SELECT SearchKey__c, RoomTypeRel__r.ShopInfoRef__c, RoomTypeRel__c, Tier__c, SalesStatus__c, BasePlanRef__c From RackRateTable__c ';
		String queryRaceRateString = queryRaceRateHeader + ' Where BasePlanRef__c = :actionModeType And RoomTypeRel__c in :typeOfRoomIdSet ';
		// 部屋タイプID/ Map<日付, 金額>
		Map<String, Boolean> raceRatePlanMstMap = new Map<String, Boolean>();
		// プラン明細に室料ありプランを表示する場合
		// 部屋タイプ毎、日単位の料金情報を初期化する
		for (RackRateTable__c RackPlan : DataBase.query(queryRaceRateString)) {
			Boolean salesStatus = RackPlan.SalesStatus__c != SALES_STATUS_STOP ? true:false;
			raceRatePlanMstMap.put(RackPlan.SearchKey__c, salesStatus);
		}
		// 全部屋タイプ情報配列
		for (TypeOfRooms__c s: roomTypeLst) {
			// 部屋タイプの月間の料金情報
			Map<Date, Boolean> monthPlanMap = raceRatePlanMap.get(s.Id);
			for(Integer day = 1; day <= daysInMonth; day ++){
				// 曜日
				Date hibiDt = startDate.addDays(day-1);
				
				String tier = defaultTier;
				// 該当部屋タイプに、TIER個別指定する
				String key = CommUtils.nullToBlank(s.ShopInfoRef__c) + '_' + hibiDt;
				if (!CommUtils.isBlank(basePlanIdStr) && teMap.containsKey(hibiDt)) {
					String[] splitLst = teMap.get(hibiDt).split('_');
					if(splitLst.size() == 2){
						tier = splitLst[1];
					}
				}else
				if (setupTierMap.containsKey(key)) {
					tier = setupTierMap.get(key);
					// 該当TIERの料金設定内容を取得する
				}
				// 部屋タイプID + "_" + プランID + "_" + Tier
				String raceRatePlanKey = s.Id + '_' + actionModeType + '_' +tier;
				if (raceRatePlanMstMap.containsKey(raceRatePlanKey)) {
					Boolean PlanFlg = raceRatePlanMstMap.get(raceRatePlanKey);
					monthPlanMap.put(hibiDt, PlanFlg);
				}
				
			}
		}
		RaceRatePlanSet();
	}
	private void RaceRatePlanSet(){
		for(Id rt : raceRatePlanMap.keyset()){
			Map<Date, Boolean> raceButtonMap = raceRatePlanMap.get(rt);
			for(Date dt : tierButtonInfoMap.keyset()){
				if (raceButtonMap.containsKey(dt)) {
					Boolean isTierButton = tierButtonInfoMap.get(dt);
					if(isTierButton){
						raceButtonMap.put(dt,!isTierButton);
					}
				}
			}
		}
	}
	// 2020/05/30 販売で部屋タイプを設定に改善対応 BY zyz END
	
	// 最新連絡事項情報取得
	public MessageItem__c messageObj{get; set;}
	private void setMessageItem(Date currDate) {
		// 2015/10/27 連絡事項共通化 END
		// 去年の年月
		//Date oldYearMonth = currDate.addYears(-1);
		DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
		String currYm = currDt.format('yyyyMM');
		//String oldYm = currDt.addYears(-1).format('yyyyMM');
		/*
		String querySql = CommSqlUtils.generateQueryString('MessageItem__c');
		//List<MessageItem__c> msgLst = [select id, name, message1__c, message2__c, message3__c, message4__c, message5__c, Message6__c
		//		from MessageItem__c where name = :currYm or name = :oldYm order by name desc limit 2];
		
		if (Commconst.OLDDATE_ISSHOW_MESSAGE) querySql += ' where name = :currYm or name = :oldYm order by name desc limit 2 ';
		else querySql += ' where name = :currYm order by name desc limit 1 ';
		
		//querySql += ' where name = :currYm or name = :oldYm order by name desc limit 2 ';
		List<MessageItem__c> msgLst = DataBase.query(querySql);
		if (msgLst.isEmpty()) {
			// 今年の連絡事項がなかった場合、去年の同じ年月の
			messageObj = new MessageItem__c(name=currYm);
		} else {
			messageObj = msgLst[0].clone(false,true);
			messageObj.Name = currYm;
			messageObj.ownerId = UserInfo.getUserId();
		}*/
		messageObj = new MessageItem__c(name=currYm);
		// 2015/10/27 連絡事項共通化 END
	}
	// 2015/10/27 連絡事項共通化 END
	/*
	public void saveMessageItem() {
		Database.upsert(messageObj, MessageItem__c.name);
	}
	*/
	// 2015/10/27 連絡事項共通化 END
    // E/B関連情報取得、設定を行う
    private void setEbInfo(Date conStartDate, Date conEndDate) {
    	// 期間内、部屋タイプ設定済、E/BフラグTRUE場合
    	/*
        for (AggregateResult ar : [Select
                                    Count(ID) usedRoom ,DAY_ONLY(convertTimezone(EntryTime__c)) cidate
                                    From Lead__c
                                    Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
                                    And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate
                                    And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate
                                    And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
                                    And ExtraBedChk__c = true
                                    Group By DAY_ONLY(convertTimezone(EntryTime__c))
                                    Order by DAY_ONLY(convertTimezone(EntryTime__c))]) {
            */
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
		String ebQuery = ' Select Count(ID) usedRoom ,DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
						 ' And ExtraBedChk__c = true ';
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			ebQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            ebQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
        ebQuery += ' And refTypeOfRooms__r.SumNotApplicableFlg__c != true ';
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 END
		ebQuery += 		 ' Group By DAY_ONLY(convertTimezone(EntryTime__c)) ' +
						 ' Order by DAY_ONLY(convertTimezone(EntryTime__c)) ';
		for (AggregateResult ar : DataBase.query(ebQuery)) {				
            // 到着日
            Date ciDate = (Date)ar.get('cidate');
            // 日付差計算[画面表示する場合：１からため、計算後の日数+1に変更が必要]
            Integer days = conStartDate.daysBetween(ciDate) + 1;
            // E/Bデータ存在する場合、日単位に、合計設定を行う
            sumEbRoomMap.put(days, (Decimal)ar.get('usedRoom'));
        }
    }
    
    // Tierの期間設定処理を行う
    public TierSetupInfo tierInfo{get;set;}
    // Tier/人数/曜日/で、料金明細情報を設定する
    public void createRaceTableDetail() {
    	// Tier設定情報
//System.debug(LoggingLevel.INFO, 'tierInfo:::' + tierInfo);
    	// TIER/人数/期間/曜日種別/
    	// 支店コードにより、支店IDを取得する
    	Id shopId = null;
    	if (!CommUtils.isBlank(branchShopNm)) {
    		shopId = [select id from ShopInformation__c where ShopCode__c = :branchShopNm][0].Id;
    	}
		// データ更新用配列
		List<RackRateTableDetail__c> upertLst = new List<RackRateTableDetail__c>();
		// クリアフラグ true:ラックレート明細削除
		boolean clearDetailFlag = false;
		Set<String> typeSet = new Set<String>();
		// 单独变更roomtype
    	if (!CommUtils.isBlank(tierInfo.moreTypeMsg)) {
    		String moreTypeMsg = tierInfo.moreTypeMsg;
    		List<String> moreTypeLst = moreTypeMsg.split(',');
    		for (String typeMsg : moreTypeLst) {
    			List<String> msgs = typeMsg.split('_');
    			String typeId = msgs[0];
    			String hidDt = msgs[1];
    			Date queryDt = CommUtils.stringtoDate(hidDt);
    			String tier = msgs[2];
    			String searchKey = genSearchKey(shopId, queryDt) + '_' + typeId;
				RackRateTableDetail__c item = new RackRateTableDetail__c(
					Tier__c = tier,
					PriceSetupDate__c = queryDt,
					ShopInfoRef__c = shopId,
					SearchKey__c = searchKey,
					RoomTypeRef__c = typeId
				);
				upertLst.add(item);
    		}
    	} else {
    		Date startDt = Date.Parse(tierInfo.startDate);
			Date endDt = Date.Parse(tierInfo.endDate);
	    	// 毎週
	    	if (tierInfo.isWeekRepeat) {
	    		// 曜日により、設定用日付を取得する
	    		// 開始日から、一週間の曜日日付を取得する
	    		List<String> weekOpts = tierInfo.weekOpts.split(',');
	    		Set<String> weekOptsSet = new Set<String>(weekOpts);
	    		DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
	    		DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
	    		while (startDTime <= endDTime) {
	    			String weekKey = startDTime.format('EEEE');
	    			if (weekOptsSet.contains(weekKey)) {
	    				Date configDate = startDTime.date();
	    				String searchKey = genSearchKey(shopId, configDate);
	    				RackRateTableDetail__c item = new RackRateTableDetail__c(
	    					Tier__c = tierInfo.tier,
	    					PriceSetupDate__c = configDate,
	    					ShopInfoRef__c = shopId,
	    					SearchKey__c = searchKey
	    				);
	    				upertLst.add(item);
	    			}
	    			startDTime = startDTime.addDays(1);
	    		}
	    		//if(!upertLst.isEmpty()) upsert upertLst RackRateTableDetail__c.SearchKey__c;
	    	}
	    	if (!CommUtils.isBlank(tierInfo.roomTypeId)) {
	    		typeSet.addAll(CommUtils.nullToBlank(tierInfo.roomTypeId).split(','));
	    	}
	    	// 部屋タイプの全て選択の場合
	    	// ラックレート部屋タイプ別の明細削除する
	    	clearDetailFlag = typeSet.isEmpty();
	    	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
    	}
    	// 2015/11/03 処理対象外ロジック、一時対象外 BEGIN
    	/* 
    	// 毎月
    	else {
    		// 1-31（終日）
    		if (tierInfo.isDayOfMonth) {
    			while(startDt <= endDt) {
    				Integer maxDaysOfMonth = Date.daysInMonth(startDt.year(), startDt.month());
    				Integer days = tierInfo.dayOfMonth;
	    			// 終日
	    			if (days == 99) {
	    				days = Date.daysInMonth(startDt.year(), startDt.month());	
	    			}
	    			// 該当年月は設定対象外/次の年月を再計算する/指定日は開始期間により、過去の日付の場合、次の月に設定を行う
	    			if (days > maxDaysOfMonth || days < startDt.day()) {
	    				Date tmpDate = Date.newInstance(startDt.year(), startDt.month(), 1);
	    				startDt = tmpDate.addMonths(1);
	    				continue;
	    			}
	    			// 設定日
	    			Date configDate = Date.newInstance(startDt.year(), startDt.month(), days);
	    			// 処理中止
	    			if (configDate > endDt) break;
	    			
    				String searchKey = genSearchKey(shopId, configDate);
    				RackRateTableDetail__c item = new RackRateTableDetail__c(
    					Tier__c = tierInfo.tier,
    					PriceSetupDate__c = configDate,
    					ShopInfoRef__c = shopId,
    					SearchKey__c = searchKey
    				);
    				upertLst.add(item);
    				startDt = configDate.addDays(1);
    			}
    			//if(!upertLst.isEmpty()) upsert upertLst RackRateTableDetail__c.SearchKey__c;
    		}
    		// 1-4週ー曜日
    		else {
    			DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
    			DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
    			//Date startDat
    			// 初め同じ週、同じ曜日の日付を取得する
    			while (startDTime <= endDTime) {
//System.debug(LoggingLevel.INFO, 'startDTime:::' + startDTime.format('yyyy/MM/dd'));
    				// 月末
    				//Integer maxDates = Date.daysInMonth(
    				// Wed...
    				String weekKey = startDTime.format('EEEE');
    				// 曜日比較する
    				if (weekKey == tierInfo.dayOfWeek) {
    					// 月における曜日を比較する
     					// 月における曜日(1-5)
    					Integer intWeekNum = Integer.valueOf(startDTime.format('W'));
    					if (tierInfo.weekOfMonth == 9) {
    						Integer maxDays = Date.daysInMonth(startDTime.year(),startDTime.month());
	    					DateTime lastDateTime = DateTime.newInstance(startDTime.year(),startDTime.month(), maxDays);
	    					tierInfo.weekOfMonth = Integer.valueOf(lastDateTime.format('F'));
    					}
//System.debug(LoggingLevel.INFO, 'intWeekNum:::' + intWeekNum);
//System.debug(LoggingLevel.INFO, 'tierInfo.weekOfMonth:::' + tierInfo.weekOfMonth);
    					// 月の曜日をチェックする
    					if (intWeekNum == tierInfo.weekOfMonth) {
    						// 終了日まで超えると、処理
    						Date configDate = startDTime.date();
    						// 該当日は対象データを作成する
		    				String searchKey = genSearchKey(shopId, configDate);
		    				RackRateTableDetail__c item = new RackRateTableDetail__c(
		    					Tier__c = tierInfo.tier,
		    					PriceSetupDate__c = configDate,
		    					ShopInfoRef__c = shopId,
		    					SearchKey__c = searchKey
		    				);
    						upertLst.add(item);
    					}
    					// 次の週を計算する
    					startDTime = startDTime.addDays(7);
    				} else {
    					// 翌日日付を加算する
    					startDTime = startDTime.addDays(1);
    				}
    			}
    		}
    	}
    	*/
    	// 2015/11/03 処理対象外ロジック、一時対象外 END
    	Savepoint sp = Database.setSavepoint();
    	try {
    		//Integer s = 1 / 0;
    		// 料金設定情報を反映する
    		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			//if(!upertLst.isEmpty()) upsert upertLst RackRateTableDetail__c.SearchKey__c;  
			RackRateUtils.saveRackDetailsByRoomType(typeSet,upertLst,clearDetailFlag);
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
    	} catch (Exception e) {
    		Database.rollback(sp);
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            bookingCreateOK = false;
            return;
    	} 
    	// 処理結果を設定する 	
    	bookingCreateOK = true;
    	// 最新表示用情報を取得する
    	doAction(0);
    }
    
    public class TierSetupInfo {
    	public TierSetupInfo() {isDayOfMonth=true;isWeekRepeat=true;}
    	public String tier{get;set;}
    	public Boolean isWeekRepeat{get;set;}
    	public String weekOpts{get;set;}		// 頻度は「毎週」の場合、繰り返しの曜日情報を格納「,」区きり
    	public Boolean isDayOfMonth{get;set;}
    	public Integer dayOfMonth{get;set;}      // 1-31-最終
    	public Integer weekOfMonth{get;set;}		// 1,2,3,4,9
    	public String dayOfWeek{get;set;}		// Monthday-Sunday
    	public String startDate{get;set;}
    	public String endDate{get;set;}
    	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
    	public String roomTypeId{get;set;}
    	public String moreTypeMsg{get;set;}
    	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
    }
    // Tier Detail Key
	private static String genSearchKey(Id shopId, Date configDate) {
    	return (CommUtils.nullToBlank(shopId) + '_' + configDate);
    }
    
    // 休館設定情報を格納する
    public HotelStatusInfo hotelInf{get; private set;}


    // 2015/12/17 FIX BEGIN
    //通常
    private String CONST_NORMAL_HOTEL = Label.CONST_003_0127;								// デフォルト営業スタータス値
    private String CONST_NORMAL_COLOR = 'black';							// デフォルト色
    private String CONST_NORMAL_OTCOLOR = 'red';							// デフォルト以外の営業スタータスの色
    // 2015/12/17 FIX END
    public String getNoramlStatus() {return CONST_NORMAL_HOTEL;}
    // private static final String CONST_REST_HOTEL = '休館';
    // private static final String CONST_FULL_HOTEL = '貸切';
    private Set<String> roomTSSSet ;
    public List<String> roomStatusList{get; private set;}		// 部屋ステータス切り替え情報格納
    private Map<String, String> statusColorMap{get; private set;}
    private void initRoomStatusList() {
    	roomStatusList = new List<String>();
    	statusColorMap = new Map<String, String>();
        String roomTSS = CommConst.APPOTION_DEF_ROOMTYPE_SALESTATUS();
        roomTSSSet = new Set<String>();
        if (!String.isEmpty(roomTSS)) {
        	String[] roomLst = roomTSS.split(',');
        	for (String key : roomLst) {
        		String[] subKey = key.split(':');
        		if (subKey.size() > 1) CONST_NORMAL_HOTEL = subKey[0];
				// 2015/12/17 FIX BEGIN
				else roomTSSSet.add(subKey[0].split(';')[0]);
				String[] colorKey = key.split(';');
				if (colorKey.size() > 1) {
					statusColorMap.put(subKey[0].split(';')[0], colorKey[1]);
				}
    			roomStatusList.add(subKey[0].split(';')[0]);
    			 // 2015/12/17 FIX END
        	}
        }
        // デフォルト営業スタータスの色の設定
       	if (!statusColorMap.containsKey(CONST_NORMAL_HOTEL)) statusColorMap.put(CONST_NORMAL_HOTEL, CONST_NORMAL_COLOR);
    }
    // 部屋状態検索機能
    private void queryRestHotelInfo (Date stDate, Date edDat) {
    	hotelInf = new HotelStatusInfo(getNoramlStatus());
    	// 支店は未指定 && 支店リストはが存在する場合
    	if (CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0) return;
    	// 画面期間範囲の 休館/全館貸切 情報を取得する
		List<RoomsStatus__c> roomsStatus = [select id, Status__c, StatusBeginDate__c, StatusEndDate__c from RoomsStatus__c 
											// where (Status__c = :CONST_REST_HOTEL OR Status__c = :CONST_FULL_HOTEL)
												where (Status__c in : roomTSSSet)
												And StatusBeginDate__c <= :edDat And StatusEndDate__c >= :stDate
												And (
												   RoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												OR RoomRef__r.TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm
												)];
   		// 休館情報を設定する
   		Date firstDay = startDate;//Date.newInstance(thisYear, thisMonth, 1);
   		Date endDay = firstDay.addDays(daysInMonth);//Date.newInstance(thisYear, thisMonth, daysInMonth);
		//restInfoMap = new Map<Integer, Boolean>();
		restInfoMap = new Map<Integer, String>();
		colorInfoMap = new Map<Integer, String>();
		for(Integer day = 1; day <= daysInMonth; day ++){
			//restInfoMap.put(day, false);
			restInfoMap.put(day, getNoramlStatus());
			colorInfoMap.put(day, statusColorMap.get(CONST_NORMAL_HOTEL));
		}
		for (RoomsStatus__c status : roomsStatus) {
			Date loopStart = status.StatusBeginDate__c;
			Date loopEnd   = status.StatusEndDate__c;
			while (loopStart <= loopEnd) {
				Integer index = firstDay.daysBetween(loopStart)+1;
				//restInfoMap.put(index, true);
				restInfoMap.put(index, status.Status__c);
				if (statusColorMap.containsKey(status.Status__c)) colorInfoMap.put(index, statusColorMap.get(status.Status__c));
				else if(status.Status__c != CONST_NORMAL_HOTEL) {
					colorInfoMap.put(index, CONST_NORMAL_OTCOLOR);
				}
				loopStart = loopStart.adddays(1);
				if (loopStart > endDay) break;
			}
		}
    }
    
    // 2014/02/16 休館機能追加
    public void updateHotelStatus () {
    	// 指定期間の休館・開館データ処理を行う
    	Date startDt = Date.parse(hotelInf.startDate);
    	Date endDt = Date.parse(hotelInf.endDate);
		// 指定期間内の既存休館情報を取得する
		List<RoomsStatus__c> roomsStatus = [select id, Name, Status__c, StatusBeginDate__c, StatusEndDate__c,RoomRef__c,Describe__c from RoomsStatus__c 
											// where (Status__c = :CONST_REST_HOTEL OR Status__c = :CONST_FULL_HOTEL )
												where (Status__c in : roomTSSSet)
												And StatusBeginDate__c <= :endDt And StatusEndDate__c >= :startDt
												And (RoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm 
													Or 
													RoomRef__r.TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm)];
		// 更新、削除リスト情報を格納する
		List<RoomsStatus__c> upsertLst = new List<RoomsStatus__c>();
		List<RoomsStatus__c> deleteLst = new List<RoomsStatus__c>();
		// 指定期間の店舗は正常営業にする
    	//if (hotelInf.isOpenHotelFlg) {
    	//if (hotelInf.hotelStatus == CONST_NORMAL_HOTEL) {
		// 画面指定期間内、休館データが存在する場合、休館データ
		// 指定期間、指定店舗の休館→開館処理を行う
		// 指定期間に、すでに存在している休館情報は削除して、正常営業情報に戻る
		// その後、画面から指定する「休館・賃切」OPTION情報をDBへ設定する
		//List<RoomsStatus__c> roomsStatus = [select id, Name, StatusBeginDate__c, StatusEndDate__c,RoomRef__c,Describe__c from RoomsStatus__c where Status__c = '休館' And StatusBeginDate__c <= :endDt And StatusEndDate__c >= :startDt];
		for (RoomsStatus__c status : roomsStatus) {
			// ---------- Start----------End------------- ←DBデータ
			// --s1-----------------e1------------------- ←指定期間変更
			// -----------------s2------------e2---------
			//------------------s3---e3------------------
			//---s4---------------------------e4---------
			// ---------- startDt----------endDt-------------
			// --s1-------------------e1---------------------
			if (startDt <= status.StatusBeginDate__c && endDt <= status.StatusEndDate__c) {
				// 休館終了日は更新処理を行う
				status.StatusBeginDate__c = endDt.addDays(1);
				if (status.StatusBeginDate__c <= status.StatusEndDate__c) {
					upsertLst.add(status);
				} else {
					deleteLst.add(status);
				}
				continue;
			} 
 			// ---------- startDt-----------endDt------------
			//---------------------s3----e3------------------
			else if (status.StatusBeginDate__c <= startDt && endDt <= status.StatusEndDate__c) {
				// CLONE
				RoomsStatus__c cloneItem = status.clone(false, true);
				cloneItem.StatusBeginDate__c = endDt.addDays(1);
				// ORG
				status.StatusEndDate__c = startDt.addDays(-1);
				
				if (status.StatusBeginDate__c <= status.StatusEndDate__c) {
					upsertLst.add(status);
				} else {
					deleteLst.add(status);
				}
				if (cloneItem.StatusBeginDate__c <= cloneItem.StatusEndDate__c) {
					upsertLst.add(cloneItem);
				}
				continue;
			}
			// ---------- Start------------End-------------
			// ---------------------s2------------e2-------
			else if (status.StatusBeginDate__c <= startDt && status.StatusEndDate__c <= endDt) {
				status.StatusEndDate__c = startDt.addDays(-1);
				if (status.StatusBeginDate__c <= status.StatusEndDate__c) {
					upsertLst.add(status);
				} else {
					deleteLst.add(status);
				}
				continue;
			}
			// ---------- Start------------End-------------
			//---s4---------------------------e4---------
			else if (startDt <= status.StatusBeginDate__c && status.StatusEndDate__c <= endDt) {
				deleteLst.add(status);
				continue;
			}
		}
		// 画面指定のOPTIONにより、【通常】以外の場合、管理データはDBへ反映する
		if (hotelInf.hotelStatus != getNoramlStatus()) {
			// 指定支店に所属する１部屋を取得して、該当店舗の関連休館データを作成する
			List<Room__c> rooms = [select id from Room__c where ShopInfoRef__r.ShopCode__c = :branchShopNm Or TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm limit 1];
			if (!rooms.isEmpty()) {
				RoomsStatus__c status = new RoomsStatus__c(
					//管理データを編集、変更しないてください。
					Name = hotelInf.hotelStatus + Label.CONST_003_0128,
					RoomRef__c = rooms[0].Id,
					Status__c  = hotelInf.hotelStatus,	//'休館',
					StatusBeginDate__c = startDt,
					StatusEndDate__c   = endDt,
					//管理データを自動作成ため、直接変更しないてください。
					Describe__c		   = hotelInf.hotelStatus +Label.CONST_003_0129
				);
				upsertLst.add(status);
			}
		}
    	/*
    	} 
    	// 指定期間の店舗は休館する
    	else {
    		// 店舗、日単位の休館データを作成する
			// ---------- Start----------End-------------
			// --s1-----------------e1-------------------
			// -----------------s2------------e2---------
			//------------------s3---e3------------------
			// すでに休館データとMergeする
			for (RoomsStatus__c status : roomsStatus) {
	    		// ---------- Start----------End-------------
	    		// --s1-----------------e1-------------------
	    		if (status.StatusEndDate__c < endDt) {
	    			status.StatusEndDate__c = endDt;
	    		}
				if (startDt < status.StatusBeginDate__c) {
					status.StatusBeginDate__c = startDt;
				}
				upsertLst.add(status);
			}
			// 休館データが非存在する場合、新規休館情報を作成する
			if (roomsStatus.isEmpty()) {
				// 指定支店に所属する１部屋を取得して、該当店舗の関連休館データを作成する
				List<Room__c> rooms = [select id from Room__c where ShopInfoRef__r.ShopCode__c = :branchShopNm Or TypeRoomRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm limit 1];
				if (!rooms.isEmpty()) {
					RoomsStatus__c status = new RoomsStatus__c(
						Name = '休館管理データを編集、変更しないてください。',
						RoomRef__c = rooms[0].Id,
						Status__c  = '休館',
						StatusBeginDate__c = startDt,
						StatusEndDate__c   = endDt,
						Describe__c		   = '休館管理データを自動作成ため、直接変更しないてください。'
					);
					upsertLst.add(status);
				}
			}
    	}*/
    	
    	Savepoint sp = Database.setSavepoint();
    	try {
//System.debug(LoggingLevel.INFO, 'upsertLst:::' + upsertLst);
//System.debug(LoggingLevel.INFO, 'deleteLst:::' + deleteLst);
    		// 休館関連情報処理を行う
			if(!upsertLst.isEmpty()) upsert upsertLst RoomsStatus__c.Id;
			if(!deleteLst.isEmpty()) delete deleteLst;
    	} catch (Exception e) {
    		Database.rollback(sp);
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            bookingCreateOK = false;
            return;
    	} 
    	// 処理結果を設定する 	
    	bookingCreateOK = true;
    	// 最新表示用情報を取得する
    	doAction(0);
    }
    // 支店単位の休館、営業制御情報格納
    public class HotelStatusInfo {
    	public HotelStatusInfo (String normalStatus) {
    		//isOpenHotelFlg = true;
    		//hotelStatus = CONST_NORMAL_HOTEL;
    		hotelStatus = normalStatus;
    	}
    	//public Boolean isOpenHotelFlg{get;set;}	// 支店開館・休館フラグ
    	public String startDate{get;set;}		// 制御開始日
    	public String endDate{get;set;}			// 制御終了日
    	public String hotelStatus{get;set;}		//　支店のステータス
    }
    
    
    
    // 指定期間の在庫情報統計処理を行う
    // 2013/07/01 支店機能対応：支店指定する場合、在庫更新は支店レベルまで更新を行う
    public void refreshStockInfo() {
		refreshNewInfo();
		return;
		/* 2013/09/27から在庫統計処理は変更するため、下記ロジックを削除する
    	// TODO
    	//Date refBeginDate = Date.today();
    	//Date refEndDate = Date.today();
        // データ表示開始日
        Date conStartDate = Date.newInstance(thisYear, thisMonth, 1);
        // データ表示終了日
        Date conEndDate = Date.newInstance(thisYear, thisMonth, Date.daysInMonth(thisYear, thisMonth));

    	// 指定期間内、有効な予約データに対して、部屋数統計を行う・
    	// 該当部屋タイプに対して、在庫更新処理を行う[通常の部屋タイプだけ処理対象です]
    	Map<Id, Decimal> roomTypeInfoMap = new Map<Id, Decimal>();
    	//for (TypeOfRooms__c roomType: [select id, Name, MaxRooms__c from TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL limit 200 for update]) {
		String typeOfRoomActType = CommConst.ROOMTYPE_NORMAL;
		String typeOfRoomQuery = ' select Id, Name, MaxRooms__c From TypeOfRooms__c where ActionType__c = :typeOfRoomActType '; //Order by Seq__c  limit 200';
		if (!CommUtils.isBlank(branchShopNm)) typeOfRoomQuery += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		typeOfRoomQuery += ' limit 500 for update ';
    	for (TypeOfRooms__c roomType: DataBase.query(typeOfRoomQuery)) {
    		roomTypeInfoMap.put(roomType.id, roomType.MaxRooms__c);
    	}
    	if (roomTypeInfoMap.isEmpty()) return;

		// 通常の部屋タイプ関連処理
		Map<String, Decimal> leadUsrRoomMap = new Map<String, Decimal>();
		// 通常の部屋タイプ関連の予約データを取得する
		*/
		/* 2013/07/01 支店機能対応
		for (AggregateResult ar : [Select
						            Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate
						            From Lead__c
						            Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
						            And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate
						            And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate
						            And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						            Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c))
						            Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c))])  {
						            */
        /* 2013/09/27 Delete
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
		String leadQuery = ' Select Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ';
		if (!CommUtils.isBlank(branchShopNm)) leadQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		leadQuery += 	 ' Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
						 ' Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
		for (AggregateResult ar : DataBase.query(leadQuery)) {			 
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 更新必要な
        	String key = getRoomStockKey(roomTypeId, ciDate);
        	leadUsrRoomMap.put(key, (Decimal)ar.get('usedRoom'));

		} // End For(予約データ取得・在庫設定処理完了)
		// 通常の各部屋タイプからすでに予約済みの部屋情報を抜いて、在庫管理データを再作成を行う
		// 期間内の在庫管理情報を削除する
		// 新規の在庫管理データを作成する　
//System.debug('-----leadUsrRoomMap:------' + leadUsrRoomMap);
		*/
		/* 2013/07/01 支店機能対応
		delete [select id from GuestRoomStock__c where StockDate__c >= :conStartDate and StockDate__c <= :conEndDate];
		*/
		/* 2013/09/27 Delete
		String delStockQuery = ' Select id From GuestRoomStock__c where StockDate__c >= :conStartDate and StockDate__c <= :conEndDate ';
		if (!CommUtils.isBlank(branchShopNm)) delStockQuery += ' And RoomTypeRef__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		List<GuestRoomStock__c> delStockLst = DataBase.query(delStockQuery);
		delete delStockLst;
		// 新規作成をおこなう
		List<GuestRoomStock__c> insLst = new List<GuestRoomStock__c>();
		// 日単位在庫データ作成
		for (Date dt = conStartDate; dt <= conEndDate;) {
			// 部屋タイプ単位でデータを作成
			for (Id typeRoomId : roomTypeInfoMap.keySet()) {
				String key = getRoomStockKey(typeRoomId, dt);
//System.debug('key:' + key);
				GuestRoomStock__c newStockObj = new GuestRoomStock__c();
				newStockObj.QtyOfStock__c = roomTypeInfoMap.get(typeRoomId) - CommUtils.nullToZero(leadUsrRoomMap.get(key));
				// 最大数を定義されていない場合、処理SKIPする
				if (newStockObj.QtyOfStock__c == null) continue;
				newStockObj.StockDate__c = dt;
				newStockObj.RoomTypeRef__c = typeRoomId;
				newStockObj.Name = key;
				insLst.add(newStockObj);
			}
			dt = dt.addDays(1);
		}

		// E/B関連機能の最新情報を取得・設定を行う
        if (isHaveEbInfo) {
            setEbInfo(conStartDate, conEndDate);
        }
        */
        /*
		//E/B処理を行う
		Map<String, Decimal> leadUsrEbRoomMap = new Map<String, Decimal>();
		// E/B設定されている予約データを取得する
		for (AggregateResult ar : [Select
						            Count(ID) usedRoom ,DAY_ONLY(EntryTime__c) cidate
						            From Lead__c
						            Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
						            And DAY_ONLY(EntryTime__c) >= :conStartDate And DAY_ONLY(EntryTime__c) <= :conEndDate
						            And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						            And ExtraBedChk__c = true
						            Group By DAY_ONLY(EntryTime__c)
						            Order by DAY_ONLY(EntryTime__c)])  {
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
			String key = getRoomStockKey(null, ciDate);
			leadUsrEbRoomMap.put(key, (Decimal)ar.get('usedRoom'));
		}
		// E/B在庫情報設定をおこなう
		for (TypeOfRooms__c typeEbRomm : [select id, Name, MaxRooms__c from TypeOfRooms__c
			where ActionType__c = :CommConst.ROOMTYPE_EB And MaxRooms__c != null Order By LastModifiedDate desc limit 1]) {
			for (Date dt = conStartDate; dt <= conEndDate;) {
				String key = getRoomStockKey(null, dt);
				GuestRoomStock__c newStockObj = new GuestRoomStock__c();
				newStockObj.StockDate__c = dt;
				newStockObj.QtyOfStock__c = typeEbRomm.MaxRooms__c - CommUtils.nullToZero(leadUsrEbRoomMap.get(key));
				newStockObj.RoomTypeRef__c = typeEbRomm.Id;
				newStockObj.Name = typeEbRomm.Id + '_' + key;
				insLst.add(newStockObj);
				// 次の日付
				dt = dt.addDays(1);
			}
		}*/
		/* 2013/09/27 Delete
		if (!insLst.isEmpty()) insert insLst;
		// 最新情報を再取得を行う
		refreshNewInfo();
		*/
    }
	private String getRoomStockKey(Id rommTypeId, Date dt) {
		if (rommTypeId == null) return DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
		else return rommTypeId + '_' + DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
	}

	// ボタン「来月」の処理
	public void toNext(){
		doAction(1);
	}

	// ボタン「先月」の処理
	public void toPrev(){
		doAction(-1);
	}
    // 年・月を選択する場合
    public void gotoYearMonth() {
    	// 選択する年月にて、今日までの月数を計算を行う
        //Date selDate = Date.newInstance(thisYear, thisMonth, Date.today().day());
    	//doAction(processDay.monthsBetween(selDate));
    	doAction(0);
    }
    // ************************
    // 支店選択リスト
    // ************************
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    private void setInitBranShopLst() {
    	branchShopLst = new List<SelectOption>();
    	shopInfoMap = new Map<String,ShopInformation__c>();
    	/* 2013/07/01 支店機能対応
        for (AggregateResult r : [  SELECT BranchShopName__c shopName FROM Room__c Where BranchShopName__c != null GROUP BY BranchShopName__c ORDER BY BranchShopName__c limit 10000]) {
            branchShopLst.add(new SelectOption(String.valueof(r.get('shopName')),String.valueof(r.get('shopName'))));
        }*/
	// 2015/09/01 多店舗機能対応 BEGIN
        /*for (ShopInformation__c shop : [select id, name,ShopCode__c,TierDefault__c,PeopleDefault__c from ShopInformation__c order by Seq__c limit 5000]) {
        	branchShopLst.add(new SelectOption(shop.ShopCode__c, shop.name));
        	shopInfoMap.put(shop.ShopCode__c, shop);
        }*/
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
	// 2015/09/01 多店舗機能対応 END
	// 2016/12/28 URLから店舗コードを指定できる機能対応　BEGIN
	if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
    	branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
	} else {
	// 2016/12/28 URLから店舗コードを指定できる機能対応　END
        if (!branchShopLst.isEmpty()) {
        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == locShopCode) {
        			branchShopNm = locShopCode;
        			break;
        		}
        	}
        }
	}
		// 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
		Apexpages.currentpage().getparameters().put('curSpcd',branchShopNm);
		// 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
        // 2016/08/01 店舗設定情報を取得する
        shopInfoMap = ShopInfoUtil.getShopInfoMap();
    }
    // Tier/営業のHeader部情報を表示・非表示制御する
    public Boolean isShowTierHeader {get{
    	// 支店あり、全店舗を選べる場合、TIERのHeader情報を非表示する
    	return !(CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);
    }}
    
	// 支店設定変更する場合
	public void changeBranchShop() {
		// 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
		if(isShopBasePlanFlg()) {
		    // 店舗別変更の場合、選択リストの選択値は初期化する
		    actionModeType = CONST_PAGELAYOUT_STOCK;
		    // 該当店舗の選択リストをリセットする
		    filterBasePlan();
		    // プラン関連情報の場合、初期化する
		    initPlanInfo(actionModeType);
		}
		// 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
		// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
	   	readRoomtypeDocInfo();
	   	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
		// 最新情報を取得する
		refreshNewInfo();
	}
    // ***************************
  	// 予約を保存する
  	// 設定情報にて、予約、予約インデックス情報を新規登録する
  	// ***************************
  	public Boolean bookingCreateOK{get;set;}
  	// データ登録の事前チェック
  	private Boolean preBookingCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		// お客様/予約名/予約チャネル
  		if((CommUtils.isBlank(newLead.Relcontact__c) && CommUtils.isBlank(contactName) ) ||
  			CommUtils.isBlank(newLead.Name) ||
  			CommUtils.isBlank(newLead.Field2__c) ||
  			newLead.StayPersons__c == null) {
  			//必須項目を入力してください。
  			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_003_0105));
  			return false;
  		}
  		// 日帰りの場合、到着日と出発日の時刻チェックを行う
  		if (staysNums == 0) {
  			// 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
  			Time startTime = CommUtils.stringToTime(newLead.Field4__c);
  			Time endTime = CommUtils.stringToTime(newLead.Field3__c);
  			//if (newLead.Field4__c >= newLead.Field3__c) {
  			if (startTime >= endTime) {
  				//出発時刻には到着時刻以降の時刻を指定して下さい
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_003_0106));
  				return false;
  			}
  		}
  		// Defautl値設定
  		if (staysNums == null) staysNums = 0;
  		
  		// 2013/10/28 部屋割り当て可能チェックを行う
  		if (!CommUtils.isBlank(newLead.Rroom__c)) {
  			Date startDt = Date.parse(startDays);
  			// 日帰りする場合、条件統一ため、０から１に変更する
  			Date endDt = startDt.addDays(staysNums == 0 ? 1 : staysNums);
			List<Lead__c> existLeads = [ select Id from Lead__c
	        	where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
	                And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
	                And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
	                And Rroom__c = :newLead.Rroom__c ];
	         if (!existLeads.isEmpty()) {
  				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_0010));
  				return false;
	         }
  		}
  		
  		if (!CommUtils.isBlank(newLead.Relcontact__c)) newContact.Id = newLead.Relcontact__c;
  		return true;
  	}
  	/**
  	* HH:MM 文字列からTIMEに変換処理
  	**/
  	private Time converHHMMtoTime(String timeStr) {
  		//if (String.isEmpty(timeStr) || timeStr.length() != 5) return Time.newInstance(0,0,0,0);
        //Integer HH = Integer.valueOf(timeStr.subString(0,2));
        //Integer MM = Integer.valueOf(timeStr.subString(3,5));
        //return Time.newInstance(HH, MM, 0, 0);
        return CommUtils.stringToTime(timeStr);
  	}
  	
	/**
	* 部屋故障状態を読み込む
    **/
    // 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
    //private Map<String, Integer> queryBadRoomMap (Date conStartDate, Date conEndDate) {
    private Map<String, Integer> queryBadRoomMap (Date conStartDate, Date conEndDate, List<TypeOfRooms__c> qTypeOfRooms) {
    // 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
    	// Map<日付, Map<部屋ID,部屋タイプID>>
    	//Map<Date,Set<Id>> badRoomMap = new Map<Date, Set<Id>>();
    	Set<String> badRoomKeySet = new Set<String>();
    	//Map<Date,Map<Id, Integer>> badRoomNumMap = new Map<Date, Map<Id, Integer>>();
    	Map<String, Integer> badRoomNumsMap = new Map<String, Integer>();
    	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
    	set<id> roomTypeIds = new set<id>();
    	for (TypeOfRooms__c s: qTypeOfRooms) roomTypeIds.add(s.id);
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        String leadQuery = ' Select Rroom__c roomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate From Lead__c ' +
                         ' Where CancelBool__c != :leadCancelFlg ' +
                         ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
                         ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
                         ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
                         ' And refTypeOfRooms__c in :roomTypeIds'+
                         ' And Rroom__c != null '+
                         ' Group By Rroom__c, DAY_ONLY(convertTimezone(EntryTime__c)) ' +
                         ' Order by Rroom__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
        List<AggregateResult> useLeadRoomAvg = DataBase.query(leadQuery);
        // 予約から割り当て済部屋情報を格納する
        set<String> leadRoomUsedInfSet = new set<string>(); 
        for (AggregateResult ar : useLeadRoomAvg) {
            // 部屋タイプIDを取得する
            Id roomId = (Id)ar.get('roomId');
            // 到着日
            Date ciDate = (Date)ar.get('cidate');
            // 処理キーを取得する
            String roomKey = getRoomStockKey(roomId, ciDate);
            // 該当部屋は該当日に利用されている
            leadRoomUsedInfSet.add(roomKey);
        }
    	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
        String queryHd = CommSqlUtils.generateQueryString('RoomsStatus__c');
        // 部屋ステータス：故障　AND　処理結果は　修理済　以外の場合
        String queryWhere = ' where Status__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED) + '\'';
        queryWhere += ' And Result__c != \'' + String.escapeSingleQuotes(CommConst.ROOM_ST_TYPE_BED_FIN) + '\'';
        queryWhere += ' And StatusBeginDate__c <= :conEndDate ';
        queryWhere += ' And StatusEndDate__c >= :conStartDate';
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
        queryWhere += ' And RoomRef__r.TypeRoomRef__r.SumNotApplicableFlg__c != true ';
        // 2015/08/05 部屋タイプの集計対象外フラグの対応 END
        String queryStr = queryHd + queryWhere;
        for (RoomsStatus__c roomSt : Database.query(queryStr)) {
        	//
        	
            //badRoomSet.add(roomSt.RoomRef__c);
            List<Date> rangeList = getDateRange(roomSt.StatusBeginDate__c, roomSt.StatusEndDate__c);
            for (Integer i = 0; i < rangeList.size(); i++) {
            	// KEY=部屋タイプID+日付
            	String roomKey = getRoomStockKey(roomSt.RoomRef__c, rangeList[i]);
            	//　部屋タイプ＿日付単位存在格納
            	if(badRoomKeySet.contains(roomKey)) continue;
            	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] BEGIN
            	if(leadRoomUsedInfSet.contains(roomKey)) continue;
            	// 2018/04/04 部屋単位の予約情報を取得する[故障部屋は時間単位登録対応] END
            	// 該当日付の部屋は格納する
            	badRoomKeySet.add(roomKey);
            	// 部屋タイプ＿日付故障数統計
            	String roomTypeKey = getRoomStockKey(roomSt.TypeOfRoomTypeId__c, rangeList[i]);
            	if(!badRoomNumsMap.containsKey(roomTypeKey)) badRoomNumsMap.put(roomTypeKey, 0);
            	// 故障数＋１統計設定
				badRoomNumsMap.put(roomTypeKey, badRoomNumsMap.get(roomTypeKey) + 1);
            	
            	
            	/*
            	//badRoomMap.get(rangeList[i]).put(roomSt.RoomRef__c, roomSt.TypeOfRoomTypeId__c);
            	// 日付単位の故障部屋を確認する
            	Set<Id> bedRoomIdSet = badRoomMap.get(rangeList[i]);
            	// 該当故障部屋は未格納の場合
            	if (!bedRoomIdSet.contains(roomSt.RoomRef__c)) {
            		// 該当故障部屋の部屋タイプ判別
            		Map<Id, Integer> typeOfRoomNumsMap = badRoomNumMap.get(rangeList[i]);
            		if (!typeOfRoomNumsMap.containsKey(roomSt.TypeOfRoomTypeId__c)) {
            			typeOfRoomNumsMap.put(roomSt.TypeOfRoomTypeId__c, 1);
            		} else {
            			typeOfRoomNumsMap.put(roomSt.TypeOfRoomTypeId__c, typeOfRoomNumsMap.get(roomSt.TypeOfRoomTypeId__c) + 1);
            		}
            		// 重複部屋判別用SET
            		bedRoomIdSet.add(roomSt.RoomRef__c);
            	}*/
            }
        }

        return badRoomNumsMap;
    }
    	// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
	public Map<Integer, Decimal> mstMaxRoomsAllMap{get; set;}
	private List<RealAGT__c> agtMsgAllLst;
	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
	private List<RealAGT__c> getRealAgtData(Date conStartDate, Date conEndDate){
		return getRealAgtData(conStartDate,conEndDate,new Set<Id>());
	}	
	private List<RealAGT__c> getRealAgtData(Date conStartDate, Date conEndDate,Set<Id> typeSetId){
	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
		// 指定期間により、各ＡＧＴに提供する部屋数を取得、格納する
		// 期間設定の重複チェックが必要：トリガーに、同じ旅行会社、同じ部屋タイプ、期間重複存在すると、エラーが発生する
		String realMstQuery = ' select id, AgtMaxRooms__c, ' +
											// 2015/08/05 部屋タイプ集計対象外対応 BEGIN
											+ ' RoomTypeRel__r.SumNotApplicableFlg__c, '
											// 2015/08/05 部屋タイプ集計対象外対応 END
											// 設定期間
											+ ' StartDate__c, EndDate__c, '
											// 部屋タイプと支店コード
											+ ' RoomTypeRel__c, RoomTypeRel__r.Name, RoomTypeRel__r.ShopInfoRef__r.ShopCode__c, '
											+ ' RoomTypeRel__r.ShopInfoRef__r.Name, RoomTypeRel__r.ShopInfoRef__r.Seq__c, RoomTypeRel__r.seq__c, '
											// 旅行会社名
											+ ' AccountRef__c, AccountRef__r.Name, AccountRef__r.AliasName__c '
											+ ' from RealAGT__c  '
											// 2020/08/30 BUG-FIX-不显示失效的AGT WGCH BEGIN
											// + ' where (StartDate__c <= :conEndDate Or EndDate__c >= :conStartDate) '
											+ ' where (StartDate__c <= :conEndDate And EndDate__c >= :conStartDate) '
											// 2020/08/30 BUG-FIX-不显示失效的AGT WGCH END
											+ ' And AccountRef__r.AccountType__c = :ACCTYPE_TRAVE '
											+ ' And RoomTypeRel__c != null '
											+ ' And AgtMaxRooms__c > 0 ';
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			realMstQuery += ' And RoomTypeRel__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
			Set<String> shopSt = userInf.shopSt;
			realMstQuery += ' And RoomTypeRel__r.ShopInfoRef__r.ShopCode__c in :shopSt';
		}
		// 2021/03/16 最大部屋タイプ数表示制限機能追加 zy BEGIN
        if (!typeSetId.isEmpty()) {
        	realMstQuery += ' And RoomTypeRel__c in :typeSetId';
        }
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 zy END
		// 2015/09/01 多店舗機能対応 END
		realMstQuery+= ' Order By RoomTypeRel__r.ShopInfoRef__r.Seq__c, AccountRef__r.Name, RoomTypeRel__r.seq__c ';
		List<RealAGT__c> agtMsgLst = DataBase.query(realMstQuery);
		return agtMsgLst;
	}
	// 2020/05/29 在庫計算ロジック改修 WGCH END

    private static final String ACCTYPE_TRAVE = '旅行会社';
    
    public Boolean isHaveTravelInfo{get; private set;}
    public List<Id>travelIdList{get; private set;}
	// 2013/12/13 リアルＡＧＴ利用する部屋数情報を統計する
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
	// private void getRealAgtInfo (Date conStartDate, Date conEndDate){
	// 节约资源, 提高效率
	private void getRealAgtInfo (Date conStartDate, Date conEndDate) {
		getRealAgtInfo(conStartDate, conEndDate, new Map<String, GuestRoomStock__c>());
	}
	private void getRealAgtInfo (Date conStartDate, Date conEndDate, Map<String, GuestRoomStock__c> stockMap) {
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		// リアルAGT関連情報判別フラグ
		isHaveTravelInfo = true;
			
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		/*
		// 指定期間により、各ＡＧＴに提供する部屋数を取得、格納する
        // 期間設定の重複チェックが必要：トリガーに、同じ旅行会社、同じ部屋タイプ、期間重複存在すると、エラーが発生する
        String realMstQuery = ' select id, AgtMaxRooms__c, ' +
        									// 2015/08/05 部屋タイプ集計対象外対応 BEGIN
        									+ ' RoomTypeRel__r.SumNotApplicableFlg__c, '
        									// 2015/08/05 部屋タイプ集計対象外対応 END
        									// 設定期間
        									+ ' StartDate__c, EndDate__c, '
                                            // 部屋タイプと支店コード
                                            + ' RoomTypeRel__c, RoomTypeRel__r.Name, RoomTypeRel__r.ShopInfoRef__r.ShopCode__c, '
                                            + ' RoomTypeRel__r.ShopInfoRef__r.Name, RoomTypeRel__r.ShopInfoRef__r.Seq__c, RoomTypeRel__r.seq__c, '
                                            // 旅行会社名
                                            + ' AccountRef__c, AccountRef__r.Name, AccountRef__r.AliasName__c '
                                            + ' from RealAGT__c  '
                                            + ' where (StartDate__c <= :conEndDate Or EndDate__c >= :conStartDate) '
                                            + ' And AccountRef__r.AccountType__c = :ACCTYPE_TRAVE '
                                            + ' And RoomTypeRel__c != null '
                                            + ' And AgtMaxRooms__c > 0 ';
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			realMstQuery += ' And RoomTypeRel__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            realMstQuery += ' And RoomTypeRel__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
	// 2015/09/01 多店舗機能対応 END
        realMstQuery+= ' Order By RoomTypeRel__r.ShopInfoRef__r.Seq__c, AccountRef__r.Name, RoomTypeRel__r.seq__c ';
        List<RealAGT__c> agtMsgLst = DataBase.query(realMstQuery);
        */
        if(agtMsgAllLst == null) agtMsgAllLst = getRealAgtData(conStartDate, conEndDate);
        List<RealAGT__c> agtMsgLst = agtMsgAllLst;
        // 2020/05/29 在庫計算ロジック改修 WGCH END
//System.debug(LoggingLevel.INFO,  'agtMsgLst:::' + agtMsgLst);
		if (agtMsgLst.isEmpty()) {
			isHaveTravelInfo = false;
			return;
		}
		// リアルAGT関連表示用情報を格納用
		dispAgtRecordMap = new Map<Id, TrvaleRecord>();
		// 旅行会社IDリスト格納する
		travelIdList = new List<Id>();

		// リアルＡＧＴマスタ設定情報を取得する
		// 各旅行開始社、期間により、販売最大可能部屋数
		for (RealAGT__c s: agtMsgLst) {
			// 最大販売できる部屋数
			Decimal mstMaxRooms = CommUtils.nullToZero(s.AgtMaxRooms__c);
			// 新旅行会社情報
			if (!dispAgtRecordMap.containsKey(s.AccountRef__c)) { 
				// 旅行会社
				TrvaleRecord travelRec = new TrvaleRecord();
				travelRec.travelId = s.AccountRef__c;
				travelRec.travelName = CommUtils.isBlank(s.AccountRef__r.AliasName__c) ? s.AccountRef__r.name : s.AccountRef__r.AliasName__c;
				// 旅行会社関連している
				dispAgtRecordMap.put(s.AccountRef__c, travelRec);
				// 旅行会社情報
				travelIdList.add(s.AccountRef__c);
			}
			
			// 該当部屋タイプ設定情報は配列に追加する
			TrvaleRecord travelRec = dispAgtRecordMap.get(s.AccountRef__c);
			// 部屋タイプの表示情報初期化
			dispRecord nwRec = travelRec.getDispRecord(s.RoomTypeRel__c);
			// 部屋タイプIDの設定
			nwRec.roomTypeId = s.RoomTypeRel__c;
			// 部屋タイプ名称の設定
			nwRec.roomTypeNm = s.RoomTypeRel__r.Name;
			// 旅行会社へ期間単位で、部屋契約するため、一か月間に、同じ部屋タイプは２件存在可能性がありますので
			Boolean isNoExistFlg = nwRec.roomList.isEmpty();
			// 2020/04/30 予約ポップの残室数画面を改修 WGCH BEGIN
			// 部屋タイプの日付単位の料金情報を
			Map<Date, Decimal> monthPriceMap = null;
			// 部屋タイプ単位の初期化定義
			if(raceRatePriceMap != null && !raceRatePriceMap.containsKey(nwRec.roomTypeId)){
				raceRatePriceMap.put(nwRec.roomTypeId, new Map<Date, Decimal>());
				// 部屋タイプの日付単位の料金情報を
				monthPriceMap = raceRatePriceMap.get(nwRec.roomTypeId);
			}
			// 2020/04/30 予約ポップの残室数画面を改修 WGCH END
			// 月間の在庫数初期化[最大使える部屋数]設定する
			for(Integer day = 1; day <= daysInMonth; day ++){
				//Date hibiDt = Date.newinstance(thisYear, thisMonth, day);
				Date hibiDt = startDate.addDays(day-1);
				// 故障部屋数取得、設定する[旅行会社に対して、故障部屋の数を計算しますか] TODO?
				//String badKey = getRoomStockKey(s.Id, hibiDt);
				//Integer badRooms = badRoomMapInfo.containsKey(badKey) ? badRoomMapInfo.get(badKey) : 0;
				Integer badRooms = 0;
				Decimal intMaxRooms = mstMaxRooms;
				// マスタデータの提供期間内の部屋数は統計を行う
				if (hibiDt < s.StartDate__c || hibiDt > s.EndDate__c) {
					intMaxRooms = 0;
				}
				// 全月分部屋在庫数初期化設定を行う
				// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
				if (isNoExistFlg) nwRec.roomList.add(new GuestRoomInfo(new GuestRoomStock__c(QtyOfStock__c=(intMaxRooms-badRooms),StockDate__c=hibiDt)));
				else nwRec.roomList[day-1].stock.QtyOfStock__c += (intMaxRooms-badRooms); 
				// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
				// 提供数
				// 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
				if (s.RoomTypeRel__r.SumNotApplicableFlg__c != true) {
				mstAgtRoomsMap.put(day, mstAgtRoomsMap.get(day) + intMaxRooms);
				}
				// 2015/08/05 部屋タイプの集計対象外フラグの対応 END
				// 2020/04/30 予約ポップの残室数画面を改修 WGCH BEGIN
				// 月間の料金表情報初期化処理
				if(monthPriceMap != null) monthPriceMap.put(hibiDt, 0);
				// 2020/04/30 予約ポップの残室数画面を改修 WGCH END
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
				// 管理キー(部屋タイプID_日付)
				nwRec.roomList[day-1].managerKey = getManagerKey(nwRec.roomTypeId, hibiDt);
				// AGT管理キー(部屋タイプID_日付_取引先ID)
				nwRec.roomList[day-1].managerKey2 = getManagerKey2(nwRec.roomList[day-1].managerKey, s.AccountRef__c);
				// 获取对应的 部屋在庫管理数据SOBJ
				GuestRoomStock__c stock = stockMap.get(nwRec.roomList[day-1].managerKey);
				// 如果存在SOBJ, 把调整过的的AGT残室数追加到AGT最大残室数上
				if(stock != null){
					Map<String, Object> atgChangeMap = StockChangeHelpUtils.getAGTChangeRoomsMap(stock.AGTChangeRoomsJSON__c);
					nwRec.roomList[day-1].stock.QtyOfStock__c += CommUtils.nullToIntZero(atgChangeMap.get(s.AccountRef__c));
					// 2021/06/31 #JP10243　対応　by zy BEGIN
					intMaxRooms = nwRec.roomList[day-1].stock.QtyOfStock__c;
					// 2021/06/31 #JP10243　対応　by zy END
				}
				setAgtStockInfoMap(nwRec.roomTypeId, hibiDt, s.AccountRef__c, nwRec.roomList[day-1].stock.QtyOfStock__c);
				// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
				// 2021/06/31 #JP10243　対応　by zy BEGIN
				if (s.RoomTypeRel__r.SumNotApplicableFlg__c != true) {
					lastAgtRoomsMap.put(day, lastAgtRoomsMap.get(day) + intMaxRooms);
				}
				// 2021/06/31 #JP10243　対応　by zy END
			}
		} // End For リアルAGTMSTデータ

        // 期間内有効な予約データを取得する
        // 取得する条件：
        // 1:到着日は検索期間
        // 2:予約は有効
        // 3:旅行会社情報 OR 旅行会社情報.親取引先の(AccountType__c)は[旅行会社]
        // ---------------------------
        // 有効な予約データ件数を統計する
        // ---------------------------
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        // 2016/08/01 リアルAGTの残室計算ロジック不具合修正 BEGIN
		//String leadQuery = ' Select Count(ID) usedRoom ,SalesOfficeInfoRef__c travelId, refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate, refTypeOfRooms__r.SumNotApplicableFlg__c SumNotAppFlg From Lead__c ' +
		String leadQuery = ' Select Count(ID) usedRoom ,SalesOfficeInfoRef__c travelId, SalesOfficeInfoRef__r.ParentId parTravelId, refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate, refTypeOfRooms__r.SumNotApplicableFlg__c SumNotAppFlg From Lead__c ' +
		// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 END
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And SalesOfficeInfoRef__r.AccountType__c = :ACCTYPE_TRAVE ' +
						 // 2015/09/25 BEGIN 旅行会社　OR　旅行会社の親会社はマスタに定義されている場合、該当残室数は合計を行う
						 //' And SalesOfficeInfoRef__c IN : travelIdList ' +
						 ' And ( SalesOfficeInfoRef__c IN : travelIdList OR SalesOfficeInfoRef__r.ParentId in :travelIdList)' +
						 // 2015/09/25 END 旅行会社　OR　旅行会社の親会社はマスタに定義されている場合、該当残室数は合計を行う
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ';
		// 2020/05/29 在庫計算ロジック改修 WGCH BEGIN
		if(isStockSyncIsMode) leadQuery += ' And AgtFlg__c = true';			 
		// 2020/05/29 在庫計算ロジック改修 WGCH END
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			leadQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            leadQuery += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
		// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 BEGIN
		//leadQuery +=	' Group By SalesOfficeInfoRef__c, refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)), refTypeOfRooms__r.SumNotApplicableFlg__c ' +
		leadQuery +=	' Group By SalesOfficeInfoRef__c, SalesOfficeInfoRef__r.ParentId, refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)), refTypeOfRooms__r.SumNotApplicableFlg__c ' +
		// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 END
				  				' Order by SalesOfficeInfoRef__c, refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c)), refTypeOfRooms__r.SumNotApplicableFlg__c ';
		for (AggregateResult ar : DataBase.query(leadQuery)) {
			// 旅行会社ＩＤを取得する
			Id travelCompId = (Id)ar.get('travelId') ;
			// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 BEGIN
			Id parTravelCompId = (Id)ar.get('parTravelId') ;
			// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 END
			// 関連の部屋タイプ情報を取得する
			TrvaleRecord travelRec = dispAgtRecordMap.get(travelCompId);
			// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 BEGIN
			if (travelRec == null) {
				travelRec = dispAgtRecordMap.get(parTravelCompId);
				if (travelRec == null) continue;
			}
			// 2016/08/01 リアルAGTの残室計算ロジック不具合修正 END
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
			dispRecord nwRec = travelRec.getDispRecord(roomTypeId);
			if (nwRec.roomList.isEmpty()) continue;
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 使える部屋数
        	Decimal userRoom = (Decimal)ar.get('usedRoom'); 
        	// 予約データの到着日から月の頭日の日付数
			Integer days = conStartDate.daysBetween(ciDate);
			// Head Index
			Integer headIdx = days + 1;
			// 販売部屋合計値
			// 2015/08/05 部屋タイプの集計対象外フラグの対応 BEGIN
			boolean sumNotAppFlg = (Boolean)ar.get('sumNotAppFlg');
			if (sumNotAppFlg == null || !sumNotAppFlg) {
			if (!usedAgtRoomsMap.containsKey(headIdx)) usedRoomsMap.put(headIdx, userRoom);
			else usedAgtRoomsMap.put(headIdx, (usedAgtRoomsMap.get(headIdx) + userRoom));
			}
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
			// 既に使用した部屋数を計算を行う
			nwRec.roomList[days].stock.QtyOfStock__c =nwRec.roomList[days].stock.QtyOfStock__c - userRoom;
			// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
			setAgtStockInfoMap(roomTypeId, ciDate, travelCompId, nwRec.roomList[days].stock.QtyOfStock__c);
			// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		} // End For(予約データ取得・在庫設定処理完了)
	}

	// 開始日から終了日まで　期間日付リストを取得する
	private List<Date> getDateRange(Date pst, Date pet) {
		Date st = (pst > pet ? pet : pst);
		Date et = (pst > pet ? pst : pet);
		Integer days = st.daysBetween(et);
		List<Date> dtRange = new List<Date>();
		for (Integer i = 0; i <= days; i++) {dtRange.add(st.addDays(i));}
		return dtRange;
	}

	/**
	* 予約情報拡張設定項目作成する
	**/
	//private String[] extendFields = new String[]{};
	//private transient Component.Apex.pageBlockSection psection;
	public Component.Apex.pageBlockSection getInputExtendFields () {
		// 拡張情報を取得する
		Component.Apex.pageBlockSection psection = parseFieldsXml(branchShopNm);
		return psection;
	}
	
	/**
	* 宿泊の予約データを登録処理
	**/	
  	public PageReference bookingCreate() {

		// 事前チェックを行う
		if (!preBookingCreate()) {
			doAction(0);
			return null;
		}
  		// Hidden項目から到着日を取得する
  		Date defaultDate = Date.parse(startDays);

  		/* 2013/01/21 到着時間と出発時間、設定によて、自動取得、設定を行う */
        //Datetime defCheInDt = Datetime.newInstance(defaultDate, CommConst.defCheckInTime);
        //Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), CommConst.defCheckOtTime);
        Datetime defCheInDt = Datetime.newInstance(defaultDate, converHHMMtoTime(newLead.Field4__c));
        Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), converHHMMtoTime(newLead.Field3__c));
  		/*
  		Datetime defCheInDt = Datetime.newInstance(defaultDate.year(), defaultDate.month(), defaultDate.day(), 15, 30, 0);
  		Datetime defCheOutDt = defCheInDt.addHours(18).addMinutes(30);
  		*/
  		// 更新用リスト
  		/* 2012/07/17 予約共通トリガーで、在庫計算を行う
  		List<GuestRoomStock__c> updList = new List<GuestRoomStock__c>();
  		for(GuestRoomStock__c item : [select id, QtyOfStock__c from GuestRoomStock__c
  											where RoomTypeRef__c = :roomType
  											and StockDate__c >= :defaultDate
  											and StockDate__c < :defaultDate.addDays(staysNums)]){
  			updList.add(new GuestRoomStock__c(id=item.id,QtyOfStock__c=item.QtyOfStock__c-bookingRooms));
  		}*/
  		// 2013/10/07お客様情報を自動登録機能追加する
  		upsertContact();
  		// プラン自動作成[ベースプランを選べてそのまま予約データを登録する場合、ベースプランCLONEして、新プランを作成して、予約に登録する]
  		// 2014/06/20 プラン自動作成が外す
  		/*
  		if (newLead.Field310__c != null && basePlanPriceMap.containsKey(newLead.Field310__c)) 
  			newLead.Field310__c = cloneBasePlanInfo(newLead.Field310__c);*/
  		// 挿入用リスト
  		List<Lead__c> insList = new List<Lead__c>();
  		// 予約受付日を処理当日に指定
  		newLead.ReservedDate__c = Datetime.now();
  		// 予約レコードタイプを設定する
		//String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
    	//RecordType s = [select id,DeveloperName, Name from RecordType where SobjectType = :leadLocalName And DeveloperName  =:'BookingRecType'][0];
    	//newLead.RecordTypeId = s.id;
    	// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
    	LeadIndex__c newLeadIndex = new LeadIndex__c();
    	newLeadIndex.EntryDate__c = defCheInDt.date();
    	newLeadIndex.EntryTime__c = defCheInDt.format('HH:mm');
//		newLeadIndex.EntryTime__c = newLead.Field4__c;
//    	newLeadIndex.DepartureDate__c = defCheOutDt.addDays(staysNums).date();
//    	newLeadIndex.DepartureTime__c = defCheOutDt.addDays(staysNums).format('HH:mm');
        newLeadIndex.DepartureDate__c = defCheInDt.addDays(staysNums).date();
        newLeadIndex.DepartureTime__c = defCheOutDt.format('HH:mm');
//		newLeadIndex.DepartureTime__c = newLead.FIeld3__c;
    	// 顧客ID + RandomID
    	// 2012/12/20 -> Null Setup
    	//newLeadIndex.ID__c = CommUtils.nullToBlank(newLead.Relcontact__c) + '_' + Crypto.getRandomLong();
    	newLeadIndex.contactRef__c = newLead.Relcontact__c;

		newLeadIndex.EventSource__c = 'FromUI';
		newLeadIndex.Nights__c = staysNums;
		newLeadIndex.Rooms__c = bookingRooms;
		newLeadIndex.LeadName__c = newLead.name;
		// 予約チャネル
		newLeadIndex.Channel__c = newLead.Field2__c;
		// セグメント
		newLeadIndex.Segment__c = newLead.Segment__c;
		// 支払方法
		newLeadIndex.Payment__c = newLead.Field315__c;
		// 特記事項
		newLeadIndex.Comment__c = newLead.Comment3__c;
		insert newLeadIndex;

		newLead.LeadIndexRef__c = newLeadIndex.Id;
		// 予約インデックス情報を作成する 2012/08/23 ADD END
  		// 予約の内容を作成する
  		String leadName = newLead.name;
  		// また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
  	    String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);

		// 自動設定内容
		// 受付日
		newLead.ReservedDate__c = System.now();
		// 受付者
		newLead.ReservedContact__c = UserInfo.getName();
		// 日帰り場合
		if (staysNums == 0) {
  			newLead.EntryTime__c = defCheInDt.addDays(0);
  			newLead.Departure__c = defCheInDt.addDays(0);
			newLead.refTypeOfRooms__c = roomType;
  			for(Integer j = 0; j < bookingRooms; j ++ ){
  				 Lead__c cloneLead =  newLead.clone(false, true);
  			   	// 2013/07/20 UPDATE
  			   	cloneLead.RoomGroupNo__c = j;
  			   	if(j == 0) cloneLead.name = (bookingRooms > 1 ? strRoomDelegatePrefix : '') + cloneLead.name;
				else setLeadValue(cloneLead);
  				insList.add(cloneLead);
  			}
		} else {
			// 1泊以上場合
	  		for(Integer i = 0; i < staysNums; i ++){
	  			//泊目
	  			if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + Label.CONST_003_0131 + ' ' + leadName;
	  			newLead.EntryTime__c = defCheInDt.addDays(i);
	  			newLead.Departure__c = defCheOutDt.addDays(i);
	  			// 到着時刻
	  			newLead.Field4__c = newLeadIndex.EntryTime__c;//newLead.EntryTime__c.format('HH:mm');
	  			// 出発時刻
	  			newLead.FIeld3__c = newLeadIndex.DepartureTime__c;//newLead.Departure__c.format('HH:mm');
	  			newLead.refTypeOfRooms__c = roomType;
	  			for(Integer j = 0; j < bookingRooms; j ++ ){
	  			   	   Lead__c cloneLead =  newLead.clone(false, true);
		  			   	// 2013/07/20 UPDATE
		  			   	cloneLead.RoomGroupNo__c = j;
		  			   	if(j == 0) cloneLead.name = (bookingRooms > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
		  			   	else setLeadValue(cloneLead);
		  				insList.add(cloneLead);
	  			}
	  		}

		}
  		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
  		try{
  			// 2012/12/22 WSQ ADD
  			// SUBINDEX自動作成
  			CommLogicProcess logic = new CommLogicProcess();
  			logic.autoCreateIndexSub(insList);
  			// データの更新
//  			update updList;
  			// データの挿入
  			insert insList;
  			// 料金表情報にて、予約情報見積もり明細自動設定を行う
  			autoCreateBookingEstItems(insList, newLeadIndex.EntryDate__c,newLeadIndex.DepartureDate__c);
  			// 画面データを再構築する
  			doAction(0);
  		}catch (Exception e){
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            Database.rollback(sp);
            bookingCreateOK = false;
            return null;
  		}
  		// 2013/06/24 ADD BEGIN
  		// Data Create OK
  		bookingCreateOK = true;
		// 設定情報をクリアする【注意：クリアしないと、常にContact　IDを更新されない】
  		newContact = new Contact();
  		return null;
  	}
  	// 20１4/06/20 プラン自動作成機能外す
  	/*
  	// Clone Plan Info Action
  	private Id cloneBasePlanInfo (Id planId) {
  		System.currentPageReference().getParameters().put('clone', '1');
  		System.currentPageReference().getParameters().put('popup', '1');
  		System.currentPageReference().getParameters().put('rp', String.valueOf(planRoomPrice-planPrice));
  		ApexPages.StandardController contrl = new ApexPages.StandardController(new Plan__c(Id = planId));
  		PlanProductSetup setup = new PlanProductSetup(contrl);
  		setup.planInfo.Name = setup.planInfo.Name + '('+String.valueOf(CommUtils.nullToZero(setup.planInfo.Price__c))+')';
  		setup.savePlanDetail();
  		return setup.planInfo.Id;
  	}*/
  	// プランなしの予約データに対して、料金表にて、見積もり明細データを作成する
  	private void autoCreateBookingEstItems(List<Lead__c> leads, Date stDate, Date edDat) {
  		// 料金情報設定用商品が非存在する場合、処理中止
  		if (roomPriceInfo == null) return;
  		// 予約の料金表情報を設定する
  		List<Lead__c> targets = new List<Lead__c>();
  		for (Lead__c lead : leads) {
  			//if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
  			// 予約人数は０の場合、見積もり明細作成対象外
  			// プラン未設定 && 予約人数は０以上場合、室料の見積もり明細を自動作成する
  			if (lead.Field310__c == null && CommUtils.nullToZero(lead.StayPersons__c) > 0) {
  				targets.add(lead);
  			}
  		}
  		// 自動料金設定する予約データがない場合、処理終了
  		if (targets.isEmpty()) return;
  		// これから、料金表設定情報にて、見積もり明細情報を作成する

  		// 店舗単位の期間範囲のTier情報を取得する
		String queryRRDetailHeader = ' Select SearchKey__c, Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
		// 店舗条件
		// 2015/09/01 多店舗機能対応 BEGIN
		if (!CommUtils.isBlank(branchShopNm)) {
			queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		}else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c in :shopSt';
        }
		// 2015/09/01 多店舗機能対応 END
		// 該当期間のTIER設定配列を格納する
		
		// 期間単位のTier情報を取得する
		Map<Date, String> setupTierMap = new Map<Date, String>();
		Set<String> tierSet = new Set<String>();
		// 支店コード_日付/TIER
		for (RackRateTableDetail__c detail : DataBase.query(queryRRDetailString)) {
			// 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 BEGIN
			String key = CommUtils.nullToBlank(detail.ShopInfoRef__c) + '_' + detail.PriceSetupDate__c;
			//CommUtils.nullToBlank(branchShopNm) + '_' + detail.PriceSetupDate__c;
			// 存在しているゴミデータを回避するため、検索キーをチェックを追加する
			String searchKey = CommUtils.nullToBlank(detail.SearchKey__c);
			if (!CommUtils.isBlank(searchKey) && searchKey != key) continue;	// ゴミデータは設定しない
			// 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 END
			setupTierMap.put(detail.PriceSetupDate__c, detail.Tier__c);
			tierSet.add(detail.Tier__c);
		}
		// 料金表からDefaultの料金情報を取得する
		Id roomTypeId = newLead.refTypeOfRooms__c;
		
		// 料金表からTier関連金額を取得する
  		String defTier = getDefTier(branchShopNm);
		tierSet.add(defTier);
		// 人数
		String persons = CommUtils.nullToBlank(newLead.StayPersons__c);
		// 同じ部屋タイプ、同じTIER、人数で、料金情報を取得する
		List<RackRateTable__c> raceRateMst = [select id, Name,Tier__c, Price__c from RackRateTable__c where RoomTypeRel__c = :roomTypeId And Tier__c in :tierSet And Persons__c = :persons ]; 
  		// 同じ部屋タイプ、同じ人数で、各TIER情報を取得する
  		Map<String, Decimal> tierMstMap = new Map<String, Decimal>();
  		for (RackRateTable__c raceRate : raceRateMst) {
  			tierMstMap.put(raceRate.Tier__c,  raceRate.Price__c);
  		}
  		
  		List<BookingEstimateItem__c> insertEstItems = new List<BookingEstimateItem__c>();
  		for (Lead__c lead : targets) {
  			// 到着日
  			Date keyDate = lead.EntryTime__c.date();
  			String tierKey = setupTierMap.containsKey(keyDate) ? setupTierMap.get(keyDate) : defTier;
  			Decimal priceVal = (tierMstMap.containsKey(tierKey) ? tierMstMap.get(tierKey) : 0);
  			// 日付から料金情報を取得する
  			BookingEstimateItem__c item = new BookingEstimateItem__c(
  				refBooking__c = lead.Id,
  				refAccountMaster__c = roomPriceInfo.Id,
  				Amount__c = newLead.StayPersons__c,
  				UnitPrice__c = priceVal
  			);
  			insertEstItems.add(item);
  		}
  		if (!insertEstItems.isEmpty()) insert insertEstItems;
  	}
  	
  	// お客様情報新規登録・更新を行う
    private void upsertContact() {
    	// 顧客情報の新規作成
    	if (newContact.Id == null) {
    		String[] names = CommUtils.splitName(contactName);
    		newContact.LastName = names[0];
    		newContact.FirstName = names[1];
    	}
    	// 2016/10/19 お客様重複管理機能対応 BEGIN
    	//upsert newContact;
    	newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact);
    	// 2016/10/19 お客様重複管理機能対応 END
    	newLead.Relcontact__c = newContact.Id;
    }
	/**
	* 顧客情報最新取得を行う
	**/
	// SOQL顧客情報項目定義
	private static final String queryContStr = 'Select Id, Phone, Name1__c, Name, Memo6__c, Memo5__c, Memo4__c, Memo3__c, Memo2__c, Memo1__c, Katakana__c, KanaName2__c, KanaName1__c,Account.Name,ApplicantName__c,ApplicantPhone__c From Contact ';
	@remoteAction
	public static DTO.ContactInfo refreshContcatInfo(String contactId, String contactName) {
		String whereStr = ' where id = \'' + CommUtils.escStr(contactId) + '\' ';
		whereStr += ' And Name = \'' + CommUtils.escStr(contactName) + '\' limit 1';
		List<Contact> contactLst = Database.query(queryContStr + whereStr);
		if (contactLst.isEmpty()) {
			return new DTO.ContactInfo(new Contact());
		} else {
			return new DTO.ContactInfo(contactLst[0]);
		}
	}
	/*
	public class ContactInfo {
		public ContactInfo(Contact c){
			KanaName = CommUtils.nullToBlank(c.KanaName1__c);
			KatakanaName = CommUtils.nullToBlank(c.Katakana__c);
			phone = CommUtils.nullToBlank(c.Phone);
		}
		public String KanaName{get;set;}	// カタカナ
		public String KatakanaName{get;set;} //ひらがな、
		public String phone{get;set;}		// Phone
	}*/
	
	// プラン明細情報を取得する
	@remoteAction
	public static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
		return ProductItemUtils.getPlanDetailList(planId);
	}
	// 商品コードにより、会計商品情報を取得する
	@remoteAction
	public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
  	// 曜日の取得処理
  	private String getYobi(Date vdDate){
  		/*
		datetime tDate = datetime.newInstance(vdDate.year(), vdDate.month(), vdDate.day());
		String week = tDate.format('E');
		if(week == 'Sun'){
			return '日';
		}else if(week =='Mon'){
			return '月';
		}else if(week =='Tue'){
			return '火';
		}else if(week =='Wed'){
			return '水';
		}else if(week =='Thu'){
			return '木';
		}else if(week =='Fri'){
			return '金';
		}else if(week =='Sat'){
			return '土';
		}
		return null;*/
		return CommUtils.getYobi(vdDate);
	}
	private void setLeadValue( Lead__c cloneLead){
		// 予約データの分割に登録する
		if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
		// 親部屋に集めるの場合、下記処理を行う
 		cloneLead.Comment3__c = null;
 		 // 代表部屋以外のデータ
 	    cloneLead.StayPersons__c = 0;
	    // 大人人員(男性)
	    cloneLead.Mans__c = 0;
		// 大人人員(女性)
		cloneLead.Femails__c = 0;
		// 子供A人数
	    cloneLead.ChildFA__c = 0;
		 // 子供B人数
		cloneLead.Childs__c = 0;
		 // 子供C人数
		cloneLead.ChildC__c = 0;
		// プラン情報 <- NULL
		cloneLead.Field310__c = null;
	}
  	// インナークラス・ヘッダー
  	public class dispHeader{
  		public String label{get;set;}
  		public String name{get;set;}
  		public Integer days{get;set;}
  		public String holidayLab{get;set;}		// 祝い日Label
  		public String yyyymmdd{get;set;}
  		public dispHeader(Integer p0, String p1, Date p2){
  			label = p1;
  			name = p2.format();
  			days = p0;
  			yyyymmdd = DateTime.newInstance(p2.year(),p2.month(),p2.day()).format('yyyyMMdd');
  		}
  	}

  	// インナークラス・データ
  	public class dispRecord{
  		public Id roomTypeId{get;set;}
  		public String roomTypeNm{get;set;}
  		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
        //public List<GuestRoomStock__c> roomList{get;set;}
        // 2018/03/15 多店舗対応 by zy BEGIN
        public String shopId;
        // 2018/07/27 宿泊税計算 WGCH BEGIN
        // public String shopCode;
        public String shopCode{get;set;}
        // 2018/07/27 宿泊税計算 WGCH END
        // 2018/03/15 多店舗対応 by zy END
        public List<GuestRoomInfo> roomList{get;set;}
        // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
        public dispRecord(){
        	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
        	roomList = new List<GuestRoomInfo>();
        	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
        }
  	}


	// 旅行会社情報
	public class TrvaleRecord {
		public Id travelId					{get; set;}
		public String travelName		{get; set;}
		private List<dispRecord> roomTypes{get; set;}
		private Map<Id, dispRecord> existRecMap;
		public TrvaleRecord() {
			roomTypes = new List<dispRecord>();
			existRecMap = new Map<Id, dispRecord>();
		}
		public dispRecord getDispRecord(Id roomTypeId) {
			if (!existRecMap.containsKey(roomTypeId))  {
				dispRecord rec = new dispRecord();
				existRecMap.put(roomTypeId, rec);
				roomTypes.add(rec);
			}
			return existRecMap.get(roomTypeId);
		}

		public List<dispRecord> getRoomTypes() {
			return roomTypes;
		}
	}

    public class colStatus {
    	public colStatus() {
    		bkColor = '';
    		disable = false;
    	}
    	public colStatus(String color) {
    		bkColor = color;
    		disable = false;
    	}
    	// 背景色
    	public String bkColor{get; set;}
    	// クリック不能制御
    	public Boolean disable{get; set;}
    }

	// ******************************************************
	// 2015/09/14 EDIT BEGIN (TLから最新取得の販売状態情報を格納する)
	// ******************************************************
	public transient List<ShopInfo> showShopList{get; private set;}
	// AGT販売先表示情報の格納一覧[販売先単位別情報を表示する用]
	public transient map<String,List<TlSalesInfo>> netAgtInfoMap{get; private set;}		// ネット販売
	public transient map<String,List<TlSalesInfo>> realAgtInfoMap{get; private set;}		// 旅行会社販売
	// SF側の部屋タイプレイアウトを表示する[SF部屋タイプ単位]map<店舗コード, List<該当部屋タイプの販売情報>
	public transient map<String,List<SfRoomTypeInfo>> sfRoomTypeAgtInfoMap{get; private set;}	// 店舗単位の部屋タイプ
	// TLの情報取込みエラーチェック
	public transient boolean isStockTlSalesInfoNoErrFlg{get; private set;}

	// *******************************************
	// 2015/09/14 EDIT BEGIN(TL側の販売状態を取得する)
	// *******************************************
	private boolean getTlSalesInfo(Date conStartDate, Date conEndDate) {

		// ネット販売とリアル販売の在庫、残室数照会APIを呼び出す
		// 多店舗兼務　かつ　ALLの場合、兼務店舗範囲の販売状態情報を確認する
		showShopList = new List<ShopInfo>();
		map<String, String> shopInfoMap = new map<String, String>();
		for (SelectOption so : branchShopLst) { shopInfoMap.put(so.getValue(), so.getLabel()); }
		
		// ALLの場合、含めされている店舗リストは全部取得対象で、TLから在庫情報を取得する
		if (CommUtils.isBlank(branchShopNm)) {
			// ALLの店舗情報から取得する
			for (SelectOption so : branchShopLst) { 
				// XMLに定義されている
				if (!TL_ServiceConfigHelp.isContractShop(so.getValue())) continue;
				showShopList.add(new ShopInfo(so.getValue(), so.getLabel())); 
			}
			// 店舗定義情報なしの場合、対応する
			if (branchShopLst.isEmpty() && TL_ServiceConfigHelp.isContractShop(branchShopNm)) showShopList.add(new ShopInfo('',''));
		} else {
			// 契約店舗のみ、情報設定
			if (TL_ServiceConfigHelp.isContractShop(branchShopNm)) {
				// 指定の店舗コードから販売状態を取得する
				showShopList.add(new ShopInfo(branchShopNm, shopInfoMap.get(branchShopNm)));
			}
		}
		// 対象なし、処理中止
		if (showShopList.isEmpty()) return true;
		
		// 照会期間情報を設定する
		String strStartDt = DateTime.newInstance(conStartDate.year(),conStartDate.month(),conStartDate.day()).format('yyyyMMdd');
		String strEndDt = DateTime.newInstance(conEndDate.year(),conEndDate.month(),conEndDate.day()).format('yyyyMMdd');
		// 店舗表示情報の初期化
		for (ShopInfo shop : showShopList) {
			// 合計値情報を初期化する
			for (dispHeader disp : dispHeaders) {
				shop.remaindCountSumMap.put(disp.yyyymmdd, 0);
			}
		}
		// 初期化処理
		netAgtInfoMap = new map<String, List<TlSalesInfo>>();	// 店舗単位にネット販売の残室情報
		realAgtInfoMap = new map<String, List<TlSalesInfo>>();	// 店舗単位にリアル販売の残室情報
		sfRoomTypeAgtInfoMap = new map<String, List<SfRoomTypeInfo>>();// 店舗単位に各部屋タイプの残室情報
		
		// 販売先情報を取得する map<店舗コード_販売先コード>
		map<String, TlSalesInfo> locNetAgtMap = new map<String, TlSalesInfo>();
		map<String, TlSalesInfo> locRealAgtMap = new map<String, TlSalesInfo>();
		// ネット販売室タイプグループ情報を格納する[map<店舗コード_室タイプグループコード, グループ情報]
		map<String, TlGroupRmTypeInfo> locNetGroupInfoMap = new map<String, TlGroupRmTypeInfo>();
		// API SERVICE 初期化
		TL_ServiceCtrl tlService = new TL_ServiceCtrl();
		// 指定の多店舗情報から各店舗の在庫情報を取得する
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			// 店舗情報初期化する
			// 店舗単位に関連情報を格納する
			netAgtInfoMap.put(shopCd, new List<TlSalesInfo>());
			realAgtInfoMap.put(shopCd, new List<TlSalesInfo>());
			List<TlSalesInfo> netAgtInfoList = netAgtInfoMap.get(shopCd);
			List<TlSalesInfo> realAgtInfoList = realAgtInfoMap.get(shopCd);
			//　店舗の部屋タイプ単位情報を格納する
			if (isSfRoomTypeLayout) sfRoomTypeAgtInfoMap.put(shopCd, new List<SfRoomTypeInfo>());
//System.debug(logginglevel.INFO, 'INIT sfRoomTypeAgtInfoMap:::' +sfRoomTypeAgtInfoMap);	
			// ネット販売先の販売状態(2. 在庫状況照会(ネット販売)API )
			TL_NetStockSearchService.extractionCondition condition
				= new TL_NetStockSearchService.extractionCondition();
			condition.extractionProcedure = '2';
			condition.searchDurationFrom = strStartDt;
			condition.searchDurationTo = strEndDt;
			// CALL API START
			TL_NetStockSearchService.stockSearchForNetResponse rep = 
				tlService.callNetStockSearchService(shopCd, condition);
			// 指定店舗の販売状態を戻る
			// 異常発生する場合、エラーは画面に戻る
			if (!rep.commonResponse.isSuccess) {
				// ERROR 戻る
				String errMsg = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
				return false;
			} 
			// 該当店舗の販売状態を戻る場合
			else {
				// ネット室グループ単位情報「指定日付期間」
				rep.netRmTypeGroupAndDailyStockStatusList = (rep.netRmTypeGroupAndDailyStockStatusList == null)
									? new TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus[0] 
									: rep.netRmTypeGroupAndDailyStockStatusList;
				// 室グループ単位の販売状態[ネット室タイプグループ日別在庫状況]
				for (TL_NetStockSearchService.netRmTypeGroupAndDailyStockStatus status : rep.netRmTypeGroupAndDailyStockStatusList) {

					// ネット室タイプグループコード
					string netRmTypeGroupCd = status.netRmTypeGroupCode;
					string netRmTypeGroupNm = status.netRmTypeGroupName;
					string netRemainingCount = status.remainingCount;
					string netSalesDate = status.saleDate;
					
					// 室タイプグループ単位の残室数を格納する
					String gpKey = shopCd + '_' + netRmTypeGroupCd;
					if (!locNetGroupInfoMap.containsKey(gpKey)) {
						TlGroupRmTypeInfo newGpItem = new TlGroupRmTypeInfo(netRmTypeGroupCd, netRmTypeGroupNm);
						locNetGroupInfoMap.put(gpKey,newGpItem);
					}
					if (status.salesStatus != SALES_STATUS_STOP) {// 販売状態=「2」:停止中、
						// 該当室タイプグループの残室数を格納
						TlGroupRmTypeInfo gpItem = locNetGroupInfoMap.get(gpKey);
						gpItem.remaindCountSumMap.put(netSalesDate, CommUtils.nullToIntZero(netRemainingCount));
					}
					// ネット販売先室タイプ日別在庫
					status.netAgtRmTypeDailyStockList = (status.netAgtRmTypeDailyStockList == null)
														? new TL_NetStockSearchService.netAgtRmTypeDailyStock[0]
														: status.netAgtRmTypeDailyStockList;

					
					// １グループに各販売先の室タイプ単位情報
					for (TL_NetStockSearchService.netAgtRmTypeDailyStock netAgtStock : status.netAgtRmTypeDailyStockList) {
						String agtCode = netAgtStock.agtCode;
						// 既存の場合
						String key = shopCd + '_'  + agtCode;
						if (!locNetAgtMap.containsKey(key)) {
							TlSalesInfo tlInfo = new TlSalesInfo(agtCode, false);
							netAgtInfoList.add(tlInfo);
							locNetAgtMap.put(key, tlInfo);
						}
						// 販売先単位の各室タイプコードで、関連情報を格納する
						TlSalesInfo tlInfo = locNetAgtMap.get(key);

						// 販売先室タイプコードと名
						String netAgtRmTypeCode = netAgtStock.netAgtRmTypeCode;
						String netAgtRmTypeName = netAgtStock.netAgtRmTypeName;
						// 該当販売先に室タイプが非存在する場合
						if (!tlInfo.agtRmTypeMap.containsKey(netAgtRmTypeCode)) {
							TlSalesInfoType tlRmTypeInfo = new TlSalesInfoType(netAgtRmTypeCode,netAgtRmTypeName);
							// GROUP情報を格納する
							tlRmTypeInfo.gpRmTypeCode = netRmTypeGroupCd;
							tlRmTypeInfo.gpRmTypeName = netRmTypeGroupNm;
							// 配列に格納する
							tlInfo.agtRmTypeLst.add(tlRmTypeInfo);
							tlInfo.agtRmTypeMap.put(netAgtRmTypeCode, tlRmTypeInfo);
						}
						// 該当室タイプの一ヶ月間の在庫情報を格納する
						TlSalesInfoType tlRmTypeInfo = tlInfo.agtRmTypeMap.get(netAgtRmTypeCode);
						
						// 指定タイプの販売情報が存在する場合
						map<String, TlSalesInfoItem> saleItemMap = tlRmTypeInfo.dailyStockMap;
						//if (!saleItemMap.containskey(status.saleDate)) {
							// 
						TlSalesInfoItem item = new TlSalesInfoItem();
						item.agtCode = agtCode;
						item.saleDate = status.saleDate;
						//item.rmTypeCode = CommUtils.nullToBlank(netAgtStock.netAgtRmTypeCode);
						//item.rmTypeName = CommUtils.nullToBlank(netAgtStock.netAgtRmTypeName);
						item.salesCount = CommUtils.nullToBlank(netAgtStock.salesCount);
						item.salesStatus = CommUtils.nullToBlank(netAgtStock.salesStatus);
						if (item.salesStatus != SALES_STATUS_STOP && netAgtStock.isStockAdjustable) { // 「2」:停止中 && 在庫調整操作可否=TRUEのみ、販売数情報を設定する
							item.remainingCount = CommUtils.nullToBlank(netAgtStock.remainingCount);
						}
						saleItemMap.put(status.saleDate, item);
//System.debug(loggingLevel.INFO, 'saleItemMap['+status.saleDate+']' + saleItemMap.get(status.saleDate));
					}
				}	
			}
			// *****************************
			// 
			// ２週間以内呼出制御が必要
			Date startDt = conStartDate;
			//Date endDate = conEndDate;
			while (startDt <= conEndDate) {
				// 2週間で取得期間を設定する
				Date endDate = startDt.addDays(14);
				endDate = (endDate > conEndDate) ? conEndDate : endDate;
				
				strStartDt = DateTime.newInstance(startDt.year(),startDt.month(),startDt.day()).format('yyyyMMdd');
				strEndDt = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day()).format('yyyyMMdd');
//System.debug(logginglevel.INFO, '======= LOOP =======');
//System.debug(logginglevel.INFO, 'strStartDt::' + strStartDt);
//System.debug(logginglevel.INFO, 'strEndDt::' + strEndDt);
				// 旅行会社（リアル）の販売状態(9. 在庫状況照会(旅行会社)API ) 
				TL_RealStockSearchService.extractionCondition realCondition = new TL_RealStockSearchService.extractionCondition();
				realCondition.extractionProcedureCode = '2';	// 「2」:照会期間で検索
				realCondition.searchDurationFrom = strStartDt;	// 照会期間FROM
				realCondition.searchDurationTo = strEndDt;		// 照会期間TO
				TL_RealStockSearchService.stockSearchForRealResponse relaRep = tlService.callRealStockSearchService(shopCd, realCondition);
				
				// 次の期間情報を取得する
				startDt = endDate.addDays(1);
				
				// 取得情報を格納する
				// 取得の情報はエラーが発生する場合
				if (!relaRep.commonResponse.isSuccess) {
					// ERROR 戻る
					String errMsg = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
					return false;
				} else {
					// 正常の場合、取得の情報はメモに格納する
					// 旅行会社室タイプ
					relaRep.realAgtRmTypeList = (relaRep.realAgtRmTypeList == null) 
							? new TL_RealStockSearchService.realAgtRmType[0] 
							: relaRep.realAgtRmTypeList;
					// 
					for (TL_RealStockSearchService.realAgtRmType realAgtStock : relaRep.realAgtRmTypeList) {
						// 販売先コート
						String agtCode = realAgtStock.agtCode;
						String key = shopCd + '_' + agtCode;		// 店舗単位のキー：店舗コード→販売先コード
						if (!locRealAgtMap.containsKey(key)) {
							// 販売先単位の在庫情報を格納する
							TlSalesInfo tlInfo = new TlSalesInfo(agtCode, true);
							realAgtInfoList.add(tlInfo);
							locRealAgtMap.put(key, tlInfo);
						}
						// 同じ販売先複数旅行会社室タイフため、室タイプ毎に情報を格納する
						TlSalesInfo tlInfo = locRealAgtMap.get(key);
						
						// 販売先の室タイプ
						String realAgtRmTypeCode = realAgtStock.realAgtRmTypeCode + '_' + realAgtStock.frame;
						String realAgtRmTypeName = realAgtStock.realAgtRmTypeName;
						// 販売先に含め室タイプコード情報「室タイプ、枠」単位
						if (!tlInfo.agtRmTypeMap.containsKey(realAgtRmTypeCode)) {
							// 販売先室タイプ情報を初期化する
							TlSalesInfoType tlRmTypeInfo = new TlSalesInfoType(realAgtRmTypeCode,realAgtRmTypeName);
							tlInfo.agtRmTypeLst.add(tlRmTypeInfo);
							tlInfo.agtRmTypeMap.put(realAgtRmTypeCode, tlRmTypeInfo);
						}
						// 旅行会社室タイプコード
						// 枠
						// 旅行会社室タイプ名
						// 日別在庫状況
						TlSalesInfoType tlRmTypeInfo = tlInfo.agtRmTypeMap.get(realAgtRmTypeCode);
						// 指定タイプの販売情報が存在する場合
						map<String, TlSalesInfoItem> saleItemMap = tlRmTypeInfo.dailyStockMap;
						// 日別在庫状況
						realAgtStock.dailyStockStatusList = (realAgtStock.dailyStockStatusList == null) 
								? new TL_RealStockSearchService.dailyStockStatus[0] 
								: realAgtStock.dailyStockStatusList;
						for (TL_RealStockSearchService.dailyStockStatus dayStatus : realAgtStock.dailyStockStatusList) {
							// 在庫状況の日付 
							String salesDate = dayStatus.saleDate;
							// 日単位の在庫状況を格納する
							TlSalesInfoItem item = new TlSalesInfoItem();
							item.agtCode = agtCode;
							item.saleDate = salesDate;
							//item.rmTypeCode = CommUtils.nullToBlank(netAgtStock.netAgtRmTypeCode);
							//item.rmTypeName = CommUtils.nullToBlank(netAgtStock.netAgtRmTypeName);
							item.salesCount = CommUtils.nullToBlank(dayStatus.salesCount);
							if (dayStatus.isStockAdjustable)	// 在庫調整操作可否はTRUEのみ、残室数設定する
							item.remainingCount = CommUtils.nullToBlank(dayStatus.remainingCount);
							//item.salesStatus = CommUtils.nullToBlank(dayStatus.salesStatus);
							
							saleItemMap.put(salesDate, item);

//System.debug(loggingLevel.INFO, '[Real]saleItemMap['+salesDate+']' + saleItemMap.get(salesDate));
						}

					}
				}
			}
		}
	
		// AGT名前情報を取得する
		Set<String> agtCdSet = new Set<String>();
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			for (TlSalesInfo tlInfo : netAgtInfoMap.get(shopCd)) { agtCdSet.add(tlInfo.agtCode);}
			for (TlSalesInfo tlInfo : realAgtInfoMap.get(shopCd)) { agtCdSet.add(tlInfo.agtCode);}
		}
		// 関連のAGT名前を取得する
		map<String, String> accNameMaps = new map<String, String>();
		List<Account> accs = [select id, name,SalesOfficeCompanyCodeTLAPI__c from Account where SalesOfficeCompanyCodeTLAPI__c in :agtCdSet And AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL];
		for (Account acc : accs) {
			accNameMaps.put(acc.SalesOfficeCompanyCodeTLAPI__c, acc.Name);
		}
		//  関連表示の情報を補足する
		//map<String, String> shopNamesMap = new map<String, String>();
		// 店舗コードー＞店舗名関連情報の設定
		//for (SelectOption s : branchShopLst) { shopNamesMap.put(s.getValue(), s.getLabel()); }
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;

			for (TlSalesInfo tlInfo : netAgtInfoMap.get(shopCd)) {
				tlInfo.agtName = accNameMaps.get(tlInfo.agtCode);
				for (TlSalesInfoType salesInfoType : tlInfo.agtRmTypeMap.values()) {
					// 初期化処理を行う
					for (dispHeader disp : dispHeaders) {
						if (!salesInfoType.dailyStockMap.containsKey(disp.yyyymmdd)) {
							TlSalesInfoItem item = new TlSalesInfoItem();
							//item.remainingCount = '';
							//item.salesCount = '';
							salesInfoType.dailyStockMap.put(disp.yyyymmdd, item);
						}
					}
				}
			}
			for (TlSalesInfo tlInfo : realAgtInfoMap.get(shopCd)) {
				tlInfo.agtName = accNameMaps.get(tlInfo.agtCode);
				for (TlSalesInfoType salesInfoType : tlInfo.agtRmTypeMap.values()) {
					// 初期化処理を行う
					for (dispHeader disp : dispHeaders) {
						// 該当日付の在庫状況をTL側戻らない場合、ダミ情報を設定する
						if (!salesInfoType.dailyStockMap.containsKey(disp.yyyymmdd)) {
							TlSalesInfoItem item = new TlSalesInfoItem();
							//item.remainingCount = '--';
							//item.salesCount = '--';
							salesInfoType.dailyStockMap.put(disp.yyyymmdd, item);
						}
					}
				}
			}
		}
		
		
		// 店舗ー＞部屋タイプから、関連の販売先コード一覧を取得する
		// map<店舗コード_販売先コード_室タイプコード, 室タイプコード（SF側の部屋タイプコードと一致）> 
		map<String, String> roomTypeRelMap = new map<String, String>();
		// SF側の部屋タイプコードー＞TLの室タイプグループコードリスト
		map<String, List<String>> sfRoomTypeToTlGroupCdLstMap = new map<String, List<String>>();
		
		set<string> locRmTypeCdSet = new set<String>();
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			
			// ネット
			// 指定店舗の部屋MAPPING情報を取得する
			// ***********************************
			// 1. 部屋タイプマスタ検索(ネット販売)API 
			// ***********************************
			TL_NetRoomTypeMasterSearchService.extractionCondition condition =
				new TL_NetRoomTypeMasterSearchService.extractionCondition();
			condition.extractionProcedureCode = '0';	// 全件検索
			TL_NetRoomTypeMasterSearchService.rmTypeMstSearchForNetResponse rep = 
				tlService.callNetRoomTypeMasterSearchService(shopCd, condition);
			if (!rep.commonResponse.isSuccess) {
				// ERROR 戻る
				String errMsg = rep.commonResponse.failureReason+':'+rep.commonResponse.errorDescription;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
				return false;
			} else {
				// SF側の室タイプコード
				rep.rmTypeList = (rep.rmTypeList == null)
										? new TL_NetRoomTypeMasterSearchService.rmType[0]
										: rep.rmTypeList;
				for (TL_NetRoomTypeMasterSearchService.rmType rmType : rep.rmTypeList) {
					// SF側の部屋タイプコードの取得範囲を設定する
					locRmTypeCdSet.add(rmType.rmTypeCode);
				}
				// SFの部屋タイプコードー＞TLのネット室タイプグループコード
				rep.netRmTypeGroupList = (rep.netRmTypeGroupList == null) 
										? new TL_NetRoomTypeMasterSearchService.netRmTypeGroup[0]		
										: rep.netRmTypeGroupList;
				for (TL_NetRoomTypeMasterSearchService.netRmTypeGroup gp : rep.netRmTypeGroupList) {
					String gpRmTypeCode = gp.netRmTypeGroupCode;
					String rmTypeCode = gp.rmTypeCode;			// SF側の室タイプコード
					String sfKey = shopCd + '_' + rmTypeCode;		// SF側の部屋タイプキー
					String tlKey = shopCd + '_' + gpRmTypeCode;	// TL側の室タイプグループコードキー
					if (!sfRoomTypeToTlGroupCdLstMap.containsKey(sfKey)) {
						sfRoomTypeToTlGroupCdLstMap.put(sfKey, new list<string>());
					}
					// SFの部屋タイプコード＝＞TLのタイプグループコード MAPPING
					sfRoomTypeToTlGroupCdLstMap.get(sfKey).add(tlKey);
				}
												
				// SFの部屋タイプコードー＞TLのネット販売先室タイプ
				rep.netAgtRmTypeList = (rep.netAgtRmTypeList == null) 
										? new TL_NetRoomTypeMasterSearchService.netAgtRmType[0]		
										: rep.netAgtRmTypeList;
				for (TL_NetRoomTypeMasterSearchService.netAgtRmType agt : rep.netAgtRmTypeList) {
					String agtCode = agt.agtCode;				// 販売先コード
					String agtRmTypeCode = agt.netAgtRmTypeCode;// 販売先室タイプコード
					String rmTypeCode = agt.rmTypeCode;			// SF側の室タイプコード
					// SF側の部屋タイプキー
					String sfKey = shopCd + '_' + rmTypeCode;
					// TL側の販売先単位の室タイプキー
					String tlKey = shopCd + '_' + agtCode + '_' + agtRmTypeCode;
					// TLのネット販売先室タイプー＞SFの部屋タイプ情報を設定する
					if (!roomTypeRelMap.containsKey(tlKey)) {
						roomTypeRelMap.put(tlKey,sfKey);
					}
				}
			}
			// リアル
			// 指定店舗の部屋MAPPING情報を取得する
			// ********************************
			// 8. 部屋タイプマスタ検索(旅行会社)API 
			// ********************************
			TL_RealRoomTypeMasterSearchService.rmTypeMstSearchForRealResponse realRep = 
				tlService.callRealRoomTypeMasterSearchService(shopCd);
			if (!realRep.commonResponse.isSuccess) {
				// ERROR 戻る
				String errMsg = realRep.commonResponse.failureReason+':'+realRep.commonResponse.errorDescription;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
				return false;
			} else {
				// SF側の室タイプコード
				realRep.rmTypeList = (realRep.rmTypeList == null)
										? new TL_RealRoomTypeMasterSearchService.rmType[0]
										: realRep.rmTypeList;
				for (TL_RealRoomTypeMasterSearchService.rmType rmType : realRep.rmTypeList) {
					// SF側の部屋タイプコードの取得範囲を設定する
					locRmTypeCdSet.add(rmType.rmTypeCode);
				}
				// 旅行会社室タイプ
				realRep.realAgtRmTypeList = (realRep.realAgtRmTypeList == null) 
										? new TL_RealRoomTypeMasterSearchService.realAgtRmType[0]		
										: realRep.realAgtRmTypeList;
				for (TL_RealRoomTypeMasterSearchService.realAgtRmType agt : realRep.realAgtRmTypeList) {
					String agtCode = agt.agtCode;
					String agtRmTypeCode = agt.realAgtRmTypeCode;
					String agtRmTypeFrame = agt.frame;
					String rmTypeCode = agt.rmTypeCode;
					// SF側の部屋タイプキー
					String sfKey = shopCd + '_' + rmTypeCode;
					// 店舗コード_販売先コード_販売先室タイプコード_枠
					String tlKey = shopCd + '_' + agtCode + '_' + agtRmTypeCode + '_' + agtRmTypeFrame;
					if (!roomTypeRelMap.containsKey(tlKey)) {
						roomTypeRelMap.put(tlKey,sfKey);
					}
				}
			}	
		} 
		
		// 表示する範囲の店舗
		set<string> shopCdsSet = new set<String>();
		for (ShopInfo shop : showShopList) {shopCdsSet.add(shop.shopCode);}
		
		// map<店舗コード＋部屋タイプコード, 部屋タイプ>
		map<String, TypeOfRooms__c> locSfRoomTypeRelMap = new map<String, TypeOfRooms__c>();
		list<TypeOfRooms__c> sfRmTypeList = [select ShopInfoRef__r.ShopCode__c, RoomTypeCode__c, Name from TypeOfRooms__c where ShopInfoRef__r.ShopCode__c in :shopCdsSet And RoomTypeCode__c in :locRmTypeCdSet order by seq__c];
		for (TypeOfRooms__c sfRmType :sfRmTypeList) {
			// 店舗コード＋部屋タイプコードから、関連の販売先情報リストを格納する 
			String key = CommUtils.nullToBlank(sfRmType.ShopInfoRef__r.ShopCode__c) + '_' + sfRmType.RoomTypeCode__c;
			// SF側に登録の部屋タイプ情報
			locSfRoomTypeRelMap.put(key, sfRmType);
		}
//System.debug(logginglevel.INFO, 'locSfRoomTypeRelMap:::' + locSfRoomTypeRelMap);
		// 個別設定する場合
		map<String, SfRoomTypeInfo> locSfClsRoomTypeRelMap = new map<String, SfRoomTypeInfo>();
		
		// 店舗単位に各販売先を格納する
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;
			// 該当店舗の部屋タイプ情報リストを取得する
			List<SfRoomTypeInfo> sfRoomTypeInfoList = sfRoomTypeAgtInfoMap.get(shopCd);

			// ネット販売にSF側の部屋タイプ情報を格納する
			List<TlSalesInfo> locTlSalesInfoLst = netAgtInfoMap.get(shopCd);
			// 販売先の室タイプのSF側の部屋タイプ情報を設定する
			for (TlSalesInfo locTlSalesInfo : locTlSalesInfoLst) {
				// 関連のTL部屋タイプ情報を取得する
				for (TlSalesInfoType tlRmType : locTlSalesInfo.agtRmTypeLst) {
						// TL側の該当販売先の室タイプコードのキー
						String tlKey = shopCd + '_' + locTlSalesInfo.agtCode + '_' + tlRmType.rmTypeCode;
//System.debug(loggingLevel.INFO, 'key:::' + key);
//System.debug(loggingLevel.INFO, 'roomTypeRelMap:::' + roomTypeRelMap);
						// 該当キーで、Tlの室タイプコードー＞SFの部屋タイプコードのMAPPING関係が存在する
						if (roomTypeRelMap.containsKey(tlKey)) {
							// SF側の室タイプコードを取得する
							String sfKey = roomTypeRelMap.get(tlKey);
//System.debug(loggingLevel.INFO, 'sfKey:::' + sfKey);
							// SF側の該当室タイプコードのSFデータを取得する[店舗コード_部屋タイプコード]
							if (locSfRoomTypeRelMap.containsKey(sfKey)) {
								// 該当キーでSF側の部屋タイプをデータを取得する
								TypeOfRooms__c sfRoomType = locSfRoomTypeRelMap.get(sfKey);
								tlRmType.sfRmTYpeName = sfRoomType.Name;
								tlRmType.sfRmTYpeCode = sfRoomType.RoomTypeCode__c;
								// 部屋タイプに情報格納する場合【部屋タイプ別】
								if (isSfRoomTypeLayout) {
//System.debug(loggingLevel.INFO, 'isSfRoomTypeLayout:::' + isSfRoomTypeLayout);
//System.debug(loggingLevel.INFO, 'sfKey:::' + sfKey);
									if (!locSfClsRoomTypeRelMap.containskey(sfKey)) {
										SfRoomTypeInfo sfRoomTypeItem = new SfRoomTypeInfo(sfRoomType.RoomTypeCode__c, sfRoomType.Name);
										locSfClsRoomTypeRelMap.put(sfKey, sfRoomTypeItem);
										sfRoomTypeInfoList.add(sfRoomTypeItem);
									}
									// SFの部屋タイプ単位に、販売先の室タイプ情報を格納する
									SfRoomTypeInfo sfRoomTypeItem = locSfClsRoomTypeRelMap.get(sfKey);
//System.debug(loggingLevel.INFO, 'sfRoomTypeItem:::' + sfRoomTypeItem);
									// 該当部屋タイプに販売先は既に存在するがどう
									String agtCodeKey = locTlSalesInfo.agtCode;
									// 該当部屋タイプに販売先の設定情報を新規追加する
									if (!sfRoomTypeItem.tlSalesInfoMap.containsKey(agtCodeKey)) {
										TlSalesInfo newTlSalesInfo = new TlSalesInfo(agtCodeKey,locTlSalesInfo.isRealAgt);
										newTlSalesInfo.agtName = locTlSalesInfo.agtName;
										sfRoomTypeItem.tlSalesInfoMap.put(agtCodeKey, newTlSalesInfo);
										sfRoomTypeItem.tlSalesInfoLst.add(newTlSalesInfo);
									}
									// 該当販売先単位に室タイプ情報を追加する
									TlSalesInfo TlSalesInfoItem = sfRoomTypeItem.tlSalesInfoMap.get(agtCodeKey);
									// 室タイプ情報を部屋タイプコードへ追加する
									TlSalesInfoItem.agtRmTypeLst.add(tlRmType);
								}
							}
						}
					}
				} // End For for (TlSalesInfo locTlSalesInfo : locTlSalesInfoLst) 
				// 販売先単位のリアル関連情報
				locTlSalesInfoLst = realAgtInfoMap.get(shopCd);
				
				// 販売先情報単位を処理を行う	
				for (TlSalesInfo locTlSalesInfo : locTlSalesInfoLst) {
					// 該当販売先に含めの部屋タイプ情報を取得する
					for (TlSalesInfoType tlRmType : locTlSalesInfo.agtRmTypeLst) {
						//List<TlSalesInfoType> agtRmTypeLst
						//tlRmType.rmTypeCode
						String tlKey = shopCd + '_' + locTlSalesInfo.agtCode + '_' + tlRmType.rmTypeCode;
						if (roomTypeRelMap.containsKey(tlKey)) {
							// SF側の室タイプコードを取得する
							String sfKey = roomTypeRelMap.get(tlKey);
							// SF側の該当室タイプコードのSFデータを取得する
							if (locSfRoomTypeRelMap.containsKey(sfKey)) {
								TypeOfRooms__c sfRoomType = locSfRoomTypeRelMap.get(sfKey);
								tlRmType.sfRmTYpeName = sfRoomType.Name;
								tlRmType.sfRmTYpeCode = sfRoomType.RoomTypeCode__c;
								// 部屋タイプに情報格納する場合[部屋タイプ別]
								if (isSfRoomTypeLayout) {
//System.debug(loggingLevel.INFO, 'isSfRoomTypeLayout:::' + isSfRoomTypeLayout);
//System.debug(loggingLevel.INFO, 'sfKey:::' + sfKey);
									if (!locSfClsRoomTypeRelMap.containskey(sfKey)) {
										SfRoomTypeInfo sfRoomTypeItem = new SfRoomTypeInfo(sfRoomType.RoomTypeCode__c, sfRoomType.Name);
										locSfClsRoomTypeRelMap.put(sfKey, sfRoomTypeItem);
										sfRoomTypeInfoList.add(sfRoomTypeItem);
									}
									SfRoomTypeInfo sfRoomTypeItem = locSfClsRoomTypeRelMap.get(sfKey);
//System.debug(loggingLevel.INFO, 'sfRoomTypeItem:::' + sfRoomTypeItem);
									// 該当部屋タイプに販売先は既に存在するがどう
									String agtCodeKey = locTlSalesInfo.agtCode;
									if (!sfRoomTypeItem.tlSalesInfoMap.containsKey(agtCodeKey)) {
										TlSalesInfo newTlSalesInfo = new TlSalesInfo(agtCodeKey,locTlSalesInfo.isRealAgt);
										newTlSalesInfo.agtName = locTlSalesInfo.agtName;
										sfRoomTypeItem.tlSalesInfoMap.put(agtCodeKey, newTlSalesInfo);
										sfRoomTypeItem.tlSalesInfoLst.add(newTlSalesInfo);
									}
									// 該当販売先に室タイプ情報を追加する
									TlSalesInfo TlSalesInfoItem = sfRoomTypeItem.tlSalesInfoMap.get(agtCodeKey);
									// 室タイプ情報を追加する
									TlSalesInfoItem.agtRmTypeLst.add(tlRmType);
								}
							} // End if (locSfRoomTypeRelMap.containsKey(sfKey))
						} // End if (roomTypeRelMap.containsKey(key))
					} // End for (TlSalesInfoType tlRmType : locTlSalesInfo.agtRmTypeLst)
					
				} // End for (TlSalesInfo locTlSalesInfo : locTlSalesInfoLst)
		} // End for (ShopInfo shop : showShopList)
		
		// *****************************
		// 店舗単位に各販売先残室数を集計する
		// *****************************
		for (ShopInfo shop : showShopList) {
			String shopCd = shop.shopCode;	
			// 店舗単位の残室数合計
			map<String, Integer> locShopSumMap = shop.remaindCountSumMap;
			// 部屋タイプ別「TL側の室タイプグループ単位で合計を行う」
			if (isSfRoomTypeLayout) {
				// ネット販売の場合、同じグループコードの残室数は合計計算しない
				// 旅行会社の場合、各室タイプの残室数はそのまま合計する
				List<SfRoomTypeInfo> sfRoomTypeInfoLst = sfRoomTypeAgtInfoMap.get(shop.shopCode);
				for (SfRoomTypeInfo locSfRoomTypeInfo : sfRoomTypeInfoLst) {
					locSfRoomTypeInfo.calRemaindCount(dispHeaders);
				}
				/*
				// グループコードチェック用SET
				//set<String> locSfRmTypeSameGroupNoSet = new set<String>();
				// 部屋タイプの関連情報の集計 [店舗ー＞部屋タイプ]
				for (SfRoomTypeInfo locSfRoomTypeInfo : sfRoomTypeInfoLst) {
					// SF部屋タイプ単位の残室数合計
					map<String, Integer> locSfRmTypeSumMap = locSfRoomTypeInfo.remaindCountSumMap;
					
					// 合計値情報を初期化する
					for (dispHeader disp : dispHeaders) {
						locSfRmTypeSumMap.put(disp.yyyymmdd, 0);
					}
					// ネット販売、部屋タイプ単位の残室数合計を設定する
					// 関連変数：sfRoomTypeToTlGroupCdLstMap,locNetGroupInfoMap
					String sfRmTypeKey = shopCd + '_' + locSfRoomTypeInfo.rmTypeCode;
					// SFの部屋タイプ→関連のTL側の室タイプグループコードリストを取得する
					if (sfRoomTypeToTlGroupCdLstMap.containsKey(sfRmTypeKey)) {
						// 室タイプグループコード単位で、残室数を計算を行う
						for (String tlGpKey : sfRoomTypeToTlGroupCdLstMap.get(sfRmTypeKey)) {
							// 残室数を合計して、部屋タイプに反映を行う
							TlGroupRmTypeInfo tlGpInfo = locNetGroupInfoMap.get(tlGpKey);
							for (string yyyymmdd : tlGpInfo.remaindCountSumMap.keySet()) {
								locSfRmTypeSumMap.put(yyyymmdd, locSfRmTypeSumMap.get(yyyymmdd) + tlGpInfo.remaindCountSumMap.get(yyyymmdd));
							}
						}
					}
					// 室タイプ単位の情報の販売先の残室数を合計する [店舗ー＞部屋タイプー＞AGT]
					for (TlSalesInfo locTlSalesInfo : locSfRoomTypeInfo.tlSalesInfoLst) {
						// 販売先単位合計値格納
						map<String, Integer> locSumMap = locTlSalesInfo.remaindCountSumMap;
						// 合計値情報を初期化する
						for (dispHeader disp : dispHeaders) {
							locSumMap.put(disp.yyyymmdd, 0);
						}
						// 旅行会社の場合、残室数はそのまま合計する
						if (locTlSalesInfo.isRealAgt) {
							// 旅行会社の場合、残室数は各室タイプの残室数をそのまま合計を行う
							for(TlSalesInfoType locTlSalesInfoType : locTlSalesInfo.agtRmTypeLst) {
								for (dispHeader disp : dispHeaders) {
									TlSalesInfoItem item = locTlSalesInfoType.dailyStockMap.get(disp.yyyymmdd);
									Integer remaindCount = CommUtils.nullToIntZero(item.remainingCount);
									// 販売先単位の残室数を合計する
									locSumMap.put(disp.yyyymmdd,  locSumMap.get(disp.yyyymmdd) + remaindCount);
									// SF側の部屋タイプ単位の残室数を合計する
									locSfRmTypeSumMap.put(disp.yyyymmdd,  locSfRmTypeSumMap.get(disp.yyyymmdd) + remaindCount);
								}
							}
						} else {
							// 同じ室グループコード重複チェック用、同じコードが存在すると、重複に計算されない制御が必要
							set<String> sameGroupNoSet = new set<String>();
							// ネット販売の場合、同じグループコードすると、一回のみ計算を行う
							// 旅行会社の場合、残室数はそのまま合計を行う
							// １ネット販売先単位に含めの販売先室タイプリスト[店舗ー＞部屋タイプー＞AGTー＞AGT室タイプ]
							for(TlSalesInfoType locTlSalesInfoType : locTlSalesInfo.agtRmTypeLst) {
								// 同じグループの残室情報は既に存在する場合
								if (sameGroupNoSet.contains(locTlSalesInfoType.gpRmTypeCode)) continue;
								sameGroupNoSet.add(locTlSalesInfoType.gpRmTypeCode);
								// 該当部屋タイプ単位に、同じ室グループNOの情報はすでに集計されているがどうか
								//Boolean isExistGroupFlg = locSfRmTypeSameGroupNoSet.contains(locTlSalesInfoType.gpRmTypeCode);
								// 一ヶ月間残室数を合計する
								for (dispHeader disp : dispHeaders) {
									TlSalesInfoItem item = locTlSalesInfoType.dailyStockMap.get(disp.yyyymmdd);
//System.debug(loggingLevel.INFO, 'item.remainingCount:::' + item.remainingCount);
									Integer remaindCount = CommUtils.nullToIntZero(item.remainingCount);
									locSumMap.put(disp.yyyymmdd,  locSumMap.get(disp.yyyymmdd) + remaindCount);
								}
								//locSfRmTypeSameGroupNoSet.add(locTlSalesInfoType.gpRmTypeCode);
								
							}
						}
						// 販売先単位合計値を設定する
						//locTlSalesInfo.remaindCountSumMap = locSumMap.clone();
					}
					// 室タイプ単位の合計を行う
					// ネット販売単位
				}*/
				// 支店単位の合計値：部屋タイプの残室数から合計する
				for (SfRoomTypeInfo locSfRoomTypeInfo : sfRoomTypeInfoLst) {
					// 一ヶ月間残室数を合計する[支店単位]
					for (dispHeader disp : dispHeaders) {
						locShopSumMap.put(disp.yyyymmdd, locShopSumMap.get(disp.yyyymmdd) + locSfRoomTypeInfo.remaindCountSumMap.get(disp.yyyymmdd));
					}
				}
				
				// 並び順を再設定する[SFの部屋タイプコード順]
				map<String, SfRoomTypeInfo> locSortMap = new map<String, SfRoomTypeInfo>();
				for (SfRoomTypeInfo locSfRoomTypeInfo : sfRoomTypeInfoLst) {
					// 20桁書式化する
					String  sfRmTypeCode = CommUtils.paddingLeftZero(locSfRoomTypeInfo.rmTypeCode,20);
					locSortMap.put(sfRmTypeCode, locSfRoomTypeInfo);
				}
				List<String> locSortList = new List<String>(locSortMap.keySet());
				locSortList.sort();
				sfRoomTypeInfoLst.clear();
				for (String key : locSortList) { sfRoomTypeInfoLst.add(locSortMap.get(key));}
			} 
			// 販売先販売別[同じAGT内部に、室タイプグループ単位の合計計算を行う]
			else {
				// set<室タイプグループコード_日付>
				set<String> sampeGroupFilterSet = new set<String>();
				// ネット会社単位の残室数合計値計算（室タイプグループ単位）
				for (TlSalesInfo agt : netAgtInfoMap.get(shopCd)) {
					agt.calRemaindCount(dispHeaders);
					// 店舗単位の最小単位から同じグループ室タイプタイプの残室数から合計を行う「販売停止、室タイプグループコード重複は対象外」
					// 所属するAGTはネットの場合、室タイプグループ、販売停止以外単位合計を行う
					for (TlSalesInfoType agtType : agt.agtRmTypeLst) {
						// 室タイプグループコード
						String gpRmTypeCode = agtType.gpRmTypeCode;
						for (dispHeader disp : dispHeaders) {
							String filterKey = gpRmTypeCode + '_' + disp.yyyymmdd;
							if (sampeGroupFilterSet.contains(filterKey)) continue;
							TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
							if (item.salesStatus == SALES_STATUS_STOP) continue;
							sampeGroupFilterSet.add(filterKey);
							locShopSumMap.put(disp.yyyymmdd,  locShopSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
						}
					}
				}
				// リアル会社単位の残室数合計値計算（販売先室タイプ単位）
				for (TlSalesInfo agt : realAgtInfoMap.get(shopCd)) {
					agt.calRemaindCount(dispHeaders);
					for (TlSalesInfoType agtType : agt.agtRmTypeLst) {
						for (dispHeader disp : dispHeaders) {
							TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
							locShopSumMap.put(disp.yyyymmdd, locShopSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
						}
					}
				}
				/*
				// グループコードチェック用SET
				set<String> locShopSameGroupNoSet = new set<String>();
				// ネット販売の場合、同じグループコードの残室数は合計計算しない
				for (TlSalesInfo locTlSalesInfo : netAgtInfoMap.get(shopCd)) {
					// 販売先単位合計値格納
					map<String, Integer> locSumMap = locTlSalesInfo.remaindCountSumMap;
					// 合計値情報を初期化する
					for (dispHeader disp : dispHeaders) {
						locSumMap.put(disp.yyyymmdd, 0);
					}
					set<String> sameGroupNoSet = new set<String>();
					// ネット販売の場合、同じグループコードすると、一回のみ計算を行う
					// 旅行会社の場合、残室数はそのまま合計を行う
					for(TlSalesInfoType locTlSalesInfoType : locTlSalesInfo.agtRmTypeLst) {
						// 同じグループの残室情報は既に存在する場合
						String groupNo = locTlSalesInfoType.gpRmTypeCode;
						if (sameGroupNoSet.contains(groupNo)) continue;
						sameGroupNoSet.add(groupNo);
						Boolean isSameGroupNo = locShopSameGroupNoSet.contains(groupNo);
						// 一ヶ月間残室数を合計する
						for (dispHeader disp : dispHeaders) {
							// 販売先室タイプの残室数から合計を行う「同じ室タイプグループは重複計算しない」
							TlSalesInfoItem item = locTlSalesInfoType.dailyStockMap.get(disp.yyyymmdd);
							if (!locSumMap.containsKey(disp.yyyymmdd)) {
								locSumMap.put(disp.yyyymmdd, 0);
							}
//System.debug(loggingLevel.INFO, 'item.remainingCount:::' + (item.remainingCount == null));
							Integer remaindCount = CommUtils.nullToIntZero(item.remainingCount);
							locSumMap.put(disp.yyyymmdd,  locSumMap.get(disp.yyyymmdd) + remaindCount);
							// 店舗の合計値を加算する
							if (!isSameGroupNo) { 
								locShopSumMap.put(disp.yyyymmdd,  locShopSumMap.get(disp.yyyymmdd) + remaindCount);
							}
						}
						locShopSameGroupNoSet.add(groupNo);
						
					}
					//locTlSalesInfo.remaindCountSumMap = locSumMap.clone();
				}
				// 旅行会社の場合、各室タイプの残室数はそのまま合計する
				// ネット販売の場合、同じグループコードの残室数は合計計算しない
				for (TlSalesInfo locTlSalesInfo : realAgtInfoMap.get(shopCd)) {
					map<String, Integer> locSumMap = locTlSalesInfo.remaindCountSumMap;
					// 合計値情報を初期化する
					for (dispHeader disp : dispHeaders) {
						locSumMap.put(disp.yyyymmdd, 0);
					}
					//set<String> sameGroupNoSet = new set<String>();
					// ネット販売の場合、同じグループコードすると、一回のみ計算を行う
					// 旅行会社の場合、残室数はそのまま合計を行う
					for(TlSalesInfoType locTlSalesInfoType : locTlSalesInfo.agtRmTypeLst) {
						// 同じグループの残室情報は既に存在する場合
						//if (sameGroupNoSet.contains(locTlSalesInfoType.gpRmTypeCode)) continue;
						//sameGroupNoSet.add(locTlSalesInfoType.gpRmTypeCode);
						// 一ヶ月間残室数を合計する
						for (dispHeader disp : dispHeaders) {
							TlSalesInfoItem item = locTlSalesInfoType.dailyStockMap.get(disp.yyyymmdd);
//System.debug(loggingLevel.INFO, 'item.remainingCount:::' + (item.remainingCount == null));
							Integer remaindCount = CommUtils.nullToIntZero(item.remainingCount);
							locSumMap.put(disp.yyyymmdd,  locSumMap.get(disp.yyyymmdd) + remaindCount);
							locShopSumMap.put(disp.yyyymmdd,  locShopSumMap.get(disp.yyyymmdd) + remaindCount);
						}
					}
					//locTlSalesInfo.remaindCountSumMap = locSumMap.clone();
				}
				*/
				
				// 並び順を再設定する[販売先コード順]
				map<String, TlSalesInfo> locSortMap = new map<String, TlSalesInfo>();
				for (TlSalesInfo locTlSalesInfo : netAgtInfoMap.get(shopCd)) {
					String sortKey = CommUtils.paddingLeftZero(locTlSalesInfo.agtCode,20);
					locSortMap.put(sortKey, locTlSalesInfo);
				}
				list<String> locSortList = new list<String>();
				locSortList.addAll(locSortMap.keySet());
				locSortList.sort();
				netAgtInfoMap.get(shopCd).clear();
				for (String sortKey : locSortList) {
					netAgtInfoMap.get(shopCd).add(locSortMap.get(sortkey));
				}
				// 並び順を再設定する[販売先コード順][リアル]
				locSortMap.clear();
				for (TlSalesInfo locTlSalesInfo : realAgtInfoMap.get(shopCd)) {
					String sortKey = CommUtils.paddingLeftZero(locTlSalesInfo.agtCode,10);
					locSortMap.put(sortKey, locTlSalesInfo);
				}
				locSortList.clear();
				locSortList.addAll(locSortMap.keySet());
				locSortList.sort();
				realAgtInfoMap.get(shopCd).clear();
				for (String sortKey : locSortList) {
					realAgtInfoMap.get(shopCd).add(locSortMap.get(sortkey));
				}
			}
			
			// 残室数は全部合計する
		}
		// 表示順の再設定を行う
		
		return true;
	}

	// 2015/09/14 EDIT END(TL側の販売状態を取得する)
	public class ShopInfo {
		public ShopInfo(String cd, String nm) {
			shopCode = CommUtils.nullToBlank(cd);
			shopName = nm;
			//sfRmTypeLst = new list<SfRoomTypeInfo>();	// SF側の部屋タイプ単位を情報を格納する
			//tlSalesInfoLst = new list<TlSalesInfo>();	// TL側の販売先単位の情報を格納
			remaindCountSumMap = new map<String, Integer>();
		}
		public String shopCode{get;set;}
		public String shopName{get;set;}
		//public List<SfRoomTypeInfo> sfRmTypeLst{get;private set;}
		//public List<TlSalesInfo> tlSalesInfoLst{get;private set;}
		// 残室数の合計値「月間」(店舗単位)
		public map<String, Integer> remaindCountSumMap{get;set;}
	}
	// SF側の部屋タイプに関連のTL側の販売先の在庫情報を格納する
	public class SfRoomTypeInfo {
		public SfRoomTypeInfo(String cd, String nm) {
			tlSalesInfoLst = new List<TlSalesInfo>();
			tlSalesInfoMap = new map<String, TlSalesInfo>();// map<販売先コード,販売先単位の在庫情報>
			rmTypeCode = cd;
			rmTypeName = nm;
			//dayTlSalesInfoMap = new map<String, TlSalesInfoItem>();
			remaindCountSumMap = new map<String, Integer>();
		}
		public String rmTypeCode{get;set;}
		public String rmTypeName{get;set;}
		// 一ヶ月間の室タイプ単位の在庫情報を格納する
		public List<TlSalesInfo> tlSalesInfoLst{get; private set;}
		public map<String, TlSalesInfo> tlSalesInfoMap{get; private set;}	// map<販売先コード,販売先の初期情報
		// 残室数の合計値「月間」
		public map<String, Integer> remaindCountSumMap{get;set;}
		// 該当AGTの残室数合計計算を行う[室タイプグループ単位、販売停止以外の残室数合計]
		public void calRemaindCount(List<dispHeader> dispHeaders) {
			// 指定期間の残室数を計算する
			for (dispHeader disp : dispHeaders) {
				remaindCountSumMap.put(disp.yyyymmdd, 0);
			}
			// SF部屋タイプ内部の室タイプグループ単位重複Filter処理
			Set<String> sampeGroupFilterSet = new Set<String>();
			for (TlSalesInfo agt : tlSalesInfoLst) {
				// SFの部屋タイプグループ内部のAGT合計値
				agt.calRemaindCount(dispHeaders);
				// 旅行会社の場合
				if (agt.isRealAgt) {
					for (TlSalesInfoType agtType : agt.agtRmTypeLst) {
						for (dispHeader disp : dispHeaders) {
							TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
							remaindCountSumMap.put(disp.yyyymmdd, remaindCountSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
						}
					}
				} else {
					// 所属するAGTはネットの場合、室タイプグループ、販売停止以外単位合計を行う
					for (TlSalesInfoType agtType : agt.agtRmTypeLst) {
						// 室タイプグループコード
						String gpRmTypeCode = agtType.gpRmTypeCode;
						for (dispHeader disp : dispHeaders) {
							String filterKey = gpRmTypeCode + '_' + disp.yyyymmdd;
							if (sampeGroupFilterSet.contains(filterKey)) continue;
							TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
							if (item.salesStatus == SALES_STATUS_STOP) continue;
							sampeGroupFilterSet.add(filterKey);
							remaindCountSumMap.put(disp.yyyymmdd, remaindCountSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
						}
					}
				}
			}
		}
	}
	// ネット販売室タイプグループ情報
	public class TlGroupRmTypeInfo {
		public TlGroupRmTypeInfo(String cd, String nm) {
			gpRmTypeCode = cd;
			gpRmTypeName = nm;
			remaindCountSumMap = new map<String, Integer>();
		}
		public String gpRmTypeCode{get;set;}
		public String gpRmTypeName{get;set;}
		//public String remainingCount{get;set;}
		// 残室数の合計値「月間」
		public map<String, Integer> remaindCountSumMap{get;set;}
	}
	// 販売先単位に関連の室タイプ情報を格納する
	public class TlSalesInfo {
		public TlSalesInfo(String cd, Boolean pIsRealAgt) {
			agtCode = cd;
			//agtName = nm;
			isRealAgt = pIsRealAgt;
			agtRmTypeLst = new List<TlSalesInfoType>();	// 該当表示単位に、該当販売先関連の室タイプコードリスト
			//stockInfoMap = new map<String, map<String, TlSalesInfoItem>>();	// 指定の室タイプコードと一ヶ月間の販売情報を格納する
			//netSaleViewKey = CommUtils.nullToBlank(shopcd) + '_' + cd;
			agtRmTypeMap = new map<String, TlSalesInfoType>();
			remaindCountSumMap = new map<String, Integer>();
		}
		//public String netSaleViewKey{get; private set;}	// 販売先単位の識別別キー
		public String agtCode{get;set;}
		public String agtName{get;set;}
		public Boolean isRealAgt{get; private set;}
		// 販売先の室タイプコードリスト
		public List<TlSalesInfoType> agtRmTypeLst{get; private set;}
		// map<室タイプコード, 室タイプ単位情報>
		public map<String, TlSalesInfoType> agtRmTypeMap{get; private set;}
		// 残室数の合計値「月間」
		public map<String, Integer> remaindCountSumMap{get;set;}
		// 該当AGTの残室数合計計算を行う[室タイプグループ単位、販売停止以外の残室数合計]
		public void calRemaindCount(List<dispHeader> dispHeaders) {
			// 指定期間の残室数を計算する
			for (dispHeader disp : dispHeaders) {
				remaindCountSumMap.put(disp.yyyymmdd, 0);
			}
			// 旅行会社の場合
			if (isRealAgt) {
				for (TlSalesInfoType agtType : agtRmTypeLst) {
					for (dispHeader disp : dispHeaders) {
						TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
						remaindCountSumMap.put(disp.yyyymmdd, remaindCountSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
					}
				}
			} else {
				// AGT内部に室タイプグループ単位重複Filter処理
				Set<String> sampeGroupFilterSet = new Set<String>();
				// 所属するAGTはネットの場合、室タイプグループ、販売停止以外単位合計を行う
				for (TlSalesInfoType agtType : agtRmTypeLst) {
					// 室タイプグループコード
					String gpRmTypeCode = agtType.gpRmTypeCode;
					for (dispHeader disp : dispHeaders) {
						String filterKey = gpRmTypeCode + '_' + disp.yyyymmdd;
						if (sampeGroupFilterSet.contains(filterKey)) continue;
						TlSalesInfoItem item = agtType.dailyStockMap.get(disp.yyyymmdd);
						if (item.salesStatus == SALES_STATUS_STOP) continue;
						sampeGroupFilterSet.add(filterKey);
						remaindCountSumMap.put(disp.yyyymmdd, remaindCountSumMap.get(disp.yyyymmdd) + CommUtils.nullToIntZero(item.remainingCount));
					}
				}
			}
		}
	}
	// 販売先の室タイプ情報　と　SF側に関連の部屋タイプ
	public class TlSalesInfoType {
		public TlSalesInfoType(String cd, String nm) {
			rmTypeCode = cd;
			rmTypeName = nm;
			//
			dailyStockMap = new map<String, TlSalesInfoItem>();
		}
		// 販売先の室タイプコードと名
		public String rmTypeCode{get;set;}
		public String rmTypeName{get;set;}
		public String rmframe{get;set;}	// 枠
		// 室タイプグループ情報[ネット販売の場合、室タイプグループの残室数で合計、リアルの場合、販売先の在庫数で合計する]
		public String gpRmTypeCode{get;set;}
		public String gpRmTypeName{get;set;}
		// SF側に定義の部屋タイプコードと部屋タイプ名
		public String sfRmTypeCode{get;set;}
		public String sfRmTypeName{get;set;}
		// 部屋タイプリスト
		public map<String, TlSalesInfoItem> dailyStockMap{get;private set;}
	}
	
	// 日単位販売情報を格納する
	public class TlSalesInfoItem {
		public String saleDate{get;set;}	// YYYYMMDD
		public String salesCount{get;set;}
		public String remainingCount{get;set;}
		public String salesStatus{get;set;}
		public String agtCode{get;set;}	
	}
	
	// **************** COOKIE ***************
	// 2015/09/15 前回選択値を記憶する BEGIN
    private CookieInf getCookieInf () {
    	CookieInf inf = new CookieInf();
		Cookie theCookie, theCookieSub1;
		theCookie = ApexPages.currentPage().getCookies().get('_RoomTypeInventory_cookie_viewmode');
		theCookieSub1 = ApexPages.currentPage().getCookies().get('_RoomTypeInventory_cookie_viewmode_sub1');
        if (theCookie != null) inf.viewMode = theCookie.getValue();
        if (theCookieSub1 != null) inf.viewModeSub1 = theCookieSub1.getValue();
        return inf;
    }
    private void setCookieInf (CookieInf inf) {
		// 画面最後利用する画面モードはCookiesに維持する
		Cookie viewModeCookie = new Cookie('_RoomTypeInventory_cookie_viewmode', inf.viewMode, null, -1, true);
		Cookie viewModeSubCookie = new Cookie('_RoomTypeInventory_cookie_viewmode_sub1', inf.viewModeSub1, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{viewModeCookie,viewModeSubCookie});
    }
    public class CookieInf {
    	public String viewMode{get; set;}
    	public String viewModeSub1{get;set;}
    	public CookieInf(){}
    	public CookieInf(String pViewMode) {
    		viewMode = pViewMode;
    	}
    }
    // 2015/09/15 前回選択値を記憶する END
    // 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH BEGIN
    // 店舗別Baseプラン
    private Boolean isShopBasePlanFlg() {
        return (CommConst.APPOTION_BI_SHOPPLAN_FLG && CommDefine__c.getOrgDefaults().ShopBasePlanFlg__c);   
    }
    // 店舗別プランの場合、
    public List<SelectOption> filterPlanList{get;set;}
    private void filterBasePlan() {
        filterPlanList = new list<SelectOption>();
        if (isShopBasePlanFlg()) {
            for (SelectOption s : planLst) {
                String key = s.getValue();
                if (!isPlanActionMode(key)) {
                    // 常に使う項目を設定する
                    filterPlanList.add(s);
                } else if (CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0) {
                    // 店舗あり　かつ　ALLの場合、全てプランを表示する
                    filterPlanList.add(s);
                } else {
                    Plan__c plan = basePlanPriceMap.get(s.getValue());
                    if (plan.ShopInfoRef__r.ShopCode__c == branchShopNm) {
                        filterPlanList.add(s);
                    }
                }
            }
        } else {
            filterPlanList.addAll(planLst);
        }
    }
	// 2017/12/29 ラックレートのベースプランが店舗ごとにその店舗のみを表示で出来ないか対応 WGCH END
    // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
	// 部屋タイプID/ Map<日付, 金額>
	public boolean isTierFlag{get{return actionModeType == CONST_PAGELAYOUT_TIERLST;}set;}
	private	transient Map<String, Decimal> raceRateMstMap;
	private	transient Map<String, String> detailTierMap;
	class TierInfo {
		public String tier{get;set;}
		public String tierClass{get;set;}
		public TierInfo(String value) {
			tier = value;
			tierClass = '';
		}
	}
	class GuestRoomInfo {
		public GuestRoomStock__c stock{get;set;}
		public TierInfo tier{get;set;}
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		public Integer qtyStock{get;set;}
		public Integer maxRoomInt{get;set;}
		public integer diffRoomInt{get;set;}
		// 2018/12/15 在庫調整と販売状態管理 by zy END
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
		public String managerKey{get; set;}  // 检索SF在库管理Key
		public String managerKey2{get; set;} // 检索AGT在库管理Key
		// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
		public GuestRoomInfo(GuestRoomStock__c guestRoom) {
			stock = guestRoom;
			// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
			qtyStock = CommUtils.nullToIntZero(stock.QtyOfStock__c);
			// 2018/12/15 在庫調整と販売状態管理 by zy END
		}
		// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
		public GuestRoomInfo(GuestRoomStock__c guestRoom,Decimal sfStock) {
			stock = guestRoom;
			qtyStock = CommUtils.nullToIntZero(sfStock);
		}
		// 2018/12/15 在庫調整と販売状態管理 by zy END
	}
	// Tier設定取得する
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
	// public void processTierXmlSetting() {
	public void processTierXmlSetting(map<Date,String> teMap) {
	// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
		RackRateUtils.TierHelp tierHelp = RackRateUtils.getTierMap();
		// all 店舗の場合
		if (!isShowTierHeader) tierSetLst = tierHelp.getAllTierSetting();
		else tierSetLst = tierHelp.getTierSetting(branchShopNm);
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
		String basePlanIdStr = '';
		if (isPlanActionMode(actionModeType)) basePlanIdStr = basePlanPriceMap.get(actionModeType).Id;
		// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
				
		// 部屋タイプ別の対応
		for (dispRecord nwRec : dispRecordMap.values()) {
			Integer diffDays = 1;
			for (GuestRoomInfo g :nwRec.roomList) {
				//利用日
				Date hibiDt = g.stock.StockDate__c;
				// ラックレート明細のSearchKey作成
				String key = CommUtils.nullToBlank(nwRec.shopId) + '_' + hibiDt + '_' + nwRec.roomTypeId;
				// 店舗別のデフォルトTier定義情報
				String defaultTier = tierHeaderInfoMap.get(diffDays);
				// 部屋タイプ別のTier定義情報取得
				if ( detailTierMap.containsKey(key)) defaultTier = detailTierMap.get(key);
				// Tier値により、Tierの詳細情報、CSSのクラス名情報を格納する
				TierInfo tierInf = new TierInfo(defaultTier);
				// ラックレート設定モードの場合
				if (isTierFlag) {
					g.tier = tierInf;
					if (!isShowTierHeader) g.tier.tierClass += ' TierSpcd_' + nwRec.shopCode;
				}
				// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
				if (!CommUtils.isBlank(basePlanIdStr) && teMap.containsKey(hibiDt)) {
					String[] splitLst = teMap.get(hibiDt).split('_');
					if(splitLst.size() == 2){
						tierInf.tier = splitLst[1];
					}
				}
				// 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
				if (!CommUtils.isBlank(tierInf.tier)) {
					// Tier + "_" + 人数 + "_" + 部屋タイプID
					String raceRateKey = tierInf.tier + '_' + nwRec.roomTypeId + '_' + persons;
					if (raceRateMstMap != null) {
						// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
						String raceRatePlanKey = '';
						if(!CommUtils.isBlank(basePlanIdStr)) raceRatePlanKey = tierInf.tier + '_' + nwRec.roomTypeId + '_' + persons + '_' + basePlanIdStr;
						if(!CommUtils.isBlank(raceRatePlanKey) && raceRateMstMap.containsKey(raceRatePlanKey) && CommConst.RACKRATE_BASEPLAN){
							Decimal price = raceRateMstMap.get(raceRatePlanKey);
							raceRatePriceMap.get(nwRec.roomTypeId).put(hibiDt,CommUtils.nullToZero(price));
						} else {
							// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
							Decimal price = raceRateMstMap.get(raceRateKey);
							raceRatePriceMap.get(nwRec.roomTypeId).put(hibiDt,CommUtils.nullToIntZero(price));
						// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz BEGIN
						}
						// 2021/04/18 ラックレート設定ベースプラン金額 BY zyz END
					}
				}
				diffDays ++;
			}
		}
	}
	// tier カラーリスト
	public List<RackRateUtils.TierSetting> tierSetLst{get;set;}
	// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	public String hotelInfoJson{get; private set;}
	public class HotelTaxDefineInfo{
		public HotelTaxDefineInfo(){
			planItemPriceMap = new Map<String, List<Map<String, Decimal>>>();// Map< pMasterId, List< Map<pdId, Price> > >
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			planBrkInfoMap = new Map<String, List<PlanBrkInfo>>();
			// 2019/07/30 軽減税率機能対応 WGCH END
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
			gOptionMapInfo = new Map<String, ProductItemUtils.ProductItem>();
			// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		}
		public Map<String, CommLogicProcess.HotelTaxDefineInfo> hotelTaxDefInstance{get{ return CommLogicProcess.getHotelTaxDefInstance();}}
		public Map<String, List<Map<String, Decimal>>> planItemPriceMap{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Map<String, List<PlanBrkInfo>> planBrkInfoMap{get; private set;}
		// 2019/07/30 軽減税率機能対応 WGCH END
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public Map<String, ProductItemUtils.ProductItem> gOptionMapInfo{get; private set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
	}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2018/12/15 在庫調整と販売状態管理 by zy BEGIN
	private static final String CONST_PAGELAYOUT_STOCKSET = '在庫設定[AGT]';
	public String STOCK_SETTYPE_STOP{get{return '止';}}
	public String STOCK_SETTYPE_SALE{get{return '販';}}
	public boolean isStockFlag{get{return actionModeType == CONST_PAGELAYOUT_STOCKSET;}set;}
	public boolean isStockFunFlg{get{return CommDefine__c.getOrgDefaults().RoomTypeStockSettingFlag__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeStockSettingFlag__c;}}
	public String requestStr {get;set;}
	// 該当販売状態保存
	public void updateSalesType(){
		if (!CommUtils.isBlank(requestStr)) {
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'stockdate__c','settingflg__c','salesstatuslst__c','roomtyperef__c','qtyofstock__c','maxsettingrooms__c','managerkey__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return ;
			}
			// 2019/09/15 Security Check BY zyz END
			StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
			Map<String, GuestRoomStockInfo> stockInfoMap = (Map<String, GuestRoomStockInfo>)JSON.deserializeStrict(requestStr, Map<String, GuestRoomStockInfo>.class);
			List<GuestRoomStock__c> stockLst = [Select Id, ManagerKey__c, QtyOfStock__c, SalesStatusLst__c From GuestRoomStock__c Where ManagerKey__c in: stockInfoMap.keySet()];
			for(GuestRoomStock__c stock : stockLst){
				GuestRoomStockInfo item = stockInfoMap.get(stock.ManagerKey__c);
				stock.QtyOfStock__c = item.qtyOfStock; 
				stock.SettingFlg__c = true;
				stock.MaxSettingRooms__c = item.maxRooms;
				// 常に設定
				stock.SalesStatusLst__c = item.salesStatusLst == STOCK_SETTYPE_STOP ? CommConst.STOCK_SET_STOP : CommConst.STOCK_SET_SALE;
				stockInfoMap.remove(stock.ManagerKey__c);
			}
			for(GuestRoomStockInfo item : stockInfoMap.values()){
				GuestRoomStock__c stock = new GuestRoomStock__c();
				stock.SettingFlg__c = true;
				stock.RoomTypeRef__c = item.roomTypeId;
				stock.StockDate__c = item.stockDate;
				stock.ManagerKey__c = helpUtils.getRoomStockKey(item.roomTypeId, item.stockDate);
				// 常に設定
				stock.SalesStatusLst__c = item.salesStatusLst == STOCK_SETTYPE_STOP ? CommConst.STOCK_SET_STOP : CommConst.STOCK_SET_SALE;
				stock.QtyOfStock__c = item.qtyOfStock;
				stock.MaxSettingRooms__c = item.maxRooms;
				stockLst.add(stock);
			}
			if(!stockLst.isEmpty()) upsert stockLst;
		}
		refreshNewInfo();
	}
	// 該当販売状態保存
	public void updateWeekOpts(){
		if (!CommUtils.isBlank(requestStr)) {
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'stockdate__c','settingflg__c','roomtyperef__c','qtyofstock__c','managerkey__c','salesstatuslst__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return ;
			}
			// 2019/09/15 Security Check BY zyz END
			List<RoomInfo> infos = new List<RoomInfo>();
			StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
			RequestInfo info = (RequestInfo)JSON.deserialize(requestStr,RequestInfo.class);
			Date startDt = Date.Parse(info.beg);
			Date endDt = Date.Parse(info.endDt);
			// 曜日により、設定用日付を取得する
			// 開始日から、一週間の曜日日付を取得する
			List<String> weekOpts = info.weekOpts;
			Set<String> weekOptsSet = new Set<String>(weekOpts);
			Set<Id> typeSet = new Set<Id>(info.rtps);
			Date todayDt = system.today();
			if (startDt < todayDt) startDt = todayDt;
			DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
			DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
			List<GuestRoomStock__c> stockLst = new List<GuestRoomStock__c>();
			Map<String,integer> remanMap = info.remanMap;
			map<String,GuestRoomStock__c> guestMap = new map<String,GuestRoomStock__c>();
			// 販売状態「販売」の場合
			if (info.salesType == '1') {
				// 既存部屋在庫取得
				List<GuestRoomStock__c> roomLst = [Select Id, ManagerKey__c, QtyOfStock__c, SalesStatusLst__c 
														// 2019/05/31 JINYABUG-1741 bug fix by zy BEGIN
														From GuestRoomStock__c Where 
														//SalesStatusLst__c = :CommConst.STOCK_SET_STOP 
														SalesStatusLst__c != :CommConst.STOCK_SET_SALE 
														and  StockDate__c >= :startDt
														// 2019/05/31 JINYABUG-1741 bug fix by zy END
														and StockDate__c <= :endDt and RoomTypeRef__c in :typeSet];
				for (GuestRoomStock__c s : roomLst) {
					guestMap.put(s.ManagerKey__c,s);
				}
			}
			// 日付一括設定
			while (startDTime <= endDTime) {
				String weekKey = startDTime.format('EEEE');
				// 該当曜日あり
				if (weekOptsSet.contains(weekKey)) {
					Date configDate = startDTime.date();
					// 部屋タイプLOOP
					for (String typeId : info.rtps) {
						GuestRoomStock__c stock = new GuestRoomStock__c();
						String genKey = helpUtils.getRoomStockKey(typeId, configDate);
						// 該当状態「販売」の場合
						if (info.salesType == CommConst.STOCK_SET_SALE) {
							// 既存「止まる」データ変更、以外不更新
							if (guestMap.containsKey(genKey)) {
								stock = guestMap.get(genKey);
								stock.SalesStatusLst__c = info.salesType;
								stockLst.add(stock);
							}
						// 該当状態「止まる」の場合
						// 該当日付、部屋タイプ在庫数ありの場合
						} else if (remanMap.containsKey(genKey)) {
							Integer chgCount = CommUtils.nullToIntZero(remanMap.get(genKey)); 
							stock.SettingFlg__c = true;
							stock.RoomTypeRef__c = typeId;
							stock.StockDate__c = configDate;
							stock.ManagerKey__c = genKey;
							stock.QtyOfStock__c = chgCount;
							stock.SalesStatusLst__c = info.salesType;
							stockLst.add(stock);
						}
					}
				}
				startDTime = startDTime.addDays(1);
			}
			if (!stockLst.isEmpty()) upsert stockLst ManagerKey__c;
		}
		refreshNewInfo();
	}
	class RoomInfo{
		List<StockInfo> stocks;
		String tpid;
		String mode;
		public RoomInfo(TypeOfRooms__c r,String m){
			mode = m;
			tpid = r.id;
			stocks = new List<StockInfo>();
		}
		public void addDate(Date dt,Decimal dec){
			stocks.add(new StockInfo(dt,dec));
		}
	}	
	class StockInfo{
		Date begDt;
		Decimal num;
		public StockInfo(Date dt,Decimal dec){
			begDt = dt;
			num = dec;
		}
	}
	class RequestInfo{
		String id;
		String beg;
		String endDt;
		String spcd;
		String salesType;
		// 部屋タイプリスト
		List<Id> rtps;
		// 日付リスト
		List<String> stockDts;
		List<String> weekOpts;
		Map<String,integer> remanMap;
		// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz BEGIN
		Map<String,integer> diffRoomMap;
		// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz END
	}	
	public class GuestRoomStockInfo{
		public String roomTypeId;
		public Date stockDate;
		public Decimal qtyOfStock;
		public Decimal remainingCount;
		public decimal maxRooms;
		public String salesStatusLst;
	}
	public String getManagerKey(Id dataId, Date dt) {
		if (dataId == null) return (Date.today()).format();
		else return dataId + '_' + dt.format();
	}
	// 2018/12/15 在庫調整と販売状態管理 by zy END
	// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz BEGIN
	// 該当販売状態保存
	public void updateWeekOpt(){
		// json不为空
		if (!CommUtils.isBlank(requestStr)) {
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldsLst = new List<String>{'stockdate__c','settingflg__c','roomtyperef__c','qtyofstock__c','maxsettingrooms__c','managerkey__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return ;
			}
			// 2019/09/15 Security Check BY zyz END
			//List<RoomInfo> infos = new List<RoomInfo>();
			// 部屋在库管理的key合成使用
			StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
			// json解析
			RequestInfo info = (RequestInfo)JSON.deserialize(requestStr,RequestInfo.class);
			// 开始时间和终了时间
			Date startDt = Date.Parse(info.beg);
			Date endDt = Date.Parse(info.endDt);
			// 曜日により、設定用日付を取得する
			// 開始日から、一週間の曜日日付を取得する
			List<String> weekOpts = info.weekOpts;
			Set<String> weekOptsSet = new Set<String>(weekOpts);
			// 房型ID 
			Set<Id> typeSet = new Set<Id>(info.rtps);
			Date todayDt = system.today();
			if (startDt < todayDt) startDt = todayDt;
			DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
			DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
			List<GuestRoomStock__c> stockLst = new List<GuestRoomStock__c>();
			// 在库数MAP
			Map<String,integer> remanMap = info.remanMap;
			// 予约数MAP
			Map<String,integer> diffRoomMap = info.diffRoomMap;
			map<String,GuestRoomStock__c> guestMap = new map<String,GuestRoomStock__c>();
			// 既存部屋在庫取得
			List<GuestRoomStock__c> roomLst = [Select Id, ManagerKey__c, QtyOfStock__c, SalesStatusLst__c 
													From GuestRoomStock__c Where SalesStatusLst__c = :CommConst.STOCK_SET_STOP and StockDate__c >= : startDt
													and StockDate__c <= :endDt and RoomTypeRef__c in :typeSet];
			for (GuestRoomStock__c s : roomLst) {
				guestMap.put(s.ManagerKey__c,s);
			}
			// 日付一括設定
			while (startDTime <= endDTime) {
				String weekKey = startDTime.format('EEEE');
				// 該当曜日あり
				if (weekOptsSet.contains(weekKey)) {
					Date configDate = startDTime.date();
					// 部屋タイプLOOP
					for (String typeId : info.rtps) {
						GuestRoomStock__c stock = new GuestRoomStock__c();
						String genKey = helpUtils.getRoomStockKey(typeId, configDate);
						// 該当日付、部屋タイプ在庫数ありの場合
						//if (remanMap.containsKey(typeId)) {
						if (remanMap.containsKey(genKey)) {
							Integer chgCount = CommUtils.nullToIntZero(remanMap.get(genKey)); 
							Integer diffCount = CommUtils.nullToIntZero(diffRoomMap.get(genKey)); 
							stock.SettingFlg__c = true;
							stock.RoomTypeRef__c = typeId;
							stock.StockDate__c = configDate;
							stock.ManagerKey__c = genKey;
							stock.QtyOfStock__c = chgCount;
							stock.MaxSettingRooms__c = diffCount;
							stockLst.add(stock);
						}
					}
				}
				startDTime = startDTime.addDays(1);
			}
			if (!stockLst.isEmpty()) upsert stockLst ManagerKey__c;
		}
		refreshNewInfo();
	}
	// 控制一括在库设定的开关
	public Boolean StockFlg{get{return true;}}
	// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz END
	// 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz BEGIN
	public String leadTimeJsons{get;set;}
	private void getDefLead(){
        // 拡張予約項目を定義する
        String xmlName = (CommConst.APPOTION_NEWBOOKING_VER != 2 ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
  		leadTimeJsons = PageCustomeFieldHelper.getNewWindowLeadFieldDefValue(xmlName,branchShopNm,new map<String,String>{'staysNums'=>'staysNums','bookingRooms'=>'bookingRooms'});
	}
	// 2019/06/15 新規予約を部屋ごとに時間と到着日をデフォルト設定 BY zyz END
    // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz BEGIN
    // 由list转换为map
    public transient map<id,PlanInfo> planInfoMap{get; set;}	// 页面显示的全部数据信息
    public transient List<Plan__c> baseplanLst{get; set;} 	// 处理的全部数据(主要应用于启动window)
    public transient List<Plan__c> obaseplanLst{get; set;} 	// 处理的全部数据(主要应用于启动window)
    public String BasePlanShopId {get{
    	Id shopId = null;
    	if (!CommUtils.isBlank(branchShopNm)) {
    		shopId = shopInfoMap.get(branchShopNm).Id;
    	}
    	return CommUtils.nullToBlank(shopId);
    }
    set;}
    public void getPlanSetInfo(Map<String, BasePlanDetail__c> BasePlanMapInfo){
    	planInfoMap = new map<id,PlanInfo>();
    	list<Plan__c> records = pageCtrl.records;
    	// 指定の会計商品IDにより、関連詳細情報を取得する
        obaseplanLst = new List<Plan__c>();
        for (Plan__c acc : records){
        	obaseplanLst.add(acc);
        }
    	// 循环显示的所有plan数据
    	for(Plan__c plan : obaseplanLst){
    		// 初期化
    		PlanInfo info = new PlanInfo();
    		// plan按数据
    		info.s = plan;
    		// 会员种别
    		info.planTypeLst = vipTypeLst;
    		// 循环会员种别
    		for(String s : vipTypeLst){
    			Integer diffDays = 1;
    			list<basePlanInfo> baselist= new list<basePlanInfo>();
    			// 循环时间
	    		for(Integer day = 1; day <= daysInMonth; day ++){
					//时间；startDate：全局变量表示开始日
					Date hibiDt = startDate.addDays(day-1);
					// 店舗別のデフォルトTier定義情報
					String defaultTier = tierHeaderInfoMap.get(diffDays);
						// 数据区分的检索key
						String badKey = getBasePlanKey(BasePlanShopId,plan.Id,s, hibiDt);
						// 一括设定的默认key
						String defKey = getBasePlanKey(BasePlanShopId,'',s, hibiDt);
						// 根据key获取的寄存数据
						BasePlanDetail__c stock = BasePlanMapInfo.containsKey(badKey) ? BasePlanMapInfo.get(badKey) : BasePlanMapInfo.get(defKey);
						// 数据库存在，使用数据库值
						if(stock != null){
							basePlanInfo detail = new basePlanInfo(stock);
							if(detail.bases.Tier__c == null || CommUtils.isBlank(detail.bases.Tier__c) ) detail.bases.Tier__c = defaultTier;
							if (!CommConst.APPOTION_ROOMTYPE_INPUT_PASTDATA && hibiDt < Date.today()) {
								detail.disable = true;
							}
							baselist.add(detail);
						// 数据库不存在，使用默认值
						}else{
							basePlanInfo detail = new basePlanInfo(new BasePlanDetail__c(Tier__c=defaultTier,BasePlanRef__c=plan.Id,GuestType__c=s,SalesStatus__c=CommConst.STOCK_SET_SALE,PriceSetupDate__c=hibiDt));
							if (!CommConst.APPOTION_ROOMTYPE_INPUT_PASTDATA && hibiDt < Date.today()) {
								detail.disable = true;
							}
							baselist.add(detail);
						}
					// 日期追加
					diffDays++;
	    		}
	    		// 单独一笔页面数据信息
	    		info.basePlanInfoMap.put(s,baselist);
    		}
    		// 全部数据处理
    		planInfoMap.put(plan.Id,info);
    	}
    }
    public class PlanInfo{
    	public PlanInfo(){
    		s = new Plan__c();
    		basePlanInfoMap = new map<String,list<basePlanInfo>>();
    		planTypeLst = new List<String>();
    	}
    	public PlanInfo(Plan__c sobj){
    		s = sobj;
    	}
    	// 页面显示的plan数据
    	public transient Plan__c s{get; set;}
    	
    	// 页面显示的baseplan数据
    	public transient map<String,list<basePlanInfo>> basePlanInfoMap{get;set;}
    	// 页面显示的会员种别集合
    	public transient List<String> planTypeLst{get;set;}
    	// plan名
    	public transient String planName{get; set;}    	
	}
	// baseplan数据
	class basePlanInfo {
		public transient BasePlanDetail__c bases{get;set;}
		public transient Boolean disable{get;set;}
		public basePlanInfo(BasePlanDetail__c groupPlan) {
			bases = groupPlan;
			disable = false;
		}
    }
    // 获取baseplan数据
    private Map<String, BasePlanDetail__c> queryBasePlanMap (Date conStartDate, Date conEndDate, List<Plan__c> qTypeOfRooms) {
    	// planKey的集合
    	Set<String> basePlanKeySet = new Set<String>();
    	// 处理tier联动plan的map
    	tierVipMap = new map<String,map<Date,String>>();
    	// plan数据处理的map
    	Map<String, BasePlanDetail__c> badRoomNumsMap = new Map<String, BasePlanDetail__c>();
    	// planId的集合
    	set<id> basePlanIds = new set<id>();
    	for (Plan__c s: qTypeOfRooms) basePlanIds.add(s.id);
    	
    	String ShopIdStr = BasePlanShopId + '%';
    	// baseplan的SQL
        String leadQuery = ' Select SearchKey__c,Tier__c,BasePlanRef__c,GuestType__c,PriceSetupDate__c,SalesStatus__c From BasePlanDetail__c Where' +
                         ' PriceSetupDate__c >= :conStartDate ' +
                         ' And PriceSetupDate__c <= :conEndDate ' +
                         ' And SearchKey__c like :ShopIdStr' +
                         ' Order by PriceSetupDate__c ';
        List<BasePlanDetail__c> useLeadRoomAvg = DataBase.query(leadQuery);
        map<String,BasePlanDetail__c> allDetailMap = new map<String,BasePlanDetail__c>();
        // 处理所有的baseplan
        for(BasePlanDetail__c detail : useLeadRoomAvg){
        	// tier特殊数据key : planId_会员种别
        	String tierKey = detail.BasePlanRef__c +'_' +detail.GuestType__c;
        	if(detail.BasePlanRef__c == null){
        		String allKey =  detail.GuestType__c +'_' + detail.PriceSetupDate__c;
        		allDetailMap.put(allKey,detail);
        	}else{      	
	    		if (!tierVipMap.containsKey(tierKey)) tierVipMap.put(tierKey,new map<Date,String>{detail.PriceSetupDate__c => detail.SalesStatus__c + '_' + detail.Tier__c});
	        	tierVipMap.get(tierKey).put(detail.PriceSetupDate__c, detail.SalesStatus__c + '_' + detail.Tier__c);
        	}
        	// baseplan的key
        	String key = getBasePlanKey(BasePlanShopId,detail.BasePlanRef__c, detail.GuestType__c, detail.PriceSetupDate__c);
            if(basePlanKeySet.contains(key)) continue;
            basePlanKeySet.add(key);              
			badRoomNumsMap.put(key,detail);
        }
        // 循环all处理
    	for(String alls : allDetailMap.keyset()){
    		String[] keys = alls.split('_');
    		if(keys.size() != 2) continue;
    		String VTStr = keys[0];
    		Date DTStr =  Date.valueOf(keys[1]);
    		BasePlanDetail__c detail = allDetailMap.get(alls);
    		for(Id pId : basePlanIds){
    			String getkey = pId +'_' + VTStr;
	    		if (!tierVipMap.containsKey(getkey)) tierVipMap.put(getkey,new map<Date,String>{DTStr => detail.SalesStatus__c + '_' + detail.Tier__c});
	        	map<Date,String> dateVipMap = tierVipMap.get(getkey);
	        	if (!dateVipMap.containsKey(DTStr)) {
	        		dateVipMap.put(DTStr, detail.SalesStatus__c + '_' + detail.Tier__c);
	        		tierVipMap.put(getkey,dateVipMap);
	        	}
	        	
    		}
    	}
        return badRoomNumsMap;
    }
    // 会员种别集合
    public List<SelectOption> planVipList{get;set;}
    // 会员种别的初始值
    public String planVipStr{get;set;}
	// map的存储内容 : map<planId_会员等级,map<日期,贩卖状态_tier>>
	private map<String,map<Date,String>> tierVipMap{get;set;}
	// baseplan显示的控制开关
	public transient boolean isBasePlanFlg{get{return actionModeType == CONST_PAGELAYOUT_BASEPLAN;}set;}
	private boolean isBasePlanLayputFlg{get{return CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c == null ? false : CommDefine__c.getOrgDefaults().RoomTypeBasePlanTierFlag__c;}}
    // 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz BEGIN
    public boolean isPlanActionFlg{get;set;}
    // 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz END
    // 数据存储的JSON
	public String planJsonStr {get;set;} 
	class PlanDetailInfo{
		String beg;				// 开始时间
		String endDt;			// 结束时间
		List<String> plps;		// plan集合
		List<String> weekOpts;	// 星期集合
		String tierType;		// tier设定
		String salesType;		// 贩卖状态
		String vipType;			// 会员种别
		String allPlanFlg;		// 全部会计设定
	}	
    // 数据存储的JSON
	public String planOneJsonStr {get;set;} 
	class PlanOneInfo{
		String searchKey;		// 数据Key
		String setupDate;		// 设定日
		String basePlanId;		// planId
		String tierType;		// tier设定
		String salesType;		// 贩卖状态
		String vipType;			// 会员种别
	}
	public void updPlanDetailInfo() {
		// 窗口修改数据集合
		PlanDetailInfo info = new PlanDetailInfo();
		// 页面修改数据集合
		Map<String, PlanOneInfo> plansInfoMap = new Map<String, PlanOneInfo>();
		set<String> keySet = new set<String>();
		
		// 窗口修改事件
		if (!CommUtils.isBlank(planJsonStr)) {
			// json解析
			info = (PlanDetailInfo)JSON.deserialize(planJsonStr,PlanDetailInfo.class);
		// 页面修改事件
		}else if (!CommUtils.isBlank(planOneJsonStr)){
			// json解析
			plansInfoMap = (Map<String, PlanOneInfo>)JSON.deserializeStrict(planOneJsonStr, Map<String, PlanOneInfo>.class);
			for(String oneKey : plansInfoMap.keyset()){
				keySet.add(oneKey);
			}
		}
		// 检索SQL初始
		String queryDetailStr = 'Select SearchKey__c,Tier__c,BasePlanRef__c,GuestType__c,PriceSetupDate__c,SalesStatus__c From BasePlanDetail__c ';
		// 窗口检索条件
		if (!CommUtils.isBlank(planJsonStr)) {
				Date startDt = Date.Parse(info.beg);
				Date endDt = Date.Parse(info.endDt);
				Set<String> basePlanSet = new Set<String>(info.plps);
				queryDetailStr += ' Where PriceSetupDate__c >= : startDt and PriceSetupDate__c <= : endDt ';
		// 页面检索条件
		}else if (!CommUtils.isBlank(planOneJsonStr)){
			queryDetailStr += ' Where SearchKey__c in: keySet';
		}
		// 检索即存数据
		List<BasePlanDetail__c> BasePlansLst = DataBase.query(queryDetailStr);
		// 即存数据集合
		map<String,BasePlanDetail__c> guestMap = new map<String,BasePlanDetail__c>();
		// 即存数据处理
		for (BasePlanDetail__c s : BasePlansLst) {
			guestMap.put(s.SearchKey__c,s);
		}
		// 更新数据集合
		List<BasePlanDetail__c> BasePlanDetailLst = new List<BasePlanDetail__c>();
		if (!CommUtils.isBlank(planJsonStr)) {
			// 开始时间和终了时间
			Date startDt = Date.Parse(info.beg);
			Date endDt = Date.Parse(info.endDt);
			// 曜日により、設定用日付を取得する
			// 開始日から、一週間の曜日日付を取得する
			List<String> weekOpts = info.weekOpts;
			Set<String> weekOptsSet = new Set<String>(weekOpts);
			// planID 
			Set<String> typeSet = new Set<String>(info.plps);
			// 贩卖状态
			String salesType = info.salesType== '2' ? CommConst.STOCK_SET_STOP : CommConst.STOCK_SET_SALE;
			// 会员种别
			String vipType = info.vipType;
			// tier
			String tierType = info.tierType;
			// 一括处理的flg
			String allPlanFlg = info.allPlanFlg.toLowerCase();
			
			Date todayDt = system.today();
			// 开始日期时间-结束日期时间
			DateTime startDTime = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
			DateTime endDTime = DateTime.newInstance(endDt.year(), endDt.month(), endDt.day());
			// 日付一括設定
			while (startDTime <= endDTime) {
				String weekKey = startDTime.format('EEEE');
				// 該当曜日あり
				if (weekOptsSet.contains(weekKey)) {
					Date configDate = startDTime.date();
					// 处理一括设定
					set<String> repeatKetset = new set<String>();
					for (String planId : info.plps) {
							BasePlanDetail__c BasePlan = new BasePlanDetail__c();
							String genKey = getBasePlanKey(BasePlanShopId,planId, vipType, configDate);
							if(guestMap.containsKey(genKey)){
								BasePlan = guestMap.get(genKey);
								BasePlan.SearchKey__c = genKey;
								BasePlan.Tier__c = tierType;
								BasePlan.GuestType__c = vipType;
								BasePlan.PriceSetupDate__c = configDate;
								// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz BEGIN
								if(!CommUtils.isBlank(CommUtils.nullToBlank(info.salesType))) BasePlan.SalesStatus__c = salesType;
								// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz END
								BasePlanDetailLst.add(BasePlan);
							// 一括处理的数据
							}else if(allPlanFlg == 'true'){
								genKey = getBasePlanKey(BasePlanShopId,'', vipType, configDate);
								if(repeatKetset.contains(genKey)) continue;
								repeatKetset.add(genKey);
								// 即存数据变更
								if(guestMap.containsKey(genKey)){
									BasePlan = guestMap.get(genKey);
									BasePlan.SearchKey__c = genKey;
									BasePlan.Tier__c = tierType;
									BasePlan.GuestType__c = vipType;
									// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz BEGIN
									if(!CommUtils.isBlank(CommUtils.nullToBlank(info.salesType))) BasePlan.SalesStatus__c = salesType;
									// 2020/05/30 予約ポップラックレート設定[プラン]bug対応 BY zyz END
									BasePlanDetailLst.add(BasePlan);
								// 不存在数据插入
								} else {
									BasePlan.SearchKey__c = genKey;
									BasePlan.Tier__c = tierType;
									BasePlan.GuestType__c = vipType;
									BasePlan.PriceSetupDate__c = configDate;
									BasePlan.SalesStatus__c = salesType;
									BasePlanDetailLst.add(BasePlan);
								}
							// 不存在数据插入
							} else {
								BasePlan.SearchKey__c = genKey;
								BasePlan.Tier__c = tierType;
								BasePlan.BasePlanRef__c = planId;
								BasePlan.GuestType__c = vipType;
								BasePlan.PriceSetupDate__c = configDate;
								BasePlan.SalesStatus__c = salesType;
								BasePlanDetailLst.add(BasePlan);
							}
					}
				}
				// 追加日期
				startDTime = startDTime.addDays(1);
			}
		// 页面检索条件
		}else if (!CommUtils.isBlank(planOneJsonStr)){
			for(String oneKey : plansInfoMap.keyset()){			
				BasePlanDetail__c BasePlan = new BasePlanDetail__c();
				// 页面修改信息获取
				PlanOneInfo oneInfo = plansInfoMap.get(oneKey);
				String genKey = getBasePlanKey(BasePlanShopId,oneInfo.basePlanId, oneInfo.vipType, Date.valueOf(oneInfo.setupDate));
				// 即存数据变更
				if(guestMap.containsKey(genKey)){
					BasePlan = guestMap.get(genKey);
					BasePlan.SearchKey__c = genKey;
					BasePlan.Tier__c = oneInfo.tierType;
					BasePlan.GuestType__c = oneInfo.vipType;
					BasePlan.SalesStatus__c = oneInfo.salesType;
					BasePlanDetailLst.add(BasePlan);
				// 不存在数据插入
				}else{
					BasePlan.SearchKey__c = genKey;
					BasePlan.Tier__c = oneInfo.tierType;
					BasePlan.BasePlanRef__c = oneInfo.basePlanId;
					BasePlan.GuestType__c = oneInfo.vipType;
					BasePlan.PriceSetupDate__c = Date.valueOf(oneInfo.setupDate);
					BasePlan.SalesStatus__c = oneInfo.salesType;
					BasePlanDetailLst.add(BasePlan);
				}
			}
		}
		// 更新/插入数据
		if (!BasePlanDetailLst.isEmpty()) upsert BasePlanDetailLst;// SearchKey__c;
		// 页面重新读取显示
		refreshNewInfo();
	}
	// 处理数据key
	private String getBasePlanKey(String shopId,String planId,String vipStr, Date dt) {
		String key = RackRateUtils.genRackRateBasePlanSearchKey(shopId,vipStr,dt);
		if (!CommUtils.isBlank(planId)) key += '_' + planId;
		return key;
	}
    private List<Plan__c> getBasePlans() {
    	String planWhereStr = '';
    	if (isShopBasePlanFlg() && !CommUtils.isBlank(branchShopNm)) planWhereStr += ' AND ShopInfoRef__r.ShopCode__c = :branchShopNm';
        String 	queryStr = ' select Id, Name From Plan__c where IsClosed__c != true And BasePlanFlg__c = true '+planWhereStr+' order by Seq__c limit 10000 ';
        return DataBase.query(queryStr);
    }
    // 会员种别可以自定义处理
    public transient list<String> vipTypeLst{get;set;}
    public void getVipList(){
		if(isBasePlanLayputFlg) {
		Schema.DescribeFieldResult fieldResult = BasePlanDetail__c.GuestType__c.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for( Schema.PicklistEntry f : ple) {
				if(f.isDefaultValue() || CommUtils.isBlank(planVipStr)) planVipStr = f.getLabel();
				vipTypeLst.add(f.getLabel());
				if(isPlanActionMode(actionModeType)) planVipList.add(new SelectOption(f.getValue(),f.getLabel()));
			}
		}
    }
    // 改ページ機能対応
    public PaginationUtil pageCtrl{get; set;}
    private Boolean pageInfoFlg{get;set;}
	public void firstPage() {
		pageCtrl.firstPage();
		pageInfoFlg = false;
		doAction(0);
	}
	public void previousPage() {
		pageCtrl.previousPage();
		pageInfoFlg = false;
		doAction(0);
	}
	public void nextPage() {
		pageCtrl.nextPage();
		pageInfoFlg = false;
		doAction(0);
	}
	public void lastPage() {
		pageCtrl.lastPage();
		pageInfoFlg = false;
		doAction(0);
	}
    // 2020/03/31 予約ポップでラックレートのテーブルを複数持つ機能 BY zyz END
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
	@remoteaction
	public static object remoteCenter(String dataType,String data){
		if (dataType == 'getTierMapInfo') return getTierMapInfo(data);
		return null;
	}
	private static object getTierMapInfo(String data){
		request info = (Request)JSON.deserializeStrict(data,Request.class);
		BasePlanSetupViewCtrl basePlanCtrl = new BasePlanSetupViewCtrl(info.typeId,info.queryDt,info.spcd,info.guestType);
		basePlanCtrl.init();
		return (Map<String, Decimal>)JSON.deserializeStrict(basePlanCtrl.raceRateMapJson,Map<String, Decimal>.class);
	}
	public class Request{
		String spcd;
		String typeId;
		String queryDt;
		String guestType;
	}
	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH BEGIN
	public String roomsChangeJsonStr{get; set;} // 变更数据集合JSON
	// 2021/03/16 viewstatus bug fix WSQ begin
	// add [transient] keyword
	public transient Map<String, AgtStockInfo> sfStockInfoMap{get; set;} // SF残室数数据集合
	public transient Map<String, AgtStockInfo> agtStockInfoMap{get; set;} // AGT残室数数据集合
	// 2021/03/16 viewstatus bug fix WSQ END
	// AGT残室数集合
	public class AgtStockInfo{
		public AgtStockInfo(String roomTypeId, Date ciDate){
			// 初期化
			init(roomTypeId, ciDate, null);
		}
		public AgtStockInfo(String roomTypeId, Date ciDate, String accountId){
			// 初期化
			init(roomTypeId, ciDate, accountId);
		}
		public void init(String roomTypeId, Date ciDate, String accountId){
			this.roomTypeId = roomTypeId;
			this.ciDate = ciDate;
			this.accountId = accountId;
			maxRooms = sfQtyOfStock = agtQtyOfStock = allQtyOfStock = 0;
		}
		public String roomTypeId{get;set;} // 房间Id
		public Date ciDate{get;set;} // 日期
		public String accountId{get;set;} // 取引先Id
		public Decimal maxRooms{get;set;} // 最大販売室数
		public Decimal sfQtyOfStock{get;set;} // SF端残室数
		public Decimal agtQtyOfStock{get;set;} // AGT端残室数
		public Decimal allQtyOfStock{get{ return (sfQtyOfStock + agtQtyOfStock);} set;} // 最大残室数
	}
	// AGT残室数集合处理
	/*
	* roomTypeId    : 部屋TypeID
	* ciDate        : 日期
	* accountId     : 取引先ID
	* maxRooms      : 最大販売室数
	* sfQtyOfStock  : SF端当前残室数
	* agtQtyOfStock : AGT端当前残室数
	*/
	// SF端当前残室数信息设定
	public void setSfStockInfoMap(String roomTypeId, Date ciDate){
		setSfStockInfoMap(roomTypeId, ciDate, null, null);
	}
	public void setSfStockInfoMap(String roomTypeId, Date ciDate, Decimal maxRooms, Decimal sfQtyOfStock){
		// 处理数据集合Key
		String managerkey = getManagerKey(roomTypeId, ciDate);
		// SF残室数数据集合处理
		if(!sfStockInfoMap.containsKey(managerkey)) sfStockInfoMap.put(managerkey, new AgtStockInfo(roomTypeId, ciDate));
		// 功能开关
		if(!isStockSyncIsMode) return;
		// 最新值重置设定
		AgtStockInfo sfStockItem = sfStockInfoMap.get(managerkey);
		// 最大販売室数
		if(maxRooms != null) sfStockItem.maxRooms = CommUtils.nullToZero(maxRooms);
		// SF端最终残室数
		if(sfQtyOfStock != null) sfStockItem.sfQtyOfStock = CommUtils.nullToZero(sfQtyOfStock);
	}
	// AGT端当前残室数信息设定
	public void setAgtStockInfoMap(String roomTypeId, Date ciDate, String accountId){
		setAgtStockInfoMap(roomTypeId, ciDate, accountId, null);
	}
	public void setAgtStockInfoMap(String roomTypeId, Date ciDate, String accountId, Decimal agtQtyOfStock){
		// 处理数据集合Key
		String managerkey = getManagerKey(roomTypeId, ciDate);
		String managerkey2 = getManagerKey2(managerkey, accountId);
		// AGT残室数数据集合处理
		if(!agtStockInfoMap.containsKey(managerkey2)) agtStockInfoMap.put(managerkey2, new AgtStockInfo(roomTypeId, ciDate, accountId));
		// 功能开关
		if(!isStockSyncIsMode) return;
		// 最新值重置设定
		AgtStockInfo agtStockItem = agtStockInfoMap.get(managerkey2);
		// AGT端最终残室数
		agtStockItem.agtQtyOfStock = CommUtils.nullToZero(agtQtyOfStock);
		// 获取当前SF端在库数信息
		AgtStockInfo sfStockItem = sfStockInfoMap.get(managerkey);
		// SF端最终残室数
		if(sfStockItem != null) agtStockItem.sfQtyOfStock = CommUtils.nullToZero(sfStockItem.sfQtyOfStock);
	}
	// 最终房间残室数更新
	public void upRoomsChange(){
		try{
			List<String> chkFieldsLst = new List<String>{'stockdate__c','settingflg__c','salesstatuslst__c','roomtyperef__c','qtyofstock__c','maxsettingrooms__c','managerkey__c'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
				return;
			}
			// 指定的修改设定值进行转化成对应的InTheClass
			Map<String, AgtRoomsInfo> agtRoomsItemMap = (Map<String, AgtRoomsInfo>)JSON.deserialize(roomsChangeJsonStr, Map<String, AgtRoomsInfo>.class);
			Map<String, AgtRoomsInfo> sfRoomsInfoMap = new Map<String, AgtRoomsInfo>();
			for(AgtRoomsInfo item : agtRoomsItemMap.values()){
				if(!sfRoomsInfoMap.containsKey(item.managerKey)) sfRoomsInfoMap.put(item.managerKey, new AgtRoomsInfo());
				AgtRoomsInfo gItem = sfRoomsInfoMap.get(item.managerKey);
				gItem.roomTypeId = item.roomTypeId;
				gItem.stockDate = item.stockDate;
				gItem.newVal = CommUtils.nullToZero(item.newVal) + CommUtils.nullToZero(gItem.newVal);
				gItem.oldval = CommUtils.nullToZero(item.oldval) + CommUtils.nullToZero(gItem.oldval);
				gItem.changeVal = CommUtils.nullToZero(item.changeVal) + CommUtils.nullToZero(gItem.changeVal);
				// 同一天同一房型这个值是一样的最大残室数
				gItem.sfQtyOfStock = CommUtils.nullToZero(item.sfQtyOfStock); // SF最大残室数
				gItem.maxRooms = CommUtils.nullToZero(item.maxRooms);
				gItem.accountRoomsMap.put(item.accountId, CommUtils.nullToZero(item.changeVal));
			}
			List<GuestRoomStock__c> stockLst = [Select Id, ManagerKey__c, QtyOfStock__c, SalesStatusLst__c, AGTChangeRoomsJSON__c From GuestRoomStock__c Where ManagerKey__c in: sfRoomsInfoMap.keySet()];
			// 部屋在库管理的key合成使用
			StockChangeHelpUtils helpUtils = new StockChangeHelpUtils();
			// list<StockChangeHisotry__c> newStockChangeHisotryLst = new List<StockChangeHisotry__c>();
			// 已存在的部屋在库管理数据集合
			for(GuestRoomStock__c stock : stockLst){
				AgtRoomsInfo item = sfRoomsInfoMap.get(stock.ManagerKey__c);
				// 該当日付、部屋タイプ在庫数ありの場合
				stock.SettingFlg__c = true;
				stock.AGTChangeRoomsJSON__c = getAGTChangeRoomsJSON(item, stock);
				stock.QtyOfStock__c = CommUtils.nullToZero(item.sfQtyOfStock) - CommUtils.nullToZero(item.changeVal);
				stock.MaxSettingRooms__c = CommUtils.nullToZero(item.maxRooms) - CommUtils.nullToZero(item.changeVal);
				sfRoomsInfoMap.remove(stock.ManagerKey__c);
			}
			// 最新数据集合更新设定
			for(AgtRoomsInfo item : sfRoomsInfoMap.values()){
				GuestRoomStock__c stock = new GuestRoomStock__c();
				stock.SettingFlg__c = true;
				stock.RoomTypeRef__c = item.roomTypeId;
				stock.StockDate__c = item.stockDate;
				stock.ManagerKey__c = helpUtils.getRoomStockKey(item.roomTypeId, item.stockDate);
				stock.QtyOfStock__c = CommUtils.nullToZero(item.sfQtyOfStock) - CommUtils.nullToZero(item.changeVal);
				stock.MaxSettingRooms__c = CommUtils.nullToZero(item.maxRooms) - CommUtils.nullToZero(item.changeVal);
				stock.AGTChangeRoomsJSON__c = getAGTChangeRoomsJSON(item, stock);
				stockLst.add(stock);
			}
			// 更新插入数据集合
			if(!stockLst.isEmpty()) upsert stockLst; // SF最大残室数, 贩卖数信息更新
		} catch (Exception e){
			SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'e.getMessage():='+e.getMessage());
		}
		// 页面重新读取显示
		refreshNewInfo();
	}
	public static String getAGTChangeRoomsJSON(AgtRoomsInfo item, GuestRoomStock__c stock){
		Map<String, Object> atgChangeMap = StockChangeHelpUtils.getAGTChangeRoomsMap(stock.AGTChangeRoomsJSON__c);
		for(String accountId : atgChangeMap.keySet()){
			Decimal newChangeVal = CommUtils.nullToZero(item.accountRoomsMap.get(accountId)) + CommUtils.nullToZero(atgChangeMap.get(accountId));
			item.accountRoomsMap.put(accountId, newChangeVal);
		}
		return StockChangeHelpUtils.setAGTChangeRoomsJson(item.accountRoomsMap);
	}
	public class AgtRoomsInfo{
		public AgtRoomsInfo(){
			accountRoomsMap = new Map<String, Decimal>();
		}
		public String managerKey; // SF在库管理KEY
		public String managerKey2; // AGT在库管理KEY
		public Decimal newVal; // 新设定的残室数
		public Decimal oldval; // 原设定的残室数
		public String roomTypeId; // 部屋TypeId
		public Date stockDate; // 对应的日期
		public String accountId; // 取引先Id
		public Decimal changeVal; // 新残室数 与 原残室数 的 差值
		public Decimal sfQtyOfStock; // SF最大残室数
		public Decimal maxRooms; // 最大販売室数
		public Decimal diffIntVal; // 故障房间数
		public Map<String, Decimal> accountRoomsMap; // Key: 取引先ID; Val: 跟AGT最大房间数的差值(变更数)
	}
	// 获取AGT残室数信息管理Key
	public String getManagerKey2(String managerKey, String accountId) {
		return managerKey + '_' + CommUtils.nullToBlank(accountId);
	}
	// 2020/11/30 リアルAGT増返室ボタン機能新規追加 WGCH END
	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
	public boolean isOverRoomTypeLimitFlg{get;set;} // 部屋タイプ数量超えるフラグ
	private void readRoomtypeDocInfo(){
		CONST_MAX_ROOMTYPE = 50;
		isOverRoomTypeLimitFlg = false;
		// 拡張予約項目を定義する
        String xmlName = (CommConst.APPOTION_NEWBOOKING_VER != 2 ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
        try{
       		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,branchShopNm);
	        if (targetNode != null) {
	        	Dom.XMLNode roomTypeIntNode = targetNode.getChildElement('MAX_ROOMTYPE_INT', null);
	        	if (roomTypeIntNode != null) {
	        		String typeIntStr = CommUtils.nullTOBlank(roomTypeIntNode.getText());
	        		if (!CommUtils.isBLank(typeIntStr)) {
	        			CONST_MAX_ROOMTYPE = CommUtils.nullToIntZero(typeIntStr);
	        		}
	        	}
	        	
	        } 
	    } catch(Exception e){
	    }
	}
	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
	// 2021/06/31 #11821 bug fixed by zy BEGIN
	public String basePlanShopCode{get;set;}
	// 2021/06/31 #11821 bug fixed by zy END
	// 2021/06/31 #JP10243　対応　by zy BEGIN
	public boolean isRealAgtLayoutSimple{get{return CommConst.REAL_AGT_LAYOUTPAGE_MODE == CommConst.REALAGT_LAYOUT_ORG;}private set;}
	// 2021/06/31 #JP10243　対応　by zy END
}