/**
* Calendar情報画面画面
* 2015/09/01 多店舗機能対応
* 2015/11/19 各種類ファイルは最新ファイルのみダウンロード画面に表示機能対応
* 2015/12/04 ファイル名表示ロジック変更
* 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる)
**/
public with sharing class CalendarExtend {
	
	// 宴会場部屋種別
	private static final String ROOM_TYPE_PTY = CommConst.ROOM_UseOfType_PTY;
	// 宴会場部屋リスト
	private List<Room__c> enkaiRooms {get;private set;}
	// 年度選択リスト[今日から前１０～未来10年]
	public List<SelectOption> yearList {get; private set;}
	// 祝日情報を格納する
	public Map<Date, String> holidayMap{get; private set;}
	// 曜日ヘーダ情報を格納する
	public transient List<String> weekFormats{get;set;}
	// 一ヶ月分の集計情報を格納する
	public transient List<WeekInfo> weeks{get; private set;}
	// カレンダー画面に宴会場表示・非表示制御フラグ
	private boolean isShowEnkai = CommDefine__c.getOrgDefaults().CalendarIsShowEnaki__c == null ? false : CommDefine__c.getOrgDefaults().CalendarIsShowEnaki__c;
	public boolean getIsShowEnaki() { return isShowEnkai; }
	// 六輝表示がどうか判断用
	public boolean isShowQreqki{get{return CommConst.IsOrgRokuyoIsNoShow();}}
	// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
	public String profileNm{get; private set;}
	// 2016/01/19 LOCALのプロファイル名を取得する END
	// インスタンス化
	public CalendarExtend() {
		// 初期化処理呼び出し
		initParameter();
		// 宴会場部屋リスト初期化
		setShowRooms();
		// 予約情報を抽出する
		doAction(null);
	}
	
	// パラメータ情報初期化する
	private void initParameter() {
		// レコードタイプ初期設定
		initLeadRecType();
		// 祝日情報を取得する
		initHolidayInfo();
		// 支店リスト設定
		setInitBranShopLst();
		// 機能リスト設定
		setinitAppOptions();
		// 2016/01/19 LOCALのプロファイル名を取得する BEGIN
		profileNm = CommLogicProcess.getLoginUserProfile().name;
		// 2016/01/19 LOCALのプロファイル名を取得する END
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) BEGIN
		if (isNoAuth(branchShopNm)) {
			profileNm = Label.MSG_1016;
		}
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) END
	}
	
	/**
	* Calendar情報初期化専用
	**/
	public CalendarExtend(Boolean calInfo) {
		if (calInfo) initHolidayInfo();
	}
	/**
	* XML定義から祝日情報を取得する
	**/
	public void initHolidayInfo () {
		// 祝日情報初期化
		holidayMap = new Map<Date, String>();
		// 祝日定義情報を取得する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'HolidayDefineXml'];
    	if (sr.isEmpty()) return;
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
		// String -> XML OBJECT
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode root = doc.getRootElement();
		for(Dom.XMLNode yearNode : root.getChildElements()) {
//System.debug(LoggingLevel.INFO, 'YEAR:::' + yearNode.getAttribute('value', null));
			//Dom.XmlNode dayNodes =  targetNode.getChildElement('dates', null);
			//if (yearNode. != null) {
			for(Dom.XMLNode dayNode : yearNode.getChildElements()) {
				//System.debug(LoggingLevel.INFO, 'LABEL:::' + dayNode.getAttribute('label', null));
				//System.debug(LoggingLevel.INFO, 'TEXT:::' + dayNode.getText());
				String holiday = dayNode.getText();
				if (!CommUtils.isBlank(holiday)) {
					// 2016/01/20 Golbal対応するため、日付変換は共通関数に変換する
					//Date holidayDt = Date.parse(holiday);
					Date holidayDt = CommUtils.stringToDate(holiday);
					if (holidayDt == null) continue;
					holidayMap.put(holidayDt, CommUtils.nullToBlank(dayNode.getAttribute('label', null)));
				}
			}
		}
//System.debug(LoggingLevel.INFO, 'holidayMap::::' + holidayMap);
	}
	
    // Tier/営業のHeader部情報を表示・非表示制御する
    public Boolean isShowTierHeader {get{
    	// 支店あり、全店舗を選べる場合、TIERのHeader情報を非表示する
    	return !(CommUtils.isBlank(branchShopNm) && branchShopLst.size() > 0);
    }}
	/**
	* Tier設定情報
	**/
	private Map<Date, String> initTierInfo (Date startDate, Date endDate) {
		// 日単位のTier情報を格納する
		Map<Date, String> tierMap = new Map<Date, String>();
		if (!isShowTierHeader) return tierMap;
		
		// 指定期間範囲内のTier情報
		String defTier = getDefTier(branchShopNm);
		// 該当支店単位のTier設定情報を取得する
		Date tmpDate = startDate;
		while (tmpDate <= endDate) {
			tierMap.put(tmpDate, defTier);
			tmpDate = tmpDate.addDays(1);
		}
		// 指定されるTIER情報を取得する
		// 日単位のTIER設定情報を取得する
		String queryRRDetailHeader = ' Select Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
		String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:startDate And PriceSetupDate__c <= :endDate';
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
		queryRRDetailString += ' and RoomTypeRef__c = null';
		// 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
		// 店舗条件
		if (!CommUtils.isBlank(branchShopNm))  queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 日付・支店単位の設定情報を取得する
		//Map<String, String> setupTierMap = new Map<String, String>();
		for (RackRateTableDetail__c item : DataBase.query(queryRRDetailString)) {
			tierMap.put(item.PriceSetupDate__c, item.Tier__c);
		}
		return tierMap;
	}

	// 支店選択切り替え対応
	public void gotoSwitchShop () {
		// 店舗により、表示する宴会場部屋切り替えする
		setShowRooms();
		// 予約集計情報を取得する
		doAction(0);
	}
	// 年月に選択する	
	public void gotoYearMonth() {
		doAction(0);
	}
	// 前月に選択する
	public void toPrev() {
		doAction(-1);
	}
	// 翌月に選択する
	public void toNext() {
		doAction(1);
	}
	
	// 画面から指定する年・月情報を格納する
	private Date processDay;
	public Integer thisYear	{get;set;}
	public Integer thisMonth{get;set;}
	private void doAction (Integer month) {
		// 週情報を格納する
		weeks = new List<WeekInfo>();
		// 表示一覧リスト情報
		// 初回表示時に、処理日付を現在の日付で設定
		if(month == null) {
			processDay = Date.today();
		}
		// 先月・来月ボタン押下時に、処理日付を変更する
		else if(month != null && thisYear != null && thisMonth != null) {
			processDay = Date.newinstance(thisYear, thisMonth, 1).addMonths(month);
		}
		thisYear = processDay.year();
		thisMonth = processDay.month();
		// ------------------------------------------------
		// 指定月から、一ヶ月日付リストを作成する[表示期間設定]
		Integer daysOfMonth = Date.daysInMonth(thisYear, thisMonth);
		Date endMonth = Date.newInstance(thisYear, thisMonth, daysOfMonth);
		Date firstDayEndWeek = endMonth.toStartOfWeek();
		// 月の初日
		Date firstDate = Date.newInstance(thisYear, thisMonth, 1);
		// 最初週の初日
        Date startDate = firstDate.toStartOfWeek();
		// 最終週の終日
		Date endDate = firstDayEndWeek.addDays(6);
		// 2018/08/28 献立表項目追加 by zy BEGIN
		Date beginDt = startDate;
		// 2018/08/28 献立表項目追加 by zy END
		// ------------------------------------------------
		weekFormats = new List<String>();
		Date weekStartDt = startDate;
		for (Integer i =0; i<7; i++) {
			weekFormats.add(CommUtils.getYobi(weekStartDt));
			weekStartDt = weekStartDt.addDays(1);
		}
		// ------------------------------------------------
		// 10年間選択リスト初期化する
		yearList = new List<SelectOption>();
		Integer oldTenYears = processDay.addYears(-10).year();
		Integer newTenYears = processDay.addYears(10).year();
		for (Integer year = oldTenYears; year <=newTenYears; year++ ) {
			//年
			yearList.add(new SelectOption(String.valueof(year),String.valueof(year)+ Label.CONST_012_0434));
		}
		// ------------------------------------------------
		// Tier設定情報を表示する
		Map<Date, String> tierMap = initTierInfo(startDate, endDate);
		
		// 予約情報を集計する
        Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
        String roomTypeNormalFlg = CommConst.ROOMTYPE_NORMAL;
        
        // 客室の予約情報を集計する
		String leadQuery1 = ' Select DAY_ONLY(convertTimezone(EntryTime__c)) cidate, ' +
						 ' SUM(StayPersons__c) stayPerson, ' +
						 ' SUM(SumHiru__c) hiruNums, ' + 
						 ' SUM(SumYoru__c) yoruNums, ' +
						 ' SUM(SumIN__c)   checkInNums, ' +
						 //' SUM(SumOUT__c)  checkOutNums, ' +
						 ' SUM(SumSTAY__c) stayNums ' +
						 ' From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
						 ' And ( 	RecordTypeId = :bookRecTypeId ' +
						 ' 		Or 	RecordTypeId = :baseRecTypeId ' +
						 ' ) ';		// 基本、宿泊レコードタイプ予約データ
		if (!CommUtils.isBlank(branchShopNm)) leadQuery1 += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
			leadQuery1 += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopSt ';
		}
		// 2015/09/01 多店舗機能対応 END
		leadQuery1 += 	 ' Group By DAY_ONLY(convertTimezone(EntryTime__c)) ';
//System.debug(LoggingLevel.INFO, 'leadQuery1:::' + leadQuery1);
		Map<Date, SummaryInfo> bookingInfoMap = new Map<Date, SummaryInfo>();
		for (AggregateResult enkaiRs : DataBase.query(leadQuery1)) {
			//bookingInfoMap.put
			SummaryInfo summaryItem = new SummaryInfo('0');
			summaryItem.stayPeoples = CommUtils.nullToIntZero(enkaiRs.get('stayPerson'));
			summaryItem.noonStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('hiruNums')));
			summaryItem.nightStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('yoruNums')));
			summaryItem.inStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('checkInNums')));
			//summaryItem.outStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('checkOutNums')));
			summaryItem.stayStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('stayNums')));
			bookingInfoMap.put((Date)enkaiRs.get('cidate'),summaryItem);
		}
        // 客室の予約情報を集計する[OUT]情報集計する
		String leadQuery1_1 = ' Select DAY_ONLY(convertTimezone(Departure__c)) codate, ' +
						 ' SUM(SumOUT__c)  checkOutNums ' +
						 ' From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(Departure__c)) >= :startDate ' +
						 ' And DAY_ONLY(convertTimezone(Departure__c)) <= :endDate ' +
						 ' And refTypeOfRooms__r.ActionType__c = :roomTypeNormalFlg ' +
						 ' And ( 	RecordTypeId = :bookRecTypeId ' +
						 ' 		Or 	RecordTypeId = :baseRecTypeId ' +
						 ' ) ';		// 基本、宿泊レコードタイプ予約データ
		if (!CommUtils.isBlank(branchShopNm)) leadQuery1_1 += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
			leadQuery1_1 += ' And refTypeOfRooms__r.ShopInfoRef__r.ShopCode__c = :shopSt ';
		}
		// 2015/09/01 多店舗機能対応 END
		leadQuery1_1 += ' Group By DAY_ONLY(convertTimezone(Departure__c)) ';
//System.debug(LoggingLevel.INFO, 'leadQuery1_1:::' + leadQuery1_1);
//System.debug(LoggingLevel.INFO, 'startDate:' + startDate);
//System.debug(LoggingLevel.INFO, 'endDate:' + endDate);
		for (AggregateResult enkaiRs : DataBase.query(leadQuery1_1)) {
			Date coDate = (Date)enkaiRs.get('codate');
			SummaryInfo summaryItem = bookingInfoMap.containsKey(coDate) ? bookingInfoMap.get(coDate) : new SummaryInfo('0');
			summaryItem.outStatus = String.valueOf(CommUtils.nullToIntZero(enkaiRs.get('checkOutNums')));
			bookingInfoMap.put(coDate, summaryItem);
		}
		
		// 宴会場予約情報を集計する
		String leadQuery2 = ' Select Rroom__c roomId, ' +
						 ' DAY_ONLY(convertTimezone(EntryTime__c)) cidate,' +
						 ' SUM(StayPersons__c) stayPerson, ' +
						 ' SUM(SumEnkaiHiru__c) hiruNums, ' + 
						 ' SUM(SumEnkaiYoru__c) yoruNums ' +
						 ' From Lead__c ' +
						 ' Where CancelBool__c != :leadCancelFlg ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDate ' +
						 ' And DAY_ONLY(convertTimezone(EntryTime__c)) <= :endDate ' +
						 ' And RecordTypeId = :enkaRecTypeId '; // 宴会場のレコードタイプ予約データ
		if (!CommUtils.isBlank(branchShopNm)) leadQuery2 += ' And Rroom__r.ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 2015/09/01 多店舗機能対応 BEGIN
		else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
			leadQuery2 += ' And Rroom__r.ShopInfoRef__r.ShopCode__c = :shopSt ';
		}
		// 2015/09/01 多店舗機能対応 END
		leadQuery2 += 	 ' Group By Rroom__c, DAY_ONLY(convertTimezone(EntryTime__c)) ';
//System.debug(LoggingLevel.INFO, 'leadQuery2:::' + leadQuery2);
		// Map<部屋ID_日付, 件数>
		Map<String, SummaryInfo> enkaiInfoMap = new Map<String, SummaryInfo>();
		for (AggregateResult enkaiRs : DataBase.query(leadQuery2)) {
			String key = ((Id)enkaiRs.get('roomId')) + '_' + ((Date)enkaiRs.get('cidate'));
			// 宴会場の集計情報を格納する
			SummaryInfo summaryItem = new SummaryInfo();
			summaryItem.stayPeoples = CommUtils.nullToIntZero(enkaiRs.get('stayPerson'));
			if ( CommUtils.nullToIntZero(enkaiRs.get('hiruNums')) > 0)  summaryItem.noonStatus = '◯';
			if ( CommUtils.nullToIntZero(enkaiRs.get('yoruNums')) > 0)  summaryItem.nightStatus = '◯';
			enkaiInfoMap.put(key, summaryItem);
		}
/*
For (SummaryInfo summaryItem : enkaiInfoMap.values()) {
System.debug(LoggingLevel.INFO, 'enkaiInfoMap:::' + summaryItem);
}
*/		
		// 日付配列を取得する
		while (startDate <= endDate) {
			
		    // 週単位データ追加する
			// 一週間予約データ情報を格納する
			WeekInfo newWeek = new WeekInfo();
			// 7日単位で情報を設定する
			for (Integer i =0; i<7; i++) {
				DayInfo day = new DayInfo(startDate, thisMonth);
				// 祝日判別
				if (holidayMap.containsKey(startDate)) day.isHoliday = true;
				if (day.isHoliday) day.holidayStr = holidayMap.get(startDate);
				// 祝日以外の場合、土曜日、日曜日
				// Tier情報を設定する
				if (tierMap.containsKey(startDate)) day.tierString = tierMap.get(startDate);
				// 該当曜日にご客室予約集計情報を設定する
				if (bookingInfoMap.containsKey(startDate)) {
					day.bookingSummaryInf = bookingInfoMap.get(startDate);
				} else {
					day.bookingSummaryInf = new SummaryInfo('0');
				}
				// 宴会場情報を設定する
				for (Room__c room : enkaiRooms) {
					// 該当部屋と日付を集計情報を取得設定を行う
					String key = room.Id + '_' + startDate;
					SummaryInfo item = enkaiInfoMap.get(key);
					if (item == null) item = new SummaryInfo();
					item.roomName = room.Name;
					day.enKaiInfLst.add(item);
				}
				
				//day.
				newWeek.days.add(day);
				// 翌日設定
				startDate = startDate.addDays(1);
			}
			weeks.add(newWeek);
		}

		// ダウンロード関連情報を初期化する
		if (appOptionVal == APP_OPTIONS.FILEDOWNLOAD.name()) {
			getDownloadInfo(branchShopNm, weeks);
		// 2018/08/28 献立表項目追加 by zy BEGIN
		} else if (appOptionVal == APP_OPTIONS.DINNER.name()) {
			dinnerData(beginDt,endDate);
		// 2018/08/28 献立表項目追加 by zy END
		}
	}
	
	// ダウンロード関連情報を取得関数
	public Map<String, Document[]> pcaDlSourceMap{get; private set;}	// Map<'yyyy/MM/dd', Document[]>
	private void getDownloadInfo (String branchShopCd, List<WeekInfo> pWeeks) {
		Date locStartDt = CommUtils.stringToDate(pWeeks[0].days[0].dayString);
		Date locEndDt = CommUtils.stringToDate(pWeeks[pWeeks.size()-1].days[6].dayString);
		// 初期化
		pcaDlSourceMap = new Map<String, Document[]>();
		// PCA抽出のフォルダ
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) BEGIN
		//List<Folder> fs = [select Id from Folder where DeveloperName = 'SyncFiles'];
		List<Folder> fs = CommNoAuthLimitUtil.getFolderId('SyncFiles');
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) END
		if (fs.isEmpty()) return;
		Id syncFolderId = fs[0].Id;
		// 2015/09/01 多店舗機能対応 BEGIN
		//String fileName = CommUtils.isBLank(branchShopCd) ? '' : '%_' + branchShopCd + '(%';
		String subWhere = '';
		if (CommUtils.isBlank(branchShopCd)) {
			// 兼務の場合、指定範囲の店舗のファイルのみダウンロードできる
			UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
			if (userInf.isShopCodePlex) {
				subWhere = ' And ( ';
				List<String> shops = userInf.shops;
				for (String shopCode : shops) {
					subWhere+=' Name like \'%_' + shopCode + '(%\' OR';
				}
				subWhere = subWhere.removeEnd('OR');
				subWhere += ' )';
			}
		} else {
			// 2017/02/08 PortalSecurity 対応 zyz BEGIN
			subWhere+= ' And Name like \'%_' + String.escapeSingleQuotes(branchShopCd) + '(%\'';
			// 2017/02/08 PortalSecurity 対応 zyz END
		}
		// 2015/09/01 多店舗機能対応 END
		// 検索SQL
		String queryStr = ' SELECT Id, FolderId, Name, Type, BodyLength, Description, CreatedDate, CreatedById, LastModifiedDate FROM Document ';
		String whereStr = ' where FolderId = :syncFolderId ';
		// 2015/09/01 多店舗機能対応 BEGIN
		//if (!CommUtils.isBlank(fileName)) whereStr += ' And Name like :fileName ';
		if (!CommUtils.isBlank(subWhere)) whereStr += subWhere;
		// 2015/09/01 多店舗機能対応 END
		// 2015/12/04 ファイル名により、取得ファイル範囲条件を変更する BEGIN
		//whereStr += ' and DAY_ONLY(convertTimezone(CreatedDate)) <= :locEndDt and DAY_ONLY(convertTimezone(CreatedDate)) >= :locStartDt';
		whereStr += ' and ((DAY_ONLY(convertTimezone(CreatedDate)) <= :locEndDt and DAY_ONLY(convertTimezone(CreatedDate)) >= :locStartDt) ';
		whereStr += '   OR (';
		// 表示期間に関連の年月情報
		Date logicDate = locStartDt;
		List<String> monthKeyLst = new list<String>();
		while (logicDate <= locEndDt) {
			logicDate = logicDate.toStartOfMonth();
			DateTime formatDt = DateTime.newInstance(logicDate.year(),logicDate.month(),logicDate.day());
			monthKeyLst.add(formatDt.format('yyyyMM'));
			logicDate = logicDate.addMonths(1);
		}
		for (String monthKey : monthKeyLst) {
			whereStr += ' Name like \'%_'+monthKey+'%\' OR';
		}
		whereStr = whereStr.removeEnd('OR') + ')) ';
		// 2015/12/04 ファイル名により、取得ファイル範囲条件を変更する END
		String otherStr = ' order by CreatedDate DESC ';
		queryStr += whereStr + otherStr;
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) BEGIN
		//List<Document> sr = Database.query(queryStr);
		List<Document> sr = CommNoAuthLimitUtil.getFiles(syncFolderId,locStartDt,locEndDt,queryStr);
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) END
//System.debug(loggingLevel.INFO, 'queryStr:::p1:' + queryStr);
//System.debug(loggingLevel.INFO, 'getDownloadInfo:::p1:' + syncFolderId);
//System.debug(loggingLevel.INFO, 'getDownloadInfo:::p2:' + fileName)	;
//System.debug(loggingLevel.INFO, 'getDownloadInfo:::p3:' + locStartDt)	;
//System.debug(loggingLevel.INFO, 'getDownloadInfo:::p4:' + locEndDt);
		Map<String, List<Document>> locDsMap = new Map<String, List<Document>>();
		// 2015/11/19 各種類ファイルは最新ファイルのみダウンロード画面に表示機能対応
		Set<String> firstPrixSet = new Set<String>();
		for (Document doc : sr) {
			// 2015/12/04 ファイル名表示ロジック変更 BEGIN
			//String key = doc.createdDate.format('yyyy/MM/dd');
			// 2015/12/16 口座情報はこよみ画面から表示対象外 BEGIN
			if (doc.name.startsWith(InfoOutputProcessCtrl.PrefixKey)) continue;
			// 2015/12/16 口座情報はこよみ画面から表示対象外 END
			// 日付は違うと、新ネーミングルールで対応する
			String nameKey = doc.name.mid(doc.name.indexOf('_')+1,8);
			Date fileDate = CommUtils.stringToDate(nameKey);
			String key = DateTime.newInstance(fileDate.year(),fileDate.month(),fileDate.day()).format(CommBaseCtrl.getDateFormat());
			// firstPrix = 'YYYY/MM/DD_PCA/BANK/FREEE/XXXX_CSV/TXT'
			// 2015/12/04 ファイル名表示ロジック変更 END
			
			integer prefixPos = doc.name.indexOf('_');
			integer endfixPos = doc.name.lastIndexOf('.')+1;
			String firstPrix = key + '_' + doc.name.mid(0,prefixPos) + '_' + doc.name.mid(endfixPos, (doc.name.length() - endfixPos));
			if(!firstPrixSet.contains(firstPrix)){ 
				firstPrixSet.add(firstPrix);
			} 
			else continue;
			if (!locDsMap.containsKey(key)) {
				locDsMap.put(key, new List<Document>());
			}
			locDsMap.get(key).add(doc);
		}
		for (WeekInfo week : pWeeks) {
			for (DayInfo day : week.days) {
				if (locDsMap.containsKey(day.dayString)) {
					pcaDlSourceMap.put(day.dayString, locDsMap.get(day.dayString));
				} else {
					pcaDlSourceMap.put(day.dayString, new List<Document>());
				}
			}
		}
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) BEGIN
		//for (List<Document> docs : pcaDlSourceMap.values()) {
		for (String key : pcaDlSourceMap.keyset()) {
			List<Document> wkLst = pcaDlSourceMap.get(key);
			List<String> nameLst = new List<String>();
			map<String,Document> sortMap = new Map<String, Document>();
			for (Document doc : wkLst) {
				nameLst.add(doc.Name);
				sortMap.put(doc.Name, doc);
			}
			nameLst.sort();
			wkLst.clear();
			for (integer i = nameLst.size()-1; i >= 0; i--) {
				wkLst.add(sortMap.get(nameLst[i]));
			}
		}
		// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) END
	}

	// 画面に表示する部屋リストを設定する
	private void setShowRooms () {
        String roomQuery = ' select Id, Name, UseOfRoom__c, Seq__c from Room__c where UseOfRoom__c =: ROOM_TYPE_PTY  ';
        // 2015/09/01 多店舗機能対応 BEGIN
        if (!CommUtils.isBlank(branchShopNm)) {
            roomQuery+= ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
        }else if (userInf.isShopCodePlex) {
            Set<String> shopSt = userInf.shopSt;
            roomQuery+= ' And ShopInfoRef__r.ShopCode__c = :shopSt ';
        }
        // 2015/09/01 多店舗機能対応 END
		roomQuery += ' order by Seq__c ';
		enkaiRooms = DataBase.query(roomQuery);
	}
	
    // ************************
    // 支店選択リスト
    // ************************
	private Map<String,ShopInformation__c> shopInfoMap;
    public List<SelectOption> branchShopLst{get; private set;}
    public String branchShopNm{get; set;}
    private UserUtil.UserShopInfo userInf;
    private void setInitBranShopLst() {
    	userInf = UserUtil.CurrentUserInfo;
    	branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        shopInfoMap   = ShopInfoUtil.getShopInfoMap(userInf.shops);
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
        // 2018/08/28 献立表項目追加 by zy BEGIN
		if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
			String spcd = ApexPages.currentPage().getParameters().get('spcd');
			branchShopNm = CommUtils.nullToBlank(spcd);
		}
		// 2018/08/28 献立表項目追加 by zy END
    }
    // ************************
    // 機能OPTIONリスト定義する
    // ************************
    public List<SelectOption> appOptionsLst{get; private set;}
    public String appOptionVal{get; set;}
    // 2018/08/28 献立表項目追加 by zy BEGIN
    public enum APP_OPTIONS{CALENDAR,EVENT,REVEEVENT,MESSAGE,FILEDOWNLOAD,DINNER}
    // 2018/08/28 献立表項目追加 by zy END
    public Boolean isAppOptFileDownload{get{return appOptionVal == APP_OPTIONS.FILEDOWNLOAD.name();} }
    private void setinitAppOptions() {
    	// 初期値設置を行う
    	appOptionVal = APP_OPTIONS.FILEDOWNLOAD.name();
    	// 2018/08/28 献立表項目追加 by zy BEGIN
		if (ApexPages.currentPage().getParameters().containsKey('mode')) {
			String mode = ApexPages.currentPage().getParameters().get('mode');
			if (!CommUtils.isBlank(mode)) appOptionVal = mode;
		}
		// 2018/08/28 献立表項目追加 by zy END
    	appOptionsLst = new List<SelectOption>();
    	//こよみ
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.CALENDAR.name()	, Label.CONST_012_0435));
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.EVENT.name()		, 'MashUpEvent'));
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.REVEEVENT.name()	, 'RevenueCalender'));
    	//連絡事項
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.MESSAGE.name()	, Label.CONST_012_0436));
    	//ダウンロード
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.FILEDOWNLOAD.name(), Label.CONST_012_0437));
    	// 2018/08/28 献立表項目追加 by zy BEGIN
    	//献立表
    	appOptionsLst.add(new SelectOption(APP_OPTIONS.DINNER.name(), '献立表'));
    	// 2018/08/28 献立表項目追加 by zy END
    }
	/**
	*　料金表関連デイフォル値
	**/
	private String getDefTier(String shopCd) {
		if (shopInfoMap.containsKey(shopCd)) {
			return 	CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
					? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
					: CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
		} else {
			return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
		}
	}
	
	// 予約のレコードタイプ
	private id bookRecTypeId;	// 基本レコードタイプ
	private id baseRecTypeId;	// 基本レコードタイプ
	private id enkaRecTypeId;	// 宴会場レコードタイプ
    private void initLeadRecType () {
		bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	    baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	    enkaRecTypeId = CommLogicProcess.getLeadEnkaiRecType();
    }
    
    // 週単位情報を格納する
	public class WeekInfo {
		public WeekInfo() {
			days = new List<DayInfo>();
		}
		// 週間集計情報を格納する
		public List<DayInfo> days{get;private set;}
	}
	
	// 日単位の情報を格納する
	public class DayInfo {
		public DayInfo(Date dt, Integer month) {
			enKaiInfLst = new List<SummaryInfo>();
			dayNum = dt.day();
			if (dt == Date.today())	cssClassName = 'calToday';
			else if(dt.month() != month) cssClassName = 'calInactive';
			else cssClassName = 'calActive';
			isHoliday = false;
			holidayStr = '';
			DateTime formatDt = DateTime.newInstance(dt.year(), dt.month(), dt.day());
			dayString = formatDt.format(CommBaseCtrl.getDateFormat());
			String weekStr = formatDt.format('E');
			if (weekStr == 'Sat' || weekStr == 'Sun') isHoliday = true;
			// 2018/08/28 献立表項目追加 by zy BEGIN
			cookinfos = new List<CookInfo>();
			// 2018/08/28 献立表項目追加 by zy END
		}
		// 日付
		public Integer dayNum{get;set;}
		public String dayString{get;set;}
		// 日付CSS
		public String cssClassName{get;set;}
		//calActive
		// 該当日の総予約人数
		/*
		public Integer sumStayPeoples{get{
			Integer peoples = bookingSummaryInf.stayPeoples;
			for (SummaryInfo inf : enKaiInfLst) {
				peoples += inf.stayPeoples;
			}
			return peoples;
		}}*/
		public Integer enakStayPeoples{get{
			Integer peoples = 0;
			for (SummaryInfo inf : enKaiInfLst) {
				peoples += inf.stayPeoples;
			}
			return peoples;
		}}
		// Tier
		public String tierString{get;set;}
		// 宴会場集計情報格納
		public List<SummaryInfo> enKaiInfLst{get;set;}
		// 客室集計情報を格納する
		public SummaryInfo bookingSummaryInf{get;set;}
		// 祝日がどうか判別用
		public Boolean isHoliday{get;set;}
		public String holidayStr{get;set;}
		// 2018/08/28 献立表項目追加 by zy BEGIN
		// 会席リスト情報
		public List<CookInfo> cookinfos{get;set;}
		// 2018/08/28 献立表項目追加 by zy END
	}
	// 一行目の「昼/夕/OUT/IN/STAY」情報格納
	public class SummaryInfo {
		
		public SummaryInfo() {
			noonStatus = nightStatus = outStatus = inStatus = stayStatus = '-';
			stayPeoples = 0;
		}
		public SummaryInfo(String strMark) {
			noonStatus = nightStatus = outStatus = inStatus = stayStatus = strMark;
			stayPeoples = 0;
		}
		public String roomName{get;set;}
		public Integer stayPeoples{get;set;}
		public String noonStatus{get;set;}
		public String nightStatus{get;set;}
		public String outStatus{get;set;}
		public String inStatus{get;set;}
		public String stayStatus{get;set;}
	}
	// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) BEGIN
	private boolean isNoAuth(String shopCode) {
		// XML READ
		String xmlConfigName = 'BatchRequstConfigXml';
		Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(xmlConfigName, shopCode);	
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 BEGIN
		Dom.XmlNode noauthField =  shopRoot.getChildElement('NOAUTH', null);
		if (noauthField != null) {
			Boolean isNoAuthFlg = false;
			String noAuthStr = CommUtils.nullToBlank(noauthField.getText());
			if (!CommUtils.isBlank(noAuthStr)) isNoAuthFlg = Boolean.valueOf(noAuthStr);
			return isNoAuthFlg;
		}
		return false;
		// 2018/08/22 一般ユーザーでも作業できるように改善対応 END
	}
	// 2018/08/22 一般ユーザーでも作業できるように改善対応(仕訳ファイルをダウンロードできる) END
	// 2018/08/28 献立表項目追加 by zy BEGIN
	// 献立の場合
	public Boolean isDinnerFlag{get{return appOptionVal == APP_OPTIONS.DINNER.name();} }
	// 献立の情報作成
	public void dinnerData(Date startDt,Date endDt){
		String startFormat = startDt.format();
		String endFormat = endDt.format();
		String mealQuery = 'select id,AccountMasterRef__c,MealDateKey__c,ShopCode__c from MealDetail__c where MealDateKey__c >= :startFormat and MealDateKey__c <=:endFormat';
		// 店舗条件
		// 2019/09/15 Security Check BY wsq BEGIN
		//if (!CommUtils.isBlank(branchShopNm))  mealQuery += ' And (ShopCode__c like \'%' + branchShopNm + ';%\' or ShopCode__c=null)';
		if (!CommUtils.isBlank(branchShopNm))  mealQuery += ' And (ShopCode__c like \'%' + String.escapeSingleQuotes(branchShopNm) + ';%\' or ShopCode__c=null)';
		// 2019/09/15 Security Check BY wsq END
		// 献立情報取得
		List<MealDetail__c> mealDetails = dataBase.query(mealQuery);
		Set<Id> prodIds = new Set<Id>();
		Map<String,List<MealDetail__c>> mealMap = new Map<String,List<MealDetail__c>>();
		Map<string,AccountMaster__c> accMap = new Map<string,AccountMaster__c>();
		Map<String,List<FoodDetail__c>> breakDownMap = new Map<String,List<FoodDetail__c>>();
		// 献立情報あり
		for (MealDetail__c meal : mealDetails) {
			String dtKey = meal.MealDateKey__c;
			if (!mealMap.containsKey(dtKey)) mealMap.put(dtKey,new List<MealDetail__c>());
			mealMap.get(dtKey).add(meal);
			prodIds.add(meal.AccountMasterRef__c);
		}
		// 該当献立料理明細参照会計商品取得
		for (AccountMaster__c acc : [select id,Materials__c,Allergy__c,name,Protein__c,Lipid__c,Carbohydrate__c,Calorie__c from AccountMaster__c where id=:prodIds]){
			accMap.put(acc.id,acc);
		}
		Set<String> detailSet = new Set<String>();
		Date todayDt = system.today();
		// 会計商品の料理ブレイクあり
		for (FoodDetail__c food : [select id,BreakName__c,DetailType__c,AccountMasterRef__c,AccountMasterSubRef__c,AccountMasterSubRef__r.name from FoodDetail__c where AccountMasterRef__c =:prodIds order by OrderNo__c]) {
			if (!breakDownMap.containsKey(food.AccountMasterRef__c)) breakDownMap.put(food.AccountMasterRef__c,new List<FoodDetail__c>());
			breakDownMap.get(food.AccountMasterRef__c).add(food);
		}
		// 料理、会計商品情報更新
		for (WeekInfo info : weeks) {
			for (DayInfo day : info.days) {
				if (mealMap.containsKey(day.dayString)) {
					List<MealDetail__c> meals = mealMap.get(day.dayString);
					for (MealDetail__c meal : meals) {
						day.cookinfos.add(new CookInfo(accMap.get(meal.AccountMasterRef__c),breakDownMap.get(meal.AccountMasterRef__c)));
					}
				}
			}
		}
	}
	// 料理情報
	public class CookInfo{
		// 会計商品
		public AccountMaster__c acc{get;set;}
		// 料理ブレイク
		public List<FoodDetail__c> foods{get;set;}
		public CookInfo(AccountMaster__c account,List<FoodDetail__c> details){
			acc = account;
			foods = new List<FoodDetail__c>();
			if (details != null) foods = details;
		}
	}
	// 2018/08/28 献立表項目追加 by zy END
}