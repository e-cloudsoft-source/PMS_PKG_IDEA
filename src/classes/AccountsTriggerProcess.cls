/*********************************************
* 会計情報の関連トリガー処理を行う
* 2012/11/02 POSNo.（POSNo__c）が０のときのみ、会計オブジェクトのレシートNo.を自動採番、０以外のときは、レシートNo.を設定しない
* 2015/02/06 会計人數情報連携
* 2015/04/03 予約から会計人數へ連動処理の修正
*********************************************/
public with sharing class AccountsTriggerProcess {
	//2016/12/27 会計人數自動設定機能封印 BEGIN by zh
	private static final Boolean AccounntStayPersonsAutoSetupFlg = CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c == null ? false : CommDefine__c.getOrgDefaults().AccounntStayPersonsAutoSetupFlg__c;
	//2016/12/27 会計人數自動設定機能封印 END by zh
	public void setupSerialNo(AccountAcount__c[] newLst, AccountAcount__c[] oldLst, CommConst.TriggerMethod action){
		// 新規の場合[After Insert]
		// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
		//List<AccountAcount__c> serinalNoLst = new List<AccountAcount__c>();
		// 2017/01/25 店舗ごとの会計権限機能対応 END
    	if (CommConst.TriggerMethod.IsInsert == action) {
    	   String definePosNo = CommUtils.getPosNoByComdefine();
    	   // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
    	   Integer loopIdx = 0;
    	   map<Integer, AccountAcount__c> dataMatchMap = new map<Integer, AccountAcount__c>();
    	   // 2017/01/25 店舗ごとの会計権限機能対応 END
    	   for (AccountAcount__c nw : newLst) {
    	   	   // 0000 場合
    	       if (nw.POSNo__c == definePosNo){
    	       		// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
                    //serinalNoLst.add(nw); 
                    dataMatchMap.put(loopIdx, nw);
                    // 2017/01/25 店舗ごとの会計権限機能対応 EN
    	       }
    	       loopIdx++;
    	   }
    	   // 自動採番項目がみ存在する場合
    	   // 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
    	   //if (serinalNoLst.isEmpty()) return;
    	   if (dataMatchMap.isEmpty()) return;
    	   // 2017/01/25 店舗ごとの会計権限機能対応 END
    	   // 自動采番を行う[4桁番号のみ]
    	   CommSeqNoProcess utils = new CommSeqNoProcess();
    	   Map<Integer, String> keyMap = utils.getSeqNumbers(dataMatchMap, false);
    	   for (Integer idx : keyMap.keySet()) {
    	   	if (dataMatchMap.containsKey(idx)) {
    	   		AccountAcount__c acc = dataMatchMap.get(idx);
    	   		acc.Field145__c = keyMap.get(idx);
    	   	}
    	   }
    	   /*
    	   Map<Id, String> keyMap = utils.getSeqNumbers(serinalNoLst, false);
    	   if (keyMap != null) {
                List<AccountAcount__c> updLst = new List<AccountAcount__c>();
				for (AccountAcount__c s : [select Field145__c from AccountAcount__c where id in :keyMap.keySet()]) {
					if (keyMap.containsKey(s.Id)) {
                        s.Field145__c = keyMap.get(s.Id);
                        updLst.add(s);
					}
				}
				if (!updLst.isEmpty()) update updLst;
    	   }*/
    	}
	}
    // 会計データは新規登録前の項目自動設定機能[insert before]
    public void autoSetupInfo(AccountAcount__c[] newList, AccountAcount__c[] oldList, CommConst.TriggerMethod action){
    	
    	// 2018/06/06 編集権限チェックできる対応 BEGIN
    	if (CommSecurityUtils.getAuthInstance().NoEditAccount__c == true) {
    		//throw new CommException('該当権限がありません。');
    		newList[0].addError(Label.MSG_9105);
    		return;
    	}
    	// 2018/06/06 編集権限チェックできる対応 END
    	
		// 新規場合
		// 2016/12/27 会計人數自動設定機能封印
		if(AccounntStayPersonsAutoSetupFlg){
		if (action == CommConst.TriggerMethod.isInsert) {
			Set<Id> leadIdSet = new Set<Id>();
			for (AccountAcount__c nw: newList) {
				if (nw.Relreserve__c == null) continue;
				leadIdSet.add(nw.Relreserve__c);
			}
			// 予約人数を自動設定を行う　
			Map<Id, Lead__c> leadMap = new Map<Id, Lead__c>([select StayPersons__c, Mans__c, Femails__c, ChildFA__c, Childs__c from Lead__c where id in :leadIdSet]);
			// 予約情報から予約人数を自動設定を行う
			for (AccountAcount__c nw: newList) {
				if (nw.Relreserve__c == null) continue;
				if(leadMap.containsKey(nw.Relreserve__c)) {
					Lead__c obj = leadMap.get(nw.Relreserve__c);
					// 会計人数から男性に優先設定を行う
					if (CommUtils.nullToZero(obj.StayPersons__c) > 0)
					   nw.Field66__c = String.valueOf(obj.StayPersons__c);
					else {
						nw.Field66__c = String.valueOf(CommUtils.nullToZero(obj.Mans__c));
						nw.Field67__c = String.valueOf(CommUtils.nullToZero(obj.Femails__c));
						nw.Field68__c = String.valueOf(CommUtils.nullToZero(obj.ChildFA__c) +
					                                   CommUtils.nullToZero(obj.Childs__c));
					}
					nw.Field57__c = String.valueOf(
										CommUtils.nullToZero(nw.Field66__c) +
										CommUtils.nullToZero(nw.Field67__c) +
										CommUtils.nullToZero(nw.Field68__c));
				}
			}
		}
		}
		/*
		// 会計人数は０の場合、会計男性は自動１に設定を行う　
		if (action == CommConst.TriggerMethod.isInsert ||
			action == CommConst.TriggerMethod.isUpdate ) {
			for (AccountAcount__c nw: newList) {
				if (CommUtils.nullToZero(nw.Field66__c) == 0 &&
					CommUtils.nullToZero(nw.Field67__c) == 0 &&
					CommUtils.nullToZero(nw.Field68__c) == 0) {
					// 2013/05/23 人数初期値定義修正
					//nw.Field66__c = '1';
					nw.Field66__c = String.valueOf(CommConst.getBookingMansDef());
					nw.Field67__c = String.valueOf(CommConst.getBookingFemailsDef());
					nw.Field68__c = String.valueOf(CommConst.getBookingChildrenDef());
				}
				// 会計人数
				nw.Field57__c = String.valueOf(
											CommUtils.nullToZero(nw.Field66__c) +
											CommUtils.nullToZero(nw.Field67__c) +
											CommUtils.nullToZero(nw.Field68__c));
			}
		}*/
		/*
		// 新規機能のみ
		// 消費税レート設定を行う
		if (action == CommConst.TriggerMethod.isInsert) {
			List<AccountAcount__c> rateLstInfo = new List<AccountAcount__c>();
			Set<Date> accountDateSet = new Set<Date>();	// 営業日付リスト
			for (AccountAcount__c nw: newList) {
				// 消費税は未設定する場合
				if (nw.TaxRate__c == null) {
					accountDateSet.add(nw.SalesdayCal__c);
					rateLstInfo.add(nw);
				}
			}
			if (!rateLstInfo.isEmpty()) {
				// 指定日付の消費税情報を取得する
				Map<Date, Decimal> rateMap = CommUtils.getTaxRateMap(accountDateSet);
				for (AccountAcount__c nw : rateLstInfo) {
					nw.TaxRate__c = rateMap.get(nw.SalesdayCal__c);
				}
			}
		}*/
		// 売上計上日設定する
		for (AccountAcount__c nw: newList) {
			nw.SalesDate__c = nw.SalesdayCal__c;
		}
			// 2019/09/30 自動レシートNO設定エラー修正 by zy BEGIN
			if (action == CommConst.TriggerMethod.isUpdate) {
				for (integer i = 0 ; i < newList.size(); i++) {
					AccountAcount__c nw = newList[i];
					AccountAcount__c od = oldList[i];
					// 売上計上日の場合、レシート印刷のNoをクリアする
					if (nw.SalesDate__c != od.SalesDate__c && !CommUtils.isBlank(nw.ReciptNo__c)) nw.ReciptNo__c = null;
				}
			}
			// 2019/09/30 自動レシートNO設定エラー修正 by zy END
    }
    
    /**
    * 会計データが新規作成場合、自動的に、予約データに設定した部屋、部屋タイプ、支店店舗情報設定を行う
    * Action: Before Insert
    * 簡易会計のとき、ユーザに店舗コードがある場合、店舗別集計されないようです、店舗集計対応
    **/
    public void copyRoomInfo(AccountAcount__c[] newLst, AccountAcount__c[] oldLst, CommConst.TriggerMethod action){
    	// 新規以外の場合、処理なし
    	if (CommConst.TriggerMethod.IsInsert != action &&
    		CommConst.TriggerMethod.IsUpdate != action ) return;
    	// Map<会計ID, 予約ID>
    	Map<Id, Id> leadAccountsIdMap = new Map<Id, Id>();
    	// 予約データ非存在 && ログインユーザーの店舗コードが存在する場合、該当店舗コードにて、店舗情報は会計に設定を行う
    	// LIST<会計情報>
    	List<AccountAcount__c> noLeadInfoAccLst = new List<AccountAcount__c>();
    	// ログインユーザーの店舗コードを取得する
    	User loginUser = UserUtil.getUser(UserInfo.getUserId());
    	// 会計に、予約データ設定あり、部屋アサイン済み場合、関連情報設定を行う
    	for (AccountAcount__c nw : newLst) {
    		// 予約データが未設定する場合、自動設定なし
    		//if (nw.Relreserve__c == null) continue;
    		// 予約データがないと、ログイン者の店舗コードで店舗設定を行う
    		if (nw.Relreserve__c == null) {
    			// 2017/01/25 簡易会計の場合、店舗コードを未設定　かつ　ユーザーの店舗コードが存在する場合、該当ユーザーの店舗コードを会計に設定する
    			//if (!CommUtils.isBlank(loginUser.ShopCode__c)) {
    			if (!CommUtils.isBlank(loginUser.ShopCode__c) && CommUtils.isBlank(nw.ShopCode__c)) {
    				noLeadInfoAccLst.add(nw);
    			}
    		}
    		// 予約データから、部屋設定の場合、関連の部屋、部屋タイプ、支店情報を取得、設定を行う
    		leadAccountsIdMap.put(nw.Id, nw.Relreserve__c);
    	}
    	// 処理データなかった場合、処理中止
    	if (leadAccountsIdMap.isEmpty() && noLeadInfoAccLst.isEmpty()) return;
    	// 予約データ設定存在する場合、該当予約の部屋情報を設定する
    	// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ BEGIN
    	Map<Id, Lead__c> existLeadMap = new Map<Id, Lead__c>();
    	// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ END
    	if (!leadAccountsIdMap.isEmpty()) {
	    	// 既存の予約情報
	    	// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ BEGIN
	    	//Map<Id, Lead__c> existLeadMap = new Map<Id, Lead__c>();
	    	// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ END
	    	for (Lead__c lead : [Select Id, Rroom__r.DisplayNo__c, Rroom__r.Seq__c, Rroom__r.Name,
	    							Rroom__c, Rroom__r.ShopInfoRef__c, Rroom__r.TypeRoomRef__c,OtherShopEditCheckFlg__c,
	    							Rroom__r.ShopInfoRef__r.Name, Rroom__r.ShopInfoRef__r.ShopCode__c, Rroom__r.ShopInfoRef__r.Seq__c,
	    							Rroom__r.TypeRoomRef__r.Name, Rroom__r.TypeRoomRef__r.Seq__c, Rroom__r.TypeRoomRef__r.RoomTypeCode__c 
	    						 From Lead__c
	    						 Where Rroom__c != null And Id in :leadAccountsIdMap.values()]) {
	    		// 予約から部屋の関連設定情報
	    		existLeadMap.put(lead.Id, lead);
	    	}
	    	for (AccountAcount__c nw : newLst) {
	    		if (leadAccountsIdMap.containsKey(nw.Id)) {
	    			Id leadId = leadAccountsIdMap.get(nw.Id);
	    			Lead__c extLead = existLeadMap.get(leadId);
	    			if (extLead == null) continue;
	    			// 店舗情報設定
	    			nw.ShopSeq__c = extLead.Rroom__r.ShopInfoRef__r.Seq__c;
	    			nw.ShopCode__c = extLead.Rroom__r.ShopInfoRef__r.ShopCode__c;
	    			nw.ShopName__c = extLead.Rroom__r.ShopInfoRef__r.Name;
	    			
	    			// 部屋情報設定
	    			nw.RoomDisplayNo__c = extLead.Rroom__r.DisplayNo__c;
	    			nw.RoomSeq__c = extLead.Rroom__r.Seq__c;
	    			nw.RoomName__c = extLead.Rroom__r.Name;
	    			
	    			// 部屋タイプ情報設定
	    			nw.TypeOfRoomSeq__c = extLead.Rroom__r.TypeRoomRef__r.Seq__c;
	    			nw.TypeOfRoomCode__c = extLead.Rroom__r.TypeRoomRef__r.RoomTypeCode__c;
	    			nw.TypeOfRoomName__c = extLead.Rroom__r.TypeRoomRef__r.Name;
		    	}
		    }//end for (AccountAcount__c nw : newLst)
    	}
    	// 予約データなし、直接店舗コードにて、店舗関連情報を設定する
    	if (!noLeadInfoAccLst.isEmpty()) {
    		List<ShopInformation__c> shopInfoLst = [select ShopCode__c, Name, Seq__c from ShopInformation__c where ShopCode__c = :loginUser.ShopCode__c];
    		if (!shopInfoLst.isEmpty()) {
    			for (AccountAcount__c nw : noLeadInfoAccLst) {
	    			// 店舗情報設定
	    			nw.ShopSeq__c 		= shopInfoLst[0].Seq__c;
	    			nw.ShopCode__c 	= shopInfoLst[0].ShopCode__c;
	    			nw.ShopName__c	= shopInfoLst[0].Name;
    			}
    		}
    	}
    	
		// 2017/01/25 店舗ごとの会計権限機能対応 BEGIN
		if (CommConst.ShopEditAuthCheckFlg) {
			// 該当会計を更新される場合
			if (action == CommConst.TriggerMethod.isUpdate ||
				action == CommConst.TriggerMethod.isInsert ) {
				// ユーザー編集できるの店舗対象リスト
				set<string> canEditShopCdSet = UserUtil.CurrentUserInfo.shopSt;
				if (!canEditShopCdSet.isEmpty()) {
					// 会計更新フラグをチェックする
					for (Integer i = 0; i < newLst.size(); i++) {
						AccountAcount__c nw = newLst[i];
						//AccountAcount__c od = oldLst[i];
						// チェック対象外の場合、次のデータを処理する
						if (nw.OtherShopEditCheckFlg__c) {
							nw.OtherShopEditCheckFlg__c = false;
							continue;
						}
						// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ BEGIN
						if (leadAccountsIdMap.containsKey(nw.Id)) {
							Id leadId = leadAccountsIdMap.get(nw.Id);
							Lead__c l = existLeadMap.get(leadId);
							if (l != null && l.OtherShopEditCheckFlg__c) continue;
						}
						// 2019/06/06 予約キャンセルにより、会計連動更新場合、予約店舗別更新可能の場合、該当会計も連動更新可能対応する WSQ BEGIN
						// 該当会計に所属する店舗コードを格納する
						String shopCode = nw.ShopCode__c;
						// 該当会計の店舗コードはNULLの場合、だれでも更新できる
						if (CommUtils.isBlank(shopCode)) continue;
						// 該当施設は多店舗　かつ　該当会計の店舗コードは該当ユーザーを参照できる店舗に含まない場合、更新できない
						if (!canEditShopCdSet.contains(shopCode)) {
							nw.addError(Label.MSG_006_0441);	
							break;
						}
					}
				}
			}
		}
		// 2017/01/25 店舗ごとの会計権限機能対応 END
    }
    
    // 会計新規作成/更新場合、予約データへ連携更新を行う(After Insert/After Update)
    public void syncAccInfoToLead(AccountAcount__c[] newList, AccountAcount__c[] oldList, CommConst.TriggerMethod action){
    	// 会計情報の[入金確認]項目連動を行う
    	// 会計から予約データへ更新[1 VS 1]
    	Map<Id, AccountAcount__c> upMap = new Map<Id, AccountAcount__c>();
    	if (action == CommConst.TriggerMethod.IsInsert) {
    		for (AccountAcount__c acc : newList) {
    			if (acc.PaymentFlg__c && acc.Relreserve__c != null) upMap.put(acc.Relreserve__c, acc);
    		}
    	} else if (action == CommConst.TriggerMethod.IsUpdate) {
    		for (Integer i = 0; i < newList.size(); i++) {
    			//if (acc.PaymentFlg__c && acc.Relreserve__c != null) upMap.put(acc.Relreserve__c, acc);
    			AccountAcount__c nw = newList[i];
    			AccountAcount__c od = oldList[i];
    			// フラグ変更場合のみ、連動を行う
    			if (nw.PaymentFlg__c != od.PaymentFlg__c && nw.Relreserve__c != null) upMap.put(nw.Relreserve__c, nw);
    		}
    	}
    	if (upMap.isEmpty()) return;
    	// 連携対象存在する場合
    	List<Lead__c> leadLst = [select PaymentFlg__c from Lead__c where id in :upMap.keySet()];
    	for (Lead__c l : leadLst) {
    		l.PaymentFlg__c = upMap.get(l.Id).PaymentFlg__c;
    	}
    	update leadLst;
    }
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	// 如果当前时间 大于 截止日就跳出 【不可变更】
	public Boolean compareSalesdayCalInfo(AccountAcount__c[] nw, AccountAcount__c[] od, CommConst.TriggerMethod action){
		Boolean isError = false;
		// 現在実行中のコードがアノテーション future が付加されたメソッドに含まれるコードから呼び出された場合は true を返します。呼び出されていない場合は false を返します。
		if(System.isFuture()) return isError;
		// 获取锁定日期设定
		CommLogicProcess.ComDay comDayItem = new CommLogicProcess.ComDay();
		// 如果没有设定信息认为功能关闭
		if(!comDayItem.setComDay()) return isError;
		// 获取管理员信息
		CommLogicProcess.AccountAdminInfo accAdminItem = CommLogicProcess.getAccountAdminInfo();
		// 新数据
		List<AccountAcount__c> nwLst = null;
		// 旧数据
		List<AccountAcount__c> odLst = null;
		// 新規場合
		if(action == CommConst.TriggerMethod.IsInsert){
			nwLst = nw;
			odLst = od;
		}
		// 更新作業場合
		if(action == CommConst.TriggerMethod.IsUpdate){
			nwLst = nw;
			odLst = od;
		}
		// 削除作業場合
		else if (action == CommConst.TriggerMethod.IsDelete ) {
			nwLst = od;
			odLst = od;
		}
		// 有效场合check
		for (Integer i = 0; i < nwLst.size(); i++){
			AccountAcount__c acc = nwLst[i];
			// old数据场合
			if(odLst != null) acc = odLst[i];
			// 设定Error成功跳到下次循环
			if(CommLogicProcess.isAccLockFlg(acc, accAdminItem, comDayItem)){
				nwLst[i].addError(Label.MSG_006_0459);
				isError = true;
				continue;
			}
		}
		return isError;
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
}