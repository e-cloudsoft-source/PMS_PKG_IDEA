/*********************************************
* 会計商品の関連トリガー処理を行う
* 2013/06/25: 税ｽﾃｰﾀｽ自動設定
* 2018/09/19: 固定の会計商品は削除できないように制限追加
**/
public with sharing class AccountMasterTriggerProcess {

	/******************
	* 消費税マスタ設定にて、税ｽﾃｰﾀｽ自動設定を行う
	******************/
	public void autoSetupAccountMaster(AccountMaster__c[] newLst, AccountMaster__c[] oldLst, CommConst.TriggerMethod action){
        // 2017/06/23 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
        Integer locPointLen = CommUtils.getPointLen();
        Integer unitPriceKbn = CommConst.APPOPTION_UTP_DEF_KB;
        CommUtils.ProductInfo priceInfo = (locPointLen > 0) ? new CommUtils.ProductInfo(unitPriceKbn) : null;
		integer idx = 0;
		List<Integer> targetLst = new List<Integer>();
        // 2017/06/23 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
		for (AccountMaster__c acc : newLst) {
			if (acc.TaxRateCal__c > 0) {
				acc.StsTaxfee__c = '0';
			} else {
				acc.StsTaxfee__c = '99';
			}
			// 2017/06/23 JPY以外の場合、２桁小数の単価（税抜き）計算を行う BEGIN
            // 単価（税抜き）金額は再計算して、設定を行う
            if (priceInfo != null) {
                priceInfo.process(Commutils.nullToZero(acc.Field5__c), 1, acc.TaxRateCal__c, CommUtils.nullToZero(acc.ServiceRate__c));
                acc.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax; 
            }
            // 2017/06/23 JPY以外の場合、２桁小数の単価（税抜き）計算を行う END
			if (CommUtils.isBlank(acc.field3__c)) {
				targetLst.add(idx);
			}
			idx++;
		}
		if (!targetLst.isempty()) {
			map<Integer, String> numMap = CommLogicProcess.getBulkAutoNumer(targetLst);
			for (Integer key : numMap.keySet()) {
				newLst[key].Field3__c = 'EP' + numMap.get(key);
			}
		}
	}
	
	// 2018/09/19: 固定の会計商品は削除できないように制限追加 BEGIN
	// 指定の商品コードを削除できない制御を行う
	public void deletePreCheck(AccountMaster__c[] newLst, AccountMaster__c[] oldLst, CommConst.TriggerMethod action){
		// '現金','カード','売掛金','クーポン','値引','予約金'
		set<string> requiredCdSet = new set<string>{'M99000','M99001','M99002','M99003','M99004','M99005'};
		for (AccountMaster__c acc : oldLst) {
			// 商品コード
			String pcode = CommUtils.nullToBlank(acc.Field3__c);
			if (requiredCdSet.contains(pcode)) {
				acc.Field3__c.adderror('整合性を保持するため、該当商品['+pcode+']を削除できません');
			}
		}
	}
	// 2018/09/19: 固定の会計商品は削除できないように制限追加 END
	// 2018/12/10 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ BEGIN
	// 会計商品新規・更新場合、該当商品情報をAWSへ送信を行う
	public void callInfoToAwsProcess(AccountMaster__c[] newLst, AccountMaster__c[] oldLst, CommConst.TriggerMethod action){
		if (action != CommConst.TriggerMethod.isUpdate && action != CommConst.TriggerMethod.isInsert) return;
		List<String> targetCodes = new list<String>();
		for (AccountMaster__c nw : newLst) {
			if (nw.DisplayDate__c != null && !CommUtils.isBlank(nw.Field3__c)) targetCodes.add(nw.Field3__c);
		}
		// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ BEGIN
		//if (!targetCodes.isEmpty()) WS_ExpoEngineService.syncSfProdInfoToAws(targetCodes);
		if (!targetCodes.isEmpty()) WS_ExpoEngineService.syncSfProdInfoToAws(targetCodes, false);
		// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ END
	}
	// 2018/12/10 EXPO会計商品変更場合、関連情報はAWSへ通知を行う WSQ END
	// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ BEGIN
	// 会計商品削除場合、該当商品情報をAWSへ送信を行う
	public void callDelInfoToAwsProcess(AccountMaster__c[] newLst, AccountMaster__c[] oldLst, CommConst.TriggerMethod action){
		if (action != CommConst.TriggerMethod.isDelete) return;
		List<String> targetCodes = new list<String>();
		for (AccountMaster__c od : oldLst) {
			if (od.DisplayDate__c != null && !CommUtils.isBlank(od.Field3__c)) targetCodes.add(od.Field3__c);
		}
		if (!targetCodes.isEmpty()) WS_ExpoEngineService.syncSfProdInfoToAws(targetCodes,true);
	}
	// 2019/06/06 EXPO会計商品削除場合、関連情報はAWSへ通知を行う WSQ END
/**
*2015-11-18
*テストクラスAccountMasterTriggerProcessに移行する
	// 税ステータス自動設定機能
	@isTest(SeeAllData=false)
	static void testAutoSetupAccountMaster() {
		List<AccountMaster__c> productMstList = TestCommon.createProductMst(2);
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
		productMstList[0].jmstRef__c = null;
		JMST__c newJmst = new JMST__c(TaxRate__c = 0);
		productMstList[1].jmstRef__c = newJmst.Id;
		update productMstList;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c]) {
			System.assertEquals(acc.StsTaxfee__c, '99');
		}
		JMST__c newJmst2 = new JMST__c(TaxRate__c = 5);
		insert newJmst2;
		productMstList[1].jmstRef__c = newJmst2.Id;
		update productMstList[1];
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :productMstList[1].Id]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
		// 新規登録の確認
		AccountMaster__c newItem1 = new AccountMaster__c(
			Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
			jmstRef__c = newJmst.Id,
			Field3__c = 'UNIT' + CommUtils.getRandom(9) // 商品コード
		);
		insert newItem1;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :newItem1.Id]) {
			System.assertEquals(acc.StsTaxfee__c, '99');
		}
		AccountMaster__c newItem2 = new AccountMaster__c(
			Name = '名称2(漢1)UNIT_TEST' + CommUtils.getRandom(9),
			jmstRef__c = newJmst2.Id,
			Field3__c = 'UNIT' + CommUtils.getRandom(9) // 商品コード
		);
		insert newItem2;
		for (AccountMaster__c acc : [select StsTaxfee__c from AccountMaster__c where id = :newItem2.Id]) {
			System.assertEquals(acc.StsTaxfee__c, '0');
		}
	}
***/
}