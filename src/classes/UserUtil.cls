/**
* ユーザー情報Memoryに格納する
* 
**/
global with sharing class UserUtil {
//Protected Members
// 2019/02/28 性能改善対応 WSQ BEGIN
//private static final UserUtil instance = new UserUtil();
private static UserUtil instance;
// 2019/02/28 性能改善対応 WSQ END
private Map<Id, User> mapUsers;

//Properties
public static User CurrentUser {get { return getUser(UserInfo.getUserId()); }}
public static UserShopInfo CurrentUserInfo{get{return getUserInfo(UserInfo.getUserId());}}

//Constructor
private UserUtil() {
    mapUsers = new Map<Id, User>(queryUsers());
}

//Public Methods
public static User getUser(Id userId) {
	// 2019/02/28 性能改善対応 WSQ BEGIN
	if (instance == null) instance = new UserUtil();
	// 2019/02/28 性能改善対応 WSQ END
    if (instance.mapUsers.containsKey(userId)) {
    	User u = instance.mapUsers.get(userId).clone(true,true);
    	String shopCode = u.ShopCode__c;
    	if(!CommUtils.isBlank(shopCode)){
			String[] shopMessage  = shopCode.split(',');
			if(shopMessage.size() > 0){
				String defualtCode = '';
				for(String shopCodeStr : shopMessage){
					if(shopCodeStr.indexOf(':') > 0){
						defualtCode = shopCodeStr.split(':')[0];
						u.ShopCode__c = defualtCode;
					}
				}
				if(CommUtils.isBlank(defualtCode))
					u.ShopCode__c = shopMessage[0];
			}
		}
        return u;
        //instance.mapUsers.get(userId);
    }
    else {
        throw new CommException('Unable to locate user id: ' + userId);
    }
}
public static UserShopInfo getUserInfo(Id userId){
	// 2019/02/28 性能改善対応 WSQ BEGIN
	if (instance == null) instance = new UserUtil();
	// 2019/02/28 性能改善対応 WSQ END
	if (instance.mapUsers.containsKey(userId)) {
        return new UserShopInfo(instance.mapUsers.get(userId).clone(true,true));
    }
    else {
        throw new CommException('Unable to locate user id: ' + userId);
    }
}
public class UserShopInfo{
	public User u;
	public List<String> shops;
	public String defaultShopCode;
	public Boolean isShopCodePlex;
	public Set<String> shopSt;
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
	public boolean hadRoomFlg;
	public boolean hadTaskFlg;
	public boolean hadTimeTable;
	// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	public UserShopInfo(User user){
		u = user;
		defaultShopCode = '';
		String shopCode = u.ShopCode__c;
		shops = new List<String>();
		shopSt = new Set<String>();
		isShopCodePlex = false;
		if(!CommUtils.isBlank(shopCode)){
			String[] shopMessage  = shopCode.split(',');
			if(shopMessage.size() > 1) isShopCodePlex = true;
			if(shopMessage.size() > 0){
				for(String shopCodeStr : shopMessage){
					if(shopCodeStr.indexOf(':') >= 0){
						defaultShopCode = shopCodeStr.split(':')[0];
						shops.add(defaultShopCode);
						shopSt.add(defaultShopCode);
					}else{
						shops.add(shopCodeStr);
						shopSt.add(shopCodeStr);
					}
				}
			if(CommUtils.isBlank(defaultShopCode))
				defaultShopCode = shopMessage[0];
			}
		}
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
		String readOnlyMsg = CommUtils.nullToBlank(u.ReadOnlyLst__c);
		hadRoomFlg = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_ROOMINDICATOR);
		hadTimeTable = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_ROOMSCHEDULE);
		hadTaskFlg = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_TASK);
		// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	}
}
//Private Methods
private List<User> queryUsers() {
    return [SELECT 
                Id
                , Name
                , UserName
                , ShopCode__c
				, OutRestTimeUnit__c
				, OutRestCalMethodType__c
				, BeginTimeUnit__c
				, BeginTimeCalMethodType__c
				, TimeUnit__c
				, CalMethodType__c
				, RestTimeUnit__c
				, RestCalMethodType__c
                , CompanyName
                , Department
                , Title
                , Street
                , City
                , State
                , PostalCode
                , Country
                , Email
                , Phone
                , Fax
                , MobilePhone
                , Alias 
                , RestMinuteIsMinusFlg__c
                , BookingFlexAppLayoutNo__c
                , EmployeeCode__c
                , UserRole.name
                // 2018/07/30 清掃状態リスト追加 by zy BEGIN
                ,NoEditCleanStatusFlg__c
                // 2018/07/30 清掃状態リスト追加 by zy END
				// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
				, ReadOnlyLst__c
				// 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
            FROM 
                User
            Limit 5000];
}
// ログインユーザの通貨設定情報
webservice static String getDefaultCurrency() {
	String locCurrency = UserInfo.getDefaultCurrency();
	if (locCurrency == null) locCurrency = 'JPY';
	return locCurrency;
}
// 2018/05/08 請求書のコメント欄を毎回手打ちし自動 zyz BEGIN
webservice static String[] getDefaultCurrencyAndBillComment() {
	String[] rs = new String[]{'',''};
	String locCurrency = UserInfo.getDefaultCurrency();
	if (locCurrency == null) locCurrency = 'JPY';
	rs[0] = locCurrency;
	rs[1] = CommentHelperCompCtrl.getBillCommentJson();
	return rs;
}
// 2018/05/08 請求書のコメント欄を毎回手打ちし自動 zyz END
// ログインユーザの使っている言語情報を取得する
webservice static String getDefaultLanguage() {
	String lng = UserInfo.getLanguage();
	if (CommUtils.isBlank(lng)) lng = 'ja';
	return lng;
}
// 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
webservice static String getAccSpCd(String userId) {
	// DBから設定情報を取得する
	map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
	String accSpCdKey = UserConfigCompCtrl.KREP_SUBTYPE.ACCSPCD.name();
	if (userConfigMap.containsKey(accSpCdKey)) {
		return CommUtils.nullToBlank(userConfigMap.get(accSpCdKey));
	}
	return '';
}
webservice static String getBillSpCd(String userId) {
	// DBから設定情報を取得する
	map<string,string> userConfigMap = UserConfigCompCtrl.getKrepConfig(userId, '');
	String billSpCdKey = UserConfigCompCtrl.KREP_SUBTYPE.BILLSPCD.name();
	if (userConfigMap.containsKey(billSpCdKey)) {
		return CommUtils.nullToBlank(userConfigMap.get(billSpCdKey));
	}
	return '';
}
// 2018/03/30 会計書の店舗切替を保存 WGCH END
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
	private static final String REC_TYPE_C = '口座情報';
	public static Map<String, List<FixedMessage>> getFixedMsg(List<String> lstSpcd) {
		Set<String> shopCodeSet = new Set<String>{NULL};
		if(!lstSpcd.isEmpty()) shopCodeSet.addAll(lstSpcd);
		Map<String, List<FixedMessage>> result = new Map<String, List<FixedMessage>>();
		String sQuery = 
			' SELECT FixedMessage__c,'
				+ ' RecTypeLst__c,'
				+ ' ShopCode__c,'
				+ ' Label,'
				+ ' Default__c,'
				+ ' MasterLabel'
			+ ' FROM CommComentDef__mdt'
			+ ' WHERE RecTypeLst__c = :REC_TYPE_C'
			+ ' AND ShopCode__c = :shopCodeSet'
			+ ' ORDER BY MasterLabel';
		List<CommComentDef__mdt> lstFixedMsg = Database.query(sQuery);
		for(CommComentDef__mdt mdt : lstFixedMsg) {
			mdt.ShopCode__c = CommUtils.nullToBlank(mdt.ShopCode__c);
			if(!result.containsKey(mdt.ShopCode__c)) result.put(mdt.ShopCode__c, new List<FixedMessage>());
			result.get(mdt.ShopCode__c).add(new FixedMessage(mdt.Label, mdt.FixedMessage__c, mdt.Default__c));
		}
		return result;
	}
	
	class FixedMessage {
		String Label;
		String Msg;
		Boolean bDefault;
		public FixedMessage(String Label, String Msg, Boolean bDefault) {
			// 2019/06/17 口座情报定型文设定为空，显示null问题对应 BY zyz BEGIN
			this.Label = CommUtils.nullToBlank(Label);
			this.Msg = CommUtils.nullToBlank(Msg);
			// 2019/06/17 口座情报定型文设定为空，显示null问题对应 BY zyz END
			this.bDefault = bDefault;
		}
	}
	
	webservice static String getFixedMsgJSON(String jsonText) {
		List<String> lstShopCode = (List<String>)JSON.deserialize(jsonText, List<String>.class);
		return JSON.serialize(getFixedMsg(lstShopCode));
	}
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
	// 2019/03/28 請求書一括印刷機能対応 WGCH BEGIN
	private static List<CommComentDef__mdt> getMdtData(Set<String> shopcdSet){
		String sQuery = ' SELECT FixedMessage__c, RecTypeLst__c, ShopCode__c, Label, Default__c, MasterLabel FROM CommComentDef__mdt ';
		String wQuery = ' WHERE RecTypeLst__c =: REC_TYPE_C AND ShopCode__c =: shopcdSet ';
		String oQuery = ' ORDER BY MasterLabel';
		return Database.query(sQuery + wQuery + oQuery);
	}
	public static FixedMessageInfo getFixedMsgInfo(String shopcd) {
		return getFixedMsgInfo(new Set<String>{shopcd});
	}
	// 获取定型文口座情報Info
	public static FixedMessageInfo getFixedMsgInfo(Set<String> shopcdSet) {
		// 目的把未设置店铺的数据查处理(未设置店铺code的数据任何店铺都可以用)
		shopcdSet.add('');
		FixedMessageInfo fmInfo = new FixedMessageInfo();
		for(CommComentDef__mdt mdt : getMdtData(shopcdSet)) {
			// 数据 in the class
			FixedMessageItem fmItem= new FixedMessageItem(mdt);
			// 定型文->口座情報数据选中默认值设定处理,如果多个默认值按第一个为准
			if(!fmInfo.fixedDef && fmItem.def){
				fmInfo.fixedMsg = fmItem.key;
				fmInfo.fixedDef = fmItem.def;
			}
			// List<定型文->口座情報数据Lst>
			fmInfo.fixedMsgLst.add(fmItem);
			// List<key:定型文字段; lab:表示ラベル>
			fmInfo.fixedMsgOpts.add(new SelectOption(fmItem.key, fmItem.lab));
			// Map<店铺code, 定型文->口座情報数据Lst>
			String shopcd = CommUtils.nullToBlank(mdt.ShopCode__c);
			if(!fmInfo.fixedMsgMap.containsKey(shopcd)) fmInfo.fixedMsgMap.put(shopcd, new List<FixedMessageItem>());
			fmInfo.fixedMsgMap.get(shopcd).add(fmItem);
		}
		return fmInfo;
	}
	public class FixedMessageItem{
		public String key;
		public String lab;
		public Boolean def;
		public FixedMessageItem(CommComentDef__mdt mdt) {
			key = CommUtils.nullToBlank(mdt.FixedMessage__c);
			lab = CommUtils.nullToBlank(mdt.Label);
			def = mdt.Default__c; // to: 设置多个默认值咋处理的
		}
	}
	public class FixedMessageInfo{
		public String fixedMsg; // 选中默认值
		public Boolean fixedDef; // 默认值设定标识
		public List<FixedMessageItem> fixedMsgLst; // List<定型文->口座情報数据Lst>
		public List<SelectOption> fixedMsgOpts; // List<key:定型文字段; lab:表示ラベル>
		public Map<String, List<FixedMessageItem>> fixedMsgMap; // Map<店铺code, 定型文->口座情報数据Lst>
		public FixedMessageInfo(){
			fixedMsg = '';
			fixedDef = false;
			fixedMsgLst = new List<FixedMessageItem>();
			fixedMsgOpts = new List<SelectOption>();
			fixedMsgMap = new Map<String, List<FixedMessageItem>>();
		}
	}
	// 2019/03/28 請求書一括印刷機能対応 WGCH END
	// 2019/02/28 ユーザ「デイフォル店舗コード」項目を自動設定機能 FUTURE BEGIN
	@future
	public static void syncShopcodeToDefShopCode() {
		// 複数店舗　かつ　ユーザ「デイフォル店舗コード」項目が空白場合、自動設定機能を有効になる
		Boolean isNoneShop = ShopInfoUtil.getShopInfoMap().isEmpty();
		// 無店舗の場合、個別設定不要
		if (isNoneShop) return;
		// 複数店舗の場合、ユーザ「デイフォル店舗コード」項目が空白データを取得する
		List<User> wkUser = [select ShopCode__c,DefaultShopCode__c from User where DefaultShopCode__c = null and ShopCode__c != null and IsActive = true];
		if (wkUser.isEmpty()) return;
		database.update(wkUser, false);
	}
	// 2019/02/28 ユーザ「デイフォル店舗コード」項目を自動設定機能 FUTURE END
	// 2020/04/30 予約の確認メールの自動送付機能 BY zyz BEGIN
	// 予約新規・変更際に、選択した予約の送信済みデータ存在チェックを行う
	// 予約キャンセル通知場合、選択した予約に有効予約存在、または　送信済みデータが存在チェックを行う
	// isCheckFlg: 実施チェックロジックから呼び出す場合(TRUE:チェックロジックから)
	private static map<Id, map<String, list<lead__c>>> getTargetLeads (List<Id> leadids, XmlConfig config, Boolean isProcessFlg) {
		// 選択した予約のみ送信する　	
		list<Lead__c> orgLeadList = [select Id,LeadIndexRef__c,LeadIndexSubId__c, RoomGroupNo__c,EntryTime__c from Lead__c where Id in: leadids ];
		set<Id> leadIndexIds = new set<id>();
		set<Id> leadIndexSubIds = new set<Id>();
		set<Decimal> groupNoSet = new Set<Decimal>();
		// 指定の部屋のみ集計情報を送信する場合
		Set<String> filterKey = new Set<String>();
		for (Lead__c lead : orgLeadList) {
			leadIndexIds.add(lead.LeadIndexRef__c);
			leadIndexSubIds.add(lead.LeadIndexSubId__c);
			groupNoSet.add(lead.RoomGroupNo__c);
			// 場外対象外データチェック用キーを格納する
			filterKey.add(getFilterKey(lead, config));
		}
		String queryHeader = 'select id,CancelBool__c,Relcontact__c,EntryTime__c,LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c ';
		if (isProcessFlg) queryHeader+= ',Mans__c,Femails__c,ChildFA__c,Childs__c,ChildC__c,ChildD__c ';
		else queryHeader+= ',PmsEmailInsUpdDateTime__c,PmsEmailDelDateTime__c ';
		queryHeader += ' from lead__c ';
		String queryWhere = ' where LeadIndexRef__c in :leadIndexIds ';

		// 予約変更通知の場合
		Integer cancelInt = CommConst.LEAD_ST_CANCEL_FLG;
		if (config.insUpdNotify) queryWhere += ' And CancelBool__c != :cancelInt '; 
		if (!CommUtils.isBlank(config.emailWhereStr)) queryWhere += ' And ('+config.emailWhereStr+') ';
		// 指定の部屋のみ対象集計の場合
		if (!config.allRoomTarget) {
			// 選択した予約の関連情報IDを取得する
			queryWhere += ' And LeadIndexSubId__c in :leadIndexSubIds and RoomGroupNo__c in :groupNoSet ';
		}
		// 並び順設定する
		String queryOrder = ' Order by LeadIndexRef__c, EntryTime__c ';
		//String queryOrder = '';
		// 予約情報を取得する map<予約インデックスID,list<到着日順 list<同じ到着日の予約>>
		map<Id, map<String, list<lead__c>>> existLeadsMap = new map<Id, map<String,list<lead__c>>>();
		for (Lead__c lead : Database.query(queryHeader + queryWhere +  queryOrder)) {
	    	// 関連の予約インデックス情報はネットから予約の情報の場合、
	    	String key = getFilterKey(lead, config);
	    	// 対象外データを外す
	    	if (!filterKey.contains(key)) continue;
	    	
	    	// 対象データリストを作成する  map<予約インデックスID,list<到着日順 list<同じ到着日の予約>>
	    	Id key2 = lead.LeadIndexRef__c;
			if (!existLeadsMap.containsKey(key2)) existLeadsMap.put(key2, new map<String,list<Lead__c>>());
			String subKey2 = getSubKey(lead.EntryTime__c);
	        map<String,list<lead__c>> subMap = existLeadsMap.get(key2);
	        if (!subMap.containsKey(subKey2)) subMap.put(subKey2, new List<Lead__c>());
	        subMap.get(subKey2).add(lead);
		}
		return existLeadsMap;
	}
	// 比較用キーを作成する
	private static String getFilterKey(Lead__c lead, XmlConfig config) {
		if (!config.allRoomTarget) {
			return (
					  CommUtils.nullToBlank(lead.LeadIndexRef__c)
				+'_'+ CommUtils.nullToBlank(lead.LeadIndexSubId__c)
				+'_'+ CommUtils.nullToBlank(lead.RoomGroupNo__c));
		} else {
			return CommUtils.nullToBlank(lead.LeadIndexRef__c);
		}
	}
	private static String getSubKey(DateTime entryDt) {
		return entryDt.format('yyyy/MM/dd');
	}
	private static String getSumInfoKey(Id leadIdxId, Date entryDt) {
		return (CommUtils.nullToBlank(leadIdxId) + '-' + entryDt.format());
	}
	// XML定義情報を格納用クラス
	class XmlConfig {
		public boolean allRoomTarget{get;set;}
		public String emailWhereStr{get;set;}
		public boolean insUpdNotify{get;set;}
        // 获取email的定义模板
        public String emailHeader{get;set;}
        public String emailDetail{get;set;}
        public String emailFooter{get;set;}
        public String roomrateformat{get;set;}
        // XML集計カスマイズあり・なしチェックフラグ
        public Boolean isHaveEmailTemplate{get{
        	return (
        		!CommUtils.isBlank(emailHeader) ||
    			!CommUtils.isBlank(emailDetail) ||
    			!CommUtils.isBlank(emailFooter)
        	);
        }}
		// XML定義情報を読み込みする
		public XmlConfig(boolean pInsUpdNotify ) {
	        // 获取email的定义
	        String docName = 'WSServiceConfigXml';
	        // 获取当前user的默认code
	        String spcd = CommUtils.nullToBlank(CurrentUserInfo.defaultShopCode);
	        // 初期化処理
	        // 数据的出力方式
	        allRoomTarget = false;
	        // 追加的where条件
	        emailWhereStr = '';
	        emailHeader = '';
	        emailDetail = '';
	        emailFooter = '';
	        roomrateformat = 'yyyy年MM月dd日';
	        // キャンセル通知フラグ
	        insUpdNotify = pInsUpdNotify;
			// XML定義情報を取得する
	        Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, spcd);
	        Dom.XmlNode emailNode = shopRoot.getChildElement('PMS_EMAIL', null);
	        if (emailNode != null) {
	            allRoomTarget = boolean.valueOf(CommUtils.nullToBlank(emailNode.getAttribute('ALLROOMCNT',null)));
	            emailWhereStr = CommUtils.nullToBlank(emailNode.getAttribute('LEADWHERE',null)).toLowerCase();
	            for (Dom.XmlNode templateNode : emailNode.getChildElements()) {
	            	if(templateNode.getName() == 'HEAD'){
	            		emailHeader = CommUtils.nullToBlank(templateNode.getText());
	            	} else if(templateNode.getName() == 'DETAIL'){
	            		emailDetail = CommUtils.nullToBlank(templateNode.getText());
	            		// 曜日書式定義場合
	            		String formatStr = CommUtils.nullToBlank(emailNode.getAttribute('ROOMDATE_FORMAT',null));
	            		if (!CommUtils.isBlank(formatStr)) roomrateformat = formatStr;
	            	} else if(templateNode.getName() == 'FOOT'){
	            		emailFooter = CommUtils.nullToBlank(templateNode.getText());
	            	}
	            }
	        }	        
		}
	}
	// insUpdNotify: TRUE(新規・変更通知)；FALSE（キャンセル通知）
	// String[]
	webservice static String getEmailStatus(String leadIdStr, Boolean insUpdNotify) {
		// 空： 正常发送邮件 ； 1:対象予约已发送过邮件 ;2:予約キャンセルの場合、有效予约存在
		String rs= '';
		try{
			// XML定義情報を取得する
			XmlConfig config = new XmlConfig(insUpdNotify);
			// 需要处理的lead
			list<Id> leadIds = (list<Id>)JSON.deserialize(leadIdStr, list<Id>.class);
			// 処理対象予約情報を取得する
			map<Id, map<String, list<lead__c>>> targetLeadMaps = getTargetLeads(leadIds,config,false);
			// 予約キャンセルの場合、予約有効データが存在場合
			for (String key : targetLeadMaps.keyset()) {
				map<String,List<lead__c>> subMaps = targetLeadMaps.get(key);
				for (list<Lead__c> leads : subMaps.values()) {
					for (lead__c lead : leads) {
						// 予約変更通知
						if (insUpdNotify) {
							// すでに発信処理履歴あり
							if (lead.PmsEmailInsUpdDateTime__c != null) return '1';
						} 
						// 予約キャンセル通知
						else {
							// 有効予約存在場合、処理中止
							if (lead.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) return '2';
							// すでに発信処理履歴あり
							else if (lead.PmsEmailDelDateTime__c != null) return '1';
						}
					}
				}
			}
		} catch (Exception e) {return e.getMessage();}
		return rs;
	}
	class SumInfo {
		//public String roomRateDate{get;set;}
		public String key{get;set;}
		public Integer rooms{get;set;}//部屋数
		public Integer mans{get;set;}//男性
		public Integer femails{get;set;}//女性
		public Integer adults{get{return (mans+femails);}}//大人数	
		public Integer childA{get;set;}
		public Integer childB{get;set;}
		public Integer childC{get;set;}
		public Integer childD{get;set;}
		public Decimal sumAmount{get;set;}
		public SumInfo(String pkey) {
			key = pkey;//yyyy/MM//dd 曜日
			rooms = mans = femails = childA = childB = childC = childD = 0;
			sumAmount = 0;
		}
		public void addSumInfo(Lead__c lead) {
			rooms++;
			mans += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'Mans__c'));
			femails += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'Femails__c'));
			childA += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildFA__c'));
			childB += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'Childs__c'));
			childC += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildC__c'));
			childD += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildD__c'));
			//childEInt += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildE__c'));
			//childFInt += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildF__c'));
			//childOInt += CommUtils.nullToIntZero(CommUtils.getFielValue(lead,'ChildOther__c'));
		}
	}
	// 予約情報を集計して、メール送信を行う
	webservice static String getEmailBody(String leadIdStr, Boolean insUpdNotify) {
		String rs = '';
		//try {
		// XML定義情報を取得する
		XmlConfig config = new XmlConfig(insUpdNotify);
		// 需要处理的lead
		list<Id> leadIds = (list<Id>)JSON.deserialize(leadIdStr, list<Id>.class);
		// 処理対象予約情報を取得する
		map<Id, map<String, list<lead__c>>> targetLeadMaps = getTargetLeads(leadIds,config,true);
		// 予約インデックスグループの集計情報を格納する
		map<Id, List<SumInfo>> leadIdxSumInfMap = new map<Id, List<SumInfo>>();
		// map<leadindex id+'-'+到着日, sumInfo>
		map<String, SumInfo> sumInfoMap = new map<String, SumInfo>();
		// メール集計カスマイズがない場合、処理飛ばす
		if (config.isHaveEmailTemplate) {
			// 対象予約IDを格納する
			set<Id> targetIdSet = new set<Id>();
			// 情報集計計算する
			for (String key : targetLeadMaps.keyset()) {
				// 該当曜日の予約情報を取得する
				map<String,List<lead__c>> subMaps = targetLeadMaps.get(key);
				List<String> sortList = new List<String>();
				sortList.addAll(subMaps.keySet());
				// 昇順処理
				sortList.sort();
				// 該当予約インデックスの情報を格納する
				leadIdxSumInfMap.put(key, new List<SumInfo>());
				// 曜日順により、予約情報を合計する
				for (String subKey : sortList) {
					// 該当曜日の予約情報を取得する
					List<lead__c> leads = subMaps.get(subKey);
					// 曜日別予約情報を初期化
					SumInfo sinfo = new SumInfo(leads[0].EntryTime__c.format(config.roomrateformat));
					// 集計処理
					for (lead__c lead : leads) {
						// 予約変更通知
						if (insUpdNotify) {
							// 予約情報キャンセルされる場合、処理対象外
							if (lead.CancelBool__c == CommConst.LEAD_ST_CANCEL_FLG) continue;
							// 情報集計する
							sinfo.addSumInfo(lead);
							// 対象予約IDを格納する
							targetIdSet.add(lead.Id);
						} 
						// 予約キャンセル通知
						else {
							// 有効予約存在場合、処理対象外
							if (lead.CancelBool__c != CommConst.LEAD_ST_CANCEL_FLG) continue;
							// 情報集計する
							sinfo.addSumInfo(lead);
							// 対象予約IDを格納する
							targetIdSet.add(lead.Id);
						}
					}
					// 曜日別情報を格納する
					leadIdxSumInfMap.get(key).add(sinfo);
					// 集計情報はMAPにマッピングする
					String sumKey = getSumInfoKey(key, leads[0].EntryTime__c.date());
					sumInfoMap.put(sumKey, sinfo);
				}
			}
			String actionPy = CommConst.PROD_ACTION_TYPE_PY;
			String actionAr = CommConst.PROD_ACTION_TYPE_AR;
			AggregateResult[] groupedResults = [select sum(Total__c) amount, 
					refBooking__r.LeadIndexRef__c leadIdxId, 
					DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c)) entryDt
				from BookingEstimateItem__c
				Where refBooking__c in: targetIdSet And (ActionType__c != :actionPy AND ActionType__c != :actionAr) And InvoiceNoShowFlg__c = false
				and ParentBookingItemRef__c = null//BreakDown明細を対象外
				Group by refBooking__r.LeadIndexRef__c, DAY_ONLY(convertTimezone(refBooking__r.EntryTime__c))
			];
			for (AggregateResult result : groupedResults) {
				Id leadIdx = (Id)result.get('leadIdxId');
				Date entryDt = (Date)result.get('entryDt');
				String sumKey = getSumInfoKey(leadIdx, entryDt);
				if (sumInfoMap.containsKey(sumKey)) {
					SumInfo sinfo = sumInfoMap.get(sumKey);
					sinfo.sumAmount = CommUtils.nulltoZero(result.get('amount'));
				}
			}
			// クリア処理
			sumInfoMap.clear();
		}
		// 予約インデックス情報を再取得して、更新時間とメール明細を設定する
		//予約インデックス関連の予約IDを取得、見積明細金額を合計する（予約インデックス、到着日別合計）
		set<Id> leadIdxIds = targetLeadMaps.keySet();
		// 予約インデックス情報を取得、メール送信対象を更新する
		// 総件数
		Integer totalCnt = 0;
		// メールあり件数
		Integer succeCnt = 0;
		// 更新時刻
		DateTime updSysDt = System.now();
		// 更新対象リスト
		List<leadIndex__c> updLeadIdxLst = new List<leadIndex__c>();
		for (leadIndex__c leadIdx : [select id, ContactEmailCal__c from leadIndex__c where id in :leadIdxIds]) {
			totalCnt++;
			if (CommUtils.isBlank(leadIdx.ContactEmailCal__c)) continue;
			succeCnt ++;
			// 処理時刻を設定して、更新する
			if (insUpdNotify) leadIdx.PmsEmailInsUpdDateTime__c = updSysDt;
			else leadIdx.PmsEmailDelDateTime__c = updSysDt;
			// メールのカスマイズ情報を入り替えする
			if (leadIdxSumInfMap.containsKey(leadIdx.Id)) {
				// テンプレート情報を作成、項目に反映する
				leadIdx.EmailBody__c = getEmailStr(leadIdxSumInfMap.get(leadIdx.Id),config);
			} else {
				// 既存内容をクリアする
				leadIdx.EmailBody__c = null;
			}
			// 更新対象リストに格納する
			updLeadIdxLst.add(leadIdx);
		}
		List<Lead__c> updLeadLst = new List<Lead__c>();
		for (leadIndex__c leadIdx : updLeadIdxLst) {
			Id key = leadIdx.Id;
			if (targetLeadMaps.containsKey(leadIdx.Id)) {
				map<String,List<lead__c>> subMaps = targetLeadMaps.get(key);
				for (List<lead__c> leads : subMaps.values()) {
					for (lead__c lead : leads) {
						// 処理時刻を設定して、更新する
						if (insUpdNotify) lead.PmsEmailInsUpdDateTime__c = updSysDt;
						else lead.PmsEmailDelDateTime__c = updSysDt;
						updLeadLst.add(lead);
					}
				}
			}
		}
		Savepoint sp = Database.setSavepoint();
		try {
			if (!updLeadIdxLst.isEmpty() || !updLeadLst.isEmpty()) {
				DataFixManagerUtils.stopTranTriggger();
				update updLeadIdxLst;
				update updLeadLst;
				DataFixManagerUtils.begTranTriggger();
			}
		} catch (Exception DbEx) {
			Database.rollback(sp);
			throw DbEx;
		}
		// 予約通知メールを送信済み（XX件成功、XX件失敗）
		rs = '予約通知メールを送信済み（' + succeCnt + '件成功、' + (totalCnt-succeCnt) +'件失敗）';
		return rs;
	}
	private static String getEmailStr(List<SumInfo> infLst, XmlConfig config) {
		String emailBody = config.emailHeader + '\n';
		Decimal totalAmount = 0;
		for (SumInfo inf : infLst) {
			emailBody += '\n' + inf.key + '\n';
			emailBody += config.emailDetail
				.replace('$__部屋数__$', CommUtils.nullToBlank(inf.rooms))
				.replace('$__#大人人数__$', CommUtils.nullToBlank(inf.adults))
				.replace('$__大人人員(男性)__$', CommUtils.nullToBlank(inf.mans))
				.replace('$__大人人員(女性)__$', CommUtils.nullToBlank(inf.femails))
				.replace('$__子供A人数__$', CommUtils.nullToBlank(inf.childA))
				.replace('$__子供B人数__$', CommUtils.nullToBlank(inf.childB))
				.replace('$__子供C人数__$', CommUtils.nullToBlank(inf.childC))
				.replace('$__子供D人数__$', CommUtils.nullToBlank(inf.childD))
				.replace('$__#料金小計__$', CommUtils.numberFormat(inf.sumAmount));
			totalAmount += inf.sumAmount;
		}
		emailBody += config.emailFooter.Replace('$__#料金合計__$' ,CommUtils.numberFormat(totalAmount));
		return emailBody;
	}
	// 2020/04/30 予約の確認メールの自動送付機能 BY zyz END
}