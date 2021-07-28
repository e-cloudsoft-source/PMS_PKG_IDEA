public with sharing class CommLockProcess {
	// 店舗設定情報を取得、格納する
	private static final Map<String,ShopInformation__c> shopMap = ShopInfoUtil.getShopInfoMap();
	// DabaLock重複ロックチェック用キー
	private static final String KEY_DUPLICATE_VALUE = 'duplicate value found:';
	/**
	* 店舗関連の検索キーを取得する
	**/
	private static String getDataLockKey(String pAppName, String pShopCode) {
		return pAppName + '_' + CommUtils.nullToBlank(pShopCode);
	}
	/**
	* 指定の店舗コードにより、関連の店舗コードを取得する
	**/
	private static List<String> getAllshopCdLst(string pShopCode) {
		// 多店舗の場合
		if (!shopMap.isEmpty()) {
			// 全店舗の関連店舗コードを取得する
			if (CommUtils.isBlank(pShopCode)) {
				List<String> shopCds = new List<String>();
				for (String shopCd : shopMap.keySet()) {
					shopCds.add(shopCd);
				}
				return shopCds;
			} else {
				return new List<String>{pShopCode};
			}
		} else {
			return new List<String>{''};
		}
	}
	/**
	* 指定の機能画面に対して、データLOCKされるがどうかチェックを行う
	* ロック情報がなければ、自動新しいロック情報を新規作成する
	* ADD LOCK
	**/
	public static LockMessage queryOrLockDataByAppNameAndShopCode(String pAppName,String timeStmp,String pShopCode) {
		return queryOrLockDataByAppNameAndShopCode(pAppName, timeStmp, pShopCode, false);
	}
	public static LockMessage queryOrLockDataByAppNameAndShopCode(String pAppName,String timeStmp,String pShopCode, Boolean isDelete) {
		//ShopInformation__c shop = null;
		//if(!CommUtils.isBlank(shopCode)) shop = shopMap(shopCode);
		// 指定店舗に対して、DataLock存在チェックを行う
		// All店舗の場合、含めの支店情報は全部自動LCOKデータ作成を行う
		Savepoint sp = Database.setSavepoint();
		
		LockMessage lm = new LockMessage();
		
		try {
			// 指定のAPPと店舗コードでロック情報を検索する
			String queryStr = commGetQuerySql(pAppName, null, pShopCode, true);
			List<DataLock__c> dls = DataBase.query(queryStr);
			// ロック情報を強制解除する場合、元のロックを削除する
			if (isDelete && !dls.isEmpty()) {
				DataLock__c ortLock = dls[0];
				// 取得したのロック情報は引渡しのTIMPSTAMPは違う場合、別の強制解除動作があります,最新のロック情報を画面に戻る
				if (ortLock.TimeStmp__c != timeStmp) {
					lm.init( ortLock,false);
					return lm;
				}
				// 2017/04/13 Sobject Security Check BEGIN
				if (CommSecurityUtils.isDeleteable(DataLock__c.getSObjectType())) {
				// 2017/04/13 Sobject Security Check END
				// 既存のロック情報を削除する
				delete dls;
				// 2017/04/13 Sobject Security Check BEGIN
				}
				// 2017/04/13 Sobject Security Check END
				dls.clear();
			}
			
			// 該当店舗関連のLOCKが非存在する場合、LOCKデータを作成する
			if (dls.isEmpty()) {
				List<DataLock__c> newLocks = new List<DataLock__c>();
				DateTime dt = System.now();
				Id operUserId = UserInfo.getUserId();
				List<String> shopCdLst = getAllshopCdLst(pShopCode);
				String newTimeStmp = String.valueOf(dt.getTime());
				for (String shopCd : shopCdLst) {
					// 新規BLOCK情報の作成
					newLocks.add(
						new DataLock__c( 
							 AppName__c = pAppName
						 	,LockTime__c = dt
						 	,TimeStmp__c = newTimeStmp
						 	,ShopInfoRef__c = (shopMap.containsKey(shopCd) ? shopMap.get(shopCd).Id : null)
						 	,LockByRef__c =  operUserId
						 	,DataLockKey__c = getDataLockKey(pAppName, shopCd)
						));	 
				}
	
				// LOCK情報登録する
				Database.SaveResult[] savaRs = Database.insert(newLocks, false);
				// 処理失敗件数
				Integer failedRsNum = 0;
				// ロック情報作成の間に、同時にロック情報を作成する回避する（外部キー利用する）ため、エラーが発生する場合、画面に最新ロック情報を戻る
				for (Integer i = 0; i < savaRs.size(); i++) {
					// データ毎の処理結果を取得する
					Database.SaveResult sr = savaRs[i];
					// データ新規作成失敗の場合
					if (!sr.isSuccess()) {
						// 処理失敗
						Database.Error err = sr.getErrors()[0];
						// 外部キーが重複問題が発生する場合
						if (err.getMessage().contains(KEY_DUPLICATE_VALUE)) {
							// 重複存在のデータの最新情報を取得して、画面へ表示する
							String queryKey = newLocks[i].DataLockKey__c;
							List<DataLock__c> dupDataLst = Database.query(queryHeader + ' Where DataLockKey__c = :queryKey ');
							//if (dupDataLst.isEmpty()) insert newLocks[i];
							lm.init( dupDataLst[0],false);
							break;
						} else {
							// その意外の異常が発生する場合
							throw new CommException (err.getMessage());
						}
					}
				}
				// 処理件数は一部成功の場合、Rollbackする
				if (failedRsNum > 0) {
					Database.rollback(sp);
				} else {
					lm.init( newLocks[0],true);
				}
	
	
			} else {
				lm.init( dls[0],false);
			}
		} catch (Exception e) {
			Database.rollback(sp);
			throw new CommException (' Data Lock Save Error:' + e);
		}
		return lm;
	}
	
	/**
	* 指定の機能画面に対して、データロック解除処理を行う
    * Before Of Update処理
	* UN LOCK
	**/
	public static LockMessage queryOrUnlockDataByAppNameAndShopCode(String pAppName,String pTimeStmp,String pShopCode){
		
		String queryStr = commGetQuerySql(pAppName,pTimeStmp,pShopCode,true);
		List<DataLock__c> dls = DataBase.query(queryStr);
		LockMessage lm = new LockMessage();
		// 指定のTIMESTAMPの自分のロック情報が非存在の場合
		if(dls.isEmpty()) {
			DateTime dt = DateTime.newInstance(Long.valueOf(pTimeStmp));
			//yyyy年MM月dd日HH時mm分ss秒
			lm.timeStr = dt.format(Label.CONST_012_0497);
		} 
		// 指定のTIMESTAMPの自分のロック情報が存在ですが、件数が一致なかった
		else if (getAllshopCdLst(pShopCode).size() != dls.size()) {
			DateTime dt = DateTime.newInstance(Long.valueOf(pTimeStmp));
			//yyyy年MM月dd日HH時mm分ss秒
			lm.timeStr = dt.format(Label.CONST_012_0497);
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(DataLock__c.getSObjectType())) {
				return lm;
			}
			// 2018/03/07 Security Check END
			delete dls;	
		} 
		// 全部OK、自分のロック情報を画面へ戻る、そして、ロック情報を削除する
		else{
			lm.init(dls[0],false);
			// 2017/04/13 Sobject Security Check BEGIN
			if (CommSecurityUtils.isDeleteable(DataLock__c.getSObjectType())) {
			// 2017/04/13 Sobject Security Check END
			delete dls;	
			// 2017/04/13 Sobject Security Check BEGIN
			}
			// 2017/04/13 Sobject Security Check END
		}
		return lm;
	}
	/**
	* 既存の編集情報をキャンセル
    * キャンセル処理（DataLock解除)
	* UN LOCK
	**/
	public static void unlockDataByAppNameAndShopCode(String pAppName,String pTimeStmp,String pShopCode){
		
		String queryStr = commGetQuerySql(pAppName,pTimeStmp,pShopCode,true);
		List<DataLock__c> dls = DataBase.query(queryStr);
		if(!dls.isEmpty())
		{
			// 2017/04/13 Sobject Security Check BEGIN
			if (CommSecurityUtils.isDeleteable(DataLock__c.getSObjectType())) {
			// 2017/04/13 Sobject Security Check END
			delete dls;	
			// 2017/04/13 Sobject Security Check BEGIN
			}
			// 2017/04/13 Sobject Security Check END
		}
	}
	/**
	* 既存のLOCK存在する場合，強制LOCK解除処理
	* 
	**/
	public static LockMessage changeLockData(String pAppName,String pTimeStmp,String pShopCode){
		return queryOrLockDataByAppNameAndShopCode(pAppName, pTimeStmp, pShopCode, true );
	}
	/**
	* boolean isQueryOrCheck(true:query get data by paramter false:check datalock has data or not)
	* 
	*/
	private static final String queryHeader = 'select name,AppName__c,LockTime__c,LockByRef__c,TimeStmp__c,ShopInfoRef__c,LockByRef__r.lastname,LockByRef__r.firstname from DataLock__c ';
	private static String commGetQuerySql(String appName,String timeStmp, String pShopCode, boolean lockFlg) {
		String sqlHead = queryHeader;
		if(CommUtils.isBlank(appName)) throw new CommException('Paramter "appName" is required ');
			
		String sqlWhere = ' where AppName__c = \'' + String.escapeSingleQuotes(appName) + '\'' ;
		
		//List<ShopInformation__c> shops = new List<ShopInformation__c>();
		List<String> seacheKeys = new List<String>();
		// 多店舗の場合
		if (!shopMap.isEmpty()) {
			// ALL店舗選択する場合
			if (CommUtils.isBLank(pShopCode)) {
				for (String shopCode : shopMap.keySet()) {
					seacheKeys.add(getDataLockKey(appName, shopCode));
				}
			// 指定店舗の場合
			} else {
				if (shopMap.containsKey(pShopCode)) {
					seacheKeys.add(getDataLockKey(appName, pShopCode));
				}
			}
		} // 多店舗の場合、店舗関連のSHOPIDを取得する
		
		// 店舗情報指定あり場合、（多店舗はALL指定の場合、複数店舗は全部検索対象になる)
		if(!seacheKeys.isEmpty()){
			String keyStr = '(\'' + String.join(seacheKeys, '\',\'') + '\')';
			sqlWhere += ' and DataLockKey__c in ' + keyStr;
			/*
			if(isQueryOrCheck){
				shopIdsStr = '(\'' + String.join(shopIds, '\',\'') + '\')';

				sqlWhere += ' and ShopInfoRef__c = \'' + String.escapeSingleQuotes(shop.id) + '\'';
			}else{
				sqlWhere += ' and (ShopInfoRef__c = null or ShopInfoRef__c = \'' + String.escapeSingleQuotes(shop.id) + '\')';
			}*/
		}
		if(!CommUtils.isBlank(timeStmp)){
			sqlWhere += ' and TimeStmp__c = \'' + String.escapeSingleQuotes(timeStmp) + '\'' ;
		}
	
		if(lockFlg) sqlWhere += ' for update';

		return sqlHead + sqlWhere;
	}
	
	public class LockMessage{
		// LOCK情報種別区分：TRUE：新規LOCK情報追加、FALSE：他人既存のLOCK情報を戻る
    	public boolean isNewOrHadlock{get;set;}
    	public DataLock__c dl{get;set;}
    	public String message{get;set;}
    	public String userName{get;set;}
    	public String timeStr{get;set;}
    	
    	public void init(DataLock__c pDataLock,boolean pIsNewOrHadlock){
    		dl = pDataLock;
    		isNewOrHadlock = pIsNewOrHadlock;
    		userName = pDataLock.LockByRef__r.lastname + (CommUtils.isBlank(pDataLock.LockByRef__r.firstname) ? '' : ' ' + pDataLock.LockByRef__r.firstname);
    		//yyyy年MM月dd日HH時mm分ss秒
    		timeStr =  pDataLock.LockTime__c.format(Label.CONST_012_0497);
    	}
    	
    }
}