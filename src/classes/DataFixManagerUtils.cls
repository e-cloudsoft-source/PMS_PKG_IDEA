public with sharing class DataFixManagerUtils {
	// 該当TRAN処理の際に、予約トリガーは処理対象外なる
	private static boolean tranTriggerStop = false;
	public static void stopTranTriggger() {
		tranTriggerStop = true;
	}
	public static void begTranTriggger() {
		tranTriggerStop = false;
	}
	public static Boolean tranTriggerIsStop() {
		return (tranTriggerStop == null ? false : tranTriggerStop);
	}
	
	private DataFixManager__c manger;
	public DataFixManagerUtils() {
		manger = getInstance();
	}
	// インストールクラスの初期化
	public void init() {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'leadupdateflg__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		if (manger.Id == null) {
			insert manger;
		}
	}
	public void updStockChangeHisotryFixed(Boolean val) {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'stockchangehisotryfixed__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		init();
		manger.StockChangeHisotryFixed__c = val;
		update manger;
	}
	public void updLeadKeyFixed(Boolean val) {
		// 2018/03/07 Security Check BEGIN
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		// List<String> chkFieldsLst = new List<String>{'LeadFixed__c','LeadUpdateFlg__c'};
		List<String> chkFieldsLst = new List<String>{'LeadFixed__c','LeadUpdateFlg__c','LeadFixed1__c'};
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		init();
		manger.LeadFixed__c = val;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		manger.LeadFixed1__c = val;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		manger.LeadUpdateFlg__c = false;//予約のトリガー機能は再度有効になる
		update manger;
	}
	// 2019/10/09 部屋状態管理インデックス機能対応 WSQ BEGIN
	public void updRoomsStatusFixed(Boolean val) {
		// 2018/03/07 Security Check BEGIN
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		// List<String> chkFieldsLst = new List<String>{'RoomsStatusFixed__c'};
		List<String> chkFieldsLst = new List<String>{'RoomsStatusFixed__c','RoomsStatusFixed1__c'};
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		init();
		manger.RoomsStatusFixed__c = val;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		manger.RoomsStatusFixed1__c = val;
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH END
		update manger;
	}
	// 2019/10/09 部屋状態管理インデックス機能対応 WSQ END
	public static set<String> dateListToStrYMD(set<Date> dts) {
		set<string> targetDtSet = new set<string>();
		for (Date d : dts) targetDtSet.add((Datetime.newInstance(d.year(),d.month(),d.day())).format('yyyyMMdd'));
		return targetDtSet;
	}
	public static String dateToYMDstr(Date dt) {
		return DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyyMMdd');
	}
	public static DataFixManager__c getInstance() {
		return DataFixManager__c.getOrgDefaults();
	}
	public void beginCommDefOpt() {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'LeadUpdateFlg__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		init();
		manger.LeadUpdateFlg__c = true;
		update manger;
	}
	public void endCommDefOpt() {
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'LeadUpdateFlg__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.DataFixManager__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		init();
		manger.LeadUpdateFlg__c = false;
		update manger;
	}
	// 2018/11/30 既存予約データの到着日は全部インデックス項目設定されているがどうかフラグ WSQ BEGIN
	public static boolean isLeadKeyFixed() {
		return (getInstance().LeadFixed__c == true);
	}
	// 2018/11/30 既存予約データの到着日は全部インデックス項目設定されているがどうかフラグ WSQ END
}