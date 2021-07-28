public with sharing class PurchaseCommTriggerProcess {
	//仕入 金額（税金込み） 金額（税金抜く）自動計算
	public void autoSetupAmountCompute(Purchase__c[] newLst, Purchase__c[] oldLst, CommConst.TriggerMethod action){
		//LOOP index
		integer currIdx = 0;
		//金額（税金込み）SET
		Set<Id> purIncTaxSet = new Set<Id>();
		//金額（税金抜く）SET
		Set<Id> purNoTaxSet = new Set<Id>();
		//取引先SET
		Set<Id> accSet = new Set<Id>();
		// 2018/09/27 入库日对应 WGCH BGEIN
		// 仕入 SET
		Map<Id, Purchase__c> purMap = new Map<Id, Purchase__c>();
		// 2018/09/27 入库日对应 WGCH END
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
		Map<String,String> jmtMap = new Map<String,String>();
		// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
		for (Purchase__c pur : newLst) {
			Decimal denpyoukei = CommUtils.nullToZero(pur.Denpyoukei__c);
			Decimal denpyoukeiIncTax = CommUtils.nullToZero(pur.DenpyoukeiIncTax__c);
			if( denpyoukei == 0 && denpyoukeiIncTax != 0){
				purIncTaxSet.add(pur.Id);
				accSet.add(pur.Purchasesource__c);
			}else if( denpyoukeiIncTax == 0 && denpyoukei != 0){
				purNoTaxSet.add(pur.Id);
				accSet.add(pur.Purchasesource__c);
			}else if(oldLst != null){
				Purchase__c oldPur = oldLst[currIdx];
				Decimal orgDenpyoukei = CommUtils.nullToZero(oldPur.Denpyoukei__c);
				Decimal orgDenpyoukeiIncTax = CommUtils.nullToZero(oldPur.DenpyoukeiIncTax__c);
				if(orgDenpyoukei != denpyoukei && orgDenpyoukeiIncTax == denpyoukeiIncTax){
					purNoTaxSet.add(pur.Id);
					accSet.add(pur.Purchasesource__c);
				}else if(orgDenpyoukei == denpyoukei && orgDenpyoukeiIncTax != denpyoukeiIncTax){
					purIncTaxSet.add(pur.Id);
					accSet.add(pur.Purchasesource__c);
				}else if(orgDenpyoukei == denpyoukei && orgDenpyoukeiIncTax == denpyoukeiIncTax && pur.NoTaxFlg__c != oldPur.NoTaxFlg__c){
					purNoTaxSet.add(pur.Id);
					accSet.add(pur.Purchasesource__c);
				}
			}
			// 2018/09/27 入库日对应 WGCH BGEIN
			purMap.put(pur.Id, pur);
			// 2018/09/27 入库日对应 WGCH END
			currIdx++;
		}
		// 2018/09/27 入库日对应 WGCH BGEIN
		List<PurchaseDetail__c> purDetailLst = [Select Id, InStockDate__c, PurchaseRef__c From PurchaseDetail__c Where PurchaseRef__c in: purMap.keySet()];
		for(PurchaseDetail__c purDetail : purDetailLst){
			Purchase__c  pur = purMap.get(purDetail.PurchaseRef__c);
			purDetail.InStockDate__c = DateTime.newInstance(pur.Field1__c, Time.newInstance(0,0,0,0)).format('yyyyMMdd');
		}
		if(!purDetailLst.isEmpty()) update purDetailLst;
		// 2018/09/27 入库日对应 WGCH END
		if(accSet.isEmpty()) return;
		Map<Id,RoundingMode> roundMap = new Map<Id,RoundingMode>();
		RoundingMode orgMode = CommUtils.pointRoundMode();
		RoundingMode roundMode;
		for(Account acc : [select id,name,RoundType__c from Account where id = :accSet]){
			if(!CommUtils.isBlank(acc.RoundType__c))
				roundMode = CommUtils.pointRoundMode(acc.RoundType__c);
			else
				roundMode = orgMode;
			roundMap.put(acc.id,roundMode);
		}

		//消費税情報を取得
		JMST__c jmst = CommLogicProcess.getTaxRateInfo();
		// 組織の通貨定義情報により、小数点桁数情報を取得する
		integer pointSize = CommUtils.getPointLen();

		for (Purchase__c pur : newLst) {
			Boolean noTaxFlg = pur.NoTaxFlg__c;

			if(!purNoTaxSet.contains(pur.Id) && !purIncTaxSet.contains(pur.Id)) continue;
			if(roundMap.containsKey(pur.Purchasesource__c)) roundMode = roundMap.get(pur.Purchasesource__c);
			else roundMode = orgMode;
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
			Decimal taxRate = pur.taxRate__c == null ? jmst.TaxRate__c : pur.taxRate__c;
			// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
			if(purNoTaxSet.contains(pur.Id)){
				//金額（税金込み）処理を行う
				// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
				//pur.DenpyoukeiIncTax__c = CommUtils.CalIncTaxPrice(pur.Denpyoukei__c, jmst.TaxRate__c, pointSize,roundMode);
				pur.DenpyoukeiIncTax__c = CommUtils.CalIncTaxPrice(pur.Denpyoukei__c, taxRate, pointSize,roundMode);
				// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
				if(noTaxFlg) pur.DenpyoukeiIncTax__c = pur.Denpyoukei__c;
			}else if(purIncTaxSet.contains(pur.Id)){
				//金額（税金抜く）処理を行う
				// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy BEGIN
				// pur.Denpyoukei__c = CommUtils.CalExcTaxPrice(pur.DenpyoukeiIncTax__c, jmst.TaxRate__c, pointSize,roundMode);
				pur.Denpyoukei__c = CommUtils.CalExcTaxPrice(pur.DenpyoukeiIncTax__c, taxRate, pointSize,roundMode);
				// 2019/09/15 11.10月以降の仕入れ入力について税率が10%の商品と8%の商品入力をすることになると思うのですが、どうやって入力するのでしょうか by zy END
				if(noTaxFlg) pur.Denpyoukei__c = pur.DenpyoukeiIncTax__c;
			}
		}
	}
}