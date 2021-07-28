/********************************
* プラントリガー共通処理クラス
*
*********************************/
public with sharing class PlanTriggerProcess {
	
	/**
	* プラン番号を採番を行う
	* Before Insert
	**/
	public void setPlanAutoNumber(Plan__c[] newList, Plan__c[] oldList, CommConst.TriggerMethod action){
		// Insertだけ対応する
		if (action != CommConst.TriggerMethod.IsInsert) {return;}
		
		List<String> autoNoLst = new List<String>();
		List<JinyaAutoNumber__c> insLst = new List<JinyaAutoNumber__c>();
		Savepoint sp = Database.setSavepoint();
		try {
			for (Plan__c plan : newList) {
				// PlanNo.既に設定済み場合、採番対象外
				if (!CommUtils.isBlank(plan.PlanNo__c)) continue;
				insLst.add(new JinyaAutoNumber__c());
			}
			Database.Saveresult[] saveRsLst = Database.insert(insLst);
			Set<Id> noIdSet = new Set<Id>();
			for (Database.Saveresult sr : saveRsLst) {
				noIdSet.add(sr.getId());
			}
			for (JinyaAutoNumber__c at : [select PlanNoAutoNumber__c from JinyaAutoNumber__c where id in :noIdSet]) {
				autoNoLst.add(at.PlanNoAutoNumber__c);
			}
			// 2017/06/26 PlanNo重複問題対応 BEGIN
			// 自動採算した番号は既に存在するがどうかチェックして、存在して、かつ　該当プランはSF側から新規作成じゃない場合、該当番号は自動設定対象外になる
			set<string> targetPlanNoSet = new set<string>();
			if (!autoNoLst.isEmpty()) {
                for (Plan__c plan : [select PlanNo__c from plan__c where PlanNo__c in :autoNoLst]) {
                    targetPlanNoSet.add(plan.PlanNo__c);
                }
			}
			// 2017/06/26 PlanNo重複問題対応 END
			// 採番内容を設定する
			Integer i = 0;
			for (Plan__c plan : newList) { 
				// PlanNo.既に設定済み場合、採番対象外
				if (!CommUtils.isBlank(plan.PlanNo__c)) continue;
				// 2017/06/26 PlanNo重複問題対応 BEGIN
				if (targetPlanNoSet.contains(autoNoLst[i]) && !plan.UIEventSource__c) continue;
				// 2017/06/26 PlanNo重複問題対応 END
				plan.PlanNo__c = autoNoLst[i];
				i++;
			}
		} finally {
			Database.rollback(sp);
		}
	}
	
	/**
	* プラン名がNULLの場合、自動的に「プラン名がありません_プランNO」で自動設定を行う
	* Before insert
	**/
	public void autoSetupPlanInfo(Plan__c[] newList, Plan__c[] oldList, CommConst.TriggerMethod action){
		if (action != CommConst.TriggerMethod.IsInsert) {return;}
		for (Plan__c plan : newList) {
			if (CommUtils.isBlank(plan.Name)) plan.Name = CommConst.PLAN_BLANK_NAME_PREFIX + plan.PlanNo__c;
		}
	}
	
	/**
	* プラン削除する場合、プラン明細も自動作成を行う
	* before delete
	**/
	public void autoDeletePlanDetail(Plan__c[] newList, Plan__c[] oldList, CommConst.TriggerMethod action){
		if (action != CommConst.TriggerMethod.IsDelete) {return;}
		// 該当プランに既に使っているかどうか、チェックを行う
		Set<Id> planIdSet = new Set<Id>();
		Set<String> planNoProdSet = new Set<String>();
		for (Plan__c plan : oldList) {
			// 該当プランのプラン明細の（会計商品ID）を取得して、予約、見積り明細、会計明細、に既につかているかどうか、チェックを行う
			planIdSet.add(plan.Id);
			// プランNOにより、関連する会計商品（プラン）情報を削除する
			planNoProdSet.add(PlanProductSetup.getPlanProdCode(plan.PlanNo__c));
		}
		// 予約に、該当プランはすでにつかているかどうか、チェックを行う
		List<Lead__c> existLeadLst = [select id from Lead__c where Field310__c in :planIdSet limit 1];
		if (!existLeadLst.isEmpty()) {
			//プランは予約に既に使用されているため、削除できません。
			oldList[0].addError('<span style="color: red">'+ Label.MSG_009_0039 +'</span>',false);
			return;
		}
		// プラン明細に（会計商品ID）を取得する
		// プラン明細ID/会計商品（プランID）[1 VS 1]
		Map<Id, Id> planProdMap = new Map<Id, Id>();
		List<PlanDetail__c> planDeLst = [select id, PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c in :planIdSet];
		for (PlanDetail__c pDetail : planDeLst) {
			planProdMap.put(pDetail.PlanRef__c,  pDetail.PlanProdcut__c);
		}
		// 見積り明細、会計明細両方共存在チェックを行う
		List<BookingEstimateItem__c> bookItemLst = [select id from BookingEstimateItem__c where refAccountMaster__c in :planProdMap.values() limit 1];
		if (!bookItemLst.isEmpty()) {
			//プランは見積明細に既に使用されているため、削除できません。
			oldList[0].addError('<span style="color: red">'+ Label.MSG_009_0040 +'</span>',false);
			return;
		}
		// 
		List<Tran1__c> tran1Lst = [select id from Tran1__c where Field7__c in :planProdMap.values() limit 1];
		if (!tran1Lst.isEmpty()) {
			//プランは会計明細に既に使用されているため、削除できません。
			oldList[0].addError('<span style="color: red">'+ Label.MSG_009_0041 +'</span>',false);
			return;
		}
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isDeleteable(AccountMaster__c.getSObjectType()) ||
		!CommSecurityUtils.isDeleteable(PlanDetail__c.getSObjectType())) {
			return;
		}
		// 2018/03/07 Security Check END
		// 使っていない場合、削除を行う
		// 関連のプラン明細を削除する
		delete planDeLst;
		// 関連の会計商品（プラン）削除する
		//delete [select id from AccountMaster__c where id in :planProdMap.values()];
		delete [select id from AccountMaster__c where Field3__c in :planNoProdSet];
	}
	
	/**
	* プランの関連情報を変更する場合、自動的に商品（プラン）に連携コピーを行う
	* 2013/06/21 プランを更新する場合、自動会計商品（プラン）へ連動コピーを行う
	* after update
	**/
	public void autoSyncPlanInfoToProductMst(Plan__c[] newList, Plan__c[] oldList, CommConst.TriggerMethod action){
		// プラン名変更する場合い、関連の商品（プラン）自動に連動コピーを行う
		Integer lsize = newList.size();
		Map<Id, Plan__c> synPlanMap = new Map<Id, Plan__c>();
		for (Integer i = 0; i < lsize; i++) {
			/*
			// プラン名 OR PlanNo変更する場合、自動会計商品（プラン）へ反映を行う（2013／06／14 PlanNo変更対象追加）
			if (newList[i].name != oldList[i].Name ||
				newList[i].PlanNo__c != oldList[i].PlanNo__c) synPlanMap.put(newList[i].Id, newList[i]); */
			synPlanMap.put(newList[i].Id, newList[i]);
		}
		if (synPlanMap.isEmpty()) return;
		// 関連の商品（プラン）の関連情報を自動コピーを行う
		//List<AccountMaster__c> accMstLst = [select Name from PlanDetail__c where PlanRef__c in :synPlanSet group by PlanRef__c ];
		List<AggregateResult> planDetail = [select PlanRef__c planId, PlanProdcut__c produId from PlanDetail__c where PlanRef__c in :synPlanMap.keySet() and PlanProdcut__c != null group by PlanRef__c, PlanProdcut__c];
		// 関連商品を取得する、更新を行う
		Map<Id, Id> planIdMap = new Map<Id, Id>();
		for (AggregateResult pd : planDetail) {
			planIdMap.put((ID)pd.get('produId'), (ID)pd.get('planId'));
		}
		// 商品名連動更新を行う
		List<AccountMaster__c> accMstLst = [select name,Field3__c,PlanAutoSyncChk__c,Field5__c,Field4__c,GPChange__c,ServiceRate__c,jmstRef__c from AccountMaster__c where id in :planIdMap.keySet()];
		for (AccountMaster__c accMst : accMstLst) {
			Plan__c orgPlan = synPlanMap.get( planIdMap.get(accMst.Id) );
			/*
			accMst.Name =  synPlanMap.get( planIdMap.get(accMst.Id) ).Name;
			accMst.Field3__c = PlanProductSetup.getPlanProdCode(synPlanMap.get( planIdMap.get(accMst.Id) ).PlanNo__c);
			accMst.PlanAutoSyncChk__c = !(accMst.PlanAutoSyncChk__c);
			*/
			/*
			// 会計商品名：プラン名
			accMst.Name =  orgPlan.Name;
			// 会計商品コード：PlanNO
			accMst.Field3__c = PlanProductSetup.getPlanProdCode(orgPlan.PlanNo__c);
			// プランから自動連動標識フラグ
			accMst.PlanAutoSyncChk__c = !(accMst.PlanAutoSyncChk__c);
			// プラン金額
			accMst.Field5__c = orgPlan.Price__c;
			// カテゴリ
			accMst.Field4__c = orgPlan.DpRef__c;
			// 部門
			accMst.GPChange__c = orgPlan.GpRef__c;
			// サービス料(%)
			accMst.ServiceRate__c = orgPlan.ServiceRate__c;
			// 消費税
			accMst.jmstRef__c = orgPlan.jmstRef__c;
			*/
			// 非公開機能連動
			accMst.IsClosed__c = orgPlan.IsClosed__c;
			accMst.BasePlanFlg__c = orgPlan.BasePlanFlg__c;
		}
		update accMstLst;
	}
	
	
/**
*2015-11-18 
*テストクラスPlanTriggerProcessTestに移行する
	
	
	// ************************************
	// テストクラス作成
	// ************************************
	@isTest
	static void selfUnit() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;

		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;

		ctrl2.savePlanDetail();
		Test.stopTest();

		Integer stepNum = 0;
		
		// 予約に登録されている場合
		Lead__c lead = TestCommon.createLead();
		lead.Field310__c = plan.Id;
		update lead;
		stepNum = 10;
		try {
			delete plan;
		} catch (Exception e) {
			stepNum = 11;
		}
		System.assertEquals(stepNum, 11);
		/*
		// 見積り明細へ設定、更新を行う
		BookingEstimateItem__c bItem = [select id from BookingEstimateItem__c where refBooking__c = :lead.Id and ParentBookingItemRef__c = null];
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
		bItem.refAccountMaster__c = accMsProdId;
		update bItem;
		
		stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);	*/
		/**
*2015-11-18 
*テストクラスPlanTriggerProcessTestに移行する
		
	}
	@isTest
	static void selfUnit2() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
    			
		// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst2 = TestCommon.createProductMst(1);
    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst2[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
 	
		Integer stepNum = 0;
		stepNum = 0;
		try {
			delete plan;
		} catch (Exception e) {
			stepNum = 1;
		}
		System.assertEquals(stepNum, 0);	
		/*
    	// 会計画面に動作確認を行う
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
    	List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	AccountAcount__c accObj = accObjLst[0];
 	
    	ApexPages.StandardController contrlAcc = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrlAcc = new BillInput_Ctrl(contrlAcc);
    	ctrlAcc.initAction();
		// 会計明細に、プラン会計商品を設定する
		ctrlAcc.oTranSobjLst[0].sobj.Field7__c = accMsProdId;
		ctrlAcc.upsertData();
		
		stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);
*//**
*2015-11-18 
*テストクラスPlanTriggerProcessTestに移行する

	}
	@isTest
	static void selfUnit2_1() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
    					
    	// 会計画面に動作確認を行う
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan2.Id]; 
		Id accMsProdId = pldLst[0].PlanProdcut__c;
    	//List<AccountAcount__c> accObjLst = [select id,frs__c,Relreserve__c from AccountAcount__c where Relreserve__c = :leadInfo.Id];
    	RsvAccount__c rsv = TestCommon.createRsvAccount();
    	String rsvQuery = CommSqlUtils.generateQueryString('RsvAccount__c');
    	rsv = Database.query(rsvQuery);
    	AccountAcount__c accObj = new AccountAcount__c(frs__r = rsv);
 	
    	ApexPages.StandardController contrlAcc = new ApexPages.StandardController(accObj);
    	BillInput_Ctrl ctrlAcc = new BillInput_Ctrl(contrlAcc);
    	ctrlAcc.initAction();
    	ctrlAcc.insertData();
		// 会計明細に、プラン会計商品を設定する
		ctrlAcc.oTranSobjLst[0].sobj.Field7__c = accMsProdId;
		ctrlAcc.oTranSobjLst[0].productNm = 'テスト商品名';
		ctrlAcc.oTranSobjLst[0].sobj.Field20__c = '2000';
		ctrlAcc.oTranSobjLst[0].sobj.Field21__c = '2000';
		ctrlAcc.oTranSobjLst[0].tranId = '';
		ctrlAcc.oTranSobjLst[0].accRefId = '';
		ctrlAcc.upsertData();
		
		Integer stepNum = 20;
		try {
			delete plan2;
		} catch (Exception e) {
			stepNum = 21;
		}
		System.assertEquals(stepNum, 21);

	}
	
	// プラン名変更にしたがって、関連商品名も自動変更を行う
	*//*
	@isTest
	static void selfUnit3() {
    	Test.startTest();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	// プラン作成
    	Plan__c plan = TestCommon.createPlan();
    	Plan__c plan2 = TestCommon.createPlan();
		// プラン明細作成を行う
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;
		// Plan1作成
		ctrl.savePlanDetail();
		
    	ApexPages.StandardController contrl2 = new ApexPages.StandardController(plan2);
 		PlanProductSetup ctrl2 = new PlanProductSetup(contrl2);
		List<PlanProductSetup.PlanDetail> planDeLst2 = ctrl2.planDetailList;

		planDeLst2[0].productNm = productLst[0].Name;
		planDeLst2[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst2[0].sobj.Price__c = 10000;
		planDeLst2[1].productNm = productLst[1].Name;
		planDeLst2[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst2[1].sobj.Price__c = 20000;
		planDeLst2[2].productNm = productLst[2].Name;
		planDeLst2[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst2[3].sobj.Price__c = 30000;
		// Plan2作成
		ctrl2.savePlanDetail();
		
		Test.stopTest();
		
		// プラン１関連の商品を確認する
		plan.Name = CommUtils.getRandom(10);
		update plan;
		// 関連の商品名を確認する
		List<PlanDetail__c> pldLst = [select id ,PlanRef__c, PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan.Id]; 
		AccountMaster__c accMst = [select name from AccountMaster__c where id = :pldLst[0].PlanProdcut__c];
		System.assertEquals(accMst.Name, plan.Name);
		
	}*/
}