public with sharing class CookTimeTableCtrl {
    // 支店選択リスト
    public List<SelectOption> branchShopLst{get; private set;}
	// 部屋タイプリスト情報
	public List<SelectOption> roomTypeLst{get; private set;}
	public List<SelectOption> businessLst{get;private set;}
	public List<SelectOption> modeLst{get;set;}
	public String branchShopNm{get;set;}
	// タイムランリスト
	public List<List<TimeInfo>> timeLsts{get;set;}
	// 該当モード
	public String curMode{get;set;}
	// 該当料理タイプ
	public String curType{get;set;}
	// 間隔時刻
	public integer minuteDiff{get;set;}
	// １分の横幅
	public integer leftDiff{get;set;}
	// カラー情報
	public ColorInfo color{get;set;}
	// 表示料理テンプレート
	public String detailInfo{get;set;}
	// 開始時刻
	public long begTmLong{get;private set;}
	// 完了時刻
	public long endTmLong{get;private set;}
	public integer lastLeftInt{get;set;}
	// 該当店舗名
	public String curShopName{get;set;}
	// 該当モード時刻数
	private integer modInt{get;set;}
	// ユーザ情報
	private UserUtil.UserShopInfo userInf;
	// 注文タイプ「見積明細」
	private static String ORDER_TYPE_BOOKINGEST = 'BookingEstimateItem__c';
	// 注文タイプ「会計明細」
    private static String ORDER_TYPE_TRAN1 = 'Tran1__c';
    // 注文タイプ「見積明細」SQL文
	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN  
    // 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN  
    private static String bookingEstQuery = 'select id,CookInfo__c,refAccountMaster__c,FoodDetailFlg__c from BookingEstimateItem__c';
    // 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
    // 2018/10/31 料理進捗開始（OWNER) by cxw END
    // 注文タイプ「会計明細」SQL文
    // 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    // 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
    private static String tran1Query = 'select id,CookInfo__c,Field7__c,FoodDetailFlg__c from Tran1__c';
    // 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
    // 2018/10/31 料理進捗開始（OWNER) by cxw END
    private static String COOKINFO_PROPTY_STATUS = 'status';
    private static String COOKINFO_PROPTY_BEGTM = 'begTm';
    private static String COOKINFO_STATUS_VALUE_DONE = 'Done';
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	private static String COOKINFO_PROPTY_ORDER = 'oid';
	private static String COOKINFO_PROPTY_CNT = 'cnt';
	private static String COOKINFO_PROPTY_SEQ = 'seq';
	private static String COOKINFO_PROPTY_DSC = 'dsc';
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    // デフォルト料理時限
    public static decimal COOKINFO_MUNITES{get;set;}
    private static decimal LIMIT_TIME_SYNC = 24*60*60*1000;
    private String decLabel;
    // 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    public BookingTimeTable__c selectDate{get; private set;}
    // 2018/10/31 料理進捗開始（OWNER) by cxw END
	public CookTimeTableCtrl(){
		initInfo();
	}
	// 初期化
    public void initInfo(){
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	selectDate = new BookingTimeTable__c(Checkinday__c = system.today());
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
    	branchShopNm = '';
    	curType = '';
    	COOKINFO_MUNITES = 10;
    	detailInfo = '@name 「@cnt点」@minute分';
    	// 当前ユーザ情報取得
    	userInf = UserUtil.CurrentUserInfo;
    	// 店舗リスト情報を取得する
    	setInitBranShopLst();
    	// 部屋タイプリスト
    	setInitRoomTypeLst();
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		locShowType = COOK_SHOW_TYPE_RES;
		selKitchenVal = '';
		accTimeFlag = true;
		cookDoneHideLen = 50;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    }
   	// 画面初期化
    public void init(){
    	boolean hadSetType = ApexPages.currentPage().getParameters().containsKey('type');
    	if (hadSetType) decLabel = ApexPages.currentPage().getParameters().get('type');
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	boolean hadDt = ApexPages.currentPage().getParameters().containsKey('dt');
    	if (hadDt) selectDate.Checkinday__c = CommUtils.stringtoDate(CommUtils.nullToBlank(ApexPages.currentPage().getParameters().get('dt')));
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
    	// ドキュメント情報取得
    	loadDocument(branchShopNm);
    	// 該当時間指定タイプ
	    if (!hadSetType) getCurrentType();
    	doAction();
    }
    // モード変更
    public void chgMode(){
    	changeMode();
    	setTimeHeader();
    }
    public void chgType(){
    	setModeLst();
    	setTimeHeader();
    }
    // 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN  
    public void gotoDate(){}
    // 2018/10/31 料理進捗開始（OWNER) by cxw END  
    public void refreshBranchShopInfo(){
    	// ドキュメント情報取得
    	loadDocument(branchShopNm);
    	// 同じ営業チェック
    	boolean hadSameSetFlag = false;
    	if (!CommUtils.isBlank(curType)) {
    		// 該当営業タイムリスト
    		for (SelectOption sec : businessLst) {
    			// 設定時刻値
    			String timeVal = sec.getValue();
    			if (curType == timeVal) hadSameSetFlag = true;
    		}
    	}
    	// 同じ営業なしの場合
    	if (!hadSameSetFlag) curType = '';
    	doAction();
    }
    // ドキュメント情報取得
    private void loadDocument(String spcd){
    	color = new ColorInfo();
    	COOKINFO_MUNITES = 10;
    	businessLst = new List<SelectOption>();
    	// 2019/01/30 料理UI改善　by zy BEGIN
    	padHeadShow = true;
    	// 2019/01/30 料理UI改善　by zy END
        // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
        isEndFlag = false;
        // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
		cookRoomSetJson = '';
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
		colorInfoJson = '';
		Map<String,String> statusColorMap = new Map<String,String>();
		Map<String,Integer> statusMap = new Map<String,Integer>();
		Map<String,String> statusLabelMap = new Map<String,String>();
		List<String> statusLst = new List<String>();
		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
		timeFlag = false;
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		isOrderEndFlg = false;
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		// 2020/05/30 リリース後の検収再対応 by zy BEGIN
		kichenOrderOnly = false;
		// 2020/05/30 リリース後の検収再対応 by zy END
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		isSameProductSumFlg = false;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
	    try{
	    		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
		    Dom.XMLNode rootNode = CommXmlUtils.encodeParseXmlDoc('OrderProductConfig', spcd,new String[]{'<LOGOIMG>','</LOGOIMG>','<ROOMFILTER>','</ROOMFILTER>'});
		    // 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
		    if (rootNode != null) {
		    	// 料理設定情報
			    Dom.XMLNode targetNode = rootNode.getChildElement('FOODSCHEDULE',null);
			    if (targetNode != null) {
			    	// 画面表示時間リスト設定
			    	Dom.XMLNode bussinessNode = targetNode.getChildElement('BUSSINESSTIME',null);
					// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
					Map<String,String> labelSetMap = new Map<String,String>();
					// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
			    	if (bussinessNode != null) {
				    	for (Dom.XMLNode bussTmNode : bussinessNode.getChildElements()) {
				    		// 表示料理ー＞時間ラベル
				    		Dom.XMLNode labelNode = bussTmNode.getChildElement('LABEL',null);
				    		// 表示料理ー＞開始時間
				    		Dom.XMLNode beginNode = bussTmNode.getChildElement('BEGIN',null);
				    		// 表示料理ー＞終了時間
				    		Dom.XMLNode endNode = bussTmNode.getChildElement('END',null);
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				    		Dom.XMLNode cookTimeNode = bussTmNode.getChildElement('COOKTIME',null);
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
				    		String label = '';
				    		String beginTm = '';
				    		String endTm = '';
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				    		String cookTm = '';
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
				    		if (labelNode != null) label = CommUtils.nullToBlank(labelNode.getText());
				    		if (beginNode != null) beginTm = CommUtils.nullToBlank(beginNode.getText());
				    		if (endNode != null) endTm = CommUtils.nullToBlank(endNode.getText());
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				    		// 該当料理開始時刻設定
				    		if(cookTimeNode != null) cookTm = CommUtils.nullToBlank(cookTimeNode.getText());
				    		// 料理開始時刻判定
				    		if (!CommUtils.isBlank(label) && !CommUtils.isBlank(beginTm) && !CommUtils.isBlank(endTm)){
				    			// 料理開始時刻あり
				    			if(!CommUtils.isBlank(cookTm)){
				    				// 無効時刻フィルター
					    			Date dt = system.today();
					    			Datetime begDt = CommUtils.convertDatetime(dt, beginTm);
					    			Datetime endDt = CommUtils.convertDatetime(dt, endTm);
					    			Datetime cookDt = CommUtils.convertDatetime(dt, cookTm);
					    			if(!(cookDt >= begDt && cookDt <= endDt)) cookTm = '';
				    			}
				    			String val = beginTm + '~' + endTm + '~' + cookTm;
				    			// 2018/10/31 料理進捗開始（OWNER) by cxw END
				    			businessLst.add(new SelectOption(val,label));
				    			if (!CommUtils.isBlank(decLabel) && decLabel == label) curType = val;
				    		}
							// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
							Dom.XMLNode roomSetNode = bussTmNode.getChildElement('COOKFIELD',null);
							if (roomSetNode != null) {
								labelSetMap.put(label + '_lead' , roomSetNode.getText());
							}
							// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
						}
						// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
					} else {
						Dom.XMLNode bussindessNode = targetNode.getChildElement('BUSSINESSFIELD',null);
						if (bussindessNode != null) {
							labelSetMap.put('_lead' , bussindessNode.getText());
						}
					}
					if (!labelSetMap.isEmpty()) cookRoomSetJson = JSON.serialize(labelSetMap);
					// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
			    	// カラー設定
			    	Dom.XMLNode colorNode = targetNode.getChildElement('COLORINFO',null);
			    	if (colorNode != null) {
						// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
						// 料理進捗奇数颜色
						String oddColor = CommUtils.nullToBlank(colorNode.getAttribute('ODD',null));
						// 料理進捗偶数颜色
						String evenColor = CommUtils.nullToBlank(colorNode.getAttribute('EVEN',null));
						if (!CommUtils.isBlank(oddColor)) color.odd = oddColor;
						if (!CommUtils.isBlank(evenColor)) color.even = evenColor;
						// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
			    		// カラー背景設定
			    		Dom.XMLNode cookNode = colorNode.getChildElement('COOKBG',null);
			    		Dom.XMLNode titleNode = colorNode.getChildElement('TITLEBG',null);
			    		Dom.XMLNode cookDoneNode = colorNode.getChildElement('COOKDONEBG',null);
			    		Dom.XMLNode cookDetailNode = colorNode.getChildElement('COOKDETAILBG',null);
						// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
						Dom.XMLNode statusLstNode = colorNode.getChildElement('COOKPROCBG',null);
						// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
			    		if (cookNode != null) {
			    			String cookBg = CommUtils.nullToBlank(cookNode.getText());
			    			if (!CommUtils.isBlank(cookBg)) color.cookBg = cookBg;
			    		}
			    		if (titleNode != null) {
			    			String titleBg = CommUtils.nullToBlank(titleNode.getText());
			    			if (!CommUtils.isBlank(titleBg)) color.titleBg = titleBg;
			    			// 字体カラー設定
			    			String textColor = titleNode.getAttribute('COLOR',null);
			    			if (!CommUtils.isBlank(textColor)) color.titleColor = textColor;
			    		}
						// 料理完了
			    		if (cookDoneNode != null) {
			    			String cookBg = CommUtils.nullToBlank(cookDoneNode.getText());
			    			if (!CommUtils.isBlank(cookBg)) color.cookDoneBg = cookBg;
			    			// 字体カラー設定
			    			String cookDoneColor = cookDoneNode.getAttribute('COLOR',null);
			    			if (!CommUtils.isBlank(cookDoneColor)) color.cookDoneColor = cookDoneColor;
							String label = cookDoneNode.getAttribute('LABEL',null);
							if (!CommUtils.isBlank(label)) statusLabelMap.put(COOKINFO_STATUS_VALUE_DONE,label);
							else statusLabelMap.put(COOKINFO_STATUS_VALUE_DONE,'完了');
			    		}
			    		if (cookDetailNode != null) {
			    			String cookBg = CommUtils.nullToBlank(cookDetailNode.getText());
			    			if (!CommUtils.isBlank(cookBg)) color.cookDetailBg = cookBg;
			    			// 字体カラー設定
			    			String cookDetailColor = cookDetailNode.getAttribute('COLOR',null);
			    			if (!CommUtils.isBlank(cookDetailColor)) color.cookDetailColor = cookDetailColor;
							String label = cookDetailNode.getAttribute('LABEL',null);
							if (!CommUtils.isBlank(label)) statusLabelMap.put('',label);
							else statusLabelMap.put('','未着手');
			    		}
						// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
						if (statusLstNode != null) {
							statusMap.put('',0);
							statusLst.add('');
							String status = statusLstNode.getAttribute('LABEL', null);
							if (CommUtils.isBlank(status)) status = 'processing';
							String color = statusLstNode.getText(); 
							statusColorMap.put(status,color);
							statusMap.put(status,statusLst.size());
							statusLst.add(status);
						}
						// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
			    	}
			    	// 料理時間設定
			    	Dom.XMLNode minuteInfoNode = targetNode.getChildElement('TIMEINFO',null);
			    	if (minuteInfoNode != null) {
			    		// 料理時刻設定
			    		Dom.XMLNode minteNode = minuteInfoNode.getChildElement('MINUTE',null);
			    		if (minteNode != null) {
			    			String minuteStr = CommUtils.nullToBlank(minteNode.getText());
			    			if (!CommUtils.isBlank(minuteStr)) COOKINFO_MUNITES = CommUtils.nullToZero(minuteStr);
			    		}
                        // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
                        // アラーム
                        Dom.XMLNode alarmNode = minuteInfoNode.getChildElement('ALARM',null);
                        if (alarmNode != null) {
                            String minuteStr = CommUtils.nullToBlank(alarmNode.getText());
                            if (!CommUtils.isBlank(minuteStr)) isEndFlag = Boolean.valueOf(minuteStr);
                        }
                        // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
			    	}
			    	Dom.XMLNode detailInfoNode = targetNode.getChildElement('COOKTEMPLATE',null);
			    	if (detailInfoNode != null) {
			    		// 料理時刻設定
		    			String detailTempStr = CommUtils.nullToBlank(detailInfoNode.getText());
		    			if (!CommUtils.isBlank(detailTempStr)) detailInfo = CommUtils.nullToBlank(detailTempStr);
			    	}
			    	// 2019/01/30 料理UI改善　by zy BEGIN
			    	Dom.XMLNode tabHeadShowNode = targetNode.getChildElement('TABHEADSHOW',null);
				    if (tabHeadShowNode != null) {
				    	String tabHead = CommUtils.nullToBlank(tabHeadShowNode.getText());
				    	padHeadShow = boolean.valueOf(tabHead);
				    }
			    	// 2019/01/30 料理UI改善　by zy END
					// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
					Dom.XMLNode sortNode = targetNode.getChildElement('ROOM_SORT',null);
                    if (sortNode != null) {
                        orderSort = CommUtils.nullToBlank(sortNode.getText());
                    }
					// 2019/09/15 部屋の並び順をSeq#順に by zy END
					// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
					String timeFlagStr = targetNode.getAttribute('NEWLAYOUT', null);
					if (!CommUTils.isBlank(timeFlagStr))
						timeFlag = boolean.valueOf(CommUtils.nullToBlank(timeFlagStr));
					// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					String orderEndFlgStr = targetNode.getAttribute('FINISHNOSHOW', null);
					if (!CommUTils.isBlank(orderEndFlgStr))
						isOrderEndFlg = boolean.valueOf(CommUtils.nullToBlank(orderEndFlgStr));
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
					// 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
					String timeAccFlagStr = targetNode.getAttribute('TIMESORT', null);
					if (!CommUTils.isBlank(timeAccFlagStr))
						accTimeFlag = boolean.valueOf(CommUtils.nullToBlank(timeAccFlagStr));
					String doneHideStr = targetNode.getAttribute('COOKDONEHIDE', null);
					if (!CommUTils.isBlank(doneHideStr)) cookDoneHideLen = Commutils.nullToIntZero(doneHideStr);
					// 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
			    }
			    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				// 厨房設定
			    Dom.XMLNode kitchensNode = rootNode.getChildElement('KITCHENS',null);
				kitchenOpts = new List<selectoption>();
				if (kitchensNode != null) {
					for (Dom.XMLNode kitchenNode : kitchensNode.getChildElements()) {
						String label = kitchenNode.getText();
						String ops = CommUtils.nullToBlank(kitchenNode.getAttribute('OPCODE',null));
						kitchenOpts.add(new SelectOption(ops,label));
					}
				}
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				String sameProdSum = CommUtils.nullToBlank(targetNode.getAttribute('PRODSUM',null));
				if (!CommUtils.isBlank(sameProdSum))
					isSameProductSumFlg = boolean.valueOf(sameProdSum);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		    }
			// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
			if (!statusMap.isEmpty()) {
				statusMap.put(COOKINFO_STATUS_VALUE_DONE,statusLst.size());
				statusLst.add(COOKINFO_STATUS_VALUE_DONE);
				// 未着手カラー
				statusColorMap.put('',color.cookDetailBg);
				// 完了カラー
				statusColorMap.put(COOKINFO_STATUS_VALUE_DONE,color.cookDoneBg);
				colorInfoJson = JSON.serialize(new map<String,Object>{
					'color' => statusColorMap,
					'status' => statusLst,
					'statusmap' => statusMap,
					'label' => statusLabelMap
				});
			}
			// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
			// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
			OrderServiceHelp.setInstance(branchShopNm);
			deslayoutOpts = OrderServiceHelp.getLayoutOpts(branchShopNm,true);
			// 2020/05/30 リリース後の検収再対応 by zy BEGIN
			kichenOrderOnly = OrderServiceHelp.getKitchenOrderOnlyFlg();
			// 2020/05/30 リリース後の検収再対応 by zy END
			// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy END
	    }catch(exception e) {
	    	system.debug(loggingLevel.info, 'EXCEPTION='+e.getStackTraceString());
	    }
    }
    // 該当時間指定タイプ
    private void getCurrentType(){
    	// 現在時刻
    	Datetime curDt = system.now();
    	// 今日
    	Date todayDt = system.today();
    	// 該当営業タイムリスト
    	for (SelectOption sec : businessLst) {
    		// 設定時刻値
    		String timeVal = sec.getValue();
    		List<String> timeArr = timeVal.split('~');
    		// 開始時刻
    		String startTm = timeArr[0];
    		// 終了時刻
    		String endTm = timeArr[1];
    		// 開始時間
    		Datetime startDt = commUtils.convertdatetime(todayDt,startTm);
    		// 終了時間
	    	Datetime endDt = commUtils.convertdatetime(todayDt,endTm);
	    	if (endDt < startDt) endDt = endDt.addDays(1);
	    	if (startDt <= curDt && curDt <= endDt) {
	    		// 該当範囲内モード設定
	    		curType = timeVal;
	    		break;
	    	}
	    }
    }
    // 画面内容処理
    private void doAction(){
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		setCookieInfo();
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
    	setModeLst();
    	// タイム頭部設定
    	setTimeHeader();
    }
    // 部屋タイプリスト
    private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
	// 2015/09/01 多店舗機能対応 BEGIN
		// List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        List<TypeOfRooms__c> roomTypeLstRs = new List<TypeOfRooms__c>();
        if (CommUtils.isBlank(branchShopNm) && userInf.isShopCodePlex) {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(userInf.shops);
        }else {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        }
	// 2015/09/01 多店舗機能対応 END
		for (TypeOfRooms__c r : roomTypeLstRs) {
    		roomTypeLst.add(new SelectOption(r.Id, r.Name));
		}
    }
    // 店舗リスト情報を取得する
  	private void setInitBranShopLst() {
  		// 店舗リスト情報を取得する
    	// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        // 2015/09/01 多店舗機能対応 END
        // 店舗コードの初期値設定を行う
        // URLから店舗コードを設定されているの場合、該当設定値は初期値として、設定する
        if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
        	branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        } else if (CommUtils.isBlank(branchShopNm)){
        // URLから店舗コードが未設定する場合、該当ユーザーに設定されている店舗コードで初期値設定
	        if (!branchShopLst.isEmpty()) {
	        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
	        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
	        	for (SelectOption s : branchShopLst) {
	        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
	        	}
	        	// 2018/08/02 チェックリストロール制御追加　by　zy　BEGIN
	        	//　デファルト店舗コード設定
	        	if (CommUtils.isBlank(branchShopNm)) branchShopNm = branchShopLst[0].getValue();
	        	// 2018/08/02 チェックリストロール制御追加　by　zy　END
	        }
        }
    }
    // モード内容初期化
    private void setModeLst(){
    	curMode = '1';
    	modeLst = new List<SelectOption> ();
    	// 営業整体一覧
    	if (CommUtils.isBlank(curType)){
    		modeLst.add(new SelectOption('1','1分'));
	    	modeLst.add(new SelectOption('5','5分'));
	    	modeLst.add(new SelectOption('10','10分'));
	    	modeLst.add(new SelectOption('15','15分'));
	    	modeLst.add(new SelectOption('30','30分'));
	    	modeLst.add(new SelectOption('60','60分'));
    	} else {
    		modeLst.add(new SelectOption('1','1分'));
	    	modeLst.add(new SelectOption('5','5分'));
	    	modeLst.add(new SelectOption('10','10分'));
	    	modeLst.add(new SelectOption('15','15分'));
	    	modeLst.add(new SelectOption('30','30分'));
	    	modeLst.add(new SelectOption('60','60分'));
    	}
    	// 該当モード設定
    	changeMode();
    }
    // 該当モード設定
    private void changeMode(){
    	// 間隔left
    	leftDiff = 10;
    	if (curMode == '1') {
    		modInt = 30;
    		// 間隔時刻
    		minuteDiff = 1;
    	} else if (curMode == '5') {
    		modInt = 6;
    		// 間隔時刻
    		minuteDiff = 5;
    	} else if (curMode == '10') {
    		modInt = 3;
    		// 間隔時刻
    		minuteDiff = 10;
    		// 間隔left
    		leftDiff = 50;
    	} else if (curMode == '15') {
    		modInt = 2;
    		// 間隔時刻
    		minuteDiff = 15;
    		// 間隔left
    		leftDiff = 50;
    	} else if (curMode == '30') {
    		modInt = 2;
    		// 間隔時刻
    		minuteDiff = 30;
    		// 間隔left
    		leftDiff = 50;
    	} else if (curMode == '60') {
    		modInt = 1;
    		// 間隔時刻
    		minuteDiff = 60;
    		// 間隔left
    		leftDiff = 100;
    	}
    }
    
    // タイム頭部設定
    private void setTimeHeader(){
    	// 営業開始時刻
    	String startTm = '09:00';
    	// 営業終了時刻
    	String endTm = '18:00';
    	if (CommUtils.isBlank(curType)) {
    		startTm = '00:00';
    		endTm = '24:00';
    	} else {
    		List<String> timeArr = curType.split('~');
    		startTm = timeArr[0];
    		endTm = timeArr[1];
    	}
    	// 今日
    	Date todayDt = system.today();
    	Datetime startDt = commUtils.convertdatetime(todayDt,startTm);
    	Datetime endDt = commUtils.convertdatetime(todayDt,endTm);
    	if (endDt < startDt) endDt = endDt.addDays(1);
    	timeLsts = new List<List<TimeInfo>>();
    	Integer timeLeftInt = 0;
    	begTmLong = startDt.getTime();
    	// タイムラン作成する
    	while(startDt <= endDt){
    		if (LIMIT_TIME_SYNC == startDt.getTime()) break;
    		TimeInfo tm = new TimeInfo(startDt,timeLeftInt*leftDiff); 
    		// 表示フラグ
    		if (Math.mod(timeLeftInt,modInt) == 0) {
    			// 最大限時刻
    			timeLsts.add(new List<TimeInfo>());
    			tm.showFlag = true;
    		}
    		integer lastSize = timeLsts.size() - 1;
    		// 最大限時刻
    		timeLsts[lastSize].add(tm);
    		startDt = startDt.addMinutes(minuteDiff);
    		timeLeftInt++;
    	}
    	endTmLong = startDt.getTime();
    	lastLeftInt = (timeLeftInt - 1)*leftDiff;
    	curShopName = '';
        try{
        	curShopName = ShopInfoUtil.getShop(branchShopNm).name;
        }catch(exception e) {
        	
        }
    }
    @remoteaction
    public static object cookRemoteData(String proType,String reqInfo){
    	// 料理データ取得
    	if (proType == 'queryCookData') return queryCookData(reqInfo);
    	// 料理進捗状態「完了」更新です
    	else if (proType == 'cookDoneData') return cookDoneData(reqInfo);
    	// 料理進捗状態「開始時刻」更新です
    	else if (proType == 'cookTimeData') return cookTimeData(reqInfo);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN	
		else if (proType == 'cookChgData') return cookChgData(reqInfo);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		else if (proType == 'leadCookDone') return leadCookDone(reqInfo);
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
    	return null;
    }	
    // 料理データ取得
    private static List<Object> queryCookData(String reqInfo){
		Date todayDt = system.today();
    	Request req = (Request)JSON.deserialize(reqInfo,Request.class);
    	String spcd = req.spcd;
    	String minute = req.minute;
    	String busType = req.busType;
    	COOKINFO_MUNITES = CommUtils.nullToZero(minute);
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	Date gotoDate = CommUtils.stringToDate(req.gotoDate);
    	if(gotoDate != null) todayDt = gotoDate;
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN	
		Map<String,String> roomInfo = req.roominfo;
		if (roomInfo != null && !roomInfo.isEmpty()) {
			customRoomSeqMap = roomInfo;
		}
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
		pRequest = req;
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
		if (req.doneflg != null || req.isHorlayout != null) {
			// ユーザーの情報取得
			String cookInfo = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.INFO.name(),spcd,false);
			Request cookieReq = new Request();
			Map<String,object> objMap = new Map<String,object>();
			if (!CommUtils.isBlank(cookInfo)) cookieReq = (Request)JSON.deserialize(cookInfo,Request.class);
			if (req.doneflg != null) cookieReq.doneflg = req.doneflg;
			if (req.isHorlayout != null) cookieReq.isHorlayout = req.isHorlayout;
			// COOKIE 設定
			if (cookieReq.doneflg != null) objMap.put('doneflg',cookieReq.doneflg);
			if (cookieReq.isHorlayout != null) objMap.put('isHorlayout',cookieReq.isHorlayout);
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy end
			// Cookieからレイアウトモードを取得する
			saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.INFO.name(),spcd,JSON.serialize(objMap));
		}
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		return getItemByLeadId(new List<Id>(),spcd,todayDt,busType);
    }
    // 今日の料理取得
    private static List<Object> getItemByLeadId(List<Id> leadLst,String spcd,Date todayDt,String curType){
		K_ScheduleCookingHelper bat = new K_ScheduleCookingHelper(todayDt,spcd);
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
		if (customRoomSeqMap != null && !customRoomSeqMap.isEmpty()) bat.otherLeadFields = new Set<String>(customRoomSeqMap.values());
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN		
		if (pRequest != null) {
			Map<String,Object> otherInfoMap = new Map<String,Object>();
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			if (!CommUtils.isBlank(pRequest.ops))
				otherInfoMap.put('ops',CommUtils.nullToBlank(pRequest.ops).split(','));
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
			otherInfoMap.put('types',pRequest.roomtype);
			otherInfoMap.put('layoutid',pRequest.layoutid);
			bat.otherSettingMap = otherInfoMap;
		}
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END
    	Map<String,String> prodToPosMap = new Map<String,String>();
    	OrderServiceHelp.setInstance(spcd);
		// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　BEGIN
		// 2020/05/30 リリース後の検収再対応 by zy BEGIN
		// boolean kichenOrderOnly = pRequest != null && pRequest.cookflg == true && OrderServiceHelp.getKitchenOrderOnlyFlg();
		// 2020/05/30 リリース後の検収再対応 by zy END
		// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　END
    	Set<String> cookProdSet = OrderServiceHelp.getCookProds();
    	// 予約明細情報を格納
    	List<K_ScheduleCookingHelper.ReportRow> repLst = bat.queryCookItem(leadLst,prodToPosMap,cookProdSet);
    	// 会席のBreakdowns情報を取得する　
    	Set<Id> productIdSet = new Set<Id>();
    	List<CookDetail> items = new List<CookDetail>();
    	// 既存料理情報
    	Map<String,CookInfo> exitCookStatusMap = new Map<String,CookInfo>();
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	ParseBusType pbt = new ParseBusType(spcd, curType);
    	for (K_ScheduleCookingHelper.ReportRow rep : repLst) {
    		if (rep.rows.isEmpty()) continue;
    		// 料理開始時刻
			Datetime begTm = null;
            // 会席情報を取得する
            for (K_ScheduleCookingHelper.ReportDetail row : rep.rows) {
            	String cookInfo = CommUtils.nullToBlank(row.cookInfo).unescapeHtml4();
				if (!CommUtils.isBlank(cookInfo)) {
			    	List<CookInfo> cookinfos = (List<CookInfo>)JSON.deserialize(cookInfo,List<CookInfo>.class);
			    	if (!cookinfos.isEmpty()) {
				    	for (CookInfo cook : cookinfos) {
				    		String cookId = CommUtils.nullToBlank(cook.cookid);
				    		String key = row.objectid + '_' + cookId;
							// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
							// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
							// if ((pRequest != null && pRequest.sumflg != null && !pRequest.sumflg) &&
							if(!CommUtils.isBlank(cook.oid)) key += '_' + Commutils.nullToBlank(cook.oid);
							// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
							// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
				    		exitCookStatusMap.put(key,cook);
				    		
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				    		// 最早料理時刻取得
				    		if (!CommUtils.isBlank(cook.begTm)){
				    			Datetime curDt = CommUtils.convertDatetime(todayDt,cook.begTm);
								if (begTm == null || begTm > curDt) begTm = curDt;
				    		}
				    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
				    	}
			    	}
		    	}
            }
	    	// 料理時刻あり
	    	if (begTm != null) rep.orderTime = begTm.format('HH:mm');
	    	// 料理開始なし
			// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
	     	else {
				if (rep.leadOtherMap != null && !rep.leadOtherMap.isEmpty()) {
					rep.orderTime = pbt.compare(rep.orderTime,rep.leadOtherMap,customRoomSeqMap);
				} else 
					rep.orderTime = pbt.compare(rep.orderTime);
			}
			// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
    	}
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		Set<String> leadIdSet = new Set<String>();
		Map<String,String> tranProdMap = new Map<String,String>();
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		Map<String,Integer> roomSeqMap = new Map<String,Integer>();
        // 出力順番情報をJSON設定する
        for (K_ScheduleCookingHelper.ReportRow rep : repLst) {
        	if (rep.rows.isEmpty()) continue;
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			leadIdSet.add(rep.leadId);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
            // 会席情報を取得する
            for (K_ScheduleCookingHelper.ReportDetail row : rep.rows) {
                productIdSet.add(row.productId);
                CookDetail detail = new CookDetail();
				detail.qty = row.qty;
				detail.allergie = rep.allergie;
				detail.leadid = rep.leadId;
				detail.roomName = rep.roomName;
				detail.objectid = row.objectid;
				detail.contactName = rep.contactName;
				detail.orderTime = rep.orderTime;
				detail.productId = row.productId;
				detail.productName = row.productName;
				detail.cookInfo = CommUtils.nullToBlank(row.cookInfo).unescapeHtml4();
				// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
				detail.roomId = rep.roomId;
				// 2019/09/15 部屋の並び順をSeq#順に by zy END
				// 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
				detail.acctm = Commutils.nullToBlank(row.accTime);
				// 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
				// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				/*
				if (!CommUtils.isBlank(detail.cookInfo)) {
			    	List<CookInfo> cookinfos = (List<CookInfo>)JSON.deserialize(detail.cookInfo,List<CookInfo>.class);
			    	if (!cookinfos.isEmpty()) {
				    	for (CookInfo cook : cookinfos) {
				    		String cookId = CommUtils.nullToBlank(cook.cookid);
				    		String key = detail.objectid + '_' + cookId;
				    		exitCookStatusMap.put(key,cook);
				    	}
			    	}
		    	}*/
		    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		    	items.add(detail);
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				tranProdMap.put(detail.objectid,detail.productId);
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
            }
        }
        Map<Id, List<FoodDetail__c>> foodDetailMap = new Map<Id, List<FoodDetail__c>>();
        Map<String,List<CookDetail>> timeCooDetailMap = new Map<String,List<CookDetail>>();
        // 料理要時
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
        accMinutesMap = new Map<String,decimal>();
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
        if (!productIdSet.isEmpty()) {
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			// 会席料理OPフィルター
        	foodDetailMap = OrderServiceHelp.getKaisakiDetailMap(productIdSet,bat.cookOpIdSet);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
        	for (AccountMaster__c acc : [select id,CookTime__c from AccountMaster__c where id=:productIdSet]) {
        		if (acc.CookTime__c != null) accMinutesMap.put(acc.id,acc.CookTime__c);
        	}
        }
        List<CookDetail> lastCookDetails = new List<CookDetail>();
		// 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
		// 2020/05/30 bug fix 6444 by zy BEGIN
		/*
		Datetime curDateTm = system.now();
		用来比较当前料理时间是否超过系统时间，但是未来日的case出现+24小时以上的问题，
		所以改成指定日+当前系统时间进行处理，这样对比时间的逻辑也可以正常使用
		*/
		Datetime curDateTm = Datetime.newInstance(todayDt,system.now().time());
		// 2020/05/30 bug fix 6444 by zy END
        // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		// 会計明細下料理「数量」「備考」取得
		// 2020/11/30 9253 bug fixed by zy BEGIN
		// NEWLAYOUT下用的集合,针对Orderentry商品合并进行处理
		// (pRequest.sumflg == null) 料理进步页面没传这个值 所以作为跟料理list页面区分
		Map<String,Map<String,Map<String,CookDetail>>> transDetailMap = getTransDetail(tranProdMap,foodDetailMap,todayDt,leadIdSet) ;
		// 2020/11/30 9253 bug fixed by zy BEGIN
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
        for (CookDetail item : items) {
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			commInfo = new CommonInfo();
			commInfo.todayDt = todayDt;
        	// 開始時刻
			commInfo.curDt = CommUtils.convertDatetime(todayDt,item.orderTime);
			commInfo.begTm = commInfo.curDt;
			commInfo.orgType = null;
			commInfo.curDateTm = curDateTm;
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			commInfo.sumflg = (pRequest != null && pRequest.sumflg != null && pRequest.sumflg) ;
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
			String tranId = item.objectid;
			if (transDetailMap.containsKey(tranId)){
				// 会席明細
				List<FoodDetail__c> foodDts = foodDetailMap.get(item.productId);
				List<CookDetail> details = processTransAndCookInfos(transDetailMap.get(tranId),exitCookStatusMap,item,foodDts);
				lastCookDetails.addAll(details);
			// 2020/05/30 リリース後の検収再対応 by zy BEGIN
			// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　BEGIN
			} else {
			// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　END
			// 2020/05/30 リリース後の検収再対応 by zy END
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				/*
				// 開始時刻
				Datetime curDt = CommUtils.convertDatetime(todayDt,item.orderTime);
				Datetime begTm = curDt;
				*/
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
        	// 料理進捗
			if (foodDetailMap.containsKey(item.productId)) {
				List<FoodDetail__c> foodDts = foodDetailMap.get(item.productId);
				String orgType = null;
				for (FoodDetail__c d : foodDts) {
					String key = item.objectid + '_' + d.id;
					CookInfo cook = exitCookStatusMap.get(key);
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
					CookDetail foodDetail = convertCookDetail(item,cook,d);
					/*
					CookDetail foodDetail = item.createFoodDetail(d,cook);
					if (cook != null && !CommUtils.isBlank(cook.begTm)){
		    			curDt = CommUtils.convertDatetime(todayDt,cook.begTm);
		    			orgType = d.BreakName__c;
		    			foodDetail.noSetTm = false;
		    		} else if (orgType != d.BreakName__c){
		    			Integer seconds = CommUtils.nullToIntZero(CommUtils.nullToZero(foodDetail.minutes) * 60);
		    			if (orgType != null) curDt = curDt.addSeconds(seconds);
		    			orgType = d.BreakName__c;
		    		}
		    		// 2018/11/06 24時以後書式バグ対応 by zy BEGIN
		    		//String begTmStr = curDt.format('HH:mm');
                    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
                    //String begTmStr = CommUtils.convertHourKm(curDt,todayDt);
                    String begTmStr = CommUtils.convertHourKm(curDt,curDateTm);
                    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
		    		// 2018/11/06 24時以後書式バグ対応 by zy END
		    		foodDetail.begTm = begTmStr;
		    		Integer seconds = CommUtils.nullToIntZero(CommUtils.nullToZero(foodDetail.minutes) * 60);
		    		// 2018/11/06 24時以後書式バグ対応 by zy BEGIN
		    		//foodDetail.endTm = curDt.addSeconds(seconds).format('HH:mm');
                    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
		    		//foodDetail.endTm = CommUtils.convertHourKm(curDt.addSeconds(seconds),todayDt);
                    foodDetail.endTm = CommUtils.convertHourKm(curDt.addSeconds(seconds),curDateTm);
                    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
		    		// 2018/11/06 24時以後書式バグ対応 by zy END
		    		if (begTm > curDt) begTm = curDt;
		    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
		    		// if (!timeCooDetailMap.containsKey(begTmStr)) timeCooDetailMap.put(begTmStr,new List<CookDetail>());
		    		//timeCooDetailMap.get(begTmStr).add(foodDetail);
					// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
					foodDetail.roomId = item.roomId;
					// 2019/09/15 部屋の並び順をSeq#順に by zy END
					*/
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		    		lastCookDetails.add(foodDetail);
		    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
				}
			} else {
				String key = item.objectid + '_';
				CookInfo cook = exitCookStatusMap.get(key);
				if (cook != null && !CommUtils.isBlank(cook.begTm)){
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
					commInfo.curDt = CommUtils.convertDatetime(todayDt,cook.begTm);
					// curDt = CommUtils.convertDatetime(todayDt,cook.begTm);
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	    		}
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				CookDetail detail = convertCookDetail(item,cook,null);
					/*
	    		CookDetail detail = item.createFoodDetail(cook);
	    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
	    		detail.itemId = item.productId;
	    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
	    		if (accMinutesMap.containsKey(item.productId)) detail.minutes = CommUtils.nullToZero(accMinutesMap.get(item.productId));
	    		// 2018/11/06 24時以後書式バグ対応 by zy BEGIN
	    		//String begTmStr = curDt.format('HH:mm');
                // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
                //String begTmStr = CommUtils.convertHourKm(curDt,todayDt);
                String begTmStr = CommUtils.convertHourKm(curDt,curDateTm);
                // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
	    		// 2018/11/06 24時以後書式バグ対応 by zy END
	    		Integer seconds = CommUtils.nullToIntZero(CommUtils.nullToZero(detail.minutes) * 60);
				detail.begTm = begTmStr;
				// 2018/11/06 24時以後書式バグ対応 by zy BEGIN
		    	//detail.endTm = curDt.addSeconds(seconds).format('HH:mm');
                // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
                //detail.endTm = CommUtils.convertHourKm(curDt.addSeconds(seconds),todayDt);
                detail.endTm = CommUtils.convertHourKm(curDt.addSeconds(seconds),curDateTm);
                // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
		    	// 2018/11/06 24時以後書式バグ対応 by zy END
				// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
				//if (!timeCooDetailMap.containsKey(begTmStr)) timeCooDetailMap.put(begTmStr,new List<CookDetail>());
		    	//timeCooDetailMap.get(begTmStr).add(detail);
				// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
				detail.roomId = item.roomId;
				// 2019/09/15 部屋の並び順をSeq#順に by zy END
					*/
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		    	lastCookDetails.add(detail);
		    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
				}
			}
        }
        // 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
        /*
       	List<String> timLst = new List<String>(timeCooDetailMap.keySet());
       	timLst.sort();
       	for (String tm : timLst) {
       		List<CookDetail> details = timeCooDetailMap.get(tm);
       		lastCookDetails.addAll(details);
       	}*/
       	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		return lastCookDetails;
    }
    // 料理進捗状態「完了」更新です
    private static Object cookDoneData(String reqInfo){
    	Request req = (Request) JSON.deserialize(reqInfo,Request.class);
    	String orderId = req.orderid;
    	String cookId = req.cookid;
    	boolean doneFlag = req.done;
    	String spcd = req.spcd;
    	String curType = req.busType;
    	String minute = req.minute;
    	COOKINFO_MUNITES = CommUtils.nullToZero(minute);
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
		Set<String> orderIdSet = new Set<String>();
		if(req.orderids != null) orderIdSet = new Set<String>(req.orderids);
    	String prodId = req.prodId;
		integer cnt = req.cnt;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		String[] oids = req.oids;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	Date queryDt = CommUtils.stringToDate(req.gotoDate) == null ? system.today() : CommUtils.stringToDate(req.gotoDate);
    	// 2018/11/07 チェックインの場合字段エラー修正　by zy BEGIN
    	// 注文状態チェック
    	//String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	//boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	// 2018/11/07 チェックインの場合字段エラー修正　by zy END
    	//Sobject curObj = getSobjectById(orderId);
    	List<Sobject> curObjs = getSobjectByIds(orderIdSet);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    	List<CookInfo> exitCooks = createCookInfo(null,cookId,new Set<String>(oids));
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	//if (curObj != null) {
    	if (!curObjs.isEmpty()) {
    		for (Sobject curObj : curObjs) {
	    		String cookInfo = CommUtils.nullToBlank(curObj.get('CookInfo__c')).unescapeHtml4();
	    		// 2018/11/07 チェックインの場合字段エラー修正　by zy BEGIN
	    		// 注文状態チェック
	    		String curObjId = CommUtils.nullToBlank(curObj.get('id'));
		    	// 予約見積の場合
		    	boolean isEstFlag = getSobjectTypeById(curObjId) == ORDER_TYPE_BOOKINGEST;
		    	// 2018/11/07 チェックインの場合字段エラー修正　by zy END
    			// 該当注文会計商品ID
    			String curAccId = isEstFlag ? CommUtils.nullToBlank(curObj.get('refAccountMaster__c')) : CommUtils.nullToBlank(curObj.get('Field7__c'));
	    		List<CookInfo> cookInfos = new List<CookInfo>();
	    		// 料理状態のなし
	    		// 料理内容作成
	    		// if (CommUtils.isBlank(cookInfo)) cookInfos = createCookInfo(orderId,cookId);
	    		if (CommUtils.isBlank(cookInfo)){
	    			// 会席の場合
	    			if (prodId != curAccId) cookInfos = exitCooks.clone();
	    		}
	    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
	    		// 既存内容作成
	    		else {
	    			// 既存料理内容取得
	    			cookInfos = (List<CookInfo>)JSON.deserialize(cookInfo,List<CookInfo>.class);
	    			// 会席料理の場合
	    			if (!CommUtils.isBlank(cookId))
	    				// 既存料理内容更新
	    				cookInfos = filterCookinfo(cookId,cookInfos,exitCooks.clone());
	    		}
	    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
	    		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
				// String done = doneFlag ? COOKINFO_STATUS_VALUE_DONE : '';
				String done = req.status;
				// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
	    		// 料理内容更新
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				Map<String,String> changeMap = new Map<String,String>{COOKINFO_PROPTY_STATUS=>done};
	    		cookInfo = changeCookInfo(cookInfos,cookId,COOKINFO_PROPTY_STATUS,done,new Set<String>(oids));
				cookInfo = changeCookInfo(cookInfos,cookId,COOKINFO_PROPTY_CNT,'',new Set<String>(oids));
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	    		curObj.put('CookInfo__c',CommUtils.nullToBlank(cookInfo));
    		}
    		update curObjs;
    	}
    	//return getOrderInfo(orderId,spcd,curType);
    	return getItemByLeadId(new List<Id>(),spcd,queryDt,curType);
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
    }
    // 料理進捗状態「開始時刻」更新です
   	private static Object cookTimeData(String reqInfo){
   		Request req = (Request) JSON.deserialize(reqInfo,Request.class);
    	String orderId = req.orderid;
    	String cookId = req.cookid;
    	String begTm = req.begTm;
    	String spcd = req.spcd;
    	String busType = req.busType;
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	String minute = req.minute; 
    	String orderSQL = isEstFlag ? bookingEstQuery : tran1Query;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		// 2020/11/30 9344 bug fixed by zy BEGIN
		Set<String> orderSet = new Set<String>{''};
		// 2020/11/30 9344 bug fixed by zy END
		if (req.oids != null) orderSet = new Set<String>(req.oids);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	COOKINFO_MUNITES = CommUtils.nullToZero(minute);
    	orderSQL += ' where id=:orderId';
		List<Sobject> sobjects = Database.query(orderSQL);
    	if (!sobjects.isEmpty()) {
    		Sobject obj = sobjects[0];
    		String cookInfo = CommUtils.nullToBlank(obj.get('CookInfo__c')).unescapeHtml4();
    		List<CookInfo> cookInfos = new List<CookInfo>();
    		// 料理状態のなし
    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
    		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			List<CookInfo> exitCooks = createCookInfo(orderId,cookId,orderSet);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    		// 料理内容作成
    		//if (CommUtils.isBlank(cookInfo)) cookInfos = createCookInfo(orderId,cookId);
    		if (CommUtils.isBlank(cookInfo)) cookInfos = exitCooks;
    		// 既存内容作成
    		else { 
    			cookInfos = (List<CookInfo>)JSON.deserialize(cookInfo,List<CookInfo>.class);
    			// 既存料理内容更新
	    		cookInfos = filterCookinfo(cookId,cookInfos,exitCooks);
    		}
    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
    		// 料理内容更新
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    		cookInfo = changeCookInfo(cookInfos,cookId,COOKINFO_PROPTY_BEGTM,begTm,orderSet);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
			obj.put('CookInfo__c',CommUtils.nullToBlank(cookInfo));
    		update obj;
    	}
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	Date queryDt = CommUtils.stringToDate(req.gotoDate) == null ? system.today() : CommUtils.stringToDate(req.gotoDate);
    	//return getOrderInfo(orderId,spcd,busType);
    	return getItemByLeadId(new List<Id>{orderId},spcd,queryDt,busType);
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
   	}
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	private static object cookChgData(String reqInfo){
		Request req = (Request) JSON.deserialize(reqInfo,Request.class);
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		if (req.sumflg == true) return sumCookCHgData(req);
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		String orderId = req.orderid;
    	String cookId = req.cookid;
    	String begTm = req.begTm;
    	String spcd = req.spcd;
    	String busType = req.busType;
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	String orderSQL = isEstFlag ? bookingEstQuery : tran1Query;
		String minute = req.minute;
		COOKINFO_MUNITES = CommUtils.nullToZero(minute);
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
		pRequest = req;
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		Set<String> orderSet = new Set<String>();
		Map<String,String> orderMap = new Map<String,String>();
		Map<String,String> orderStatusMap = new Map<String,String>();
		if (req.oids != null) {
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			String splitTxt = '&&';
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
			for (String orderMsg : req.oids) {
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				String[] orderArr = orderMsg.split(splitTxt);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
				if (!CommUtils.isBlank(orderMsg) && orderArr.size() == 0) {
					orderMap.put('','');
					continue;
				}
				orderSet.add(orderArr[0]);
				if (orderArr.size() > 1) orderMap.put(orderArr[0],orderArr[1]);
				if (orderArr.size() > 2) orderStatusMap.put(orderArr[0],orderArr[2]);
			}
		}
		// if (req.oids != null) orderSet = new Set<String>(req.oids);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		String statusName = req.name;
		// String statusValue = req.value;
			orderSQL += ' where id=:orderId';
		List<Sobject> sobjects = Database.query(orderSQL);
    	if (!sobjects.isEmpty()) {
    		Sobject obj = sobjects[0];
    		String cookInfo = CommUtils.nullToBlank(obj.get('CookInfo__c')).unescapeHtml4();
    		List<CookInfo> cookInfos = new List<CookInfo>();
    		// 料理状態のなし
    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
    		
    		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			List<CookInfo> exitCooks = createCookInfo(orderId,cookId,orderSet);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    		// 料理内容作成
    		//if (CommUtils.isBlank(cookInfo)) cookInfos = createCookInfo(orderId,cookId);
			if (CommUtils.isBlank(cookInfo)) cookInfos = exitCooks;
    		// 既存内容作成
    		else { 
    			cookInfos = (List<CookInfo>)JSON.deserialize(cookInfo,List<CookInfo>.class);
    			// 既存料理内容更新
    			cookInfos = filterCookinfo(cookId,cookInfos,exitCooks);
    		}
    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
    		// 料理内容更新
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    			for (String oid : orderMap.keySet()) {
    				cookInfo = changeCookInfo(cookInfos,cookId,statusName,orderMap.get(oid),new Set<String>{oid});
					if (orderStatusMap.containsKey(oid))
						cookInfo = changeCookInfo(cookInfos,cookId,COOKINFO_PROPTY_STATUS,orderStatusMap.get(oid),new Set<String>{oid});
				}
    		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
			obj.put('CookInfo__c',CommUtils.nullToBlank(cookInfo));
    		update obj;
    	}
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	Date queryDt = CommUtils.stringToDate(req.gotoDate) == null ? system.today() : CommUtils.stringToDate(req.gotoDate);
    	return getItemByLeadId(new List<Id>{orderId},spcd,queryDt,busType);
   	}
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
	private static object leadCookDone(String reqInfo){
		Request req = (Request) JSON.deserialize(reqInfo,Request.class);
		Set<String> leadSet = new Set<String>();
		Set<String> leadIds = new SEt<String>(req.orderIds);
		if (leadIds != null && !leadIds.isEmpty()) {
			List<OrderEntryInfo__c> orders = new List<OrderEntryInfo__c>();
			for (OrderEntryInfo__c order : [select id,CookDoneFlg__c,leadref__c from OrderEntryInfo__c where leadref__c =:leadIds and orderStatus__c = :OrderserviceHelp.ORDER_STATUS_ACCOUNT_ING]) {
				leadIds.remove(order.leadref__c);
				if (order.CookDoneFlg__c) continue;
				order.CookDoneFlg__c = true;
				leadSet.add(order.leadref__c);
				orders.add(order);
			}
			if (!orders.isEmpty()) {
				update orders;
			}
			if (!leadIds.isEmpty()) {
				List<OrderEntryInfo__c> orderLst = new List<OrderEntryInfo__c>();
				Map<String,Lead__c> leadMap = new Map<String,Lead__c>([select id,rroom__c from lead__c where id = :leadIds]);
				Date queryDt = CommUtils.stringToDate(req.gotoDate) == null ? system.today() : CommUtils.stringToDate(req.gotoDate);
				for (String leadId : leadIds) {
					OrderEntryInfo__c orderInfo = new OrderEntryInfo__c(OrderStatus__c = OrderserviceHelp.ORDER_STATUS_ACCOUNT_ING, 
												RoomRef__c = leadMap.get(leadId).rroom__c,
												SearchDate__c = queryDt, LeadRef__c = leadId,CookDoneFlg__c=true);
					orderLst.add(orderInfo);
				}
				if (!orderLst.isEmpty()) insert orderLst;
			}
		}
		return leadSet; 
	}
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
	/*
   	// 注文情報取得
    private static Object getOrderInfo(String orderId,String spcd,String curType){
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	List<Id> leadIdLst = new List<Id>();
    	// 今日
    	Date todayDt = system.today();
    	if (isEstFlag) {
    		List<BookingEstimateItem__c> bookEsts = [select id,refBooking__c from BookingEstimateItem__c where id =:orderId];
    		if (!bookEsts.isEmpty()) leadIdLst.add(bookEsts[0].refBooking__c);
    	} else {
    		List<Tran1__c> tran1s = [select id,Field1__r.Relreserve__c from Tran1__c where id =:orderId];
    		if (!tran1s.isEmpty()) leadIdLst.add(tran1s[0].Field1__r.Relreserve__c);
    	}
    	return getItemByLeadId(leadIdLst,spcd,todayDt,curType);	
    }*/
    // 注文取得
    private static Sobject getSobjectById(String orderId){
    	Sobject curObj = null;
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	String orderSQL = isEstFlag ? bookingEstQuery : tran1Query;
    	orderSQL += ' where id=:orderId';
    	List<Sobject> sobjects = Database.query(orderSQL);
    	if (!sobjects.isEmpty()) curObj = sobjects[0];
    	return curObj;
    }
    // 注文ID区分
    private static String getSobjectTypeById(String orderId){
		// ID前三位
		String prefix = orderId.subString(0,3);
		// 見積の場合
		if (BookingEstimateItem__c.sObjectType.getDescribe().getKeyPrefix() == prefix) return ORDER_TYPE_BOOKINGEST;
		else return ORDER_TYPE_TRAN1;
    }
    // 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    // 料理進捗内容作成
    public static List<CookInfo> createCookInfo(String orderId,String cookId,Set<String> orderSet){
    	List<CookInfo> cooks = new List<CookInfo>();
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	if (!CommUtils.isBlank(cookId)) {
    		List<FoodDetail__c> details = [select id,name,AccountMasterRef__c From FoodDetail__c where id=:cookId];
    		if (!details.isEmpty()) {
    			FoodDetail__c food = details[0];
    			List<FoodDetail__c> foodDetails = [select id,name from FoodDetail__c where AccountMasterRef__c = :food.AccountMasterRef__c order by OrderNo__c];
    			// 該当会計商品の料理ブレイクありの場合
		    	if (!foodDetails.isEmpty()) {
					// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
					List<CookInfo> detailCooks = new List<CookInfo>();
					for (FoodDetail__c f : foodDetails) {
						CookInfo info = new CookInfo();
						info.cookid = f.id;
						detailCooks.add(info);
					}
					// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
					// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
					if (!orderSet.isEmpty() && !orderSet.contains(orderid)) {
					// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
						for ( String oid : orderSet) {	
							for (FoodDetail__c f : foodDetails) {
								CookInfo info = new CookInfo();
								info.cookid = f.id;
								info.oid = oid;
								cooks.add(info);
							}
						}
					}
					// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END	
					// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
					else cooks = detailCooks;
					// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
		    	}
    		}
    	} else {
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			if (!orderSet.isEmpty()) {
				for ( String oid : orderSet) {	
    				CookInfo info = new CookInfo();
					info.cookid = cookId;
					info.oid = oid;
					cooks.add(info);
				}
			}
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
			else {
				CookInfo info = new CookInfo();
				info.cookid = cookId;
				cooks.add(info);
			}
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	}
    	return cooks;
    }
    // 料理進捗指定内容と指定値変更
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	public static String changeCookInfo(List<CookInfo> cookInfos,String cookId,String propertyName,String propertyVal,Set<String> oidSet){
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	boolean hadChanged = false;
    	// 2020/11/30 9368 bug fixed by zy BEGIN
		if (COOK_STATUS_BLANK == propertyVal && propertyName != COOKINFO_PROPTY_DSC) propertyVal = '';
		// 2020/11/30 9368 bug fixed by zy END
    	if (!cookInfos.isEmpty()) {
    		if (!CommUtils.isBlank(cookId)) {
    			boolean timeChgFlag = false;
    			for (CookInfo info : cookInfos) {
		    		// 料理ブレイクありの場合
		    		if (info.cookId == cookId) {
						// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
						if (oidSet.isEmpty() || (!oidSet.isEmpty() && !oidSet.contains(info.oid))) continue;
						// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
						hadChanged = true;
						// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
						oidSet.remove(info.oid);
						// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		    			info = changePropery(info,propertyName,propertyVal);
		    			timeChgFlag = propertyName == COOKINFO_PROPTY_BEGTM;
		    			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
						// if (!timeChgFlag) break;
		    			if (timeChgFlag) continue;
						// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		    		// 会計商品の場合
		    		}
		    		// 時刻変更の場合該当料理後明細時間クリン
		    		if (timeChgFlag) {
		    			if (COOKINFO_PROPTY_STATUS != COOKINFO_STATUS_VALUE_DONE)
		    				info = changePropery(info,propertyName,'');
		    		}
		    	}
    		} else {
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				for (CookInfo info : cookInfos) {
					// 2020/08/31 7368 bug fixed by zy BEGIN
					if (oidSet.isEmpty() || (!oidSet.isEmpty() && !oidSet.contains(info.oid))) continue;
					// 2020/08/31 7368 bug fixed by zy END
					info = changePropery(info,propertyName,propertyVal);
					oidSet.remove(info.oid);
				}
				if (!oidSet.isEmpty()) {
					for (String oid : oidSet) {
						CookInfo info = new CookInfo();
						info.oid = oid;
						info = changePropery(info,propertyName,propertyVal);
						cookInfos.add(info);
					}
				}
				hadChanged = true;
    			//CookInfo info = cookInfos[0];
    			// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    			//hadChanged = true;
    			// 2018/10/31 料理進捗開始（OWNER) by cxw END
    			//info = changePropery(info,propertyName,propertyVal);
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    		}
	    	
    	}
    	// 特殊の場合
    	// 該当料理ブレイク、会計商品、既存の情報不存在の場合
    	if (!hadChanged) {
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			if (!oidSet.isEmpty()) {
				for (String oid : oidSet) {
					CookInfo info = new CookInfo();
					info = changePropery(info,propertyName,propertyVal);
					// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
					info.oid = oid;
					info.cookid = cookId;
					// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
					cookInfos.add(info);
				}
			}
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	}
    	return JSON.serialize(cookInfos);
    }
    //　指定字段変更
    private static CookInfo changePropery(CookInfo info,String name,String value){
    	if (name == COOKINFO_PROPTY_STATUS) {
    		info.status = value;
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
    		// if (value == COOKINFO_STATUS_VALUE_DONE) info.begTm = system.now().format('HH:mm');
			if (value != '') info.begTm = system.now().format('HH:mm');
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    		else info.begTm = '';
    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
    	} else if (name == COOKINFO_PROPTY_BEGTM) info.begTm = value;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		else if (name == COOKINFO_PROPTY_ORDER) info.oid = value;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
		else if (name == COOKINFO_PROPTY_CNT) info.cnt = value;
		else if (name == COOKINFO_PROPTY_SEQ) info.seq = value;
		else if (name == COOKINFO_PROPTY_DSC) info.dsc = value;
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
    	return info;
    }
    // 料理明細情報
    public class CookInfo{
    	String begTm; // 開始時間
    	String endTm; // 終了時間
    	String cookid;// 
    	String status;// 料理状態
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		String oid;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
		String cnt;
		String seq;
		String dsc;
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
    	public CookInfo(){
    		begTm = '';
    		endTm = '';
    		cookid = '';
    		status = '';
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			oid = '';
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
			// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
			cnt = '';
			seq = '';
			dsc = '';
			// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
    	}
    }
    class Request{
    	string spcd;
    	String orderId;
    	String cookId;
    	String begTm;
    	boolean done;
    	String busType;
    	String minute;
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	String gotoDate;
    	String[] orderIds;
    	String lead;
    	String prodId;
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
		Map<String,String> roominfo;
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
		String status;
		// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
		boolean cookflg;
		String layoutid;
		String roomtype;
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		String ops;
		String[] oids;
		integer cnt;
		String name;
		String value;
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		boolean doneflg;
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		String filterRoomIds;
		// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
		boolean isHorlayout;
		// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		boolean sumflg;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
    }
    class CookDetail{
    	String qty;
    	String orderTime;
    	String productId;
    	String productName;
    	String parentId;
    	String parentName;
    	String begTm;
    	String endTm;
    	String status;
    	String objectid;
    	String foodid;
    	String cookInfo;
    	String detailType;
    	String allergie;
    	String roomName;
    	String contactName;
    	String leadid;
    	boolean noSetTm;
    	Decimal minutes;
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	String itemId;
    	// 2018/10/31 料理進捗開始（OWNER) by cxw END
		// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
		String roomId;
		// 2019/09/15 部屋の並び順をSeq#順に by zy END
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
		String chgQty;
		// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		String cookdes;
		String cookseq;
		String orderid;
		String parseq;
		String acctm;
		public CookDetail(){}
		public CookDetail(String tranCookInfo){
			if (!CommUtils.isBlank(tranCookInfo)) {
				String[] cookArr = tranCookInfo.split(':');
				objectid = cookArr[0];
				qty = cookArr[1];
				cookseq = cookArr[2];
				if (cookArr.size() > 3) cookdes = cookArr[3];
			}
		}
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	// 明細展開
    	public CookDetail createFoodDetail(FoodDetail__c food,CookInfo child){
    		CookDetail detail = new CookDetail();
    		detail.minutes = COOKINFO_MUNITES;
    		detail.status = '';
    		detail.begTm = '';	
    		detail.endTm = '';
    		detail.foodid = food.id;
    		detail.objectid = objectid;
    		detail.allergie = allergie;
    		detail.roomName = roomName;
    		detail.productId = productId;
    		detail.contactName = contactName;
    		detail.noSetTm = true;
    		detail.leadid = leadid;
    		// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    		detail.itemId = productId;
    		// 2018/10/31 料理進捗開始（OWNER) by cxw END
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			detail.orderid = orderid;
			detail.cookdes = cookdes;
			detail.cookseq = cookseq;
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
			// 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
			detail.acctm = Commutils.nullToBlank(acctm);
			// 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
    		// 料理ブレイクあり
    		if (food != null) {
    			if (food.AccountMasterSubRef__c != null) {
    				detail.productName = food.AccountMasterSubRef__r.name;
	    			//detail.productId = food.AccountMasterSubRef__c;
	    			// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
	    			// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
	    			//detail.itemId = food.AccountMasterSubRef__c;
	    			// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
	    			// 2018/10/31 料理進捗開始（OWNER) by cxw END
	    			detail.detailType = food.BreakName__c;
	    			if (food.AccountMasterSubRef__r.CookTime__c != null)
	    				detail.minutes = food.AccountMasterSubRef__r.CookTime__c;
    			} else {
    				detail.productName = food.BreakName__c;
    				detail.detailType = food.BreakName__c;
    			}
    			// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
    			detail.itemId = CommUtils.nullToBlank(food.AccountMasterSubRef__c);
    			// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
	    		detail.parentId = productId;
	    		detail.parentName = productName;
    		}
    		// 料理進捗あり
    		if (child != null) {
    			detail.begTm = child.begTm;
    			detail.endTm = child.endTm;
    			detail.status = child.status;
				detail.orderid = child.oid;
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				detail.cookseq = child.seq;
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
				detail.chgQty = child.cnt;
				detail.cookdes = child.dsc;
				
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
    		}
    		detail.qty = qty;
    		return detail;
    	}
    	public CookDetail createFoodDetail(CookInfo child){
    		CookDetail detail = new CookDetail();
    		detail.productName = productName;
    		detail.productId = productId;
    		detail.minutes = COOKINFO_MUNITES;
    		detail.status = '';
    		detail.begTm = '';	
    		detail.endTm = '';
    		detail.objectid = objectid;
    		detail.allergie = allergie;
    		detail.roomName = roomName;
    		detail.contactName = contactName;
    		detail.productId = productId;
			detail.leadid = leadid;
			// 2020/03/30 並び順を「料理スタート時間」にできるように by zy BEGIN
			detail.acctm = Commutils.nullToBlank(acctm);
			// 2020/03/30 並び順を「料理スタート時間」にできるように by zy END
    		if (child != null) {
    			detail.begTm = child.begTm;
    			detail.endTm = child.endTm;
    			detail.status = child.status;
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				detail.orderid = child.oid;
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
				detail.chgQty = child.cnt;
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
				detail.cookdes = child.dsc;
				// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				detail.cookseq = child.seq;
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    		}
    		detail.qty = qty;
    		return detail;
    	}
    }
    // カラー設定
    class ColorInfo{
    	// 料理背景
    	public String cookBg{get;set;}
    	// 料理完了背景
    	public String cookDoneBg{get;set;}
    	// 料理明細背景
    	public String cookDetailBg{get;set;}
    	// 料理タイトル背景
    	public String titleBg{get;set;}
    	// 料理タイトル字体カラー
    	public String titleColor{get;set;}
    	// 料理完了字体カラー
    	public String cookDoneColor{get;set;}
    	// 料理明細字体カラー
    	public String cookDetailColor{get;set;}
		// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
		public String odd{get;set;} // 料理奇数列color
		public String even{get;set;} // 料理偶数列color
		// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
    	public ColorInfo(){
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
			odd = 'white'; // 料理奇数列color
			even = '#e3e3e3';	 // 料理偶数列color
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
    		cookBg = 'white';
    		titleBg = 'blue';
    		titleColor = 'white';
    		cookDoneBg = 'gray';
    		cookDetailBg = 'cookDetailBg';
    		cookDoneColor = 'black';
    		cookDetailColor = 'black';
    	}
    }
    // タイム情報
    public class TimeInfo{
    	public String timeStamp{get;set;}
    	public String dTimeFormat{get;set;}
    	public String timeFormat{get;set;}
    	public boolean currentFlag{get;set;}
    	public integer leftInt{get;set;}
    	public boolean showFlag{get;set;}
    	public TimeInfo(Datetime dt,Integer left){
    		timeStamp = CommUtils.nullToBlank(dt.getTime());
    		timeFormat = dt.format('HH:mm');
    		dTimeFormat = dt.format('yyyy/MM/dd HH:mm');
    		currentFlag = false;
    		leftInt = left;
    		showFlag = false;
    	}
    }
    // 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    private class ParseBusType {
    	List<CookTmSetting> cookTmLst;
        public ParseBusType(String spcd, String busType){
        	cookTmLst = new List<CookTmSetting>();
        	String curBusType = CommUtils.nullToBlank(busType).trim();
        	if(CommUtils.isBlank(curBusType)) parseXml(spcd);
        	else parseType(curBusType);
        }
        
        private void parseType(String busType){
        	try{
            	busType = busType.trim();
                String[] arr = busType.split('~');
                if(arr.size() == 3){
                    Datetime[] detm = new Datetime[2];
                    detm[0] = CommUtils.convertDatetime(Date.newInstance(0, 0, 0), arr[0]);
                    detm[1] = CommUtils.convertDatetime(Date.newInstance(0, 0, 0), arr[1]);
                    if(!String.isBlank(arr[2])){
                    	CookTmSetting result = new CookTmSetting(detm[0], detm[1], arr[2]);
                    	cookTmLst.add(result);
                    }
                }
        	}catch(Exception e){}
        }
        
        private void parseXml(String spcd){
        	try{
				// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
        		Dom.XMLNode rootNode = CommXmlUtils.encodeParseXmlDoc('OrderProductConfig', spcd,new String[]{'<LOGOIMG>','</LOGOIMG>','<ROOMFILTER>','</ROOMFILTER>'});
				// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
        		if(rootNode != null){
	        		Dom.XMLNode targetNode = rootNode.getChildElement('FOODSCHEDULE',null);
	        		if(targetNode != null){
	        			Dom.XMLNode bussinessNode = targetNode.getChildElement('BUSSINESSTIME',null);
	        			if(bussinessNode != null){
		        			for (Dom.XMLNode bussTmNode : bussinessNode.getChildElements()) {
					    		Dom.XMLNode beginNode = bussTmNode.getChildElement('BEGIN',null);
					    		Dom.XMLNode endNode = bussTmNode.getChildElement('END',null);
					    		Dom.XMLNode cookTimeNode = bussTmNode.getChildElement('COOKTIME',null);
					    		String beginTm = '';
					    		String endTm = '';
					    		String cookTm = '';
					    		if (beginNode != null) beginTm = CommUtils.nullToBlank(beginNode.getText());
					    		if (endNode != null) endTm = CommUtils.nullToBlank(endNode.getText());
					    		if(cookTimeNode != null) cookTm = CommUtils.nullToBlank(cookTimeNode.getText());
					    		if (!CommUtils.isBlank(cookTm) && !CommUtils.isBlank(beginTm) && !CommUtils.isBlank(endTm)){
					    			Date dt = system.today();
					    			Datetime begDt = CommUtils.convertDatetime(dt, beginTm);
					    			Datetime endDt = CommUtils.convertDatetime(dt, endTm);
					    			Datetime cookDt = CommUtils.convertDatetime(dt, cookTm);
					    			if(!(cookDt >= begDt && cookDt <= endDt)) continue;
					    			CookTmSetting result = new CookTmSetting(CommUtils.convertDatetime(Date.newInstance(0, 0, 0), beginTm), CommUtils.convertDatetime(Date.newInstance(0, 0, 0), endTm), cookTm);
					    			// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
									// 表示料理ー＞時間ラベル
				    				Dom.XMLNode labelNode = bussTmNode.getChildElement('LABEL',null);
									if (labelNode != null) result.label = CommUtils.nullToBLank(labelNode.getText());
									// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
									cookTmLst.add(result);
					    		}
					    	}
	        			}
	        		}
        		}
        	}catch(Exception e){}
        }
        public String compare(String tm){
        	if(cookTmLst.isEmpty()) return tm;
        	Datetime currDt = CommUtils.convertDatetime(Date.newInstance(0, 0, 0), tm);
        	for(CookTmSetting ct : cookTmLst){
        		if(ct.startDt <= currDt && currDt < ct.endDt) return ct.cookDt;
        	}
        	return tm;
        }
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
		public String compare(String tm,Map<String,String> lead,Map<String,String> cus){
			String type = '';
        	if(cookTmLst.isEmpty()) {
				String customTm = CommUtils.nullToBlank(getTypeSeqTime(lead,cus,type));
				return CommUtils.isBlank(customTm) ? tm : customTm;
			}
        	Datetime currDt = CommUtils.convertDatetime(Date.newInstance(0, 0, 0), tm);
        	for(CookTmSetting ct : cookTmLst){
        		if(ct.startDt <= currDt && currDt < ct.endDt) {
					String customTm = CommUtils.nullToBlank(getTypeSeqTime(lead,cus,CommUtils.nullToBlank(ct.label)));
					return CommUtils.isBlank(customTm) ? ct.cookDt : customTm;
				}
        	}
        	return tm;
		}
		// 該当タイプのカスタム字段時間
		private String getTypeSeqTime(Map<String,String> leadOtherMap,Map<String,String>customRoomSeqMap,String type){
			String typeKey = type + '_lead';
			if (customRoomSeqMap.containsKey(typeKey)) {
				String field = customRoomSeqMap.get(typeKey);
				if (leadOtherMap.containsKey(field)) return leadOtherMap.get(field);
			}
			return '';
		}
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
    }
    
    private class CookTmSetting{
    	Datetime startDt;
    	Datetime endDt;
    	String cookDt;
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy BEGIN
		String label;
		// 2019/09/15 料理の開始時刻を「夕食時間」に紐づくように by zy END
    	public CookTmSetting(Datetime startDt, Datetime endDt, String cookDt){
    		this.startDt = startDt;
    		this.endDt = endDt;
    		this.cookDt = cookDt;
    	}
    }
    // 注文IDs取得
    private static List<Sobject> getSobjectByIds(Set<String> orderSet){
    	String orderId = (new List<String>(orderSet))[0];
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	String orderSQL = isEstFlag ? bookingEstQuery : tran1Query;
    	orderSQL += ' where id = :orderSet';
    	List<Sobject> sobjects = Database.query(orderSQL);
    	return sobjects;
    }
    // 2018/10/31 料理進捗開始（OWNER) by cxw END
    // 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy BEGIN
    // 既存料理内容更新
    private static List<CookInfo> filterCookinfo(String cookId,List<CookInfo> cookInfos,List<CookInfo> orgCookinfo){
    	// 該当料理処理フラグ
    	boolean hadCookFlag = false;
    	Map<String,CookInfo> cookMap = new Map<String,CookInfo>();
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		Map<String,List<CookInfo>> orderCookMap = new Map<String,List<CookInfo>>();
		for (CookInfo cook : orgCookinfo) {
			String curCookId = CommUtils.nullToBlank(cook.cookid);
			if (cookMap.containsKey(curCookId)) cook = cookMap.get(curCookId);
			String orderId = CommUtils.nullToBlank(cook.oid); 
			if (!orderCookMap.containsKey(orderId)) orderCookMap.put(orderId,new List<cookinfo>());
			orderCookMap.get(orderId).add(cook);
		}
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	// 既存料理情報フィルター
    	for (CookInfo cook : cookInfos) {
    		String curCookId = CommUtils.nullToBlank(cook.cookid);
    		// 該当料理ID,明細情報含むの場合
    		if (CommUtils.isBlank(cookId) || (!CommUtils.isBlank(cookId) && cookId == curCookId)) hadCookFlag = true;
    		cookMap.put(curCookId,cook);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
			String orderId = CommUtils.nullToBlank(cook.oid); 
			// 此次处理指定的order以外既存的order
			orderCookMap.remove(orderId);
			// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	}
    	// 該当料理未処理の場合
    	if (!hadCookFlag) {
    		for (CookInfo cook : orgCookinfo) {
    			String curCookId = CommUtils.nullToBlank(cook.cookid);
    			if (cookMap.containsKey(curCookId)) cook = cookMap.get(curCookId);
    		}
    		cookInfos = orgCookinfo;
    	}
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		if (!orderCookMap.isEmpty()) {
			for(String orderId : orderCookMap.keySEt()){
				for (CookInfo cook : orderCookMap.get(orderId)) {
					cookInfos.add(cook);
				}
			}
		}
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    	return cookInfos;
    }
    // 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
    // 2019/01/30 料理UI改善　by zy BEGIN
    public boolean padHeadShow{get;set;}
    // 2019/01/30 料理UI改善　by zy END
    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
    public boolean isEndFlag{get;set;} // 料理アラーム時間
    // 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
	private static Map<String,String>customRoomSeqMap;
	public String cookRoomSetJson{get;set;}
	// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
	private string orderSort; // 部屋順
	// 部屋表示順フラグ定数定義
	private static final String ROOM_SORT_NAME_DIV = '1';
	private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	// 部屋順JSON
	public String roomSortJson{get{
		String queryOrder = '';
		if (CommUtils.isBlank(orderSort)) {
			queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
			if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
				queryOrder += ' Seq__c asc ';
			} else {
				queryOrder += ' DisplayNo__c asc ';
			}
		} else {
			queryOrder = ' order by ' + orderSort;
		}
		String roomQuery = 'select id from Room__c where ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		LIst<String> roomLst = new List<String>();
		for (Room__c r : Database.query(roomQuery + queryOrder)) roomLst.add(r.id);
		String result = '';
		if (!roomLst.isEmpty()) result = String.join(roomLst,',');
		return result;
	}set;}
	// 2019/09/15 部屋の並び順をSeq#順に by zy END
	// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy BEGIN
	public String colorInfoJson{get;set;}
	// 2019/12/30 料理リスト機能、オーダー提供ボタン（接待側からリクエストと調理場提供ボタン） by zy END
	// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
	public List<System.SelectOption> deslayoutOpts{get;set;}
	private static Request pRequest;
	// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy END
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	public String locShowType{get;set;}
	private final static String COOK_SHOW_TYPE_RES = 'grid';
	private final static String COOK_SHOW_TYPE_KIT = 'cook';
	public boolean isRestrantFlg{get{return locShowType != COOK_SHOW_TYPE_KIT;}set;}
	public List<System.SelectOption> kitchenOpts{get;set;}
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	private static Map<String,decimal> accMinutesMap; //会計商品料理時間
	private static Map<String,Map<String,Map<String,CookDetail>>> getTransDetail(Map<String,String> tranProdMap,Map<Id, List<FoodDetail__c>> foodDetailMap,Date todayDt,Set<String> leadIdSet) {
		// 会計明細下料理「数量」「備考」取得
		Map<String,Map<String,Map<String,CookDetail>>> transDetailMap = new Map<String,Map<String,Map<String,CookDetail>>>();
		List<OrderEntryInfo__c> orders = [select id,OrderStatus__c,RoomRef__c,AccountRef__c,SearchDate__c,OrderTime__c,LeadRef__c ,Trans__c,CookInfo__c
					, LeadRef__r.RelContact__r.name,LeadRef__r.name,LeadRef__r.LeadIndexRef__c
						from OrderEntryInfo__c where SearchDate__c = :todayDt and LeadRef__c =:leadIdSet and OrderStatus__c = :OrderserviceHelp.ORDER_STATUS_PRINT_INFO order by LastModifiedDate];
		for (OrderEntryInfo__c order : orders) {
			if (!CommUtils.isBlank(order.trans__c)){
				List<String> transCnt = order.trans__c.split(',');
				List<String> cookInfo = order.cookinfo__c.split(',');
				for (integer i = 0 ; i < transCnt.size(); i++) {
					string[] tranArr = transCnt[i].split(':');
					// 削除チェック
					if (tranArr.size() < 3) {
						String cook = cookInfo[i];
						CookDetail info = new CookDetail(cook);
						info.orderid = order.id;
						// 同一个明细下料理展开
						if (tranProdMap.containsKey(info.objectid)) {
							// 明细下内容初始化
							if (!transDetailMap.containsKey(info.objectid)) transDetailMap.put(info.objectid,new Map<String,Map<String,CookDetail>>());
							String productId = tranProdMap.get(info.objectid);
							// Order对应内容作成
							Map<String,Map<String,CookDetail>> orderMap = transDetailMap.get(info.objectid);
							if (!orderMap.containskey(order.id)) orderMap.put(order.id,new Map<String,CookDetail>());
							if (foodDetailMap.containskey(productId)) {
								for (FoodDetail__c food : foodDetailMap.get(productId)){
									CookDetail detail = new CookDetail();
									// オーダー指定順番、備考
									detail.cookdes = info.cookdes;
									detail.cookseq = info.cookseq;
									detail.qty = info.qty;
									detail.ordertime = order.OrderTime__c;
									// 指定内容設定
									String key = info.objectid + '_' + CommUtils.nullToBlank(food.id) + '_' + order.id;
									if (!orderMap.get(order.id).containsKey(key)) orderMap.get(order.id).put(key,detail);
								}
							} else {
								String key = info.objectid + '_' + CommUtils.nullToBlank(productId) + '_' + order.id;
								info.OrderTime = order.OrderTime__c;
								if (!orderMap.get(order.id).containsKey(key)) orderMap.get(order.id).put(key,info);
							}
							transDetailMap.put(info.objectid,orderMap);
						}
					}
				}
			}
		}
		return transDetailMap;
	}
	private static CommonInfo commInfo;
	private class CommonInfo {
		Date todayDt;
		// 開始時刻
		Datetime curDt;
		Datetime begTm;
		String orgType;
		Datetime curDateTm;
		Integer seq;
		// 会席明細SEQ
		integer childSeq;
		Map<String,integer> qtyProdMap;
		Map<String,Integer> seqProdMap;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		boolean sumflg;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		public CommonInfo(){
			seq = 1;
			childSeq = 1;
			seqProdMap = new Map<String,Integer>();
			qtyProdMap = new Map<String,Integer>();
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			sumflg = false;
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		}
	}
	private static List<CookDetail> processTransAndCookInfos(Map<String,Map<String,CookDetail>> orderTranDetails,Map<String,CookInfo> exitCookStatusMap,CookDetail item,List<FoodDetail__c> foodDts) {
		// 既存料理情報
		List<CookDetail> details = new List<CookDetail>();
		// 区分Id 
		String tranId = item.objectid;
		// 商品Id
		String prodId = item.productId;
		// 默认状态下包含既存oid为空时候的数据
		Set<String> orderSet = new Set<String>();
		if (orderTranDetails != null) orderSet = orderTranDetails.keySet();
		comminfo.qtyProdMap = new Map<String,Integer>();
		for (String orderId : orderSet) {
			details.addAll(convertOrderAndCookInfo(orderId,tranId,prodId,item,foodDts,orderTranDetails.get(orderId),exitCookStatusMap,null));
		}
		if (!Comminfo.qtyProdMap.isEmpty()) {
			String orderId = '';
			details.addAll(convertOrderAndCookInfo(orderId,tranId,prodId,item,foodDts,orderTranDetails.get(orderId),exitCookStatusMap,Comminfo.qtyProdMap));
		}
		return details;
	}
	private static List<CookDetail> convertOrderAndCookInfo(String orderId,String tranId,string prodId,CookDetail item,List<FoodDetail__c> foodDts,Map<String,CookDetail> orderMap ,Map<String,CookInfo> exitCookStatusMap,Map<String,integer> qtyProdMap){
		List<CookDetail> details = new List<CookDetail>();
		if (foodDts != null && !foodDts.isEmpty()) {
			String cookSeq = '';
			for (integer i = 0 ; i < foodDts.size(); i++) {
				FoodDetail__c food = foodDts[i];
				String key = tranId + '_' + CommUtils.nullToBlank(food.id);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				if (!CommUtils.isBlank(orderId)) key += '_' + Commutils.nullToBlank(orderId);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
				// 既存料理情報
				CookInfo cook = exitCookStatusMap.get(key);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				// 合并状态下因为只有一个状态生效，但是其他Order也会读取同一个信息
				if (comminfo.sumflg && exitCookStatusMap.containsKey(key)) exitCookStatusMap.remove(key);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
				// オーダーエンドリー設定時報
				CookDetail orderDetail = null;
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				// オーダー鍵
				String orderKey = tranId + '_' + CommUtils.nullToBlank(food.id) + '_' + Commutils.nullToBlank(orderId);
				// 数据库里作成的注文内容
				if (orderMap != null && orderMap.containsKey(orderKey)) {
					orderDetail = orderMap.get(orderKey);
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
					// 会席の場合下、料理明細不設定
					cookSeq = orderDetail.cookseq;
					orderDetail.cookseq = null;
					// 料理時報刷新
					cook = refreshCookInfo(cook,orderDetail);
					// 開始時刻
					if (i == 0 && CommUtils.isBlank(cook.begTm)) cook.begTm = orderDetail.orderTime;	
				}
				// 指定数量处理
				if (!comminfo.qtyProdMap.containsKey(food.id)) comminfo.qtyProdMap.put(food.id,CommUtils.nullToIntZero(item.qty));
				// 最終情報作成
				CookDetail foodDetail = convertCookDetail(item,cook,food);
				// 没有其他order情报
				if (orderDetail != null) {
					// 不指定数量的状态
					if (qtyProdMap == null) {
						foodDetail.qty = orderDetail.qty;
						Integer chgQty = comminfo.qtyProdMap.get(food.id) - CommUtils.nullToIntZero(orderDetail.qty);
						if (chgQty > 0) comminfo.qtyProdMap.put(food.id,chgQty);
						else comminfo.qtyProdMap.remove(food.id);
					}			
				} else if (qtyProdMap != null) {
					foodDetail.qty = Commutils.nullTOBlank(qtyProdMap.get(food.id));
				}
				foodDetail.parseq = cookSeq;
				foodDetail.orderid = orderId;
				details.add(foodDetail);
			}
		} else { 
			// 区分鍵
			String key = tranId + '_';
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			// !comminfo.sumflg && 
			if (!CommUtils.isBlank(orderId)) key += '_' + Commutils.nullToBlank(orderId);
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
			if (!comminfo.qtyProdMap.containsKey(prodId)) comminfo.qtyProdMap.put(prodId,CommUtils.nullToIntZero(item.qty));
			CookInfo cook = exitCookStatusMap.get(key);
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			if (orderMap == null && cook == null && !comminfo.sumflg) return details;
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
			// オーダーエンドリー設定時報
			CookDetail orderDetail = null;
			// オーダー鍵
			String orderKey = tranId + '_' + prodId + '_' + Commutils.nullToBlank(orderId);
			// 数据库里作成的注文内容
			if (orderMap != null && orderMap.containsKey(orderKey)) {
				orderDetail = orderMap.get(orderKey);
				// 料理時報刷新
				cook = refreshCookInfo(cook,orderDetail);
				// 開始時刻
				if (CommUtils.isBlank(cook.begTm)) cook.begTm = orderDetail.orderTime;
			}
			// 情報作成
			CookDetail detail = convertCookDetail(item,cook,null);
			if (orderDetail != null) {
				// 不指定数量的状态
				if (qtyProdMap == null) {
					detail.qty = orderDetail.qty;
					Integer chgQty = comminfo.qtyProdMap.get(prodId) - CommUtils.nullToIntZero(orderDetail.qty);
					if (chgQty > 0) comminfo.qtyProdMap.put(prodId,chgQty);
					else comminfo.qtyProdMap.remove(prodId);
				} 
			} else if (qtyProdMap != null) {
				detail.qty = CommUtils.nullToblank(qtyProdMap.get(prodId));
			}
			detail.orderid = orderId;
			details.add(detail);
		}
		return details;
	}
	// 料理時報刷新
	private static CookInfo refreshCookInfo(CookInfo cook,CookDetail orderDetail){
		// オーダー設定あり
		if (orderDetail != null) {
			if (cook == null) cook = new CookInfo();
			// 料理順番
			if (CommUtils.isBlank(cook.seq)) cook.seq = orderDetail.cookSeq;
			// 料理備考
			if (CommUtils.isBlank(cook.dsc)) cook.dsc = orderDetail.cookDes;
			// 2020/11/30 9368 bug fixed by zy BEGIN
			if (cook.dsc == COOK_STATUS_BLANK) cook.dsc = '';
			// 2020/11/30 9368 bug fixed by zy END
		}
		return cook;
	}
	// 料理情報設定
	private static CookDetail convertCookDetail(CookDetail item,CookInfo cook,FoodDetail__c d){
		CookDetail foodDetail = null;
		if (d != null) {
			foodDetail = item.createFoodDetail(d,cook);
			if (cook != null && !CommUtils.isBlank(cook.begTm)){
				commInfo.curDt = CommUtils.convertDatetime(commInfo.todayDt,cook.begTm);
				commInfo.orgType = d.BreakName__c;
				foodDetail.noSetTm = false;
			} else if (commInfo.orgType != d.BreakName__c){
				Integer seconds = CommUtils.nullToIntZero(CommUtils.nullToZero(foodDetail.minutes) * 60);
				if (commInfo.orgType != null) commInfo.curDt = commInfo.curDt.addSeconds(seconds);
				commInfo.orgType = d.BreakName__c;
			}
		} else{
			foodDetail = item.createFoodDetail(cook);
			if (cook != null && !CommUtils.isBlank(cook.begTm)){
				commInfo.curDt = CommUtils.convertDatetime(commInfo.todayDt,cook.begTm);
			}
			if (accMinutesMap.containsKey(item.productId)) foodDetail.minutes = CommUtils.nullToZero(accMinutesMap.get(item.productId));
			// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
			foodDetail.itemId = item.productId;
			// 2018/10/31 料理進捗開始（OWNER) by cxw END
		}
		String begTmStr = CommUtils.convertHourKm(commInfo.curDt,commInfo.curDateTm);
		foodDetail.begTm = begTmStr;
		Integer seconds = CommUtils.nullToIntZero(CommUtils.nullToZero(foodDetail.minutes) * 60);
		foodDetail.endTm = CommUtils.convertHourKm(commInfo.curDt.addSeconds(seconds),commInfo.curDateTm);
		if (commInfo.begTm > commInfo.curDt) commInfo.begTm = commInfo.curDt;
		// 2019/09/15 部屋の並び順をSeq#順に by zy BEGIN
		foodDetail.roomId = item.roomId;
		// 2019/09/15 部屋の並び順をSeq#順に by zy END
		// 未设定seq的明细
		if (CommUtils.isBlank(foodDetail.cookseq)) {
			//  同一个会计商品同一个料理状态进行合并
			String foodKey = CommUtils.isBLank(foodDetail.foodid) ? foodDetail.roomId : foodDetail.foodid + '_' + foodDetail.detailType;
			if (!commInfo.seqProdMap.containsKey(foodKey)) {
				foodDetail.cookseq = CommUtils.nullToBlank(commInfo.childSeq);
				commInfo.seqProdMap.put(foodKey,commInfo.childSeq);
				commInfo.childSeq++;
			} else foodDetail.cookseq = CommUtils.nullToBlank(commInfo.seqProdMap.get(foodKey));
		}
		return foodDetail;
	}
	private static String COOK_STATUS_BLANK = '_blank_';
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy BEGIN
	public boolean timeFlag{get;set;}
	// 2020/02/28 テーブル側のレイアウトも大幅改変 by zy END
	// 2020/02/28 並び順を「料理スタート時間」にできるように by zy BEGIN
	public boolean accTimeFlag{get;set;}
	public String selKitchenVal{get;set;}
	public Integer cookDoneHideLen{get;set;}
	// 2020/02/28 並び順を「料理スタート時間」にできるように by zy END
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
	public boolean isOrderEndFlg{get;set;} // 料理済みの状態
	public boolean isDoneFlg{get;set;}
	// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
	public boolean isHorlayout{get;set;}  // 画面用料理進捗 横のレイアウト
	// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
	// 画面情報保持
	private void setCookieInfo(){
		isDoneFlg = false;
		// ユーザーの情報取得
		String cookInfo = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.INFO.name(),branchShopNm,false);
		if (!CommUtils.isBlank(cookInfo)) {
			Request req = (Request)JSON.deserialize(cookInfo,Request.class);
			isDoneFlg = req.doneflg;
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy BEGIN
			isHorlayout = req.isHorlayout; // ユーザーの横のレイアウト設定
			// 2020/08/31 料理進捗を階段状ではなく、横並びにする by zy END
		}
	}
	public static void saveCookieInfo(String subType,String spcd ,String settingInfo){
		// Cookieからレイアウトモードを取得する
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.COOK,
				subType,settingInfo,UserUtil.CurrentUser.id,spcd);
	}
	public static String getCookieInfo(String subType,String spcd,boolean isHadNull){
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.COOK,
											UserUtil.CurrentUser.id,spcd);
		String cookieInfo = userBookMap.get(subType);
		if (!isHadNull) cookieInfo = CommUtils.nullToBlank(cookieInfo);
	   	return cookieInfo;
	}
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
	// 2020/05/30 リリース後の検収再対応 by zy BEGIN
	public boolean kichenOrderOnly{get;set;}
	// 2020/05/30 リリース後の検収再対応 by zy END
	// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
	public boolean isSameProductSumFlg{get;set;}
	// 商品合并mode变更数据
	private static object sumCookChgData(Request req){
		// 見積明細/会計明細Id
		String orderId = req.orderid;
		// 料理Id
    	String cookId = req.cookid;
    	// 変更時刻
    	String begTm = req.begTm;
    	// 店舗コード
    	String spcd = req.spcd;
    	// 営業状態
    	String busType = req.busType;
    	// 注文状態チェック
    	String orderType = getSobjectTypeById(orderId);
    	// 予約見積の場合
    	boolean isEstFlag = orderType == ORDER_TYPE_BOOKINGEST;
    	// 該当処理オブジェクSQL区分
    	String orderSQL = isEstFlag ? bookingEstQuery : tran1Query;
    	// 料理用時
		String minute = req.minute;
		// カスタム料理用時設定
		COOKINFO_MUNITES = CommUtils.nullToZero(minute);
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
		// 検索用情報設定
		pRequest = req;
		// 2020/02/15 ■同店舗内でもレストラン毎の表示を可能にする by zy END
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		Set<String> orderSet = new Set<String>();
		Map<String,String> orderMap = new Map<String,String>();
		Map<String,String> orderStatusMap = new Map<String,String>();
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		Set<String> tranSet = new Set<String> ();
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		if (req.oids != null) {
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
			String splitTxt = '&&';
			// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
			for (String orderMsg : req.oids) {
				String[] orderArr = orderMsg.split(splitTxt);
				if (!CommUtils.isBlank(orderMsg) && orderArr.size() == 0) {
					orderMap.put('','');
					continue;
				}
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
				if (req.sumflg) {
					String orderIdStr = orderArr[0];
					String[] msgArr = orderIdStr.split('_');
					// tranId -> orderId
					tranSet.add(msgArr[0]);
				}
				// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
				orderSet.add(orderArr[0]);
				if (orderArr.size() > 1) orderMap.put(orderArr[0],orderArr[1]);
				if (orderArr.size() > 2) orderStatusMap.put(orderArr[0],orderArr[2]);
			}
		}
		// if (req.oids != null) orderSet = new Set<String>(req.oids);
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		String statusName = req.name;
		// String statusValue = req.value;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
		//　空白料理情报作成
		List<CookInfo> exitCooks = new List<CookInfo>();
		if (!CommUtils.isBlank(cookId)) {
    		List<FoodDetail__c> details = [select id,name,AccountMasterRef__c From FoodDetail__c where id=:cookId];
    		if (!details.isEmpty()) {
    			FoodDetail__c food = details[0];
				List<FoodDetail__c> foodDetails = [select id,name from FoodDetail__c where AccountMasterRef__c = :food.AccountMasterRef__c order by OrderNo__c];
				// 該当会計商品の料理ブレイクありの場合
		    	if (!foodDetails.isEmpty()) {
					List<CookInfo> detailCooks = new List<CookInfo>();
					for (FoodDetail__c f : foodDetails) {
						CookInfo info = new CookInfo();
						info.cookid = f.id;
						exitCooks.add(info);
					}
				}
			}
		}
		// 防止地址共存，用JSON进行内存地址清除
		String exitCookInfo = JSON.serialize(exitCooks);
		String exitBlankCookInfo = JSON.serialize(new List<CookInfo>{new CookInfo()});
    	orderSQL += ' where id=:tranSet';
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
		List<Sobject> sobjects = Database.query(orderSQL);
    	if (!sobjects.isEmpty()) {
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy BEGIN
    		for (Sobject obj : sobjects) {
    			// Sobject obj = sobjects[0];
	    		String cookInfo = CommUtils.nullToBlank(obj.get('CookInfo__c')).unescapeHtml4();
	    		boolean isCookFlg = boolean.valueOf(CommUtils.nullToBlank(obj.get('FoodDetailFlg__c')));
	    		List<CookInfo> cookInfos = new List<CookInfo>();
	    		// 料理内容作成
	    		if (!CommUtils.isBlank(cookInfo)) { 
	    			cookInfos = (List<CookInfo>)JSON.deserialize(cookInfo,List<CookInfo>.class);
	    			// 既存料理内容更新
		    		// if (isCookFlg) cookInfos = filterCookinfo(cookId,cookInfos,exitCooks);
	    		}
	    		// 2018/11/05 料理ブレイクBreakDown参照会計商品なし、「料理開始」機能失効のバグ修正 by zy END
	    		// 料理内容更新
				// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
				String curObjId = CommUtils.nullToBlank(obj.get('id'));
				for (String key : orderMap.keySet()) {
					String[] msgArr = key.split('_');
					// tranId
					if (curObjId != msgArr[0]) continue;
					String oid = '';
					if (msgArr.size() > 1) oid = CommUtils.nullToBlank(msgArr[1]);
					if (cookInfos.isEmpty()) {
						cookInfos = isCookFlg ? (List<CookInfo>)JSON.deserialize(exitCookInfo,List<CookInfo>.class) : (List<CookInfo>)JSON.deserialize(exitBlankCookInfo,List<CookInfo>.class);
						for (CookInfo info : cookInfos) info.oid = oid;
					}
    				cookInfo = changeCookInfo(cookInfos,isCookFlg ? cookId : '',statusName,orderMap.get(key),new Set<String>{oid});
					if (orderStatusMap.containsKey(key))
						cookInfo = changeCookInfo(cookInfos,isCookFlg ? cookId : '',COOKINFO_PROPTY_STATUS,orderStatusMap.get(key),new Set<String>{oid});
				}
	    		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
    			obj.put('CookInfo__c',CommUtils.nullToBlank(cookInfo));
    		}
    		update sobjects;
		// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
    	}
    	// 2018/10/31 料理進捗開始（OWNER) by cxw BEGIN
    	Date queryDt = CommUtils.stringToDate(req.gotoDate) == null ? system.today() : CommUtils.stringToDate(req.gotoDate);
    	return getItemByLeadId(new List<Id>{orderId},spcd,queryDt,busType);
	}
	// 2020/11/30 5.8.明細が分かれていても同じ料理ならひとつにまとめて表示させるように by zy END
}