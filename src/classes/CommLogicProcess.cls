/**
* ロジック処理共通化
**/
public with sharing class CommLogicProcess {
	// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
    private Integer CONST_MAX_ROOMTYPE = 10000;
    public CommLogicProcess(){}
    public CommLogicProcess(Integer maxInt){
    	CONST_MAX_ROOMTYPE = maxInt;
    }
    // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
	/**
	* 重複チェック処理を行う
	* nwLst: チェック対象リスト
	* uniqueFieldNm: チェック対象項目名
	* sobjectName: オブジェクト名
	**/
	public void hasCandidateDuplicates(List<Sobject> nwLst, String uniqueFieldNm, String sobjectName) {
		hasCandidateDuplicates(nwLst, uniqueFieldNm, sobjectName, null);
	}
	public void hasCandidateDuplicates(List<Sobject> nwLst, String uniqueFieldNm, String sobjectName, String message) {
		// チェック対象項目名対応値, チェック対象オブジェクト
		Map<Object, Sobject> candidateMap = new Map<Object, Sobject>();
		for (Sobject s : nwLst) {
			Object uniqueFieldVal = s.get(uniqueFieldNm);
			if (candidateMap.containsKey(uniqueFieldVal)) {
				//重複データ存在するため、登録できません。
				s.addError((message == null ? Label.MSG_012_0416 : message));
			} 
			// 非存在する場合
			else {
				candidateMap.put(uniqueFieldVal, s);
			}
		}
		// 処理対象なし場合、処理完了
		if (candidateMap.isEmpty()) return;

System.debug('candidateMap::::' + candidateMap);	
		// 
		CommUtils.ObjectBuilder factory = new CommUtils.ObjectBuilder(nwLst[0].getSObjectType());
/*
System.debug('factory:' + factory);		
System.debug('uniqueFieldNm:' + uniqueFieldNm);		
for (String ty: factory.fieldTypeMap.keyset()) {
	System.debug('ty:::::' + ty);
}*/
		Schema.DisplayType fieldType = factory.getDisplayType(uniqueFieldNm);
		// 検索結果格納
		List<Sobject> rsLst = null;
		// Query SQL
		String strQuery = ' Select ' + uniqueFieldNm + ' From ' + sobjectName + ' Where ' + uniqueFieldNm + ' in : keySet';
System.debug('---- [fieldType] ----' + fieldType);
/*		if(	fieldType == Schema.DisplayType.Integer ||
			fieldType == Schema.DisplayType.Double ||
			fieldType == Schema.DisplayType.Percent ||
			fieldType == Schema.DisplayType.Currency ) {
			Set<Decimal> keyset = new Set<Decimal>();
			for (Object o : candidateMap.keySet()) { keyset.add((Decimal)o);}
			rsLst = Database.query(strQuery);
        }
        else */
        if(fieldType == Schema.DisplayType.Date) {
			Set<Date> keyset = new Set<Date>();
			for (Object o : candidateMap.keySet()) { keyset.add((Date)o);}
			rsLst = Database.query(strQuery);
        }
/*
        else if(fieldType == Schema.DisplayType.DateTime) {
			Set<DateTime> keyset = new Set<DateTime>();
			for (Object o : candidateMap.keySet()) { keyset.add((DateTime)o);}
			rsLst = Database.query(strQuery);
        }
        else if(fieldType == Schema.DisplayType.Boolean) {
			Set<Boolean> keyset = new Set<Boolean>();
			for (Object o : candidateMap.keySet()) { keyset.add((Boolean)o);}
			rsLst = Database.query(strQuery);
        } */
        else if(fieldType == Schema.DisplayType.String) {
			Set<String> keyset = new Set<String>();
			for (Object o : candidateMap.keySet()) { keyset.add((String)o);}
			rsLst = Database.query(strQuery);
        }
        
        // 結果にて、重複チェックを行う
        //処理項目タイプは処理対象外。
        if (rsLst == null) throw new CommException(Label.MSG_012_0415);
		for (Sobject s: rsLst) {
			Object uniqueFieldVal = s.get(uniqueFieldNm);
			if (candidateMap.containsKey(uniqueFieldVal)) {
				if (candidateMap.get(uniqueFieldVal).id != s.Id) 
				//重複データ存在するため、登録できません。
				candidateMap.get(uniqueFieldVal).addError((message == null ? Label.MSG_012_0416 : message));
			}
		}

	}
	/**
	* 予約一括登録画面データ構造に合わせて、IndexSub自動作成機能
	* 予約ポップ画面・中継アプリ自動連携機能対応、その以外使わないください
	* 処理前提条件：INDEXの開始日は全体の開始日、終了日は全体の処理日、部屋数は全体部屋数、人数は予約全体一致
	**/
	public void autoCreateIndexSub(List<Lead__c> p_leadLst) {
        // 前提条件は同じINDEXの予約情報の処理する
     	// Index ID/RoomType ID
    	// 同じIndexの予約データの部屋タイプを取得する
    	Set<Id> roomTypeIdSet = new Set<Id>();
    	Map<Id, Lead__c> leadMapInfo = new Map<Id, Lead__c>();
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		Set<String> roomTypeKeyIdSet = new Set<String>();
		Map<String, Lead__c> leadRoomMapInfo = new Map<String, Lead__c>();
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        // Leadの部屋タイプを処理を行う
        for (Lead__c ld : p_leadLst) {
        	if (ld.LeadIndexRef__c == null) throw new CommException('Required Field Value Not Setup!');
			//if (ld.refTypeOfRooms__c == null) continue;
        	roomTypeIdSet.add(ld.refTypeOfRooms__c);
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			String key = ld.refTypeOfRooms__c;
			if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) key += '_' + ld.roomgroupNo__c;
			roomTypeKeyIdSet.add(key);
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        	// 同じ部屋タイプの予約情報の基本設計情報はと一致する「例：開始日・終了日」
        	//leadMapInfo.put(ld.refTypeOfRooms__c, ld);
        	// 2013/08/12 親部屋機能に従って、格納方式変更
        	if (!leadMapInfo.containsKey(ld.refTypeOfRooms__c)) leadMapInfo.put(ld.refTypeOfRooms__c, ld);
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			if (!leadRoomMapInfo.containsKey(key)) leadRoomMapInfo.put(key, ld);
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        }
 		if (roomTypeIdSet.isEmpty()) return;
 		
 		// Index オブジェクト情報を取得する
 		List<LeadIndex__c> leadIdxLst = [select id, name, EntryDate__c, DepartureDate__c, Nights__c, Rooms__c, contactRef__c
 												,LeadName__c,EntryTime__c,DepartureTime__c,Payment__c,Comment__c
                    from LeadIndex__c where id = :p_leadLst[0].LeadIndexRef__c];
		if (leadIdxLst.isEmpty()) return;
		
		// 予約INDEX情報
		LeadIndex__c idxInfo = leadIdxLst[0];
        // Sub Index作成を行う
        // Index情報を取得して、SUBINDEXへ設定を行う
        Map<Id, LeadIndex__c> idxSubMap = new Map<Id, LeadIndex__c>();
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
		Map<String, LeadIndex__c> idxSubRoomMap = new Map<String, LeadIndex__c>();
		boolean hadParFlag = false;
        // 部屋タイプ
        // for (Id roomTypeId : roomTypeIdSet) {
		for (String key : roomTypeKeyIdSet) {
			Id roomTypeId = null;
        	// 部屋タイプにて、共通の予約情報を取得する
        	// Lead__c leadInfo = leadMapInfo.get(roomTypeId);
            Lead__c leadInfo = null;
			if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) {
				leadInfo = leadRoomMapInfo.get(key);
				roomTypeId = leadInfo.refTypeOfRooms__c;
			} else {
				roomTypeId = key;
				leadInfo = leadMapInfo.get(roomTypeId);
			}
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
            LeadIndex__c nwSub = new LeadIndex__c();
            nwSub.ParentLeadIndxRef__c = idxInfo.Id;
            // エキストラベッド(E/B)
            nwSub.ExtraBedChk__c = leadInfo.ExtraBedChk__c;
            nwSub.PlanRef__c = leadInfo.Field310__c;
            nwSub.Nights__c = idxInfo.Nights__c;
            nwSub.Rooms__c = CommUtils.nullToZero(idxInfo.Rooms__c) == 0 ? 1 : CommUtils.nullToZero(idxInfo.Rooms__c);
            nwSub.RoomTypeRef__c = roomTypeId;
            nwSub.DepartureDate__c = idxInfo.DepartureDate__c;
            nwSub.EntryDate__c = idxInfo.EntryDate__c;
            nwSub.StayPersons__c = leadInfo.StayPersons__c;
            nwSub.contactRef__c = idxInfo.contactRef__c;
            // 出発時刻と到着時刻設定追加
            nwSub.EntryTime__c = idxInfo.EntryTime__c;
            nwSub.DepartureTime__c = idxInfo.DepartureTime__c;
            nwSub.LeadName__c = idxInfo.LeadName__c;
			// 支払方法
			nwSub.Payment__c = idxInfo.Payment__c;
			// 特記事項
			nwSub.Comment__c = idxInfo.Comment__c;
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			if (!hadParFlag) {
				nwSub.ParentFlg__c = hadParFlag = true;
			}
			if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG){
				nwSub.Rooms__c = 1;
				idxSubRoomMap.put(key, nwSub);
			} else
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
            idxSubMap.put(roomTypeId, nwSub);
        }
		// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
system.debug(LoggingLevel.info, 'idxSubRoomMap::::' + idxSubRoomMap);
        if (!idxSubMap.isEMpty())insert idxSubMap.values();
		if (!idxSubRoomMap.isEMpty())insert idxSubRoomMap.values();
		// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        for (Lead__c nw : p_leadLst) {
			// 2019/11/15 一括予約画面の部屋直接選択 by zy BEGIN
			String key = nw.refTypeOfRooms__c;
			if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG) key += '_' + nw.roomGroupNo__c; 
        	// if (idxSubMap.containsKey(nw.refTypeOfRooms__c)) {
				// nw.LeadIndexSubId__c = idxSubMap.get(nw.refTypeOfRooms__c).Id;
        	if (idxSubRoomMap.containsKey(key)) {
				nw.LeadIndexSubId__c = idxSubRoomMap.get(key).Id;
        	} else
			if (idxSubMap.containsKey(nw.refTypeOfRooms__c)) {
				nw.LeadIndexSubId__c = idxSubMap.get(key).Id;
        	}  
			// 2019/11/15 一括予約画面の部屋直接選択 by zy END
        }
 	
	}

	public static String getLeadCateringRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'CateringRecType'][0].Id;       
	}
    public static String getLeadBaseRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'BaseRecType'][0].Id;   
    }
    // 宴会のレコードタイプ
    public static String getLeadEnkaiRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'EnkaiRecType'][0].Id;   
    }
    // 宿泊
    public static String getLeadBookingRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'BookingRecType'][0].Id;   
    }
    // 2017/02/21 予約関連の識別のキーを共通化関数
    public static String getKeyOfSameGroupLead(Id leadIdxId, Id leadSubIdx, Decimal groupNo) {
		return 	  CommUtils.nullToBlank(leadIdxId) 
				+ '_' 
				+ CommUtils.nullToBlank(leadSubIdx) 
				+ '_' 
				+ CommUtils.nullToBlank(groupNo);
    }
    // 発行日内容設定
    // 2013/09/25 但し書き内容を更新する [Parameter:accountProviso]
    @future
    public static void writeLogInfo(List<Id> idLst, String accountProviso, String receiptName, String accName) {
    	// 処理対象なし、処理中止
    	if (idLst.isEmpty()) return;
    	// Salesforce ID -> Sobject Type
    	String locPrefix = String.valueOf(idLst[0]).substring(0,3);
		Schema.DescribeSObjectResult r = AccountAcount__c.sObjectType.getDescribe();
		if (locPrefix == r.keyPrefix) {
			// 会計データにデータを書き込むする
    		commWriteLogInfo(idLst, accountProviso, receiptName, accName);
		} else {
			// 会計明細にデータを書き込みする
			commTranWriteLogInfo(idLst, accountProviso, receiptName, accName);
		}
    }
    /**
    * 引数: accIdLst 会計対象リストID
    *      accountProviso 但し書き
    *      receiptName    請求書宛名
    *      accName        会計宛名
    **/
    private static void commWriteLogInfo(List<Id> accIdLst, String accountProviso, String receiptName, String accName) {
    	// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'IssueDate__c','AccountReceiptName__c','AccountProviso__c','AccountName__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountAcount__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2017/02/21 Field Security Check End
    	List<AccountAcount__c> accRsLst = new List<AccountAcount__c>();
    	for (AccountAcount__c acc :[select IssueDate__c,AccountProviso__c from AccountAcount__c where id in :accIdLst]) {
    		acc.IssueDate__c = Date.today();
    		if (accountProviso != null) acc.AccountProviso__c = accountProviso;
    		if (receiptName != null) acc.AccountReceiptName__c = receiptName;
    		if (accName != null) acc.AccountName__c = accName;
    		accRsLst.add(acc);
    	}
    	// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
    	(new CommLogicProcess()).preventShopAuthCheckSetup(accRsLst);
    	// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
    	update accRsLst;
    }
    /**
    * 引数: accIdLst 会計明細対象リストID
    *      accountProviso 但し書き
    *      receiptName    請求書宛名
    *      accName        会計宛名
    **/
    private static void commTranWriteLogInfo(List<Id> tranIdLst, String accountProviso, String receiptName, String accName) {
    	// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'AccountReceiptName__c','AccountProviso__c','AccountName__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.Tran1__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2017/02/21 Field Security Check End
	    // 2017/05/11 明細印刷済み識別機能追加 BEGIN
		Schema.SObjectType ttendStype = Ttend__c.sObjectType;
		List<Id> wkTranIdLst = new List<id>();
		List<Id> wkTtendIdLst = new List<Id>();
	    // 会計支払の場合
	    for (Id wkId : tranIdLst) {
			if (wkId.getSobjectType() == ttendStype) {
				wkTtendIdLst.add(wkId);
			} else {
				wkTranIdLst.add(wkId);
			}
	    }
	    if (!wkTtendIdLst.isEmpty()) {
	    	list<Ttend__c> updTtendLst = [select Id,PrintedFlg__c from Ttend__c where id in :wkTtendIdLst];
	    	for (Ttend__c wkTtend : updTtendLst) {
	    		wkTtend.PrintedFlg__c = true;
	    	}
	    	update updTtendLst;
	    }
	    if (!wkTranIdLst.isEmpty()) {
	    // 2017/05/11 明細印刷済み識別機能追加 END
	        List<Tran1__c> rsLst = new List<Tran1__c>();
	        Set<Id> accIdSet = new Set<Id>();
	        List<AccountAcount__c> updAccList = new List<AccountAcount__c>();
	        Date todayDt = Date.today();
	        for (Tran1__c acc :[select Id,AccountProviso__c,Field1__c from Tran1__c where id in :wkTranIdLst]) {
	            if (accountProviso != null) acc.AccountProviso__c = accountProviso;
	            if (receiptName != null) acc.AccountReceiptName__c = receiptName;
	            if (accName != null) acc.AccountName__c = accName;
	            // 2017/05/11 明細印刷済み識別機能追加 BEGIN
	            acc.PrintedFlg__c = true;
	            // 2017/05/11 明細印刷済み識別機能追加 END
	            rsLst.add(acc);
	            // 関連会計更新を行う
	            if (!accIdSet.contains(acc.Field1__c)) {
	            	AccountAcount__c pAcc = new AccountAcount__c(id = acc.Field1__c, IssueDate__c = todayDt);
	            	updAccList.add(pAcc);
	            	accIdSet.add(acc.Field1__c);
	            }
	        }
	        // 関連の会計の会計時間も更新を行う
	        update rsLst;
	        if (!updAccList.isEmpty()) update updAccList;
	    }  
    }
    @future
    public static void writeLogInfo(List<Id> accIdLst) {
    	commWriteLogInfo(accIdLst, null, null, null);
    }
    
    // 2013/07/30 支店機能対応
    public List<TypeOfRooms__c> getTypeOfRooms(String branchShopNm) {
        String typeOfRoomActType = CommConst.ROOMTYPE_NORMAL;
        // 2018/12/15 ラックレート部屋タイプ別の対応　by　zy　BEGIN
        // 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz BEGIN
        String typeOfRoomQuery = ' select Id, Name, SumNotApplicableFlg__c,MaxRooms__c,MaxNumber__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ActionType__c,AgtInitStockCal__c From TypeOfRooms__c where ActionType__c = :typeOfRoomActType '; //Order by Seq__c  limit 200';
        // 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz END
        // 2018/12/15 ラックレート部屋タイプ別の対応　by　zy　END
        if (!CommUtils.isBlank(branchShopNm)) typeOfRoomQuery += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
        // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
	// typeOfRoomQuery += ' Order by Seq__c, RoomTypeCode__c  limit 10000 ';
	    typeOfRoomQuery += ' Order by Seq__c, RoomTypeCode__c  limit :CONST_MAX_ROOMTYPE';
	    // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
        return DataBase.query(typeOfRoomQuery);
    }
    public List<TypeOfRooms__c> getTypeOfRooms(List<String> branchShopNm) {
 		String typeOfRoomActType = CommConst.ROOMTYPE_NORMAL;
 		// 2018/12/15 ラックレート部屋タイプ別の対応　by　zy　BEGIN
 		// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz BEGIN
		String typeOfRoomQuery = ' select Id, Name, SumNotApplicableFlg__c,MaxRooms__c,MaxNumber__c,ShopInfoRef__c,ShopInfoRef__r.ShopCode__c,ActionType__c,AgtInitStockCal__c From TypeOfRooms__c where ActionType__c = :typeOfRoomActType '; //Order by Seq__c  limit 200';
		// 2019/04/30 予約ポップの在庫設定(AGT)の変更機能 BY zyz END
		// 2018/12/15 ラックレート部屋タイプ別の対応　by　zy　END
		if (branchShopNm.size() > 0) typeOfRoomQuery += ' And ShopInfoRef__r.ShopCode__c = :branchShopNm ';
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy BEGIN
		// 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ BEGIN
		// typeOfRoomQuery += ' Order by ShopInfoRef__r.ShopCode__c, Seq__c, RoomTypeCode__c  limit 10000 ';
	    typeOfRoomQuery += ' Order by ShopInfoRef__r.ShopCode__c, Seq__c, RoomTypeCode__c  limit :CONST_MAX_ROOMTYPE';
	    // 2021/03/16 最大部屋タイプ数表示制限機能追加 WSQ END
		// 2019/01/30 部屋タイプを選ぶ際、ユーザは複数店舗 by zy END
		return DataBase.query(typeOfRoomQuery);
    }
    // 2014/09/29 仮お客様情報を自動作成機能
    public static Contact getOrInsertTempContact() {
    	// 2017/02/23 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'ID__c','LastName','email'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		// 2017/02/23 Field Security Check End by wx
    	String searchKey = CommConst.CONTACT_TEMP_ID;
    	Contact contact = null;
    	List<Contact> contacts = [select name,lastName,firstName,email from Contact where ID__c =:searchKey];
    	if(contacts.isEmpty() ) {
    		contact = new Contact(
    		//上様
				LastName = Label.CONST_012_0414
			   ,ID__c = searchKey
			);
			insert contact;
			return contact;
    	} else {
    		return contacts[0];
    	}
    }
    // 2014/11/04 売上新規、取得共通Method
    public static RsvAccount__c getRsvAccountInf (Date pDt) {
		String strName = DateTime.newInstance( pDt.year(), pDt.month(), pDt.day() ).format('yyyyMMdd');
        List<RsvAccount__c> existRsvLst = [select id,Name,Salesday__c from RsvAccount__c where Name = :strName limit 1];
		// 非存在する場合、自動売上データを作成する
		if (existRsvLst.isEmpty()) {
			RsvAccount__c nw = new RsvAccount__c(name = strName) ;
			upsert nw name;
			return nw;
		} else {
			return existRsvLst[0];
		}
    }
    // 2015/05/21 会計書、請求書、見積書敬称取得対応
    public static String getPrintReceiptTitle(String receiptName) {
    	//様
        String defTitle = Label.CONST_012_0413;
        if (CommUtils.isBlank(receiptName)) return defTitle;
        // 引渡しの宛名により、敬称を取得する
        String receiptTitleRule = CommDefine__c.getOrgDefaults().AccountPrintRecipientTitleRule__c;
        if (CommUtils.isBLank(receiptTitleRule)) return defTitle;
        // 書式：key1,key2,...,keyn?敬称1:敬称2
        String[] keyRule = receiptTitleRule.split('[?:]');
        if (keyRule.size() != 3) return defTitle;
        String[] keys = keyRule[0].split(',');
        for (String key : keys) {
            if (receiptName.contains(key)) {
                return keyRule[1];
            }
        }
        return keyRule[2];
	}
    // 2015/09/21 消費税情報を取得Method
    public static JMST__c getTaxRateInfo () {
		List<JMST__c> taxRates = [Select Id, TaxRate__c From JMST__c where TaxRate__c > 0 Order By CreatedDate asc limit 1];
		if (taxRates.isEmpty()) return new JMST__c();
		else return taxRates[0];
    }
    // 2015/09/29 室数会計商品を取得する
    /* 2015/10/13 DELETE BEGIN
    public static List<AccountMaster__c> getRoomAccountMaster() {
    	// 
    	return [select id, Name from AccountMaster__c where ActionType__c = :CommConst.PROD_ACTION_TYPE_RP And Name = :CommConst.APPOPTION_ROOMPRICE_PRODNAME limit 1];
    }
    */
	// 2016/01/19 ユーザープロファイル情報を取得する
	public static Profile getLoginUserProfile() {
		return [select Name From Profile where id = :UserInfo.getProfileId() limit 1];
	}
	
	
	
	public static void writeChangeInfoToHistory(Sobject[] newLst, Sobject[] oldLst, CommConst.TriggerMethod action){
        // 2017/11/02 共通定義により、項目履歴情報自動格納有効・無効切替対応 BEGIN
        if (!CommConst.APPOTION_ITEMHISTORY_CREATEFLG) return;
        // 2017/11/02 共通定義により、項目履歴情報自動格納有効・無効切替対応 END
 		List<Sobject> syncTargetLst = new List<Sobject>();
   		// 新規
   		if (action == CommConst.TriggerMethod.isInsert) {
   			for (Sobject nw : newLst) {
   				syncTargetLst.add(genItemChangeHistory(nw, 'Created'));
   			}
   		} 
   		// 変更
   		else if (action == CommConst.TriggerMethod.isUpdate) {
   			Id objectId = newLst[0].Id;
   			Schema.SObjectType sobjType = objectId.getSobjectType();
   			Map<String, String> checkFieldMap = CommSqlUtils.getCustomeFieldLst(sobjType,true);
   			Integer maxLen = newLst.size();
   			for (Integer i =0; i<maxLen; i++) {
   				Sobject nw = newLst[i];
   				Sobject od = oldLst[i];
   				String changeContent = '';
   				for (String fieldNm : checkFieldMap.keySet()) {
   					if (nw.get(fieldNm) != od.get(fieldNm)) {   						
   						changeContent += checkFieldMap.get(fieldNm) + ':'+ CommUtils.nullToBlank(od.get(fieldNm)) + '→' + CommUtils.nullToBlank(nw.get(fieldNm)) + '\n';
   					}
   				}
   				if (!CommUtils.isBlank(changeContent)) {
   					syncTargetLst.add(genItemChangeHistory(nw, changeContent));
   				}
   			}
   		}
   		if (syncTargetLst.isEmpty()) return;
   		// 変更情報は履歴オブジェクトに変更を行う
   		insert syncTargetLst;
   } 
   // 変更情報は履歴オブジェクトに変更を行う
   private static ItemChangeHistory__c genItemChangeHistory(Sobject obj, String changeStr) {
   		ItemChangeHistory__c newItem = new ItemChangeHistory__c();
   		Schema.sObjectType objType = obj.getSObjectType();
   		if (objType == Schema.CashVerification__c.getSObjectType()) { 
   			newItem.CashVerificationRef__c = obj.Id;
   		} else if (objType == Schema.AccountAcount__c.getSObjectType()) { 
   			newItem.AccountAcountRef__c = obj.Id;
   		}
   		newItem.ParentId__c = obj.Id;
   		newItem.LastModifiedBy__c = UserInfo.getLastName() + '  ' + UserInfo.getFirstName(); 
		newItem.LastModifiedTime__c = Datetime.now();
   		newItem.History__c = changeStr;
   		return newItem;
   }
   //  重複チェック登録対応 BEGIN
   public Contact upsertDuplicateErrorProcess(Contact curContact) {
   		return upsertDuplicateErrorProcess(curContact,null);
   }
// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
   public Contact upsertDuplicateErrorProcess(Contact curContact, CommLogUtils log) {
	   return upsertDuplicateErrorProcess(curContact, log, null);
   }
   public Contact upsertDuplicateErrorProcess(Contact curContact, CommLogUtils log, List<String> lstError) {
	// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
   		// 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFieldsLst = new List<String>{'MailingStreet','ApplicantPhone__c','ApplicantName__c','MailingPostalCode',
														'MailingCity','MailingState','Email','Phone2__c','Phone','gender__c',
														'Name1__c','KanaName1__c','Katakana__c','FirstName','LastName'};
		Map<String,Schema.SObjectField> insmm = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFieldsLst, insmm)) {
			return null;
		}
		// 2017/02/24 Field Security Check End by wx
		// 2017/02/24 Field Security Check BEGIN
		if (!CommSecurityUtils.isCanUpdateable(insChkFieldsLst, insmm)) {
			return null;
		}
   		// 2017/02/24 Field Security Check End 
   		// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 BEGIN
   		string custPrefix = Contact.sObjectType.getDescribe().getKeyPrefix();
   		// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 END
   		Boolean isUpdFlg = (curContact.Id == null ? false : true);
		if (log != null) log.write_log('upsertDuplicateErrorProcess更新処理:'+isUpdFlg); else System.debug(logginglevel.INFO, 'upsertDuplicateErrorProcess更新処理:'+isUpdFlg);
        Database.SaveResult sr = isUpdFlg ? Database.update(curContact, false) : Database.insert(curContact, false);
		if (log != null) log.write_log('SR='+sr); else System.debug(logginglevel.INFO, 'SR='+sr);
        if (!sr.isSuccess()){
        	Database.Error error = sr.getErrors()[0];
        	if (log != null) log.write_log('データインサート/更新失敗...'+error); else System.debug(logginglevel.INFO, 'データインサート/更新失敗...');
    		if (error instanceof Database.DuplicateError){
    			if (log != null) log.write_log('重複データ存在...'); else System.debug(logginglevel.INFO, '重複データ存在...');
    			Database.DuplicateError duplicateError = (Database.DuplicateError)error;
    			Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();  
    			Set<Id> setDuplicateIds = new Set<Id>();                  	
            	for (Datacloud.MatchResult duplicateMatchResult : duplicateResult.getMatchResults()) {
					for (Datacloud.MatchRecord duplicateMatchRecord : duplicateMatchResult.getMatchRecords()) {
						// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 BEGIN
						String recId = duplicateMatchRecord.getRecord().Id;
						if (recId.startsWith(custPrefix))//お客様の003開始のデータIDのみ、リストに格納する
						// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 END
						setDuplicateIds.add(duplicateMatchRecord.getRecord().Id);
					}
				}
				if (!setDuplicateIds.isEmpty()) {
					// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 BEGIN
					//Contact orgContact -> List<Contact> orgContacts へ変更
					/*Contact orgContact = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,Account.Name,
							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone from Contact where id = :setDuplicateIds order by LastModifiedDate desc limit 1];*/
					List<Contact> orgContacts = [select LastName,FirstName,Name1__c,KanaName1__c,Katakana__c,Phone,Email,MailingPostalCode,MailingStreet,Account.Name,
							ApplicantName__c,ApplicantPhone__c,Birthdate,MobilePhone from Contact where id = :setDuplicateIds order by LastModifiedDate desc limit 1];
					Contact orgContact = (!orgContacts.isEmpty()) ? orgContacts[0] : new Contact();
					// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 END
					Boolean isChange = false;
					if (CommUtils.isBLank(orgContact.MobilePhone) && !CommUtils.isBlank(curContact.MobilePhone)) {
						isChange = true;
						orgContact.MobilePhone = curContact.MobilePhone;
					}
					if (orgContact.Birthdate == null && curContact.Birthdate != null) {
						Integer y = curContact.Birthdate.year();
						Integer m = curContact.Birthdate.month();
						Integer d = curContact.Birthdate.day();
						if (CommUtils.isBirthDay(y,m,d)) {
							isChange = true;
							orgContact.Birthdate = curContact.Birthdate;
						}
					}
					if (CommUtils.isBLank(orgContact.Email) && !CommUtils.isBlank(curContact.Email)) {
						isChange = true;
						orgContact.Email = curContact.Email;
					}
					if (CommUtils.isBLank(orgContact.Phone) && !CommUtils.isBlank(curContact.Phone)) {
						isChange = true;
						orgContact.Phone = curContact.Phone;
					}
					if (isChange) {
						// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
						forceUpdate(orgContact,log, lstError);
						// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
					}
					if (log != null) log.write_log('重複データを出力する:'+orgContact); else System.debug(logginglevel.INFO, '重複データを出力する:'+orgContact);
					return orgContact;
				}
				// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 BEGIN
				else {
					if (log != null) log.write_log('お客様情報を強制インサート/更新する:'); else System.debug(logginglevel.INFO, 'お客様情報を強制インサート/更新する:');
					forceUpdate(curContact,log, lstError);
				}
				// 2019/05/06 WSQ データ重複ルールにより、返却されるIDはお客様以外の場合、問題回避対応 END
    		} else {
    			if (log != null) log.write_log('お客様情報を強制インサート/更新する:'); else System.debug(logginglevel.INFO, 'お客様情報を強制インサート/更新する:');
    			// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
    			forceUpdate(curContact,log, lstError);
    			// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
    		}       
        }
        return curContact;
   }
   // 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
   public void forceUpdate(Sobject s, CommLogUtils log) {
		forceUpdate(s, log, null);
   }
   // 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
   // 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
   public void forceUpdate(Sobject s, CommLogUtils log, List<String> lstErrorMsg){
   	// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
   		Boolean isUpdFlg = s.id == null ? false : true;
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true;
		Database.SaveResult sr2 = isUpdFlg ? Database.update(s, dml) : Database.insert(s, dml);
		// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw BEGIN
		List<Database.Error> lstError = sr2.getErrors();
		if(null != lstErrorMsg && !lstError.isEmpty()) {
			for(Database.Error error : lstError) {
				lstErrorMsg.add(error.getMessage());
			}
		}
		// 2018/12/30 BookingAPIのお客様情報を登録されないの調査 by cxw END
		if (log != null) log.write_log('お客様情報を強制インサート/更新結果:'+sr2); else System.debug(logginglevel.INFO, 'お客様情報を強制インサート/更新結果:');
   }
   
   //  重複チェック登録対応 END
   
   // 2016/06/17 2way明細並び替え順設定処理ロジック BEGIN
   // 取得の予約リストと新規追加の見積明細リスト
   public void sync2wayEstRowNoSetup(List<Lead__c> insLeadLst, List<BookingEstimateItem__c> lastInsItems) {
        // KEY:SUB_GROUPNO->ROWNO
        // 関連の予約情報を再取得する、取得後、予約インデックスID,SUBID,グループNOでグループして、同じグループ内部のROWNOを設定する
        // 設定順番：プランー＞その後会計商品コード順
        set<id> leadIdSet = new set<id>();
        map<Id, Decimal> existEstRowNoMap = new map<id,Decimal>();
        List<BookingEstimateItem__c> updEstLst = new list<BookingEstimateItem__c>();
        for (Lead__c lead : insLeadLst) leadIdSet.add(lead.Id);
        map<id, list<BookingEstimateItem__c>> leadEstLstMap = new map<id, list<BookingEstimateItem__c>>();
        /* N泊N部屋、集める場合、見積明細再SORT機能対応 BEGIN 
        for (BookingEstimateItem__c est : lastInsItems) {
        	Id leadId = est.refBooking__c;
        	if (!leadEstLstMap.containsKey(leadId)) leadEstLstMap.put(leadId, new List<BookingEstimateItem__c>());
        	leadEstLstMap.get(leadId).add(est);
        }*/
		// 既存予約情報と見積情報を取得する
        List<Lead__c> existLeads = [select LeadIndexRef__c,LeadIndexSubId__c,RoomGroupNo__c,(Select Id,refAccountMaster__c,RowNo__c From BookingEstimateItemFgKu__r where refAccountMaster__c != null and ParentBookingItemRef__c = null Order BY RowNo__c,Name) from Lead__c where id in :leadIdSet order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c];
        map<String,list<id>> leadGroupMap = new map<string, list<id>>();
        for (Lead__c lead : existLeads) {
        	// 既存会計情報はMAPに格納する（グループ化）
        	String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + lead.RoomGroupNo__c;
        	if (!leadGroupMap.containskey(key)) leadGroupMap.put(key, new List<Id>());
        	leadGroupMap.get(key).add(lead.id);
        	// 既存見積明細情報はMAPに格納する
        	if (!lead.BookingEstimateItemFgKu__r.isEmpty()) {
        		if (!leadEstLstMap.containsKey(lead.Id)) leadEstLstMap.put(lead.Id, new list<BookingEstimateItem__c>());
        		leadEstLstMap.get(lead.Id).addAll(lead.BookingEstimateItemFgKu__r);
        		for (BookingEstimateItem__c est : lead.BookingEstimateItemFgKu__r) {
        			existEstRowNoMap.put(est.Id, est.RowNo__c);
        		}
        	}
        }
        // N泊N部屋、集める場合、見積明細再SORT機能対応 BEGIN 
        for (BookingEstimateItem__c est : lastInsItems) {
        	Id leadId = est.refBooking__c;
        	if (!leadEstLstMap.containsKey(leadId)) leadEstLstMap.put(leadId, new List<BookingEstimateItem__c>());
        	leadEstLstMap.get(leadId).add(est);
        }
        // N泊N部屋、集める場合、見積明細再SORT機能対応 END
        // 同じ部屋のN泊の予約見積明細は合流して、SORTする。ソートのルールはプランー＞その後会計商品コード順
        set<id> accMstIdSet = new set<Id>();
        for (List<BookingEstimateItem__c> estLst : leadEstLstMap.values()) {
        	for (BookingEstimateItem__c est : estLst) {
        		accMstIdSet.add(est.refAccountMaster__c);
        	}
        }
        map<id, AccountMaster__c> locAccMstMap = new map<id, AccountMaster__c>([select id,Field3__c,ActionType__c from AccountMaster__c where id in :accMstIdSet]);
        // 1部屋N泊の予約情報の会計商品並び替え
        for (List<Id> leadIdsLst : leadGroupMap.values()) {
        	Integer rowNo = 1;
        	// 商品コード->見積明細順
        	map<String, list<BookingEstimateItem__c>> accProductCdSortMap = new map<String,list<BookingEstimateItem__c>>();
        	// 該当部屋の関連の予約リスト
        	for (Id leadId : leadIdsLst) {
        		// 集めるの場合、見積明細は子部屋は非存在のため、処理対象外
        		if (!leadEstLstMap.containsKey(leadId)) continue;
        		// 見積明細
        		for (BookingEstimateItem__c est : leadEstLstMap.get(leadId)) {
        			// プラン以外の商品に対して、商品コード順で再SORTする
    				AccountMaster__c acc = locAccMstMap.get(est.refAccountMaster__c);
    				if (acc == null) acc = new AccountMaster__c();
    				// 商品はNULLの場合（正常はありえないです）
        			if (acc.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
        				est.RowNo__c = rowNo;
        				rowNo++;
        				// N泊N部屋、集める場合、見積明細再SORT機能対応 BEGIN
						if (est.id != null && existEstRowNoMap.containsKey(est.id)) {
        					Decimal orgRowNo = existEstRowNoMap.get(est.Id);
        					if (orgRowNo != est.RowNo__c) updEstLst.add(est);
        				}
        				// N泊N部屋、集める場合、見積明細再SORT機能対応 END
        			} else {
        				String accCode = CommUtils.nullToBlank(acc.Field3__c);
        				if (!accProductCdSortMap.containsKey(accCode)) accProductCdSortMap.put(accCode, new List<BookingEstimateItem__c>());
        				accProductCdSortMap.get(accCode).add(est);
        			}
        		}
        	}
        	// そのた商品が存在する場合、
        	if (!accProductCdSortMap.isEmpty()) {
        		list<String> sortLst = new List<String>(accProductCdSortMap.keySet());
        		sortLst.sort();
        		// ROWNO設定を行う
        		for (String accCode : sortLst) {
        			for (BookingEstimateItem__c est : accProductCdSortMap.get(accCode)) {
        				est.RowNo__c = rowNo;
        				rowNo++;
        				if (est.id != null && existEstRowNoMap.containsKey(est.id)) {
        					Decimal orgRowNo = existEstRowNoMap.get(est.Id);
        					if (orgRowNo != est.RowNo__c) updEstLst.add(est);
        				}
        			}
        		}
        	}
        }
        if (!lastInsItems.isEmpty()) insert lastInsItems;
        if (!updEstLst.isEmpty()) update updEstLst;
   }
   // 2016/06/17 2way明細並び替え順設定処理ロジック END
	// 2017/02/23 同期処理機能実施する、しないチェック
	public list<Rollupparameter__c> getRollupParameter(ROLLUP_PAR parType) {
		String functonName = '';
		if (parType == ROLLUP_PAR.TTEND) functonName = 'TtendToCash';
		return [select InActive__c, DestFieldApi__c from Rollupparameter__c where FunctionName__c = :functonName limit 1];
	}
	public enum ROLLUP_PAR{TTEND}
	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 BEGIN
	public static boolean isPosImportData(AccountAcount__c acc) {
		return (acc.Field150__c != null);
	}
	// 2017/04/11 現在の会計情報はPOSから取り込みのデータ場合、該当会計人數は予約へ連携する、しない処理対応 END
	
	// 2017/05/04 店舗ごとの予約・会計権限機能対応 BEGIN
	// 連携からの予約に対して、店舗ごとの権限チェック対象外が一時設定
	public void preventShopAuthCheckSetup(List<Sobject> leads) {
		if (!CommConst.ShopEditAuthCheckFlg) return;
		String fieldApi = CommConst.APPOTION_NAMESPACE + 'OtherShopEditCheckFlg__c';
		for (Sobject sobj : leads) {
			sobj.put(fieldApi,true);
		}
	}
	// 連携からの予約に対して、店舗ごとの権限チェック対象に設定する
	public void restoreShopAuthCheckSetup(List<Sobject> leads, Boolean isAutoUpdate) {
		if (!CommConst.ShopEditAuthCheckFlg) return;
		String fieldApi = CommConst.APPOTION_NAMESPACE + 'OtherShopEditCheckFlg__c';
		for (Sobject sobj : leads) {
			sobj.put(fieldApi,false);
		}
		if (isAutoUpdate) update leads;
	}
	// 2017/05/04 店舗ごとの予約・会計権限機能対応 END
    // 2017/12/11 カスタマイズメッセージ解析処理 BEGIN
	public static set<string> parseFieldByLable(String labmsg) {
	    set<string> rsset = new set<string>();
		String apikey = labmsg.substringBetween('{@','}');
		// 拆分label取得
		while (apikey != null) {
    		if (apikey != '') {
    			rsset.add(apiKey);
    		}
    		string repkey = '{@'+apikey+'}';
    		labmsg = labmsg.substringAfter(repkey);
    		apikey = labmsg.substringBetween('{@','}');
		}
	    return rsset;
	} 
	// 2017/12/11 カスタマイズメッセージ解析処理 END
	// 2018/07/27 宿泊税計算 WGCH BEGIN
	// map<店舗コード,該当店舗の宿泊税定義情報>
	public enum MODE_TYPE{R1,R2,R3,R4,R5}
	private static map<String,HotelTaxDefineInfo> hotelTaxDefInstance = null;
	public static map<String, HotelTaxDefineInfo> getHotelTaxDefInstance() {
		if (hotelTaxDefInstance != null) return hotelTaxDefInstance;
		else {
			List<HotelTaxDefine__mdt> rs = [Select Id, IsIncHotelTax__c, ShopCode__c,
									MinPriceR1__c, MaxPriceR1__c, TaxPriceR1__c, 
									MinPriceR2__c, MaxPriceR2__c, TaxPriceR2__c, 
									MinPriceR3__c, MaxPriceR3__c, TaxPriceR3__c, 
									MinPriceR4__c, MaxPriceR4__c, TaxPriceR4__c, 
									MinPriceR5__c, MaxPriceR5__c, TaxPriceR5__c From HotelTaxDefine__mdt 
									Where isInvalidFlg__c = false
									Order By Label];
			// 初期化
			hotelTaxDefInstance = new map<String, HotelTaxDefineInfo>();
			// 該当店舗対応した宿泊情報
			for(HotelTaxDefine__mdt hotelTax : rs) {
				for(String hotelSpCd : CommUtils.nullToBlank(hotelTax.ShopCode__c).split(',')){
					String spcd = CommUtils.nullToBlank(hotelSpCd);
					if(hotelTaxDefInstance.containsKey(spcd)) continue;
					hotelTaxDefInstance.put(spcd, new HotelTaxDefineInfo(hotelTax));
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH BEGIN
			if(Test.isRunningTest()){
				for(ShopInformation__c sp : [Select Id, ShopCode__c From ShopInformation__c]){
					HotelTaxDefine__mdt s = new HotelTaxDefine__mdt();
					s.IsIncHotelTax__c = true;
					s.TaxPriceR1__c = 200;
					hotelTaxDefInstance.put(CommUtils.nullToBlank(sp.ShopCode__c), new HotelTaxDefineInfo(s));
				}
			}
			// 2019/07/30 軽減税率機能対応 WGCH END
			return hotelTaxDefInstance;
		}
	}
	public static Decimal getHotelTax(Decimal unitPrice, HotelTaxDefineInfo hotelTaxDef) {
		if(hotelTaxDef == null || hotelTaxDef.isIncHotelTaxFlg) return 0;
		// 宿泊税は単価から計算する場合
		return getHotelTax(unitPrice, hotelTaxDef, true);
	}
	public static Decimal getHotelTax(Decimal unitPrice, HotelTaxDefineInfo item, Boolean isCalRoomRateFlg){
		// 単価に宿泊税含む=TRUEかつ単価から宿泊税計算フラグ＝TRUE || unitPrice <= 0 、処理中止
		if(item == null || unitPrice <= 0) return 0;
		else if(!isCalRoomRateFlg && !item.isIncHotelTaxFlg) return 0;
		if(item.getInRangeFlg(item.minPriceR1, item.maxPriceR1, unitPrice)){
			return item.getHotelTax(item.minPriceR1, item.maxPriceR1, item.taxPriceR1, unitPrice, MODE_TYPE.R1.NAME());
		}
		else if(item.getInRangeFlg(item.minPriceR2, item.maxPriceR2, unitPrice)){
			return item.getHotelTax(item.minPriceR2, item.maxPriceR2, item.taxPriceR2, unitPrice, MODE_TYPE.R2.NAME());
		}
		else if(item.getInRangeFlg(item.minPriceR3, item.maxPriceR3, unitPrice)){
			return item.getHotelTax(item.minPriceR3, item.maxPriceR3, item.taxPriceR3, unitPrice, MODE_TYPE.R3.NAME());
		}
		else if(item.getInRangeFlg(item.minPriceR4, item.maxPriceR4, unitPrice)){
			return item.getHotelTax(item.minPriceR4, item.maxPriceR4, item.taxPriceR4, unitPrice, MODE_TYPE.R4.NAME());
		}
		else if(item.getInRangeFlg(item.minPriceR5, item.maxPriceR5, unitPrice)){
			return item.getHotelTax(item.minPriceR5, item.maxPriceR5, item.taxPriceR5, unitPrice, MODE_TYPE.R5.NAME());
		}
		else return 0;
	}
	// 宿泊税Info处理
	public class HotelTaxDefineInfo{
		public HotelTaxDefineInfo(HotelTaxDefine__mdt hotelTax){
			isIncHotelTaxFlg = hotelTax.IsIncHotelTax__c;
			minPriceR1 = CommUtils.nullToZero(hotelTax.MinPriceR1__c);
			maxPriceR1 = hotelTax.MaxPriceR1__c == null ? MAXPRICE : CommUtils.nullToZero(hotelTax.MaxPriceR1__c);
			taxPriceR1 = CommUtils.nullToZero(hotelTax.TaxPriceR1__c);
			
			minPriceR2 = CommUtils.nullToZero(hotelTax.MinPriceR2__c);
			maxPriceR2 = hotelTax.MaxPriceR2__c == null ? MAXPRICE : CommUtils.nullToZero(hotelTax.MaxPriceR2__c);
			taxPriceR2 = CommUtils.nullToZero(hotelTax.TaxPriceR2__c);
			
			minPriceR3 = CommUtils.nullToZero(hotelTax.MinPriceR3__c);
			maxPriceR3 = hotelTax.MaxPriceR3__c == null ? MAXPRICE : CommUtils.nullToZero(hotelTax.MaxPriceR3__c);
			taxPriceR3 = CommUtils.nullToZero(hotelTax.TaxPriceR3__c);
			
			minPriceR4 = CommUtils.nullToZero(hotelTax.MinPriceR4__c);
			maxPriceR4 = hotelTax.MaxPriceR4__c == null ? MAXPRICE : CommUtils.nullToZero(hotelTax.MaxPriceR4__c);
			taxPriceR4 = CommUtils.nullToZero(hotelTax.TaxPriceR4__c);
			
			minPriceR5 = CommUtils.nullToZero(hotelTax.MinPriceR5__c);
			maxPriceR5 = hotelTax.MaxPriceR5__c == null ? MAXPRICE : CommUtils.nullToZero(hotelTax.MaxPriceR5__c);
			taxPriceR5 = CommUtils.nullToZero(hotelTax.TaxPriceR5__c);
		}
		private Decimal getHotelTax(Decimal minPrice, Decimal maxPrice, Decimal taxPrice, Decimal unitPrice, String mode){
			if(isIncHotelTaxFlg){
				if(getInRangeFlg(minPrice, maxPrice, unitPrice - taxPrice)) return taxPrice;
				else if(getInRangeFlg(minPriceR1, maxPriceR1, unitPrice - taxPriceR1) && mode != MODE_TYPE.R1.NAME()) return taxPriceR1;
				else if(getInRangeFlg(minPriceR2, maxPriceR2, unitPrice - taxPriceR2) && mode != MODE_TYPE.R2.NAME()) return taxPriceR2;
				else if(getInRangeFlg(minPriceR3, maxPriceR3, unitPrice - taxPriceR3) && mode != MODE_TYPE.R3.NAME()) return taxPriceR3;
				else if(getInRangeFlg(minPriceR4, maxPriceR4, unitPrice - taxPriceR4) && mode != MODE_TYPE.R4.NAME()) return taxPriceR4;
				else if(getInRangeFlg(minPriceR5, maxPriceR5, unitPrice - taxPriceR5) && mode != MODE_TYPE.R5.NAME()) return taxPriceR5;
				else return 0;
			}
			else return taxPrice;
		}
		private Boolean getInRangeFlg(Decimal minPrice, Decimal maxPrice, Decimal unitPrice){
			return unitPrice >= minPrice && unitPrice < maxPrice;
		}
		public Decimal MAXPRICE = 9999999999.00; // MAXPRICE
		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
		public Boolean isIncHotelTaxAndAccIsShowFlg{get{ return isIncHotelTaxFlg;}}// 単価に宿泊税含む
		// 2019/07/30 軽減税率機能対応 WGCH END
		public Boolean isIncHotelTaxFlg;// 単価に宿泊税含む
		public Decimal minPriceR1; // ランク1最小値
		public Decimal maxPriceR1; // ランク1最大値
		public Decimal taxPriceR1; // ランク1宿泊税
		public Decimal minPriceR2; // ランク2最小値
		public Decimal maxPriceR2; // ランク2最大値
		public Decimal taxPriceR2; // ランク2宿泊税
		public Decimal minPriceR3; // ランク3最小値
		public Decimal maxPriceR3; // ランク3最大値
		public Decimal taxPriceR3; // ランク3宿泊税
		public Decimal minPriceR4; // ランク4最小値
		public Decimal maxPriceR4; // ランク4最大値
		public Decimal taxPriceR4; // ランク4宿泊税
		public Decimal minPriceR5; // ランク5最小値
		public Decimal maxPriceR5; // ランク5最大値
		public Decimal taxPriceR5; // ランク5宿泊税
	}
	// 2018/07/27 宿泊税計算 WGCH END
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	/*
	* shopCode      : 店铺Code
	* actionType    : 明细类型
	* dataId        : 明细Id
	* incTaxUnitPrice: 室料单价
	* nums          : 明细数量
	* tax           : 明细消费税
	* service       : 明细サビース料
	* priceInfo     : 明细函数Info
	* pItemPriceLst : Plan明细室料单价List
	*/
	public static HotelTaxInfo getHotelTaxInfo(String shopCode, String actionType, Decimal unitPrice, Decimal nums, Decimal tax, Decimal service, CommUtils.ProductInfo priceInfo){
		return getHotelTaxInfo(shopCode, actionType, unitPrice, nums, tax, service, priceInfo, getHotelTaxDefInstance());
	}
	public static HotelTaxInfo getHotelTaxInfo(String shopCode, String actionType, Decimal unitPrice, Decimal nums, Decimal tax, Decimal service, CommUtils.ProductInfo priceInfo, Map<String, HotelTaxDefineInfo> hotelTaxDefMap){
		HotelTaxInfo hotelTaxItem = new HotelTaxInfo();
		priceInfo.process(unitPrice, nums, tax, service);
		hotelTaxItem.priceInfo = priceInfo;
		if(actionType != CommConst.PROD_ACTION_TYPE_RP) return hotelTaxItem;
		hotelTaxItem.autoSetFlg = true;
		if(hotelTaxDefMap == null || CommUtils.nullToZero(unitPrice) == 0 || CommUtils.nullToZero(nums) == 0) return hotelTaxItem;
		HotelTaxDefineInfo hotelTaxDefInfo = hotelTaxDefMap.get(CommUtils.nullToBlank(shopCode)); // 获取当前店铺的宿泊税定义信息
		if(hotelTaxDefInfo == null) return hotelTaxItem;
		hotelTaxItem.isIncHotelTaxAndAccIsShowFlg = hotelTaxDefInfo.isIncHotelTaxAndAccIsShowFlg;
		Decimal wkHotelTax = 0; // 存在的宿泊税
		for(Integer i = 1; i < 6; i++){ // 假设带入法反推处理
			if(i == 1){ // 第一条定义信息处理
				Decimal wkUnitPrice = hotelTaxItem.isIncHotelTaxAndAccIsShowFlg ? unitPrice - hotelTaxDefInfo.taxPriceR1 : unitPrice;
				priceInfo.process(wkUnitPrice, nums , tax, service);
				// 判断反推回来的单价（无税含サビース料）是否在当天范围内
				if(priceInfo.unitPriceIncServiceExcTax >= hotelTaxDefInfo.minPriceR1 && priceInfo.unitPriceIncServiceExcTax < hotelTaxDefInfo.maxPriceR1){
					wkHotelTax += hotelTaxDefInfo.taxPriceR1;
					break;
				}
			}
			else if(i == 2){ // 第二条定义信息处理
				Decimal wkUnitPrice = hotelTaxItem.isIncHotelTaxAndAccIsShowFlg ? unitPrice - hotelTaxDefInfo.taxPriceR2 : unitPrice;
				priceInfo.process(wkUnitPrice, nums , tax, service);
				// 判断反推回来的单价（无税含サビース料）是否在当天范围内
				if(priceInfo.unitPriceIncServiceExcTax >= hotelTaxDefInfo.minPriceR2 && priceInfo.unitPriceIncServiceExcTax < hotelTaxDefInfo.maxPriceR2){
					wkHotelTax += hotelTaxDefInfo.taxPriceR2;
					break;
				}
			}
			else if(i == 3){ // 第三条定义信息处理
				Decimal wkUnitPrice = hotelTaxItem.isIncHotelTaxAndAccIsShowFlg ? unitPrice - hotelTaxDefInfo.taxPriceR3 : unitPrice;
				priceInfo.process(wkUnitPrice, nums , tax, service);
				// 判断反推回来的单价（无税含サビース料）是否在当天范围内
				if(priceInfo.unitPriceIncServiceExcTax >= hotelTaxDefInfo.minPriceR3 && priceInfo.unitPriceIncServiceExcTax < hotelTaxDefInfo.maxPriceR3){
					wkHotelTax += hotelTaxDefInfo.taxPriceR3;
					break;
				}
			}
			else if(i == 4){ // 第四条定义信息处理
				Decimal wkUnitPrice = hotelTaxItem.isIncHotelTaxAndAccIsShowFlg ? unitPrice - hotelTaxDefInfo.taxPriceR4 : unitPrice;
				priceInfo.process(wkUnitPrice, nums , tax, service);
				// 判断反推回来的单价（无税含サビース料）是否在当天范围内
				if(priceInfo.unitPriceIncServiceExcTax >= hotelTaxDefInfo.minPriceR4 && priceInfo.unitPriceIncServiceExcTax < hotelTaxDefInfo.maxPriceR4){
					wkHotelTax += hotelTaxDefInfo.taxPriceR4;
					break;
				}
			}
			else if(i == 5){ // 第五条定义信息处理
				Decimal wkUnitPrice = hotelTaxItem.isIncHotelTaxAndAccIsShowFlg ? unitPrice - hotelTaxDefInfo.taxPriceR5 : unitPrice;
				priceInfo.process(wkUnitPrice, nums , tax, service);
				// 判断反推回来的单价（无税含サビース料）是否在当天范围内
				if(priceInfo.unitPriceIncServiceExcTax >= hotelTaxDefInfo.minPriceR5 && priceInfo.unitPriceIncServiceExcTax < hotelTaxDefInfo.maxPriceR5){
					wkHotelTax += hotelTaxDefInfo.taxPriceR5;
					break;
				}
			}
		}
		hotelTaxItem.hotelTax = wkHotelTax;
		if(hotelTaxItem.isIncHotelTaxAndAccIsShowFlg){
			hotelTaxItem.hasNumSepcTax =  wkHotelTax;
			hotelTaxItem.hasNumSepcTaxSum =  wkHotelTax * nums;
			// 去掉包含的宿泊税再计算
			Decimal incTaxUnitPrice = unitPrice - hotelTaxItem.hasNumSepcTax;
			priceInfo.process(incTaxUnitPrice, nums, tax, service);
			// 在把去掉的宿泊税加回来
			priceInfo.getNewPriceInfo(priceInfo, hotelTaxItem.hasNumSepcTax, nums);
			hotelTaxItem.priceInfo = priceInfo;
		} else {
			hotelTaxItem.newNumSepcTax = wkHotelTax;
			hotelTaxItem.newNumSepcTaxSum = wkHotelTax * CommUtils.nullToZero(nums);
		}
		return hotelTaxItem;
	}
	public class HotelTaxInfo{
		public HotelTaxInfo(){
			autoSetFlg = isIncHotelTaxAndAccIsShowFlg = false;
			hotelTax = newNumSepcTax = newNumSepcTaxSum = hasNumSepcTax = hasNumSepcTaxSum = 0;
		}
		public Boolean autoSetFlg;
		public Boolean isIncHotelTaxAndAccIsShowFlg;
		public Decimal hotelTax; // 存在的宿泊税
		public Decimal newNumSepcTax; // 单价对应的宿泊税
		public Decimal newNumSepcTaxSum; // 合计金额对应的宿泊税
		public Decimal hasNumSepcTax; // 单价包含的宿泊税
		public Decimal hasNumSepcTaxSum; // 合计金额包含的宿泊税
		public CommUtils.ProductInfo priceInfo;
	}
	public static String getPlanBrkInfo(String unitPrice, String taxRate, String serviceRate, String amount, String newNumSepcTaxSum, String unitPriceDefKbCal, String accMstId, String actionType){
		return	CommUtils.nullToBlank(unitPrice) + ':' + // 単価
				CommUtils.nullToBlank(taxRate) + ':' + // 消費税
				CommUtils.nullToBlank(serviceRate) + ':' + // サービス料
				CommUtils.nullToBlank(amount) + ':' + // 数量
				CommUtils.nullToBlank(newNumSepcTaxSum) + ':' + // 特別税
				CommUtils.nullToBlank(unitPriceDefKbCal) + ':' + // 会計商品単価定義区分
				CommUtils.nullToBlank(accMstId) + ':' + // 会計商品Id
				// bug fix by zy BEGIN
				// 新split 方法如果最后一位出现空会影响结果集的长度，如果按照长度判断就会出错
				//CommUtils.nullToBlank(actionType) + ';'; // 商品処理種別
				(CommUtils.isBlank(actionType) ? '通常' : actionType)  + ';'; // 商品処理種別
				// bug fix by zy END
	}
	public static List<List<String>> getPlanBrkInfoLst(String planBrkInfo){
		List<List<String>> brkInfoLst = new List<List<String>>();
		if(CommUtils.isBlank(planBrkInfo)) return brkInfoLst;
		for(String str : CommUtils.nullToBlank(planBrkInfo).split(';') ){ // 分割明细
			if(CommUtils.isBlank(str)) continue;
			// bug fix by zy BEGIN
			List<String> msgStr = CommUtils.nullToBlank(str).split(':');
			// 新split 方法如果最后一位出现空会影响结果集的长度，如果按照长度判断就会出错
			if (msgStr.size() < 8) {
				for(integer i = 0 ; i < 8 - msgStr.size(); i++ ){
					msgStr.add('');
					if (msgStr.size() == 7 && CommUtils.isBlank(msgStr[7])) msgStr[7] = '通常';
				}
			}
			brkInfoLst.add(msgStr); // 分割明细数据
			// bug fix by zy END
		}
		return brkInfoLst;
	}
	// 2019/07/30 軽減税率機能対応 WGCH END
	// 2019/10/30 軽減税率割合モード機能対応 WGCH BEGIN
	// 小数部分桁数取得する
	private static final Integer gPointLen = CommUtils.getPointLen();
	public enum CLASS_MODE{BILL} // Class标识符「请求书」
	public static final String REDUCED_TAXRATE_MIN_MODE = '1'; // 8%优先按分「从小税种优先按分」
	public static final String REDUCED_TAXRATE_MAX_MODE = '2'; // 10%优先按分「从大税种优先按分」
	public static void addDetailToMapFun(ItemData item, Decimal noTaxUnitPriceSum, SumRowInfo sum) {
		// 变量局部赋值
		SumAmountRowData sumRowData = sum.sumRowData;
		Map<Decimal, TaxRowData> taxRowDataMap = sum.taxRowDataMap;
		// 每笔会计商品 合計税込
		Decimal priceAmount = CommUtils.RoundProcess(CommUtils.nullToZero(item.unitPrice) * CommUtils.nullToZero(item.quantity), gPointLen);
		// 每笔会计商品 合計消費税
		Decimal taxAmount = CommUtils.RoundProcess(CommUtils.nullToZero(item.taxUnitPrice) * CommUtils.nullToZero(item.quantity), gPointLen);
		// 每笔会计商品 的 特别税
		Decimal specialTax = item.specialTax;
		if((priceAmount + specialTax + taxAmount) == 0 && CommUtils.nullToZero(noTaxUnitPriceSum) == 0) return;
		Decimal taxRate = CommUtils.nullToZero(item.taxRate);
		taxRate = taxRate == 0 ? 0 : taxRate.setScale(4);
		sum.taxUnitPriceAll += taxAmount;
		// 合计行 会计商品 税拔金额的合计值:
		sumRowData.amountExcTax += priceAmount - taxAmount;
		// 合计行 会计商品 税込金额的合计值:
		sumRowData.amountIncTax += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		// 合计行 课税会计商品 税込金额的合计值:
		if(taxRate != 0) sumRowData.priceAmountSum += priceAmount;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		// 合计行 会计商品 消费税金额的合计值:
		sumRowData.taxAmount += taxAmount;
		// Plan明细里  含有非课税 
		if(CommUtils.nullToZero(noTaxUnitPriceSum) != 0 || specialTax > 0){
			// Plan明细里 含有非课税 并且 Map key没有0的情况
			Decimal noTaxKey = 0;
			if(!taxRowDataMap.containsKey(noTaxKey)) taxRowDataMap.put(noTaxKey, new TaxRowData());
			taxRowDataMap.get(noTaxKey).amountExcTax += noTaxUnitPriceSum + specialTax;
			// 集计处理
			sumRowData.amountExcTax += noTaxUnitPriceSum + specialTax;
			sumRowData.amountIncTax += noTaxUnitPriceSum + specialTax;
		}
		if(!taxRowDataMap.containsKey(taxRate)) taxRowDataMap.put(taxRate, new TaxRowData());
		// 対象板块合计处理
		TaxRowData taxRow = taxRowDataMap.get(taxRate);
		// 消费税率
		taxRow.taxRate = taxRate;
		// 対象行 会计商品 税拔金额的合计值:
		taxRow.amountExcTax += priceAmount - taxAmount;
		// 対象行 会计商品 税込金额的合计值:
		taxRow.amountIncTax += priceAmount;
		// 対象行 会计商品 消费税金额的合计值:
		taxRow.taxAmount += taxAmount;
	}
	// 値引 比率计算 + 详细设值
	// 値引合计值 amoutIncDiscont
	public static void processSumInfo(Decimal amoutIncDiscont, SumRowInfo sum){
		// 变量局部赋值
		// 対象行Lst
		List<TaxRowData> taxRowDataLst = sum.taxRowDataLst;
		// 対象行Map
		Map<Decimal, TaxRowData> taxRowDataMap = sum.taxRowDataMap;
		// 値引行
		DisRowData disRowData = sum.disRowData;
		// 並び順で最小税からMAX税を設定する
		// 值引行Lst
		List<DisRowData> disRowDataLst = sum.disRowDataLst;
		// 值引行Map
		Map<Decimal, DisRowData> disRowDataMap = sum.disRowDataMap;
		// 合计行
		SumAmountRowData sumRowData = sum.sumRowData;
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		// 值引处理
		// 值引金额 > 课税商品合计金额 Flg
		Boolean disMaxFlg = amoutIncDiscont >= sum.sumRowData.priceAmountSum;
		// 当值引金额 > 课税商品合计金额 时, 金额置换, 防止负值
		if(disMaxFlg) amoutIncDiscont = sum.sumRowData.priceAmountSum;
		// 最终有效的值引金额
		Decimal disEnd = amoutIncDiscont;
		Decimal disSumEnd = amoutIncDiscont;
		// 占最大比例的key
		Decimal larger = 0;
		// Key: 最大比例, Val: 消费税
		Map<Decimal, Decimal> disTaxMaxMap = new Map<Decimal, Decimal>();
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		List<Decimal> taxRateLst = new List<Decimal>(taxRowDataMap.keySet());
		
		String reducedProMode = CommConst.REDUCED_TAXRATE_PRO_MODE; // 按分比例处理モード
		taxRateLst.sort();
		if(reducedProMode == REDUCED_TAXRATE_MAX_MODE){
			List<Decimal> taxRateAscLst = new List<Decimal>();
			for(Integer i = (taxRateLst.size() - 1); i >= 0; i--){
				taxRateAscLst.add(taxRateLst[i]);
			}
			taxRateLst = taxRateAscLst;
		}
		for (Decimal taxRate : taxRateLst) {
			TaxRowData taxRow = taxRowDataMap.get(taxRate);
			/** 值引【税込】= 值引【税拔】 + 值引【总消费税金额】
			** keyDiscountRatio =>: 構成比率 = 每笔  合計税抜  / W：GrandTota
			-------------传入的值引为--值引【税拔】------------------------------------
			** (値引【税抜】 * 構成比率 * 当前消费税).小数点处理【跟着共同定义走】 = 当前值引的消费税金额
			** 把每笔值引消费税金额 累加 = 值引【总消费税金额】
			-------------传入的值引为--值引【税込】------------------------------------
			** (値引【税込】 / (1 + 構成比率1 * 当前消费税1 + 構成比率2 * 当前消费税2 + ....)).小数点处理【跟着共同定义走】 = 值引【税抜】
			** 值引【税込】 - 值引【税抜】 = 值引【总消费税金额】
			**/
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			if(taxRate != 0){
				// 税抜 比率
				Decimal keyDiscountRatio = sumRowData.priceAmountSum == 0 ? 0 : taxRow.amountIncTax / sumRowData.priceAmountSum;
				larger = math.max(keyDiscountRatio, larger);
				// 集计占比例最大的税种别
				disTaxMaxMap.put(larger, taxRate);
				// 值引行Info
				DisRowData disRow = new DisRowData();
				disRow.taxRate = taxRate;
				// 值引拔
				disRow.disUnitPriceSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.amountExcTax : ((disEnd * keyDiscountRatio) / (1+taxRate))), gPointLen);
				// 值引税
				disRow.disTaxAmountSum = CommUtils.RoundProcess((disMaxFlg ? taxRow.taxAmount : ((disEnd * keyDiscountRatio) - disRow.disUnitPriceSum)), gPointLen);
				if(!disMaxFlg && (reducedProMode == REDUCED_TAXRATE_MIN_MODE || reducedProMode == REDUCED_TAXRATE_MAX_MODE)){
					if(disEnd >= taxRow.amountIncTax){
						disEnd -= taxRow.amountIncTax;
						// 值引拔
						disRow.disUnitPriceSum = taxRow.amountExcTax;
						// 值引税
						disRow.disTaxAmountSum = taxRow.taxAmount;
					} else {
						// 值引拔
						disRow.disUnitPriceSum = CommUtils.RoundProcess((disEnd / (1+taxRate)), gPointLen);
						// 值引税
						disRow.disTaxAmountSum = CommUtils.RoundProcess((disEnd - disRow.disUnitPriceSum), gPointLen);
						disEnd = 0;
					}
				}
				// 値引 合计值 税拔
				disRowData.disUnitPriceSum += disRow.disUnitPriceSum;
				// 値引き合計行目の金額を計算する（該当金額は税率混在の金額を合計する
				disRowData.disTaxAmountSum += disRow.disTaxAmountSum;
				// 最终差值
				disSumEnd -= (disRow.disUnitPriceSum + disRow.disTaxAmountSum);
				// 值引行集计
				disRowDataLst.add(disRow);
				// 值引行集计
				disRowDataMap.put(taxRate, disRow);
			}
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			taxRowDataLst.add(taxRow); // 消費税リスト情報を格納する
		}
		// 重新排序·升序
		if(reducedProMode == REDUCED_TAXRATE_MAX_MODE){
			taxRateLst.sort();
			// 重置リスト情報を格納する
			taxRowDataLst.clear();
			disRowDataLst.clear();
			for (Decimal taxRate : taxRateLst) {
				// 消費税リスト情報を格納する
				TaxRowData taxRow = taxRowDataMap.get(taxRate);
				if(taxRow != null) taxRowDataLst.add(taxRow);
				// 值引リスト情報を格納する
				DisRowData disRow = disRowDataMap.get(taxRate);
				if(disRow != null) disRowDataLst.add(disRow);
			}
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
		// 値引き明細行目合計値は値引き合計金額と一致しない場合、差分金額は値引行目の税抜列の最大行目に金額を差分設定する
		if(!disMaxFlg && disTaxMaxMap.containsKey(larger) && disSumEnd != 0){
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisRowData disRow = disRowDataMap.get(taxRate);
			// 差值找平
			disRow.disUnitPriceSum += disSumEnd;
			// 总差值找平
			disRowData.disUnitPriceSum += disSumEnd;
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
		
		// 割引後の消費税 = 合計消費税 - 合計 値引金額に対する消費税額
		sumRowData.taxAmount -= disRowData.disTaxAmountSum;
		sumRowData.amountExcTax -= disRowData.disUnitPriceSum;
		// 负值处理(値引き消費税がマイナスの場合)
		if(sumRowData.taxAmount < 0){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH BEGIN
			Decimal taxRate = disTaxMaxMap.get(larger);
			DisRowData disRow = disRowDataMap.get(taxRate);
			// 差值找平
			disRow.disUnitPriceSum -= sumRowData.taxAmount;
			disRow.disTaxAmountSum += sumRowData.taxAmount;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WGCH END
			disRowData.disUnitPriceSum -= sumRowData.taxAmount;
			disRowData.disTaxAmountSum += sumRowData.taxAmount;
			sumRowData.amountExcTax += sumRowData.taxAmount;
			sumRowData.taxAmount -= sumRowData.taxAmount;
		}
		/*
		//　最终隐藏行后MODE处理显示
		if(CommConst.ROW_HIDE_DIS_FLG){
			for(DisRowData disRow : disRowDataLst){
				if(disRow.isDisRowShowFlg) continue;
				for(TaxRowData taxRow : taxRowDataLst){
					if(disRow.taxRate != taxRow.taxRate) continue;
					taxRow.amountExcTax -= disRow.disUnitPriceSum;
					taxRow.taxAmount -= disRow.disTaxAmountSum;
				}
			}
			// 重置リスト情報を格納する
			disRowDataLst.clear();
		}
		*/
	}
	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH BEGIN
	public static Integer getRowBreakNumEnd(SumRowInfo sum) {
		return getRowBreakNumEnd(sum, null);
	}
	public static Integer getRowBreakNumEnd(SumRowInfo sum, String cls) {
		// 显示行数
		Integer rowBreakNumShow = 0;
		// 非表示行数「默认值1:原来的消费税行」
		Integer rowBreakNumHide = 1;
		// 消費税対象行
		// 显示行
		Integer lineSize = sum.taxRowDataLst.Size();
		if(cls == CLASS_MODE.BILL.Name()){
			// head 内容行间距缩小节省行数 by zy BEGIN
			if (lineSize == 4) rowBreakNumShow += 3;
			else if (lineSize > 1 && lineSize < 4) rowBreakNumShow += 2;
			else rowBreakNumShow += 1;
			// head 内容行间距缩小节省行数 by zy END
		} else rowBreakNumShow += lineSize;
		for(TaxRowData item : sum.taxRowDataLst){
			if(item == null) continue;
			// 非表示行
			if((!item.isNoTaxRowShowFlg) || ((CommUtils.nullToZero(item.amountExcTax) + CommUtils.nullToZero(item.taxAmount)) == 0)) rowBreakNumHide += 1;
		}
		// 値引行
		// 显示行
		rowBreakNumShow += sum.disRowDataLst.size();
		for(DisRowData item : sum.disRowDataLst){
			if(item == null) continue;
			// 非表示行
			if((!item.isDisRowShowFlg) || ((CommUtils.nullToZero(item.disUnitPriceSum) + CommUtils.nullToZero(item.disTaxAmountSum)) == 0)) rowBreakNumHide += 1;
		}
		// 合計行
		// 显示行
		if(sum.taxRowDataLst.Size() != 0) rowBreakNumShow += 1;
		// 非表示行
		if((!sum.sumRowData.isSumRowShowFlg) || (sum.taxRowDataLst.Size() == 0)) rowBreakNumHide += 1;
		// 最终显示行
		Integer rowBreakNumEnd = rowBreakNumShow - rowBreakNumHide;
		return rowBreakNumEnd;
	}
	// 2019/10/30 消費税対象、値引行非表示の機能機能対応 WGCH END
	// 合计板块总集合
	public class SumRowInfo{
		public SumRowInfo(){
			// 合計消費税
			taxUnitPriceAll = 0;
			// 対象行Lst
			taxRowDataLst = new List<TaxRowData>();
			// 対象行Map
			taxRowDataMap = new Map<Decimal, TaxRowData>();
			// 値引行
			disRowData = new DisRowData();
			// 値引行Lst
			disRowDataLst = new List<DisRowData>();
			// 値引行Map
			disRowDataMap = new Map<Decimal, DisRowData>();
			// 合计行
			sumRowData = new SumAmountRowData();
		}
		// 合計消費税
		public Decimal taxUnitPriceAll;
		// 対象行Lst
		public List<TaxRowData> taxRowDataLst;
		// 対象行Map <消費税レート, 該当消費税関連の金額合計>
		public Map<Decimal, TaxRowData> taxRowDataMap;
		// 値引行
		public DisRowData disRowData;
		// 値引行Lst
		public List<DisRowData> disRowDataLst;
		// 値引行Map
		public Map<Decimal, DisRowData> disRowDataMap;
		// 合计行
		public SumAmountRowData sumRowData;
	}
	// 转换明细行数据集
	public class ItemData{
		public ItemData(){
			quantity = unitPrice = taxUnitPrice = specialTax = taxRate;
		}
		public Decimal quantity; // 明细-数量
		public Decimal unitPrice; // 明细-单价
		public Decimal taxUnitPrice; // 明细-消費税
		public Decimal specialTax; // 明细-特别税
		public Decimal taxRate; // 明细-特别税
	}
	// 対象
	public class TaxRowData {
		public TaxRowData() {
			taxRate = amountExcTax = amountIncTax = taxAmount = 0;
			isNoTaxPrice = isDiscountTax = true;
		}
		public Decimal taxRate{get{return (CommUtils.nullToZero(taxRate));}set;}	// 消費税率
		public Decimal amountExcTax{get;set;}	// 税抜きの合計金額
		public Decimal amountIncTax{get;set;}	// 税込きの合計金額
		public Decimal taxAmount{get;set;}		// 該当行目の消費税合計
		public Boolean isNoTaxPrice{get; set;}	// 非課税金額
		public Boolean isDiscountTax{get;set;}	// 割引
		public Boolean isNoTaxRowShowFlg{get { return taxRate == 0 ? !CommConst.ROW_HIDE_NOTAX_FLG : true;} set;}	// 値引显示FLG
		// 2019/11/15 PDF性能优化对应 WGCH BEGIN
		public String isRowStyle{get { return isNoTaxRowShowFlg && ((amountExcTax + taxAmount) != 0) ? 'display: true;' : 'display: none;'; } set;}
		// 2019/11/15 PDF性能优化对应 WGCH END
	}
	// 値引
	public class DisRowData {
		public DisRowData(){
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ BEGIN
			taxRate = 0;
			// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ END
			disUnitPriceSum = disTaxAmountSum = 0;
		}
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ BEGIN
		public Decimal taxRate{get;set;} //値引き行目の税率情報を格納する
		// 2019/10/12 8と10％が混在する為、値引きも両方表記の対応 WSQ END
		public Decimal disUnitPriceSum{get;set;} // 税抜きの合計金額
		public Decimal disTaxAmountSum{get;set;} // 該当行目の消費税合計
		public Boolean isDisRowShowFlg{get {return !CommConst.ROW_HIDE_DIS_FLG;} set;}	// 値引显示FLG
		// 2019/11/15 PDF性能优化对应 WGCH BEGIN
		public String isRowStyle{get { return isDisRowShowFlg && ((disUnitPriceSum + disUnitPriceSum) != 0) ? 'display: true;' : 'display: none;'; } set;}
		// 2019/11/15 PDF性能优化对应 WGCH END
	}
	// 合计
	public class SumAmountRowData {
		public SumAmountRowData() {
			taxAmount = amountExcTax = amountIncTax = priceAmountSum = 0;
		}
		public Decimal taxAmount{get;set;} // 該当行目の消費税合計
		public Decimal amountExcTax{get;set;} // 合计税拔
		public Decimal amountIncTax{get;set;} // 合计税込
		public Decimal priceAmountSum{get;set;} // 课税合计税込
		public Boolean isSumRowShowFlg{get { return !CommConst.ROW_HIDE_SUM_FLG;} set;}	// 合計显示FLG
	}
	// 2019/10/30 軽減税率割合モード機能対応 WGCH END
	// 2019/10/18 領収証内税修正 WGCH BEGIN
	public static Decimal getReceiptTax(Decimal paymented, SumAmountRowData sumRowData){
		Decimal ratio = (sumRowData.amountExcTax + sumRowData.taxAmount) == 0 ? 0 : (paymented / (sumRowData.amountExcTax + sumRowData.taxAmount));
		return CommUtils.RoundProcess(((1 - ratio) * sumRowData.taxAmount), gPointLen);
	}
	// 2019/10/18 領収証内税修正 WGCH END
	// 2018/09/25 自動採番機能を新規追加 WSQ BEGIN
	public static map<Integer, String> getBulkAutoNumer(List<Integer> indexLst) {
		// 処理途中データ格納
		map<Integer,JinyaAutoNumber__c> rsMap = new map<Integer, JinyaAutoNumber__c>();
		// 返却結果情報を格納
		map<Integer, String> retMap = new map<Integer, String>();
		//List<JinyaAutoNumber__c> insLst = new List<>
		for (Integer i : indexLst) {
			rsMap.put(i, new JinyaAutoNumber__c());
		}
		Savepoint sp = Database.setSavepoint();
		try {
			insert rsMap.values();
			set<Id> idSet = new set<Id>();
			for (JinyaAutoNumber__c rs : rsMap.values()) {
				idSet.add(rs.Id);
			}
			Map<Id,JinyaAutoNumber__c> insRsMap = new Map<Id, JinyaAutoNumber__c>([select Id, CommAutoNumber10__c from JinyaAutoNumber__c where id in:idSet Order by Id]);
			for (Integer key : rsMap.keySet()) {
				Id findId = rsMap.get(key).Id;
				retMap.put(key, insRsMap.get(findId).CommAutoNumber10__c);
			}
		} finally {
			Database.rollback(sp);
		}
		return retMap;
	}
	// 2018/09/25 自動採番機能を新規追加 WSQ END
	// 2019/04/30 増税仮対応 WGCH BEGIN
	// 增税商品json数据
	public String taxIncMstItemJson{get;private set;}
	public static String getTaxIncMstJson(){
		// 增税商品json数据 
		return JSON.serialize(getTaxIncMstInfo());
	}
	// 增税商品数集合
	public static TaxIncMstInfo getTaxIncMstInfo(){
		TaxIncMstInfo taxIncMstItem = new TaxIncMstInfo();
		// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH BEGIN
		// List<TaxIncreaseInfo__mdt> taxIncInfoLst = [Select Id, StartDate__c, EndDate__c, TaxIncMstCode__c, TaxIncRate__c From TaxIncreaseInfo__mdt Order By Label limit 1];
		List<TaxIncreaseInfo__mdt> taxIncInfoLst = [Select Id, StartDate__c, EndDate__c, TaxIncMstCode__c, TaxIncRate__c, RoundType__c, FilterMstCode__c From TaxIncreaseInfo__mdt Order By Label limit 1];
		// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH END
		for(TaxIncreaseInfo__mdt taxIncItem : taxIncInfoLst){
			taxIncMstItem.setInfo(taxIncItem);
			break;
		}
		return taxIncMstItem;
	}
	// 增税商品数据集合
	public class TaxIncMstInfo{
		// 变量初始化构造器
		public TaxIncMstInfo(){
			sobj = new TaxIncreaseInfo__mdt();
			startDate = endDate = taxIncMstId = taxIncMstCode ='';
			taxIncRate = 0;
			taxIncMst = new ProductItemUtils.ProductItem(new AccountMaster__c());
		}
		// 变量赋值函数
		public void setInfo(TaxIncreaseInfo__mdt s){
			sobj = s;
			// 開始日->如果null就认为时无限小日期
			Date wkStartDate = s.StartDate__c == null ? Date.newInstance(1900, 1, 1) : s.StartDate__c;
			// 終了日->如果null就认为时无限大日期
			Date wkEndDate = s.EndDate__c == null ? Date.newInstance(2200, 1, 1) : s.EndDate__c;
			// 開始日->固定Format格式*利用于前台脚本比较日期大小
			startDate = DateTime.newInstance(wkStartDate.year(), wkStartDate.month(), wkStartDate.day()).format(g_DateFormat);
			// 終了日->固定Format格式*利用于前台脚本比较日期大小
			endDate = DateTime.newInstance(wkEndDate.year(), wkEndDate.month(), wkEndDate.day()).format(g_DateFormat);
			// 増税商品コード->指定会计商品code
			taxIncMstCode = CommUtils.nullToBlank(s.TaxIncMstCode__c);
			// 増税率->如果null就认为是0
			taxIncRate = CommUtils.nullToZero(s.TaxIncRate__c);
			// 如果増税商品コード有值处理
			if(!CommUtils.isBlank(taxIncMstCode)){
				// 根据指定的増税商品コード获取该商品的数据集合InTheClass*会计商品コード唯一
				List<ProductItemUtils.ProductItem> taxIncMstLst = ProductItemUtils.getArrayProdcutItemByCode(taxIncMstCode);
				// 如果存在
				if(!taxIncMstLst.isEmpty()){
					// 増税商品数据集合
					taxIncMst = taxIncMstLst[0];
					// 増税商品Id
					taxIncMstId = taxIncMst.productId;
				}
			}
			// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH BEGIN
			pointRoundMode = CommUtils.isBlank(s.RoundType__c) ? CommDefine__c.getOrgDefaults().RoundType__c : CommUtils.nullToZero(s.RoundType__c);
			if(pointRoundMode == 0){
				pointRoundModeStr = 'floor'; // 切り捨て
			} else if(pointRoundMode == 1){
				pointRoundModeStr = 'half'; // 四捨五入
			} else if(pointRoundMode == 2){
				pointRoundModeStr = 'ceil'; // 切り上げ
			}
			// 过滤商品code处理
			filterMstCodeSet = new Set<String>();
			for(String filterMstCode : CommUtils.nullToBlank(s.FilterMstCode__c).split(',')){
				if(!CommUtils.isBlank(filterMstCode)) filterMstCodeSet.add(CommUtils.nullToBlank(filterMstCode));
			}
			filterMstIdSet = new Set<String>();
			// 过滤商品code转成对应的商品Id处理
			if(!filterMstCodeSet.isEmpty()){
				for(AccountMaster__c accMst : [Select Id From AccountMaster__c Where Field3__c In: filterMstCodeSet]){
					filterMstIdSet.add(CommUtils.nullToBlank(accMst.Id));
				}
			}
			// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH END
		}
		public TaxIncreaseInfo__mdt sobj{get; set;} // 增税商品MDT数据源
		public String startDate{get; set;} // 增税-開始日
		public String endDate{get; set;} // 增税-開始日
		public String taxIncMstId{get; set;} // 增税-終了日
		public String taxIncMstCode{get; set;} // 增税-増税商品コード
		public Decimal taxIncRate{get; set;} // 增税-増税率
		public ProductItemUtils.ProductItem taxIncMst{get; set;} // 增税-増税商品数据集合
		public String g_DateFormat{get{ return CommBaseCtrl.getDateFormat();} set;} // 日期-FORMAT
		// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH BEGIN
		public Decimal pointRoundMode{get; set;} // 增税-増税商品数据集合
		public String pointRoundModeStr{get; set;} // 增税-増税商品数据集合
		public Set<String> filterMstCodeSet{get; set;} // 过滤处理商品code集合
		public Set<String> filterMstIdSet{get; set;} // 过滤处理商品Id集合
		// 2019/05/31 消費税の端数計算は見積書と一致しなかった、対応 WGCH END
	}
	// 2019/04/30 増税仮対応 WGCH END
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
	// 施設コードにより、会計書の敬称有効かどうか判断する
	public static Boolean isShowRespectLst(string fc) {
		return (CommConst.RESPECT_ISSHOW_FLG && (fc == '33' || fc == '34' || fc == '35' || fc == '36'));
	}
	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH BEGIN
	// 获取管理员信息
	public static AccountAdminInfo getAccountAdminInfo(){
		// 管理员信息
		AccountAdminInfo accAdminItem = new AccountAdminInfo();
		// 当前UserName
		String userName = CommUtils.nullToBlank(UserInfo.getUserName());
		// 获取会计管理员一览
		List<AccountAdministrator__mdt> rsLst = [ Select Id, AdministratorsName__c, ShopCode__c From AccountAdministrator__mdt
													Where isInvalidFlg__c = false Order By Label];
		for(AccountAdministrator__mdt rs : rsLst){
			// 管理员Flg
			Boolean accountAdminFlg = CommUtils.nullToBlank(rs.AdministratorsName__c) == userName;
			// 非管理员跳出到下一次循环
			if(!accountAdminFlg) continue;
			// 该用户对应的管理店铺code
			for(String spcd : CommUtils.nullToBlank(rs.ShopCode__c).split(',')){
				if(CommUtils.isBlank(spcd)) continue;
				accAdminItem.spcdSet.add(CommUtils.nullToBlank(spcd));
			}
			accAdminItem.isAdminFlg = true;
			// 调用时只有一个User, 满足条件就跳出
			break;
		}
		// 管理员用户信息
		return accAdminItem;
	}
	// 管理员设定信息
	public class AccountAdminInfo{
		public AccountAdminInfo(){
			isAdminFlg = false;
			spcdSet = new Set<String>();
		}
		public Boolean isAdminFlg{get; set;} // 管理员Flg
		public Boolean isSpcdAllAdminFlg{get { return spcdSet.isEmpty();} set;} // 管理全店铺FLG
		public Set<String> spcdSet{get; set;} // 管理的店铺Code
	}
	// 共同Lock设定信息
	public class ComDay{
		public ComDay(){
			// 当前系统时间
			preDate = Date.today();
			// 功能开关
			isLockFlg = false;
			// PDF发行人员权限Mode
			pdfLockMode = '0';
			// 指定加几月数值
			addMonthsVal = 0;
			// 指定几号
			daysVal = 1;
		}
		public Boolean setComDay(){
			// 获取锁定日期定义信息
			String commDay = CommConst.COM_CUTOFFDAY;
			if(CommUtils.isBlank(commDay)) return isLockFlg;
			// 设定信息解析
			String[] comVal = commDay.split(';');
			// PDF发行人员权限Mode设定
			if(comVal.size() > 1) pdfLockMode = CommUtils.nullToBlank(comVal[1]);
			// 获取锁定日期设定
			String[] val = comVal[0].split(':');
			if(val.size() > 1){
				// 功能开关
				isLockFlg = true;
				// 指定加几月数值
				addMonthsVal = CommUtils.nullToIntZero(val[0]);
				// 指定几号
				daysVal = CommUtils.nullToIntZero(val[1]);
			} else return isLockFlg;
			return isLockFlg;
		}
		public Date preDate{get; set;} // 当前系统时间
		public Boolean isLockFlg{get; set;} // 功能开关
		public String pdfLockMode{get; set;} // 0: 所有的人都不可以; 1: 管理者可以; 2: 所有的人都可以;
		public Integer addMonthsVal{get; set;} // 指定加几月数值
		public Integer daysVal{get; set;} // 指定几号
	}
	public static Boolean isAccLockFlg(AccountAcount__c acc, AccountAdminInfo accAdminItem, ComDay comItem){
		return isAccLockFlg(acc, accAdminItem, comItem, false);
	}
	// 验证此会计是否已锁定
	public static Boolean isAccLockFlg(AccountAcount__c acc, AccountAdminInfo accAdminItem, ComDay comItem, Boolean isPDF){
		// 会计锁定功能关闭跳出
		if(!comItem.isLockFlg) return false;
		// 会计的「売上計上日」
		Date salesdayCal = acc.SalesdayCal__c;
		// 会计的「売上計上日」-无效跳出
		if(salesdayCal == null) return false;
		// Lock日期设定
		Date lockDt = Date.newInstance(salesdayCal.year(), (salesdayCal.month() + comItem.addMonthsVal), comItem.daysVal);
		// 今日大于此会计的Lock日期需要加锁处理
		if(comItem.preDate > lockDt){
			Boolean isAccAdmin = confirmAdmin(accAdminItem, acc.ShopCode__c);
			// PDF处理
			if(isPDF){
				// 0: 所有的人都不可以; 1: 管理者可以; 2: 所有的人都可以;
				if((comItem.pdfLockMode == '0') && isAccAdmin) return true;
				else if((comItem.pdfLockMode == '1') && isAccAdmin) return false;
				else if(comItem.pdfLockMode == '2') return false;
			}
			// 有效管理员确认跳出
			if(isAccAdmin) return false;
			// 锁定场合跳出
			return true;
		}
		// 非锁定场合跳出
		return false;
	}
	// 验证管理员身份
	public static Boolean confirmAdmin(AccountAdminInfo accAdminItem, String spcd){
		// 有效管理员处理
		if(accAdminItem.isAdminFlg){
			// 有效管理员-全店铺管理
			if(accAdminItem.isSpcdAllAdminFlg) return true;
			// 有效管理员-指定店铺管理
			return accAdminItem.spcdSet.contains(CommUtils.nullToBlank(spcd));
		}
		// 无效管理员跳出
		return false;
	}
	// 2019/12/30 会計機能、日付が変わった後、会計データにロックがかかり変更出来ない機能対応 WGCH END
	// 2019/12/30 小部屋の作成 BY zyz BEGIN
	public void autoCreateRoomIndexSub(List<Lead__c> p_leadLst) {
 		// Index オブジェクト情報を取得する
 		List<LeadIndex__c> leadIdxLst = [select id, name, EntryDate__c, DepartureDate__c, Nights__c, Rooms__c, contactRef__c
 												,LeadName__c,EntryTime__c,DepartureTime__c,Payment__c,Comment__c
                    from LeadIndex__c where id = :p_leadLst[0].LeadIndexRef__c];
		if (leadIdxLst.isEmpty()) return;
		// 予約INDEX情報
		LeadIndex__c idxInfo = leadIdxLst[0];
		// LeadIndex__c的数据Map
		map<Integer,LeadIndex__c> newIndexSubMap = new map<Integer,LeadIndex__c>();
		// Lead__c的数据Map
		map<Integer,Lead__c> newLeadSubMap = new map<Integer,Lead__c>();
		// 循环予约做indexsub
        for(Integer i=0;i < p_leadLst.size();i++){
        	if (p_leadLst[i].LeadIndexRef__c == null) throw new CommException('Required Field Value Not Setup!');
        	Lead__c leadInfo = p_leadLst[i];
        	date DepartureDate = Date.newInstance(leadInfo.Departure__c.year(),leadInfo.Departure__c.month(),leadInfo.Departure__c.day());
        	date EntryTimeDate = Date.newInstance(leadInfo.EntryTime__c.year(),leadInfo.EntryTime__c.month(),leadInfo.EntryTime__c.day());
        	Integer nights = EntryTimeDate.daysBetween(DepartureDate);
            LeadIndex__c nwSub = new LeadIndex__c();
            nwSub.ParentLeadIndxRef__c = idxInfo.Id;
            // エキストラベッド(E/B)
            nwSub.ExtraBedChk__c = leadInfo.ExtraBedChk__c;
            nwSub.PlanRef__c = leadInfo.Field310__c;
            nwSub.Nights__c = nights;
            nwSub.Rooms__c = CommUtils.nullToZero(idxInfo.Rooms__c) == 0 ? 1 : CommUtils.nullToZero(idxInfo.Rooms__c);
            nwSub.RoomTypeRef__c = leadInfo.refTypeOfRooms__c;
            nwSub.DepartureDate__c = DepartureDate;
            nwSub.EntryDate__c = EntryTimeDate;
            nwSub.StayPersons__c = leadInfo.StayPersons__c;
            nwSub.contactRef__c = idxInfo.contactRef__c;
            // 出発時刻と到着時刻設定追加
            nwSub.EntryTime__c = leadInfo.Field4__c;
            nwSub.DepartureTime__c = leadInfo.Field3__c;
            nwSub.LeadName__c = leadInfo.Name;
			// 支払方法
			nwSub.Payment__c = idxInfo.Payment__c;
			// 特記事項
			nwSub.Comment__c = idxInfo.Comment__c;
			if (Commconst.BOOKING_FLEX_SEL_ROOM_FLG){
				nwSub.Rooms__c = 1;
			}
			// LeadIndex__c的数据Map
			newIndexSubMap.put(i,nwSub);
			// Lead__c的数据Map
			newLeadSubMap.put(i,leadInfo);
        }
        // 插入LeadIndexSubId
        if (!newIndexSubMap.isEMpty())insert newIndexSubMap.values();
        // 对应予约赋值SubId
        for(Integer Ilead : newLeadSubMap.keyset()){
        	lead__c nwlead = newLeadSubMap.get(Ilead);
        	LeadIndex__c nwSub = newIndexSubMap.get(Ilead);
        	nwlead.LeadIndexSubId__c = nwSub.Id;
        }
	}
	// 2019/12/30 小部屋の作成 BY zyz END
	// 2020/03/31 会計ロック機能 by zy BEGIN
	public static boolean lockCheck(sobject [] nw, sobject[] od){
		return lockCheck(nw,od, false);
	}
	public static boolean lockCheck(sobject [] nw, sobject[] od,boolean isAfter){
		// 機能閉じる
		if (Commconst.RSVACCOUNT_LOCK_TYPE == commconst.RSVACCOUNT_TYPE_INVALID) return false;
		String errorMsg = Label.MSG_006_0459; //エラーメッセージ 
		CommLockInfo lockInfo = new CommLockInfo();
		// tigger after对应
		if (isAfter) lockInfo.isAfter = isAfter;
		Sobject errorObj = null;
		// 新規と更新の場合
		if (nw != null) {
			Map<String, Schema.DescribeFieldResult> finalFieldMap = null;
			// 指定オブジェクト名
			String objName = nw[0].getSObjectType().getDescribe().getName();
			// 最終泊チェック
			lockInfo.filterLastLockSet(objName,nw);
			for (integer i = 0 ; i < nw.size() ; i++) {
				Sobject o = nw[i];
				Sobject old = null;
				if (od != null) old = od[i];
				// ロック処理
				lockInfo.chkLockStatus(old,o,objName);
				if (!lockInfo.dateMap.isEmpty()) break;
			}
			errorObj = nw[0];
		// 削除対応
		} else if (od != null) {
			// 指定オブジェクト名
			String objName = od[0].getSObjectType().getDescribe().getName();
			// 最終泊チェック
			lockInfo.filterLastLockSet(objName,od);
			// 更新作業場合
			for (sobject o : od) {
				// ロック処理
				lockInfo.chkLockStatus(null,o,objName);
				if (!lockInfo.dateMap.isEmpty()) break;
			}
			// エラーメッセージ作成
			errorObj = od[0];
		}
		// エラーメッセージ作成
		if (!lockInfo.dateMap.isEmpty()) {
			// エラーメッセージ合併
			errorMsg = convertErrorMsg(errorMsg,lockInfo.dateMap);
			errorObj.addError(errorMsg);
		}
		return !lockInfo.dateMap.isEmpty();
	}
	private static String convertErrorMsg(String errorMsg , Map<String,String> dateMap ){
		/*
		if (!dateMap.isEmpty() && !dateMap.containsKey('')){
			errorMsg += '（ 売上日：';
			errorMsg += String.join(dateMap.values(),'、');
		} else {
		if (!dateMap.isEmpty()) errorMsg += '（ 該当売上日がロックされました。）'; 
		*/
		return errorMsg;
	}
	// 会計
	private static String OBJ_NAME_ACCOUNT = Schema.AccountAcount__c.getSObjectType().getDescribe().getName();
	// 会計明細
	private static String OBJ_NAME_TRAN = Schema.Tran1__c.getSObjectType().getDescribe().getName();
	// 会計支払い
	private static String OBJ_NAME_TTEND = Schema.Ttend__c.getSObjectType().getDescribe().getName();
	// 売上
	private static String OBJ_NAME_RSV = Schema.RsvAccount__c.getSObjectType().getDescribe().getName();
	// 現金合せ
	private static String OBJ_NAME_CASH = Schema.CashVerification__c.getSObjectType().getDescribe().getName();
	// 入金
	private static String OBJ_NAME_DEP = Schema.deposit__c.getSObjectType().getDescribe().getName();
	// 出金
	private static String OBJ_NAME_PAY = Schema.Paymentslip__c.getSObjectType().getDescribe().getName();
	// 仕入
	private static String OBJ_NAME_PUR = Schema.Purchase__c.getSObjectType().getDescribe().getName();
	private static final String ACC_TRADE_VOID = CommConst.ACC_TRADE_VOID;   
	private static final String RSV_NAME_FORMAT = 'yyyyMMdd';
	public Class CommLockInfo{
		String sobj; // オブジェクト名
		Set<String> noChk; // 不チェック字段
		Set<String> chkSet; // チェック字段
		Set<String> decimalChk; // 数字字段
		List<String> msgField; // メッセージ字段
		Map<String,CommLockInfo> lockMap;
		boolean isAfter = false; // trigger状態
		Map<String,String> dateMap;// 日付のエラー集合
		Map<String, Schema.DescribeFieldResult> finalFieldMap;
		Map<String,Map<String, Schema.DescribeFieldResult>> objFieldMap = new Map<String,Map<String, Schema.DescribeFieldResult>>();
		// 初期化
		public CommLockInfo(){
			dateMap = new Map<String,String>();
			// 売上チェック字段
			Set<String> rsvChkField = new Set<String>{'revpar__c','cuponkomi__c','otherfree__c','chargeofother__c','purchasebridal__c','purchasebeverage__c','kakekeikomi__c','discount2__c','discount__c','initialinventorybridal__c','initialinventorybeverage__c','initialinventorymaterial__c','initialinventoryroom__c','initialinventorystand__c','finalinventorybridal__c','finalinventorybeverage__c','finalinventorymaterial__c','finalinventoryroom__c','finalinventorystand__c','persons__c','salesaverage__c','salesaveragekomi__c','accountingsection__c','genkinkeikomi__c','roomcfree__c','chargeofroom__c','purchaseroom__c','uriagelastyear__c','uchikinkomi__c','restrunt5free__c','restrunt19__c','restrunt4free__c','restraunt3__c','restruntdrinkfree__c','rchargeofdrink__c','restrunt2free__c','restraunt4__c','restrunt17__c','restrunt16__c','frestrunt9__c','restrunt8__c','restrunt1free__c','restraunt2__c','restrunt3free__c','restrunt18__c','restrunt25__c','restraunt1__c','restruntmealfree__c','rchargeofmeal__c','nyuutoum__c','nyuuyokufree__c','chargeofonsen__c','uriage6__c','uriage6total__c','futureyen__c','baitenfree__c','chargeofbaiten__c','purchasestand__c','front5free__c','fornt2__c','front4free__c','field4__c','front2free__c','front3__c','front17__c','front16__c','front9__c','front8__c','front1free__c','front7__c','front26__c','front3free__c','front6__c','front25__c','front1__c','purchaseexpenses__c','mealfree__c','chargeofmeal__c','purchaseruikei__c','mealsalesfree__c','mealsalesfreeruikei__c','adr__c'};
			// 会計チェック字段
			Set<String> accChkField = new Set<String>{'field39__c','discount__c','field126__c','field110__c','field111__c','field112__c','field113__c','field114__c','field115__c','field116__c','field117__c','field140__c','frs__c'};
			// 会計明細チェック字段
			Set<String> tranChkField = new Set<String>{'field23__c','field21__c','field20__c','field1__c','relaccount__c'};
			//  会計支払いの字段
			Set<String> ttenChkField = new Set<String>{'field16__c','field20__c','cardtypelst__c','field2__c','field3__c','field1__c','relaccount__c','field19__c'}; 
			// 変更不チェック
			Set<String> noCheckSet = new Set<string>{'field22__c','rowno__c','field25__c','cookinfo__c'};
			// 数字特殊対応
			Set<String> checkDecimalSet = new Set<string>{'field20__c','field21__c','field23__c','specialtax__c','servicerate__c'};
			lockMap = new Map<String,CommLockInfo>{
				OBJ_NAME_ACCOUNT => new CommLockInfo(OBJ_NAME_ACCOUNT,accChkField,new Set<String>{'field126__c','field114__c','field116__c'},new Set<String>{'discount__c'},new List<String>{'salesdaycal__c'}),
				OBJ_NAME_TTEND => new CommLockInfo(OBJ_NAME_TTEND,ttenChkField,null,checkDecimalSet,new List<String>{'usedatecal__c'}),
				OBJ_NAME_TRAN => new CommLockInfo(OBJ_NAME_TRAN,tranChkField,new Set<String>{'field23__c'},checkDecimalSet,new List<String>{'usedatecal__c'}),
				OBJ_NAME_RSV => new CommLockInfo(OBJ_NAME_RSV,rsvChkField,null,null,new List<String>{'salesday__c'}),
				// 現金合せ
				OBJ_NAME_CASH => new CommLockInfo(OBJ_NAME_CASH,null,null,null,new List<String>{'salesdatecal__c'}),
				// 入金
				OBJ_NAME_DEP => new CommLockInfo(OBJ_NAME_DEP,null,null,null,new List<String>{'salesdatecal__c'}),
				// 出金
				OBJ_NAME_PAY => new CommLockInfo(OBJ_NAME_PAY,null,null,null,new List<String>{'salesdatecal__c'}),
				// 仕入
				OBJ_NAME_PUR => new CommLockInfo(OBJ_NAME_PUR,null,null,null,new List<String>{'field1__c'})
			};
		}
		// ロック内容設定
		public CommLockInfo(String sobjName,Set<String> chkFieldSet,Set<String> noCheckSet,Set<String> checkDecimalSet,List<String> msgName){
			sobj = sobjName;
			noChk = noCheckSet;
			decimalChk = checkDecimalSet;
			msgField = msgName;
			chkSet = chkFieldSet;
			dateMap = new Map<String,String>();
		} 
		// ロック処理
		public void chkLockStatus(Sobject old,SObject nw,String objName){
			chkLockStatus(old, nw,objName,null);
		}
		// ロック処理対応
		private void chkLockStatus(Sobject old,SObject nw,String objName,CommLockInfo info){
			// 指定オブジェクトのロックのルール取得
			if (info == null) {
				if (lockMap.containsKey(objName)) info = lockMap.get(objName);
				else info = new CommLockInfo(objName,null,null,null,null);
				info.filterSet = filterSet;
				info.isAfter = isAfter;
				info.chkLockStatus(old,nw,objName,info);
				this.dateMap = info.dateMap;
				return;
			}
			// ロックのルール処理
			boolean isLock = (boolean)nw.get('isLockFlg__c');
			boolean isLockFlg = false; // ロックの場合、字段変更フラグ
			Id objId = (Id) nw.get('Id');
			// 変更の場合
			if (old != null){
				// trigger before的场合lockflg用old，after的场合用new
				boolean orgLock = (boolean)old.get('isLockFlg__c');
				// 変更前後、ロック含む「true」変更ない
				isLock = orgLock || isLock;
			}
			// 连泊lock有效
			if (filterSet != null) {
				// 該当明細の予約、最終泊未ロック
				if (!filterSet.contains(CommUtils.nullToBlank(nw.get('leadInfo__c')))) return;
				//  該当売上日未ロックで終日の予約ロックの場合、会計ロック
				// 新規と削除の場合
				if (old == null) {
					isLockFlg = true;
				}
				// 连泊check时其他泊没有被lock对应
				if (!isLock) isLock = true;
			}
			// 指定オブジェクトの字段取得
			if (objId != null) finalFieldMap = CommSqlUtils.getAllFieldLst(objId.getSObjectType(),true,true,false);
			// データロックの場合
			if (isLock) {
				if (old != null && finalFieldMap != null) {
					Set<String> checkSet = finalFieldMap.keySet();
					if (chkSet != null) checkSet = chkSet;
					for (String fieldName : checkSet){
						// 変更不チェック
						if (noChk != null && noChk.contains(fieldName.toLowerCase())) continue;
						if (nw.get(fieldName) != old.get(fieldName)) {
							// 数值型check
							if (decimalChk != null && decimalChk.contains(fieldName.toLowerCase())) {
								String newStr = CommUtils.nullTOBLank(nw.get(fieldName));
								String oldStr = CommUtils.nullTOBLank(old.get(fieldName));
								if(CommUtils.nullToZero(oldStr) == CommUtils.nullToZero(newStr)) continue;
							}
							isLockFlg = true;
							break;
						}
					}
				} else isLockFlg = true;
				if (isLockFlg) {
					String filedName = msgField != null ? msgField[0] : '';
					String salesDtStr = '';
					if (!Commutils.isBlank(filedName)) {
						if (!objFieldMap.containsKey(objName)) objFieldMap.put(objName,CommSqlUtils.getAllFieldLst(nw.getSObjectType(),false,true,false));
						Map<String, Schema.DescribeFieldResult> objMap = objFieldMap.get(objName);
						if (objMap != null && objMap.containsKey(filedName)) {
							Object value = nw.get(filedName);
							Schema.DisplayType typeName = objMap.get(filedName).getType();
							if (typeName == Schema.DisplayType.Date) {
								if (value != null) salesDtStr = Date.valueOf(value).format();
							} else if(typeName == Schema.DisplayType.DateTime) {
								if (value != null) salesDtStr = DateTime.valueOf(value).date().format();
							} else salesDtStr = Commutils.nullToBlank(value);
						}
					} 
					if (!CommUtils.isBlank(salesDtStr)) dateMap.put(salesDtStr,'[' + salesDtStr + ']');
					else dateMap.put(salesDtStr,salesDtStr);
				}
			}
		}
		Set<String> filterSet;
		// 最終泊チェック
		private void filterLastLockSet(String objName,List<Sobject> nw){
			// 最終泊フラグチェック
			if (Commconst.RSVACCOUNT_TYPE_LAST != commconst.RSVACCOUNT_LOCK_TYPE) return;
			// 会計明細と会計支払いの場合
			if (objName == OBJ_NAME_TRAN || objName == OBJ_NAME_TTEND) {
				filterSet = new Set<String>();
				// 連泊指定集合
				Set<Decimal> roomGroupSet = new Set<Decimal>();
				Set<String> leadindexSubs = new Set<String>();
				Set<String> leadindexRefs = new Set<String>();
				// 予約関連の処理対象
				List<Sobject> sobjs = new List<Sobject>();
				// 処理最小日付
				Date orgDt = null;
				// 連泊情報作成
				for (Sobject obj  : nw) {
					// 連泊鍵
					String leadInfo = CommUtils.nullToBlank(obj.get('LeadInfo__c'));
					//予約参照なし
					if (CommUtils.isBlank(leadInfo)) continue;
					//　売上日付
					Date dt = (Date)obj.get('UseDateCal__c');
					// 処理最小日付設定
					if (orgDt == null || orgDt > dt) orgDt = dt;
					// 検索字段設定
					String[] infos = leadInfo.split(':');
					leadindexRefs.add(infos[0]);
					leadindexSubs.add(infos[1]);
					roomGroupSet.add(commutils.nulltozero(infos[2]));
					sobjs.add(obj);
				}
				if (!sobjs.isEmpty() && !leadindexRefs.isEmpty()) {
					Map<String,AccountAcount__c> groupLeadKeyMap = new Map<String,AccountAcount__c>();
					// 取得の会計の最終泊のSQL文
					String leadQuery = 'select id,frs__r.name,isLockFlg__c,Relreserve__r.EntryTime__c, Relreserve__r.LeadIndexRef__c , Relreserve__r.LeadIndexSubId__c , Relreserve__r.roomgroupNo__c from AccountAcount__c  where Relreserve__r.LeadIndexRef__c =  :leadindexRefs and Relreserve__r.LeadIndexSubId__c = :leadindexSubs and Relreserve__r.roomgroupNo__c = :roomGroupSet  And Field39__c != :ACC_TRADE_VOID';
					// インデックスフィルター追加
					if (orgDt != null) {
						String formatDt = datetime.newInstance(orgDt,system.now().time()).format(RSV_NAME_FORMAT); 
						// 該当リストの参照の売上日以後のデータ
						leadQuery += ' and frs__r.name >= :formatDt' ;
					}
					// 最終泊の予約の会計作成
					for (AccountAcount__c acc : Database.query(leadQuery)){
						String key = acc.Relreserve__r.LeadIndexRef__c + ':' + acc.Relreserve__r.LeadIndexSubId__c + ':' + CommUtils.nullToBlank(CommUtils.nullTOIntZero(acc.Relreserve__r.roomgroupNo__c));
						if (!groupLeadKeyMap.containsKey(key) || 
							// 既存到着日＜該当到着日
							groupLeadKeyMap.get(key).Relreserve__r.EntryTime__c < acc.Relreserve__r.EntryTime__c) groupLeadKeyMap.put(key,acc);
					}
					// 最終泊の予約の売上ロックチェック
					for (Sobject obj : sobjs) {
						String leadInfo = CommUtils.nullToBlank(obj.get('LeadInfo__c'));
						// 既存売上
						if (filterSet.contains(leadInfo)) continue;
						// 該当ロック売上の予約鍵追加
						if (groupLeadKeyMap.containsKey(leadInfo) && groupLeadKeyMap.get(leadInfo).isLockFlg__c ) filterSet.add(leadInfo);
					}
				}
			}
		}
	}
	// 2020/03/31 会計ロック機能 by zy END
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	// 2020/05/29 bug fixed 6437 WGCH BEGIN
	public static String getNwOptionPlanKey(String optionPlanKey){
		String SYM = '_';
		// [0]DataID_[1]会计商品ID_[2]OptionNo_[3]分割No_[4](合计税込/数量)
		String[] optionPlanKeyArr = CommUtils.nullToBlank(optionPlanKey).split(SYM);
		String nwOptionPlanKey = '';
		for(Integer i = 0; i < optionPlanKeyArr.size(); i++){
			// 当它是分割No跳出
			if(i == 3) continue;
			nwOptionPlanKey += optionPlanKeyArr[i] + SYM;
		}
		return nwOptionPlanKey.removeEnd(SYM);
	}
	public static OptionPlanInfo getOptionPlanInfo(List<BookingEstimateItem__c> bookingEstimateLst){
		return getOptionPlanInfo(bookingEstimateLst, false);
	}
	public static OptionPlanInfo getOptionPlanInfo(List<BookingEstimateItem__c> bookingEstimateLst, Boolean isGroupShowFlg){
		OptionPlanInfo optionItem = new OptionPlanInfo();
		for(BookingEstimateItem__c sobj : BookingEstimateLst){
			// [0]预约ID_[1]会计商品ID_[2]OptionNo_[3]分割No_[4](合计税込/数量)
			String optionPlanKey = sobj.OptionPlanKey__c;
			// 分割KEY获取处理
			if(!isGroupShowFlg){
				optionPlanKey = getNwOptionPlanKey(optionPlanKey);
			}
			if(!CommUtils.isBlank(optionPlanKey) ){
			   if(!optionItem.planHeaderNumMap.containsKey(optionPlanKey)){
			   		optionItem.planEstIdSet.add(sobj.Id);
					optionItem.nwBookingEstimateLst.add(sobj);
					optionItem.planHeaderKeyMap.put(sobj.Id, optionPlanKey);
					optionItem.planHeaderNumMap.put(optionPlanKey, 0);
					optionItem.planHeaderTaxMap.put(optionPlanKey, 0);
				}
				Decimal amountSum = CommUtils.nullToZero(sobj.Amount__c) + optionItem.planHeaderNumMap.get(optionPlanKey);
				optionItem.planHeaderNumMap.put(optionPlanKey, amountSum);
				Decimal specialTaxSum = CommUtils.nullToZero(sobj.SpecialTax__c) + optionItem.planHeaderTaxMap.get(optionPlanKey);
				optionItem.planHeaderTaxMap.put(optionPlanKey, specialTaxSum);
			} else {
				optionItem.planEstIdSet.add(sobj.Id);
				optionItem.nwBookingEstimateLst.add(sobj);
			}
		}
		return optionItem;
	}
	public static OptionPlanInfo getOptionPlanInfo(List<Tran1__c> tran1Lst){
		return getOptionPlanInfo(tran1Lst, false);
	}
	public static OptionPlanInfo getOptionPlanInfo(List<Tran1__c> tran1Lst, Boolean isGroupShowFlg){
		OptionPlanInfo optionItem = new OptionPlanInfo();
		for(Tran1__c sobj : tran1Lst){
			// [0]会计ID_[1]会计商品ID_[2]OptionNo_[3]分割No_[4](合计税込/数量)
			String optionPlanKey = sobj.ParentTran1Ref__r.OptionPlanKey__c;
			// 分割KEY获取处理
			if(!isGroupShowFlg){
				optionPlanKey = getNwOptionPlanKey(optionPlanKey);
			}
			if(!CommUtils.isBlank(optionPlanKey)){
				if(optionItem.planEstIdSet.contains(sobj.ParentTran1Ref__c)) continue;
				optionItem.planEstIdSet.add(sobj.ParentTran1Ref__c);
				if(!optionItem.planHeaderNumMap.containsKey(optionPlanKey)){
					optionItem.planHeaderKeyMap.put(sobj.ParentTran1Ref__c, optionPlanKey);
					optionItem.planHeaderNumMap.put(optionPlanKey, 0);
					optionItem.planHeaderTaxMap.put(optionPlanKey, 0);
				}
				Decimal amountSum = CommUtils.nullToZero(sobj.ParentTran1Ref__r.Field21__c) + optionItem.planHeaderNumMap.get(optionPlanKey);
				optionItem.planHeaderNumMap.put(optionPlanKey, amountSum);
				Decimal specialTaxSum = CommUtils.nullToZero(sobj.ParentTran1Ref__r.SpecialTax__c) + optionItem.planHeaderTaxMap.get(optionPlanKey);
				optionItem.planHeaderTaxMap.put(optionPlanKey, specialTaxSum);
			} else if(!CommUtils.isBlank(sobj.ParentTran1Ref__c)) {
				optionItem.planEstIdSet.add(sobj.ParentTran1Ref__c);
			}
		}
		return optionItem;
	}
	// 2020/05/29 bug fixed 6437 WGCH END
	public class OptionPlanInfo{
		public OptionPlanInfo(){
			planEstIdSet = new Set<String>();
			planHeaderKeyMap = new Map<String, String>();
			planHeaderNumMap = new Map<String, Decimal>();
			planHeaderTaxMap = new Map<String, Decimal>();
			nwBookingEstimateLst = new List<BookingEstimateItem__c>();
		}
		public Set<String> planEstIdSet;
		public Map<String, String> planHeaderKeyMap;
		public Map<String, Decimal> planHeaderNumMap;
		public Map<String, Decimal> planHeaderTaxMap;
		public List<BookingEstimateItem__c> nwBookingEstimateLst;
	}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
// 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
// プランの入湯税に自動入力フラグ
public static String bTaxSetMode{get{ return CommConst.PLAN_BATHTAXAUTOSET_MODE;} set;}
/*
* proLeadLst: 含有要处理的所有预约Lst「如有有非处理的预约, 必须要在oldLeadLst里配置」
* lastInsItems: 要处理的预约予約見積明細「要处理的包含在内就行」
* oldLeadLst: 非处理的预约Lst「过滤掉proLeadLst里的非处理预约」
*/
public static List<BookingEstimateItem__c> getBathTaxBookEstLst(List<Lead__c> proLeadLst, List<BookingEstimateItem__c> lastInsItems){
	return getBathTaxBookEstLst(proLeadLst, lastInsItems, new List<Lead__c>());
}
public static List<BookingEstimateItem__c> getBathTaxBookEstLst(List<Lead__c> proLeadLst, List<BookingEstimateItem__c> proBookEstLst, List<Lead__c> oldLeadLst){
	// 新规关联的入汤税商品数据集合
	List<BookingEstimateItem__c> bathTaxBookEstLst = new List<BookingEstimateItem__c>();
	// 获取新预约数据集合
	List<Lead__c> newLeadLst = getNwLeadLst(proLeadLst, oldLeadLst);
	// 处理入汤税商品信息
	ProBathTaxMstInfo proBathTaxMst = getProBathTaxMstInfo(proBookEstLst);
	// 无有效数据终止处理
	if(proBathTaxMst.accMstLst.isEmpty()) return bathTaxBookEstLst;
	// 处理新预约数据集合
	bathTaxBookEstLst.addAll(getInsBathTaxBookEstLst(newLeadLst, proBookEstLst, proBathTaxMst));
	// 处理旧预约数据集合
	bathTaxBookEstLst.addAll(getInsBathTaxBookEstLst(oldLeadLst, proBookEstLst, proBathTaxMst));
	return bathTaxBookEstLst;
}
// 获取入汤税商品对应的新规予約見積明細数据集合
public static List<BookingEstimateItem__c> getInsBathTaxBookEstLst(List<Lead__c> proLeadLst, List<BookingEstimateItem__c> proBookEstLst, ProBathTaxMstInfo proBathTaxMst){
	// 新规关联的入汤税商品数据集合
	List<BookingEstimateItem__c> bathTaxBookEstLst = new List<BookingEstimateItem__c>();
	// 处理预约信息数据集合分类
	ProLeadInfo proLead = getProLeadInfo(proLeadLst);
	// 无有效数据终止处理
	if(proLead.proLeadMap.isEmpty()) return bathTaxBookEstLst;
	// 获取予約見積明細处理分类集合
	proLead.proBookEst = getProBookEstInfo(proLead, proBookEstLst);
	// 获取入汤税商品对应的新规予約見積明細数据集合
	return getInsBathTaxBookEstLst(proBathTaxMst, proLead);
}
// 获取入汤税商品对应的新规予約見積明細数据集合
public static List<BookingEstimateItem__c> getInsBathTaxBookEstLst(ProBathTaxMstInfo proBathTaxMst, ProLeadInfo proLead){
	// 新规关联的入汤税商品数据集合
	List<BookingEstimateItem__c> bathTaxBookEstLst = new List<BookingEstimateItem__c>();
	try {
		// 防御处理
		if(proLead == null || proLead.proLeadMap.isEmpty()) return bathTaxBookEstLst;
		// 有效的入汤税商品->予約見積明細处理
		for(String bathTaxMstId : proBathTaxMst.bathTaxMstMap.KeySet()){
			// 防御处理
			if(!proBathTaxMst.bathTaxMstPlanMstSetMap.containsKey(bathTaxMstId)) continue;
			// 该入汤税商品
			AccountMaster__c bathTaxMst = proBathTaxMst.bathTaxMstMap.get(bathTaxMstId);
			// 新规作成入汤税对应的予約見積明細数据
			for(Lead__c lead : proLead.proLeadMap.values()){
				// 预约ID
				String leadId = lead.Id;
				// 2020/07/09 BUG-FIX-#6995 WGCH BEGIN
				// 相同预约—相同商品,Key
				String bathTaxMstKey = getAccMstNumsKey(leadId, bathTaxMstId);
				// 存在入汤税商品跳出集计
				if(proLead.proBookEst.accMstNumsMap.containsKey(bathTaxMstKey)) continue;
				// 2020/07/09 BUG-FIX-#6995 WGCH END
				// 入汤税的数量
				Decimal amount = 0;
				for(String planMstId : proBathTaxMst.bathTaxMstPlanMstSetMap.get(bathTaxMstId)){
					if(!proLead.proBookEst.proAccMstIdSet.contains(planMstId)) continue;
					// 参照相同入汤税商品的PLAN数量合计处理gr
					String key = getAccMstNumsKey(leadId, planMstId);
					if(proLead.proBookEst.accMstNumsMap.containsKey(key)) amount += proLead.proBookEst.accMstNumsMap.get(key);
				}
				// 无关联信息跳出
				if(amount == 0) continue;
				// 单价定义区分
				String unitPriceDefKb = '';
				if(proLead.proBookEst.leadBookEstLstMap.containsKey(leadId)){
					for(BookingEstimateItem__c bookEst : proLead.proBookEst.leadBookEstLstMap.get(leadId)){
						unitPriceDefKb = bookEst.UnitPriceDefKb__c;
						break;
					}
				}
				// 单价
				Decimal unitPrice = CommUtils.nullToZero(bathTaxMst.Field5__c);
				// 消费税率
				Decimal taxRate = CommUtils.nullToZero(bathTaxMst.TaxRateCal__c);
				// サービス料
				Decimal serviceRate = CommUtils.nullToZero(bathTaxMst.ServiceRate__c);
				// 调用共通计算公式, 设定单价定义区分
				CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(unitPriceDefKb));
				// 调用计算公式
				priceInfo.process(unitPrice, amount, taxRate, serviceRate);
				// 作成该入汤税对应的予約見積明細
				BookingEstimateItem__c bathTaxBookEst = new BookingEstimateItem__c(
						refBooking__c = leadId,	                       // ご予約
						UnitPriceDefKb__c = unitPriceDefKb,            // 単価定義区分の自動設定
						refAccountMaster__c  = bathTaxMst.Id,          // 商品コード
						ActionType__c = bathTaxMst.ActionType__c,      // 商品処理種別
						TaxRate__c = taxRate,                          // 消費税
						ServiceRate__c = serviceRate,                  // サービス料
						UnitPrice__c = unitPrice,                      // 単価
						Amount__c = amount,                            // 数量
						SpTotal__c = priceInfo.priceIncTax,            // $合計金額(税込)
						ProductName__c = bathTaxMst.Name,              // 会计商品名字
						SpecialTax__c = bathTaxMst.SpecialTax__c,      // 特别税
						Field3__c = bathTaxMst.Field3__c               // 商品コード
				);
				// ADD当前入汤税对应的予約見積明細数据
				bathTaxBookEstLst.add(bathTaxBookEst);
			} // FOR 处理预约循环 END
		}
	} catch(Exception e) {}
	return bathTaxBookEstLst;
}
// 处理预约信息数据集合分类
public static ProLeadInfo getProLeadInfo(List<Lead__c> proLeadLst){
	ProLeadInfo proItem = new ProLeadInfo();
	try {
		// 防御处理
		if(proLeadLst == null || proLeadLst.isEmpty()) return proItem;
		// プランの入湯税に自動入力フラグ
		String bTaxSetMode = CommConst.PLAN_BATHTAXAUTOSET_MODE;
		if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_1) return proItem;
		proItem.proLeadLst = proLeadLst;
		// 处理所有预约的数据集合分类等
		for(Lead__c lead : proItem.proLeadLst){
			// 到着日
			DateTime entryTime = lead.EntryTime__c;
			// 无效到着日跳出处理
			if(entryTime == null) continue;
			// 集计到着日关联数据信息
			if(!proItem.entryTimeLst.contains(entryTime)){
				proItem.entryTimeLst.add(entryTime);
				proItem.entryTimeLeadMap.put(entryTime, new List<Lead__c>());
			}
			// 同一到着日预约数据集合处理
			proItem.entryTimeLeadMap.get(entryTime).add(lead);
			// ONEROOMの識別キー
			String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
			// 同一房间的预约集合处理
			if(!proItem.oneRoomLeadLstMap.containsKey(key)) proItem.oneRoomLeadLstMap.put(key, new List<Lead__c>());
			proItem.oneRoomLeadLstMap.get(key).add(lead);
		}
		// 到着日排序, 目的获取最新的第一泊日日期
		proItem.entryTimeLst.sort();
		// Mode2每笔预约都对应的关联设定
		if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_2) proItem.proEntryTimeLst.addAll(proItem.entryTimeLst);
		// Mode3多泊的关联的入汤税关联到第一泊上
		else if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_3 && !proItem.entryTimeLst.isEmpty()) proItem.proEntryTimeLst.add(proItem.entryTimeLst[0]);
		// 处理预约数据
		for(DateTime entryTime : proItem.proEntryTimeLst){
			// 非处理到着日跳出
			if(!proItem.entryTimeLeadMap.containsKey(entryTime)) continue;
			for(Lead__c lead : proItem.entryTimeLeadMap.get(entryTime)){
				proItem.proLeadMap.put(lead.Id, lead);
			}
		}
	} catch(Exception e) {}
	return proItem;
}
public class ProLeadInfo{
	public ProLeadInfo(){
		// 处理预约集合
		proLeadLst = new List<Lead__c>();
		// 所有预约的到着日集合
		entryTimeLst = new List<DateTime>();
		// 到着日对应的预约集合; KEY: 到着日, Val: 当前的预约List
		entryTimeLeadMap = new Map<DateTime, List<Lead__c>>();
		// 同一个房间的预约集合; KEY: ONEROOMの識別キー, Val: 同一个房间的预约List
		oneRoomLeadLstMap = new Map<String, List<Lead__c>>(); 
		// 当前要处理的到着日数据
		proEntryTimeLst = new List<DateTime>();
		// 当前要处理的预约数据集合
		proLeadMap = new Map<String, Lead__c>();
		// 予約見積明細处理分类集合
		proBookEst = new ProBookEstInfo();
	}
	public List<Lead__c> proLeadLst{get; set;} // 处理预约集合
	public List<DateTime> entryTimeLst{get; set;} // 所有预约的到着日集合
	public Map<DateTime, List<Lead__c>> entryTimeLeadMap{get; set;} // 到着日对应的预约集合; KEY: 到着日, Val: 当前的预约List
	public Map<String, List<Lead__c>> oneRoomLeadLstMap{get; set;} // 同一个房间的预约集合; KEY: ONEROOMの識別キー, Val: 同一个房间的预约List
	public List<DateTime> proEntryTimeLst{get; set;} // 当前要处理的到着日数据
	public Map<String, Lead__c> proLeadMap{get; set;} // 当前要处理的预约数据集合
	public ProBookEstInfo proBookEst{get; set;} // 予約見積明細处理分类集合
}
// 获取予約見積明細处理分类集合
public static ProBookEstInfo getProBookEstInfo(ProLeadInfo proLead, List<BookingEstimateItem__c> proBookEstLst){
	ProBookEstInfo proItem = new ProBookEstInfo();
	try {
		// 防御处理
		if(proBookEstLst == null || proBookEstLst.isEmpty() || proLead.proLeadMap.isEmpty()) return proItem;
		// 处理的予約見積明細集合
		proItem.proBookEstLst = proBookEstLst;
		// 处理予約見積明細数据集合
		for(BookingEstimateItem__c bookEst : proItem.proBookEstLst){
			// PLANBRKDOWN数据跳出处理
			if(bookEst.ParentBookingItemRef__c != null) continue;
			// 预约ID
			String leadId = bookEst.refBooking__c;
			// 同一预约的予約見積明細数据集合处理
			if(!proItem.leadBookEstLstMap.containsKey(leadId)) proItem.leadBookEstLstMap.put(leadId, new List<BookingEstimateItem__c>());
			proItem.leadBookEstLstMap.get(leadId).add(bookEst);
			// 非处理对象予約見積明細跳出处理
			if(!proLead.proLeadMap.containsKey(leadId)) continue;
			// 集计处理的会计商品ID
			proItem.proAccMstIdSet.add(bookEst.refAccountMaster__c);
		}
		// 当前要出来的有效数据对应的关联数量合并处理
		for(Lead__c lead : proLead.proLeadMap.values()){
			// 当前相同会计商品数量集合
			proItem.accMstNumsMap = getAccMstNumsMap(lead, proItem.leadBookEstLstMap.get(lead.Id), proItem.accMstNumsMap);
			// 当入汤税在第一泊显示的情况下, 把后几泊的预约对应的予約見積明細数据合计处理
			if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_3){
				// ONEROOMの識別キー
				String key = lead.LeadIndexRef__c + '_' + lead.LeadIndexSubId__c + '_' + lead.RoomGroupNo__c;
				if(!proLead.oneRoomLeadLstMap.containsKey(key)) continue;
				// 处理关联的同一房间的其它预约商品数量集计处理
				for(Lead__c oneRoomLead : proLead.oneRoomLeadLstMap.get(key)){
					// 防止重复集计数量
					if(lead.Id == oneRoomLead.Id) continue;
					// 当前相同会计商品数量集合
					proItem.accMstNumsMap = getAccMstNumsMap(lead, proItem.leadBookEstLstMap.get(oneRoomLead.Id), proItem.accMstNumsMap);
				}
			}
		}
	} catch(Exception e) {}
	return proItem;
}
public class ProBookEstInfo{
	public ProBookEstInfo(){
		// 处理的予約見積明細集合
		proBookEstLst = new List<BookingEstimateItem__c>();
		// 当前要处理的会计商品ID集合
		proAccMstIdSet = new Set<String>();
		// 会计商品对应的数量
		accMstNumsMap = new Map<String, Decimal>();
		// 预约对应的予約見積明細集合
		leadBookEstLstMap = new Map<String, List<BookingEstimateItem__c>>();
	}
	public List<BookingEstimateItem__c> proBookEstLst{get; set;} // 处理的予約見積明細集合
	public Set<String> proAccMstIdSet{get; set;} // 当前要处理的会计商品ID集合
	public Map<String, Decimal> accMstNumsMap{get; set;} // 会计商品对应的数量
	public Map<String, List<BookingEstimateItem__c>> leadBookEstLstMap{get; set;} // 预约对应的予約見積明細集合
}
// 处理入汤税商品信息
public static ProBathTaxMstInfo getProBathTaxMstInfo(List<BookingEstimateItem__c> proBookEstLst){
	ProBathTaxMstInfo bathTaxItem = new ProBathTaxMstInfo();
	try{
		Set<String> proAccMstIdSet = new Set<String>();
		// 处理予約見積明細数据集合
		for(BookingEstimateItem__c bookEst : proBookEstLst){
			// PLANBRKDOWN数据跳出处理
			if(bookEst.ParentBookingItemRef__c != null) continue;
			// 集计处理的会计商品ID
			proAccMstIdSet.add(bookEst.refAccountMaster__c);
		}
		// 防御处理
		if(proAccMstIdSet.isEmpty()) return bathTaxItem;
		// 查询处理的会计商品等相关数据
		String queryStr = ' Select Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Id, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Name, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field3__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.Field5__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.TaxRateCal__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ServiceRate__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.SpecialTax__c, PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r.ActionType__c From AccountMaster__c ';
		queryStr += ' Where Id in: proAccMstIdSet And PlanBathTaxAccMstRef__c != null And PlanBathTaxAccMstRef__r.BathTaxAccMstRef__c != null '; 
		// Plan的会计商品数据集合「Plan内参照入汤税会计商品」
		bathTaxItem.accMstLst = Database.query(queryStr);
		// 当前处理的会计商品分类集合处理
		for(AccountMaster__c accMst : bathTaxItem.accMstLst){
			AccountMaster__c bathTaxMst = accMst.PlanBathTaxAccMstRef__r.BathTaxAccMstRef__r;
			// 无有效的参照入汤商品跳出处理
			if(bathTaxMst == null) continue;
			// 入汤书商品ID
			String bathTaxMstId = bathTaxMst.Id;
			// 参照相同入汤税商品, 不同的PLAN会计商品集合处理; KEY: 入汤税商品ID, VAL: PLAN会计商品ID集合Set
			if(!bathTaxItem.bathTaxMstPlanMstSetMap.containsKey(bathTaxMstId)) bathTaxItem.bathTaxMstPlanMstSetMap.put(bathTaxMstId, new Set<String>());
			bathTaxItem.bathTaxMstPlanMstSetMap.get(bathTaxMstId).add(accMst.Id);
			// 入汤税商品数据集合; KEY: 入汤税商品ID, VAL: 入汤税商品数据
			bathTaxItem.bathTaxMstMap.put(bathTaxMstId, bathTaxMst);
		}
	} catch(Exception e) {}
	return bathTaxItem;
}
public class ProBathTaxMstInfo{
	public ProBathTaxMstInfo(){
		// Plan的会计商品数据集合「Plan内参照入汤税会计商品」
		accMstLst = new List<AccountMaster__c>();
		// 入汤税商品对应的PLAN会计商品集合; KEY: 入汤税商品ID, VAL: PLAN会计商品ID集合Set
		bathTaxMstPlanMstSetMap = new Map<String, Set<String>>();
		// 入汤税商品数据集合; KEY: 入汤税商品ID, VAL: 入汤税商品数据
		bathTaxMstMap = new Map<String, AccountMaster__c>();
	}
	public List<AccountMaster__c> accMstLst{get; set;}
	public Map<String, Set<String>> bathTaxMstPlanMstSetMap{get; set;} // 入汤税商品对应的PLAN会计商品集合; KEY: 入汤税商品ID, VAL: PLAN会计商品ID集合Set
	public Map<String, AccountMaster__c> bathTaxMstMap{get; set;} // 入汤税商品数据集合; KEY: 入汤税商品ID, VAL: 入汤税商品数据
}
// 获取同一预约, 同一会计商品的KEY
public static String getAccMstNumsKey(String leadId, String accMstId){
	// 预约ID_会计商品ID
	return CommUtils.nullToBlank(leadId) + '_' + CommUtils.nullToBlank(accMstId);
}
// 处理会计商品数量合并
public static Map<String, Decimal> getAccMstNumsMap(Lead__c lead, List<BookingEstimateItem__c> proBookEstLst, Map<String, Decimal> accMstNumsMap){
	// 防御处理
	if(proBookEstLst == null) return accMstNumsMap;
	// 当前预约对应的予約見積明細集合
	for(BookingEstimateItem__c bookEst : proBookEstLst){
		// 相同预约—相同商品,Key
		String key = getAccMstNumsKey(lead.Id, bookEst.refAccountMaster__c);
		// 相同预约,相同商品数量集合处理
		if(!accMstNumsMap.containsKey(key)) accMstNumsMap.put(key, 0);
		// 数量累计处理
		Decimal amount = accMstNumsMap.get(key) + CommUtils.nullToZero(bookEst.Amount__c);
		accMstNumsMap.put(key, amount);
	}
	// 所有会计商品对应的数量集合
	return accMstNumsMap;
}
// OTA新规PLAN的获取关联入汤税商品ID处理
public static String getBathTaxAccMstRef(ShopInformation__c shopInf, String oShopCode){
	String bathTaxAccMstRef = null;
	if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_1) return bathTaxAccMstRef;
	// 不存在店铺情报的下的处理Logic
	if(shopInf == null){
		// 会計の入湯税のコード
		String accBathTaxCode = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().AccountBathTaxCode__c);
		// Map<店铺code, 商品code>
		Map<String, String> accBathTaxCodeMap = new Map<String, String>();
		// todo:特殊定义不考虑 例如 =>' C0001: ' 这样的设定认为是他个人设定错误
		// 多店铺定义格式: 01:C0001;02:C0002; * 严格按照店铺code区分没有默认值
		String[] accBathTaxCodeSplit = accBathTaxCode.split(';');
		for(String wkAccBathTaxCode : accBathTaxCodeSplit){
			// 获取多店铺定义详细
			String[] wkAccBathTaxCodeSplit = wkAccBathTaxCode.split(':');
			// 有效定义时处理
			if(wkAccBathTaxCodeSplit.size() == 2){
				String shopCodeStr = CommUtils.nullToBlank(wkAccBathTaxCodeSplit[0]); // 店铺code
				String accBathTaxCodeStr = CommUtils.nullToBlank(wkAccBathTaxCodeSplit[1]); // 商品code
				// 设置Map<店铺code, 商品code> * 重复定义只有第一个设定有效
				if(!accBathTaxCodeMap.containsKey(shopCodeStr)) accBathTaxCodeMap.put(shopCodeStr, accBathTaxCodeStr);
			}
		}
		// 默认值设定
		String accBathTaxCodeFinal = accBathTaxCode;
		// 存在有效多店铺定义的时候处理
		if(accBathTaxCodeMap.size() > 0){
			// 多店铺处理时严格按照店铺code区分没有就跳出处理
			if(accBathTaxCodeMap.containsKey(oShopCode)){
				// 当前店铺有效设定时,code置换处理
				accBathTaxCodeFinal = accBathTaxCodeMap.get(oShopCode);
			}
		}
		// 根据该会計の入湯税のコード获取对应的会计商品DATA
		List<AccountMaster__c> accMstLst = [ Select Id From AccountMaster__c where Field3__c =: accBathTaxCodeFinal];
		// 存在该会计商品的时候, 设定该会计商品ID
		if(!accMstLst.isEmpty()) bathTaxAccMstRef = accMstLst[0].Id;
	} else{
		// 设定该店铺信息对应的入汤税会计商品ID
		bathTaxAccMstRef = shopInf.BathTaxAccMstRef__c;
	}
	// 该关联的入汤税会计商品ID
	return bathTaxAccMstRef;
}
public static List<Lead__c> getNwLeadLst(List<Lead__c> allLeadLst, List<Lead__c> oldLeadLst){
	if(oldLeadLst == null || oldLeadLst.isEmpty()) return allLeadLst;
	// 旧数据LeadIdSet
	Set<String> oldLeadIdSet = new set<String>();
	// 旧预约数据集合
	for(Lead__c lead : oldLeadLst) oldLeadIdSet.add(lead.Id);
	// 新预约数据集合
	List<Lead__c> nwLeadLst = new List<Lead__c>();
	for(Lead__c lead : allLeadLst){
		// 旧预约跳出处理
		if(oldLeadIdSet.contains(lead.Id)) continue;
		// 集计新预约
		nwLeadLst.add(lead);
	}
	return nwLeadLst;
}
/*
* 预约新规场合
* proLead: 要处理的Lead数据集合
* lead: 当前预约
* sobj: 当前予約見積明細
* staysNums: 泊数
*/
public static Boolean proBathTaxAccMst(ProLeadInfo proLead, Lead__c lead, BookingEstimateItem__c sobj, Integer staysNums){
	try {
		// 自動入力の入湯税は1泊目に集める
		if(bTaxSetMode == CommConst.PLAN_BATHTAXAUTOSET_3){
			// 存在要处理的入汤税商品明细
			if(proLead.proBookEst.proAccMstIdSet.contains(sobj.refAccountMaster__c)){
				// 2020/07/30 BUG-FIX-#7088 WGCH BEGIN
				if(CommUtils.nullToZero(staysNums) != 0){
					// 重置数量
					sobj.Amount__c = CommUtils.nullToZero(sobj.Amount__c) * CommUtils.nullToZero(staysNums);
					// 2020/07/30 BUG-FIX-#7037 WGCH BEGIN
					// 重置合计税込金额
					sobj.SpTotal__c = CommUtils.nullToZero(sobj.SpTotal__c) * CommUtils.nullToZero(staysNums);
					// 2020/07/30 BUG-FIX-#7037 WGCH END
				}
				// 2020/07/30 BUG-FIX-#7088 WGCH END
				// 不符合条件数据跳出[到着日]
				if(!proLead.proEntryTimeLst.contains(lead.EntryTime__c)) return true;
			}
		}
	} catch(Exception e) {}
	return false;
}
// 2020/07/30 入湯税の自動入力機能について改善 WGCH END
}