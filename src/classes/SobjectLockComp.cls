public with sharing class SobjectLockComp {
	/**
	* 画面EDITORボタンをクリックする後、該当ロジックを呼び出する(指定のAPP名と店舗コードでロック情報チェックを行う)
	**/
	@remoteAction
	public static CommLockProcess.LockMessage beforeEdit(String LockAppName,String shopCode)
	{
		DateTime dt = DateTime.now();
		String timeStmp = String.valueOf(dt.getTime());
		CommLockProcess.LockMessage lm = CommLockProcess.queryOrLockDataByAppNameAndShopCode(LockAppName,timeStmp,shopCode);
		return lm;
	}
	/**
	* ロック情報が存在、続ける処理　OR　キャンセル　選べるの場合、関連ロジックの呼び出し
	* LockAppName : AppName
	* isUnLockOrChangeFlg : 強制解除するがどうか判別フラグ
	*      TRUE:現在自分所属LOCK情報を削除 / FALSE:強制ロック解除
	* timeStmp : 解除のDataLock指定のTIMESTAMP
	* shopCode : 支店コード
	**/
	@remoteAction
	public static CommLockProcess.LockMessage unlockOrChangeLockStatus(String LockAppName,boolean isUnLockOrChangeFlg,String timeStmp,String shopCode)
	{					 
		if(isUnLockOrChangeFlg) {
			// 編集EDITのRequestをキャンセル
			CommLockProcess.unlockDataByAppNameAndShopCode(LockAppName,timeStmp,shopCode);
			return null;
		} else { 
			// 強制解除、「執行」ボタンをクリックする
			return CommLockProcess.changeLockData(LockAppName, timeStmp, shopCode);
		}
	}
	/**
	* 更新処理の実施前の関連チェックと処理
	*/
	@remoteAction
	public static CommLockProcess.LockMessage beforeUpdate(String LockAppName,String shopCode,String timeStmp)
	{
		CommLockProcess.LockMessage lm = CommLockProcess.queryOrUnlockDataByAppNameAndShopCode(LockAppName,timeStmp,shopCode);
		return lm;
		
	}
}